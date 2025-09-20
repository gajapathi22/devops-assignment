# infrastructure/modules/vm/main.tf

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# Generate SSH key pair
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private key locally
resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.root}/devops-vm-key.pem"
  file_permission = "0600"
}

# Network Interface
resource "azurerm_network_interface" "main" {
  name                = "nic-${var.vm_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.public_ip_id
  }
}

# Virtual Machine
resource "azurerm_linux_virtual_machine" "main" {
  name                = var.vm_name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_B2s"  # 2 vCPU, 4GB RAM - better for K8s
  admin_username      = "azureuser"
  tags                = var.tags

  # Disable password authentication
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 64
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}

# Data source to get public IP address (after VM is created)
data "azurerm_public_ip" "main" {
  name                = split("/", var.public_ip_id)[8]
  resource_group_name = var.resource_group_name
  depends_on          = [azurerm_linux_virtual_machine.main]
}

# Wait for VM to be fully ready
resource "time_sleep" "wait_for_vm" {
  depends_on      = [azurerm_linux_virtual_machine.main]
  create_duration = "60s"
}

# Null resource to handle provisioning after VM is ready
resource "null_resource" "vm_provisioning" {
  depends_on = [time_sleep.wait_for_vm, data.azurerm_public_ip.main]

  # Copy installation script
  provisioner "file" {
    source      = "${path.root}/scripts/install_tools.sh"
    destination = "/tmp/install_tools.sh"

    connection {
      type        = "ssh"
      user        = "azureuser"
      private_key = tls_private_key.ssh.private_key_pem
      host        = data.azurerm_public_ip.main.ip_address
      timeout     = "10m"
    }
  }

  # Install required tools
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "sudo apt-get update -y",
      "chmod +x /tmp/install_tools.sh",
      "/tmp/install_tools.sh"
    ]

    connection {
      type        = "ssh"
      user        = "azureuser"
      private_key = tls_private_key.ssh.private_key_pem
      host        = data.azurerm_public_ip.main.ip_address
      timeout     = "15m"
    }
  }

  # Trigger re-provisioning when script changes
  triggers = {
    script_hash = filemd5("${path.root}/scripts/install_tools.sh")
  }
}