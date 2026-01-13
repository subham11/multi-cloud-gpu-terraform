# Azure Resource Group and Networking

resource "azurerm_resource_group" "rg" {
  count    = 1
  name     = "${var.vm_name}-rg"
  location = var.region

  tags = var.tags
}

# Virtual Network with configurable CIDR
resource "azurerm_virtual_network" "main" {
  count               = 1
  name                = "${var.vm_name}-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.rg[0].location
  resource_group_name = azurerm_resource_group.rg[0].name

  tags = merge(var.tags, { Name = "${var.vm_name}-vnet" })
}

# Optional private DNS zone
resource "azurerm_private_dns_zone" "internal" {
  count               = var.enable_private_dns_zone ? 1 : 0
  name                = var.private_dns_zone_name
  resource_group_name = azurerm_resource_group.rg[0].name

  tags = merge(var.tags, { Name = "${var.vm_name}-pdns" })
}

resource "azurerm_private_dns_zone_virtual_network_link" "internal" {
  count                 = var.enable_private_dns_zone ? 1 : 0
  name                  = "${var.vm_name}-pdns-link"
  resource_group_name   = azurerm_resource_group.rg[0].name
  private_dns_zone_name = azurerm_private_dns_zone.internal[0].name
  virtual_network_id    = azurerm_virtual_network.main[0].id
  registration_enabled  = true
}

# Public Subnets (tier 1)
resource "azurerm_subnet" "public" {
  for_each             = var.public_subnets
  name                 = "${var.vm_name}-${each.key}"
  resource_group_name  = azurerm_resource_group.rg[0].name
  virtual_network_name = azurerm_virtual_network.main[0].name
  address_prefixes     = [each.value.cidr]
  service_endpoints    = ["Microsoft.Storage"]
}

# Private Subnets (tier 2)
resource "azurerm_subnet" "private" {
  for_each             = var.private_subnets
  name                 = "${var.vm_name}-${each.key}"
  resource_group_name  = azurerm_resource_group.rg[0].name
  virtual_network_name = azurerm_virtual_network.main[0].name
  address_prefixes     = [each.value.cidr]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.KeyVault"]
}

# Database Subnets (tier 3)
resource "azurerm_subnet" "database" {
  for_each             = var.enable_database_subnet ? var.database_subnets : {}
  name                 = "${var.vm_name}-${each.key}"
  resource_group_name  = azurerm_resource_group.rg[0].name
  virtual_network_name = azurerm_virtual_network.main[0].name
  address_prefixes     = [each.value.cidr]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.Sql"]
}

# Public IP for Load Balancer
resource "azurerm_public_ip" "lb" {
  count               = 1
  name                = "${var.vm_name}-lb-ip"
  location            = azurerm_resource_group.rg[0].location
  resource_group_name = azurerm_resource_group.rg[0].name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = merge(var.tags, { Name = "${var.vm_name}-lb-ip" })
}

# Public IP for NAT Gateway
resource "azurerm_public_ip" "nat" {
  count               = var.enable_nat_gateway ? 1 : 0
  name                = "${var.vm_name}-nat-ip"
  location            = azurerm_resource_group.rg[0].location
  resource_group_name = azurerm_resource_group.rg[0].name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = merge(var.tags, { Name = "${var.vm_name}-nat-ip" })
}

# NAT Gateway for private subnets
resource "azurerm_nat_gateway" "main" {
  count               = var.enable_nat_gateway ? 1 : 0
  name                = "${var.vm_name}-nat-gw"
  location            = azurerm_resource_group.rg[0].location
  resource_group_name = azurerm_resource_group.rg[0].name

  sku_name = "Standard"

  public_ip_address_ids = var.enable_nat_gateway ? [azurerm_public_ip.nat[0].id] : []

  tags = merge(var.tags, { Name = "${var.vm_name}-nat-gw" })
}

resource "azurerm_subnet_nat_gateway_association" "private" {
  for_each = var.enable_nat_gateway ? azurerm_subnet.private : {}

  nat_gateway_id = azurerm_nat_gateway.main[0].id
  subnet_id      = each.value.id
}

# Route tables for public and private tiers
resource "azurerm_route_table" "public" {
  count               = 1
  name                = "${var.vm_name}-rt-public"
  location            = azurerm_resource_group.rg[0].location
  resource_group_name = azurerm_resource_group.rg[0].name

  route {
    name           = "internet-out"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }

  tags = merge(var.tags, { Name = "${var.vm_name}-rt-public" })
}

resource "azurerm_route_table" "private" {
  count               = 1
  name                = "${var.vm_name}-rt-private"
  location            = azurerm_resource_group.rg[0].location
  resource_group_name = azurerm_resource_group.rg[0].name

  route {
    name           = "internet-via-nat"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }

  tags = merge(var.tags, { Name = "${var.vm_name}-rt-private" })
}

resource "azurerm_subnet_route_table_association" "public" {
  for_each       = azurerm_subnet.public
  subnet_id      = each.value.id
  route_table_id = azurerm_route_table.public[0].id
}

resource "azurerm_subnet_route_table_association" "private" {
  for_each       = azurerm_subnet.private
  subnet_id      = each.value.id
  route_table_id = azurerm_route_table.private[0].id
}

# NSG associations
resource "azurerm_subnet_network_security_group_association" "public" {
  for_each                  = azurerm_subnet.public
  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.main[0].id
}

resource "azurerm_subnet_network_security_group_association" "private" {
  for_each                  = azurerm_subnet.private
  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.main[0].id
}

# Network Watcher and Flow Logs
resource "azurerm_network_watcher" "nw" {
  count               = var.enable_flow_logs ? 1 : 0
  name                = "${var.vm_name}-nw"
  location            = azurerm_resource_group.rg[0].location
  resource_group_name = azurerm_resource_group.rg[0].name
}

resource "azurerm_storage_account" "flowlogs" {
  count                    = var.enable_flow_logs ? 1 : 0
  name                     = substr(lower(replace("${var.vm_name}flowlogs", "-", "")), 0, 24)
  resource_group_name      = azurerm_resource_group.rg[0].name
  location                 = azurerm_resource_group.rg[0].location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  tags = merge(var.tags, { Name = "${var.vm_name}-flowlogs" })
}

resource "azurerm_network_watcher_flow_log" "nsg" {
  count                     = var.enable_flow_logs ? 1 : 0
  network_watcher_name      = azurerm_network_watcher.nw[0].name
  resource_group_name       = azurerm_resource_group.rg[0].name
  target_resource_id        = azurerm_network_security_group.main[0].id
  storage_account_id        = azurerm_storage_account.flowlogs[0].id
  enabled                   = true
  version                   = 2
  retention_policy {
    enabled = true
    days    = 7
  }
}
