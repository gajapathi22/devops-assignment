#!/bin/bash
# k8s/deploy.sh

set -e

echo "🚀 Starting Kubernetes deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if minikube is running
if ! minikube status > /dev/null 2>&1; then
    echo -e "${YELLOW}Starting Minikube...${NC}"
    minikube start --driver=docker --memory=4096 --cpus=2
    echo -e "${GREEN}✅ Minikube started${NC}"
else
    echo -e "${GREEN}✅ Minikube is already running${NC}"
fi

# Enable necessary addons
echo -e "${YELLOW}Enabling Minikube addons...${NC}"
minikube addons enable ingress
minikube addons enable metrics-server
echo -e "${GREEN}✅ Addons enabled${NC}"

# Wait for ingress controller to be ready
echo -e "${YELLOW}Waiting for ingress controller...${NC}"
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s || echo "Timeout waiting for ingress controller, continuing..."

echo -e "${GREEN}✅ Ingress controller ready${NC}"

# Deploy the application
echo -e "${YELLOW}Deploying application...${NC}"
kubectl apply -f manifests/deployment.yaml
kubectl apply -f manifests/service.yaml
kubectl apply -f manifests/ingress.yaml

# Wait for deployment to be ready
echo -e "${YELLOW}Waiting for deployment to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/devops-app || echo "Deployment may still be starting..."

echo -e "${GREEN}✅ Application deployed${NC}"

# Install Prometheus and Grafana using Helm
echo -e "${YELLOW}Installing monitoring stack...${NC}"

# Add Helm repositories
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values manifests/monitoring/prometheus-values.yaml \
  --wait \
  --timeout=10m || echo "Monitoring installation may need more time..."

echo -e "${GREEN}✅ Monitoring stack installed${NC}"

# Get access information
echo -e "\n${GREEN}🎉 Deployment complete!${NC}\n"

# Get Minikube IP
MINIKUBE_IP=$(minikube ip)

echo -e "${YELLOW}Access Information:${NC}"
echo -e "📱 Application: http://${MINIKUBE_IP}"
echo -e "📊 Grafana: http://${MINIKUBE_IP}:32000 (admin/admin123)"

echo -e "\n${YELLOW}Port Forwarding Commands (run in separate terminals):${NC}"
echo -e "• Grafana: kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80"
echo -e "• Prometheus: kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090"

echo -e "\n${YELLOW}Useful Commands:${NC}"
echo -e "• Check pods: kubectl get pods"
echo -e "• Check services: kubectl get svc"
echo -e "• Check ingress: kubectl get ingress"
echo -e "• View logs: kubectl logs -f deployment/devops-app"

echo -e "\n${YELLOW}Monitoring:${NC}"
echo -e "• Grafana username: admin"
echo -e "• Grafana password: admin123"

# Test the application
echo -e "\n${YELLOW}Testing application...${NC}"
sleep 10  # Give a moment for services to be ready

if curl -f http://${MINIKUBE_IP}/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Application is responding${NC}"
    echo -e "${GREEN}✅ Health check: $(curl -s http://${MINIKUBE_IP}/health)${NC}"
else
    echo -e "${RED}❌ Application is not responding yet.${NC}"
    echo -e "${YELLOW}Try: curl http://${MINIKUBE_IP}/health${NC}"
    echo -e "${YELLOW}Or check pods: kubectl get pods${NC}"
fi

echo -e "\n${GREEN}🚀 All done! Your DevOps pipeline is complete!${NC}"

echo -e "\n${YELLOW}Next Steps for Demo:${NC}"
echo -e "1. Access your app: http://${MINIKUBE_IP}"
echo -e "2. Check Grafana: http://${MINIKUBE_IP}:32000"
echo -e "3. Take screenshots for your documentation"
echo -e "4. Show the CI/CD pipeline in GitHub Actions"