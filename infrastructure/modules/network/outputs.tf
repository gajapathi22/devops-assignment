# infrastructure/modules/network/outputs.tf

output "vnet_id" {
  description = "ID of the Virtual Network"
  value       = azurerm_virtual_network.main.id
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = azurerm_subnet.internal.id
}

output "public_ip_id" {
  description = "ID of the public IP"
  value       = azurerm_public_ip.main.id
}

output "public_ip_address" {
  description = "The actual public IP address"
  value       = azurerm_public_ip.main.ip_address
}

output "network_security_group_id" {
  description = "ID of the Network Security Group"
  value       = azurerm_network_security_group.main.id
}