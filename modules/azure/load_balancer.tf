# Azure Load Balancer

resource "azurerm_lb" "main" {
  count               = 1
  name                = "${var.vm_name}-lb"
  location            = azurerm_resource_group.rg[0].location
  resource_group_name = azurerm_resource_group.rg[0].name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb[0].id
  }
}

resource "azurerm_lb_backend_address_pool" "main" {
  count           = 1
  loadbalancer_id = azurerm_lb.main[0].id
  name            = "${var.vm_name}-backend-pool"
}

resource "azurerm_network_interface_backend_address_pool_association" "main" {
  count                   = 1
  network_interface_id    = azurerm_network_interface.main[0].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.main[0].id
}

resource "azurerm_lb_probe" "http" {
  count           = 1
  loadbalancer_id = azurerm_lb.main[0].id
  name            = "http-probe"
  protocol        = "Http"
  port            = 5000
  request_path    = "/health"
}

resource "azurerm_lb_rule" "http" {
  count                          = 1
  loadbalancer_id                = azurerm_lb.main[0].id
  name                           = "HTTP"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 5000
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main[0].id]
  probe_id                       = azurerm_lb_probe.http[0].id
  load_distribution              = "Default"
}

resource "azurerm_lb_rule" "https" {
  count                          = 1
  loadbalancer_id                = azurerm_lb.main[0].id
  name                           = "HTTPS"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 5000
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main[0].id]
  probe_id                       = azurerm_lb_probe.http[0].id
  load_distribution              = "Default"
}
