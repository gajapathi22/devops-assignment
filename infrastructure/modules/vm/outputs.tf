# infrastructure/modules/vm/outputs.tf

output "vm_id" {
  description = "ID of the virtual machine"
  value       = azurerm_linux_virtual_machine.main.id
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_linux_virtual_machine.main.name
}

output "public_ip_address" {
  description = "Public IP address of the VM"
  value       = data.azurerm_public_ip.main.ip_address
}

output "private_ip_address" {
  description = "Private IP address of the VM"
  value       = azurerm_network_interface.main.private_ip_address
}

output "ssh_private_key" {
  description = "Private SSH key for connecting to the VM"
  value       = tls_private_key.ssh.private_key_pem
  sensitive   = true
}

output "ssh_connection_command" {
  description = "SSH command to connect to the VM"
  value       = "ssh -i devops-vm-key.pem azureuser@${data.azurerm_public_ip.main.ip_address}"
}