#!/bin/bash
# infrastructure/scripts/install_tools.sh

set -e

echo "Starting installation of DevOps tools..."

# Update system
sudo apt-get update -y
sudo apt-get upgrade -y

# Install basic utilities
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    unzip \
    wget \
    jq \
    htop \
    vim

echo "✅ Basic utilities installed"

# Install Docker
echo "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Add user to docker group
sudo usermod -aG docker $USER

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

echo "✅ Docker installed"

# Install kubectl
echo "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

echo "✅ kubectl installed"

# Install Helm
echo "Installing Helm..."
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm get_helm.sh



echo "✅ Helm installed"

# Install minikube
echo "Installing Minikube..."
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube
sudo mv minikube /usr/local/bin/

echo "✅ Minikube installed"

# Install Node.js (for local testing if needed)
echo "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

echo "✅ Node.js installed"

# Install Azure CLI
echo "Installing Azure CLI..."
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

echo "✅ Azure CLI installed"

# Clean up
sudo apt-get autoremove -y
sudo apt-get autoclean

echo "🎉 All tools installed successfully!"

# Display versions
echo "=== Installed Versions ==="
echo "Docker: $(docker --version)"
echo "kubectl: $(kubectl version --client --short)"
echo "Helm: $(helm version --short)"
echo "Minikube: $(minikube version --short)"
echo "Node.js: $(node --version)"
echo "npm: $(npm --version)"
echo "Azure CLI: $(az --version | head -1)"

echo "=== Next Steps ==="
echo "1. Logout and login again to apply docker group changes"
echo "2. Start minikube: minikube start --driver=docker"
echo "3. Check cluster: kubectl cluster-info"

echo "Installation complete! 🚀"