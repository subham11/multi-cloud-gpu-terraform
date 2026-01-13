# Azure Resource Group and Networking

resource "azurerm_resource_group" "rg" {
  count    = 1
  name     = "${var.vm_name}-rg"
  location = var.region
}

resource "azurerm_virtual_network" "main" {
  count               = 1
  name                = "${var.vm_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg[0].location
  resource_group_name = azurerm_resource_group.rg[0].name
}

resource "azurerm_subnet" "main" {
  count                = 1
  name                 = "${var.vm_name}-subnet"
  resource_group_name  = azurerm_resource_group.rg[0].name
  virtual_network_name = azurerm_virtual_network.main[0].name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "lb" {
  count               = 1
  name                = "${var.vm_name}-lb-ip"
  location            = azurerm_resource_group.rg[0].location
  resource_group_name = azurerm_resource_group.rg[0].name
  allocation_method   = "Static"
  sku                 = "Standard"
}
