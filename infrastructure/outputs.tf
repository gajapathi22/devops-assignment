# infrastructure/outputs.tf

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "vm_public_ip" {
  description = "Public IP address of the VM"
  value       = module.vm.public_ip_address
}

output "vm_private_ip" {
  description = "Private IP address of the VM"
  value       = module.vm.private_ip_address
}

output "ssh_connection_command" {
  description = "SSH command to connect to the VM"
  value       = module.vm.ssh_connection_command
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = module.vm.vm_name
}

output "next_steps" {
  description = "Next steps after infrastructure deployment"
  value = <<-EOT
  
  🎉 Infrastructure deployed successfully!
  
  Next steps:
  1. SSH into the VM: ${module.vm.ssh_connection_command}
  2. Start Minikube: minikube start --driver=docker
  3. Deploy your application to Kubernetes
  
  VM Details:
  - Public IP: ${module.vm.public_ip_address}
  - Private IP: ${module.vm.private_ip_address}
  - SSH Key: devops-vm-key.pem (created in current directory)
  
  EOT
}