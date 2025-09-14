#!/bin/bash

# Microservices Kubernetes Deployment Script
# This script automates the deployment of microservices to Kubernetes

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="microservices"
NAMESPACE="microservices"
K8S_DIR="k8s"
LOG_FILE="/var/log/$PROJECT_NAME-k8s-deploy.log"

# Functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a $LOG_FILE
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a $LOG_FILE
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a $LOG_FILE
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a $LOG_FILE
    exit 1
}

info() {
    echo -e "${PURPLE}[INFO]${NC} $1" | tee -a $LOG_FILE
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        error "kubectl is not installed. Please install kubectl first."
    fi
    
    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        warning "Helm is not installed. Some features may not work."
    fi
    
    # Check if istioctl is installed
    if ! command -v istioctl &> /dev/null; then
        warning "Istio is not installed. Service mesh features will be disabled."
    fi
    
    # Check kubectl connection
    if ! kubectl cluster-info &> /dev/null; then
        error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    fi
    
    success "Prerequisites check completed"
}

# Create namespace and RBAC
create_namespace() {
    log "Creating namespace and RBAC..."
    
    kubectl apply -f $K8S_DIR/namespace.yaml
    
    # Wait for namespace to be ready
    kubectl wait --for=condition=Active namespace/$NAMESPACE --timeout=60s
    
    success "Namespace and RBAC created"
}

# Deploy secrets and configmaps
deploy_secrets() {
    log "Deploying secrets and configmaps..."
    
    # Deploy secrets
    kubectl apply -f $K8S_DIR/secrets/
    
    # Deploy configmaps
    if [ -d "$K8S_DIR/configmaps" ]; then
        kubectl apply -f $K8S_DIR/configmaps/
    fi
    
    success "Secrets and configmaps deployed"
}

# Deploy databases
deploy_databases() {
    log "Deploying databases..."
    
    # Deploy PostgreSQL
    kubectl apply -f $K8S_DIR/deployments/databases/postgres.yaml
    kubectl apply -f $K8S_DIR/services/postgres.yaml
    
    # Deploy MongoDB
    kubectl apply -f $K8S_DIR/deployments/databases/mongodb.yaml
    kubectl apply -f $K8S_DIR/services/mongodb.yaml
    
    # Deploy Redis
    kubectl apply -f $K8S_DIR/deployments/databases/redis.yaml
    kubectl apply -f $K8S_DIR/services/redis.yaml
    
    # Wait for databases to be ready
    log "Waiting for databases to be ready..."
    kubectl wait --for=condition=Available deployment/postgres -n $NAMESPACE --timeout=300s
    kubectl wait --for=condition=Available deployment/mongodb -n $NAMESPACE --timeout=300s
    kubectl wait --for=condition=Available deployment/redis -n $NAMESPACE --timeout=300s
    
    success "Databases deployed and ready"
}

# Deploy microservices
deploy_microservices() {
    log "Deploying microservices..."
    
    # Deploy user service
    kubectl apply -f $K8S_DIR/deployments/user-service.yaml
    kubectl apply -f $K8S_DIR/services/user-service.yaml
    
    # Deploy product service
    kubectl apply -f $K8S_DIR/deployments/product-service.yaml
    kubectl apply -f $K8S_DIR/services/product-service.yaml
    
    # Deploy order service
    kubectl apply -f $K8S_DIR/deployments/order-service.yaml
    kubectl apply -f $K8S_DIR/services/order-service.yaml
    
    # Deploy payment service
    kubectl apply -f $K8S_DIR/deployments/payment-service.yaml
    kubectl apply -f $K8S_DIR/services/payment-service.yaml
    
    # Deploy notification service
    kubectl apply -f $K8S_DIR/deployments/notification-service.yaml
    kubectl apply -f $K8S_DIR/services/notification-service.yaml
    
    # Deploy analytics service
    kubectl apply -f $K8S_DIR/deployments/analytics-service.yaml
    kubectl apply -f $K8S_DIR/services/analytics-service.yaml
    
    # Wait for microservices to be ready
    log "Waiting for microservices to be ready..."
    kubectl wait --for=condition=Available deployment/user-service -n $NAMESPACE --timeout=300s
    kubectl wait --for=condition=Available deployment/product-service -n $NAMESPACE --timeout=300s
    kubectl wait --for=condition=Available deployment/order-service -n $NAMESPACE --timeout=300s
    kubectl wait --for=condition=Available deployment/payment-service -n $NAMESPACE --timeout=300s
    kubectl wait --for=condition=Available deployment/notification-service -n $NAMESPACE --timeout=300s
    kubectl wait --for=condition=Available deployment/analytics-service -n $NAMESPACE --timeout=300s
    
    success "Microservices deployed and ready"
}

# Deploy API Gateway
deploy_api_gateway() {
    log "Deploying API Gateway..."
    
    kubectl apply -f $K8S_DIR/deployments/api-gateway.yaml
    kubectl apply -f $K8S_DIR/services/api-gateway.yaml
    
    # Wait for API Gateway to be ready
    kubectl wait --for=condition=Available deployment/api-gateway -n $NAMESPACE --timeout=300s
    
    success "API Gateway deployed and ready"
}

# Deploy monitoring stack
deploy_monitoring() {
    log "Deploying monitoring stack..."
    
    # Deploy Prometheus
    kubectl apply -f $K8S_DIR/monitoring/prometheus.yaml
    kubectl apply -f $K8S_DIR/services/prometheus.yaml
    
    # Deploy Grafana
    kubectl apply -f $K8S_DIR/monitoring/grafana.yaml
    kubectl apply -f $K8S_DIR/services/grafana.yaml
    
    # Deploy Jaeger
    kubectl apply -f $K8S_DIR/monitoring/jaeger.yaml
    kubectl apply -f $K8S_DIR/services/jaeger.yaml
    
    # Wait for monitoring to be ready
    kubectl wait --for=condition=Available deployment/prometheus -n $NAMESPACE --timeout=300s
    kubectl wait --for=condition=Available deployment/grafana -n $NAMESPACE --timeout=300s
    kubectl wait --for=condition=Available deployment/jaeger -n $NAMESPACE --timeout=300s
    
    success "Monitoring stack deployed and ready"
}

