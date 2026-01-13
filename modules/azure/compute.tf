# Azure GPU Virtual Machine

locals {
  primary_private_subnet_id = length(azurerm_subnet.private) > 0 ? values(azurerm_subnet.private)[0].id : null
}

resource "azurerm_network_interface" "main" {
  count               = 1
  name                = "${var.vm_name}-nic"
  location            = azurerm_resource_group.rg[0].location
  resource_group_name = azurerm_resource_group.rg[0].name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.primary_private_subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = merge(var.tags, { Name = "${var.vm_name}-nic" })
}

resource "azurerm_network_interface_security_group_association" "main" {
  count                     = 1
  network_interface_id      = azurerm_network_interface.main[0].id
  network_security_group_id = azurerm_network_security_group.main[0].id
}

resource "azurerm_linux_virtual_machine" "gpu" {
  count                 = 1
  name                  = var.vm_name
  resource_group_name   = azurerm_resource_group.rg[0].name
  location              = azurerm_resource_group.rg[0].location
  size                  = var.vm_size
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.main[0].id]
  custom_data           = var.user_data_script

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = merge(var.tags, { Name = var.vm_name, Tier = "compute" })
}
