# DevOps Take-Home Assignment

## Project Overview

This project demonstrates a complete DevOps pipeline that automates the deployment of a Node.js web application from code commit to a production-ready, observable service on a Kubernetes cluster running in Azure.

## Architecture

- Node.js Express application with health endpoints
- Docker containerization with multi-stage builds
- GitHub Actions CI/CD pipeline
- Terraform Infrastructure as Code for Azure resources
- Kubernetes deployment with Minikube
- Monitoring stack with Prometheus and Grafana

## Repository Structure

```
devops-assignment/
├── app/
│   ├── app.js                    # Node.js Express application
│   ├── package.json              # Dependencies and scripts
│   ├── Dockerfile                # Multi-stage container build
│   └── tests/
│       └── app.test.js           # Unit tests
├── .github/
│   └── workflows/
│       └── ci.yml                # GitHub Actions CI/CD pipeline
├── infrastructure/
│   ├── main.tf                   # Main Terraform configuration
│   ├── modules/
│   │   ├── network/              # VNet and security groups
│   │   └── vm/                   # Virtual machine configuration
│   └── scripts/
│       └── install_tools.sh     # VM setup script
└── k8s/
    ├── manifests/
    │   ├── deployment.yaml       # Kubernetes application deployment
    │   ├── service.yaml          # ClusterIP service
    │   ├── ingress.yaml          # Ingress configuration
    │   └── monitoring/
    │       └── prometheus-values.yaml  # Monitoring configuration
    └── deploy.sh                 # Deployment script
```

## Prerequisites

- Azure account with active subscription
- GitHub account
- Local machine with:
  - Azure CLI
  - Terraform
  - Git

## Deployment Instructions

### 1. Infrastructure Setup

```bash
# Clone repository
git clone https://github.com/gajapathi22/devops-assignment.git
cd devops-assignment

# Login to Azure
az login

# Deploy infrastructure
cd infrastructure
terraform init
terraform plan
terraform apply

# Note the VM public IP from output
```

### 2. CI/CD Pipeline

The GitHub Actions workflow automatically triggers on push to main branch:

1. Runs ESLint code quality checks
2. Executes Jest unit tests
3. Builds Docker image with multi-stage build
4. Pushes image to GitHub Container Registry

Access pipeline: `https://github.com/gajapathi22/devops-assignment/actions`

### 3. Kubernetes Deployment

```bash
# SSH into Azure VM
ssh -i devops-vm-key.pem azureuser@<VM_PUBLIC_IP>

# Clone repository on VM
git clone https://github.com/gajapathi22/devops-assignment.git
cd devops-assignment

# Start Minikube
minikube start --driver=docker --memory=4096 --cpus=2

# Deploy application and monitoring
cd k8s
chmod +x deploy.sh
./deploy.sh
```

### 4. Monitoring Configuration

The monitoring stack uses Helm with custom values configuration:

```bash
# Monitoring installed via Helm chart
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values manifests/monitoring/prometheus-values.yaml \
  --wait \
  --timeout=10m
```

**Monitoring Values Configuration** (`k8s/manifests/monitoring/prometheus-values.yaml`):

```yaml
prometheus:
  prometheusSpec:
    retention: 15d
    resources:
      requests:
        memory: 400Mi
        cpu: 200m
      limits:
        memory: 800Mi
        cpu: 500m

grafana:
  enabled: true
  adminPassword: admin123
  service:
    type: NodePort
    nodePort: 32000

alertmanager:
  enabled: false

kubeStateMetrics:
  enabled: true

nodeExporter:
  enabled: true
```

## Application Access

### External Access (from Internet)

```bash
# Get VM public IP
terraform output vm_public_ip

# Application endpoints
http://<VM_PUBLIC_IP>:30080/          # Application home
http://<VM_PUBLIC_IP>:30080/health    # Health check
http://<VM_PUBLIC_IP>:30080/status    # Status endpoint

# Grafana dashboard
http://<VM_PUBLIC_IP>:32000           # Username: admin, Password: admin123
```

### Internal Access (from VM)

```bash
# Via Ingress
http://192.168.49.2/
http://192.168.49.2/health

# Prometheus (port-forward required)
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090
# Then access: http://localhost:9090
```

## Services Configuration

### Application Services

- **ClusterIP Service**: Internal cluster communication
- **NodePort Service**: External access on port 30080
- **Ingress**: HTTP routing within cluster

### Monitoring Services

- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization dashboards
- **Metrics Server**: Kubernetes resource monitoring

## Key Features Implemented

### Infrastructure as Code
- Modular Terraform design with separate network and VM modules
- Automated VM provisioning with tool installation
- Security groups configured for required ports

### CI/CD Pipeline
- Automated testing and quality gates
- Docker image building and registry storage
- Triggered on code changes to main branch

### Container Orchestration
- Kubernetes deployment with health checks
- Service discovery and load balancing
- Resource limits and scaling configuration

### Monitoring and Observability
- Prometheus metrics collection from cluster and applications
- Grafana dashboards for system visualization
- Real-time cluster and pod monitoring

## Verification Commands

```bash
# Check application
kubectl get pods
kubectl get services
curl http://<VM_PUBLIC_IP>:30080/health

# Check monitoring
kubectl get pods -n monitoring
kubectl get services -n monitoring

# View logs
kubectl logs -f deployment/devops-app
```

## Troubleshooting

### Application Issues
```bash
# Check pod status
kubectl describe pods -l app=devops-app

# View application logs
kubectl logs -f deployment/devops-app
```

### Monitoring Issues
```bash
# Check monitoring pods
kubectl get pods -n monitoring

# Restart monitoring if needed
helm upgrade monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values manifests/monitoring/prometheus-values.yaml
```

## Cleanup

```bash
# Destroy infrastructure
cd infrastructure
terraform destroy

# This will remove all Azure resources
```

## Technical Stack

- **Application**: Node.js, Express
- **Infrastructure**: Azure (VM, VNet, NSG)
- **IaC**: Terraform
- **Containers**: Docker
- **Orchestration**: Kubernetes (Minikube)
- **CI/CD**: GitHub Actions
- **Monitoring**: Prometheus, Grafana
- **Container Registry**: GitHub Container Registry