# Deploy ingress
deploy_ingress() {
    log "Deploying ingress..."
    
    kubectl apply -f $K8S_DIR/ingress/
    
    # Wait for ingress to be ready
    kubectl wait --for=condition=Ready ingress/microservices-ingress -n $NAMESPACE --timeout=300s
    
    success "Ingress deployed and ready"
}

# Install Istio (if available)
install_istio() {
    if command -v istioctl &> /dev/null; then
        log "Installing Istio service mesh..."
        
        # Install Istio
        istioctl install --set values.defaultRevision=default -y
        
        # Enable sidecar injection for namespace
        kubectl label namespace $NAMESPACE istio-injection=enabled --overwrite
        
        # Deploy Istio addons
        kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.19/samples/addons/prometheus.yaml
        kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.19/samples/addons/grafana.yaml
        kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.19/samples/addons/jaeger.yaml
        kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.19/samples/addons/kiali.yaml
        
        success "Istio service mesh installed"
    else
        warning "Istio not available, skipping service mesh installation"
    fi
}

# Verify deployment
verify_deployment() {
    log "Verifying deployment..."
    
    # Check all pods are running
    running_pods=$(kubectl get pods -n $NAMESPACE --field-selector=status.phase=Running | wc -l)
    total_pods=$(kubectl get pods -n $NAMESPACE | wc -l)
    
    if [ $running_pods -lt $((total_pods - 1)) ]; then
        warning "Not all pods are running. Running: $running_pods, Total: $total_pods"
        kubectl get pods -n $NAMESPACE
    fi
    
    # Check services
    kubectl get services -n $NAMESPACE
    
    # Check ingress
    kubectl get ingress -n $NAMESPACE
    
    success "Deployment verification completed"
}

# Show deployment information
show_info() {
    log "Microservices deployment completed successfully!"
    echo
    echo "=========================================="
    echo "  Microservices Deployment Information"
    echo "=========================================="
    echo
    echo "🌐 API Gateway:"
    echo "   URL: http://api.your-domain.com"
    echo "   Admin: http://api.your-domain.com:8001"
    echo
    echo "🔧 Microservices:"
    echo "   User Service: http://api.your-domain.com/api/users"
    echo "   Product Service: http://api.your-domain.com/api/products"
    echo "   Order Service: http://api.your-domain.com/api/orders"
    echo "   Payment Service: http://api.your-domain.com/api/payments"
    echo "   Notification Service: http://api.your-domain.com/api/notifications"
    echo "   Analytics Service: http://api.your-domain.com/api/analytics"
    echo
    echo "📊 Monitoring:"
    echo "   Grafana: http://monitoring.your-domain.com"
    echo "   Prometheus: http://monitoring.your-domain.com:9090"
    echo "   Jaeger: http://monitoring.your-domain.com:16686"
    echo
    echo "🗄️  Databases:"
    echo "   PostgreSQL: postgres-service:5432"
    echo "   MongoDB: mongodb-service:27017"
    echo "   Redis: redis-service:6379"
    echo
    echo "📝 Useful Commands:"
    echo "   View pods: kubectl get pods -n $NAMESPACE"
    echo "   View services: kubectl get services -n $NAMESPACE"
    echo "   View logs: kubectl logs -f deployment/<service-name> -n $NAMESPACE"
    echo "   Port forward: kubectl port-forward service/<service-name> <local-port>:<service-port> -n $NAMESPACE"
    echo "   Scale service: kubectl scale deployment <service-name> --replicas=5 -n $NAMESPACE"
    echo
    echo "🔍 Debug Commands:"
    echo "   Describe pod: kubectl describe pod <pod-name> -n $NAMESPACE"
    echo "   Get events: kubectl get events -n $NAMESPACE"
    echo "   Check logs: kubectl logs <pod-name> -n $NAMESPACE"
    echo
    echo "=========================================="
}

# Cleanup function
cleanup() {
    log "Cleaning up deployment..."
    
    kubectl delete namespace $NAMESPACE --ignore-not-found=true
    
    success "Cleanup completed"
}

# Main deployment function
main() {
    log "Starting Microservices Kubernetes deployment..."
    
    check_prerequisites
    create_namespace
    deploy_secrets
    deploy_databases
    deploy_microservices
    deploy_api_gateway
    deploy_monitoring
    deploy_ingress
    install_istio
    verify_deployment
    show_info
    
    success "Microservices deployment completed successfully!"
}

# Handle script arguments
case "${1:-}" in
    "cleanup")
        cleanup
        ;;
    "status")
        kubectl get all -n $NAMESPACE
        ;;
    "logs")
        kubectl logs -f deployment/${2:-user-service} -n $NAMESPACE
        ;;
    "scale")
        kubectl scale deployment ${2:-user-service} --replicas=${3:-3} -n $NAMESPACE
        ;;
    "restart")
        kubectl rollout restart deployment/${2:-user-service} -n $NAMESPACE
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo
        echo "Commands:"
        echo "  (no args)  Full deployment"
        echo "  cleanup    Remove all resources"
        echo "  status     Show deployment status"
        echo "  logs       Show logs for a service"
        echo "  scale      Scale a service"
        echo "  restart    Restart a service"
        echo "  help       Show this help message"
        ;;
    *)
        main
        ;;
esac
