# Azure Outputs

output "resource_group_name" {
  description = "Resource group name"
  value       = try(azurerm_resource_group.rg[0].name, null)
}

output "vm_id" {
  description = "Virtual machine ID"
  value       = try(azurerm_linux_virtual_machine.gpu[0].id, null)
}

output "load_balancer_ip" {
  description = "Load balancer public IP"
  value       = try(azurerm_public_ip.lb[0].ip_address, null)
}

output "vnet_id" {
  description = "Virtual network ID"
  value       = try(azurerm_virtual_network.main[0].id, null)
}
