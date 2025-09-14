#!/bin/bash

# Deploy Microservices Demo with Docker Compose
# This script builds and deploys all microservices using Docker Compose

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command_exists docker; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command_exists docker-compose; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Build microservices
build_microservices() {
    print_status "Building microservices..."
    
    # Build User Service
    print_status "Building User Service (Node.js)..."
    docker build -t user-service:latest ./microservices/user-service/
    
    # Build Product Service
    print_status "Building Product Service (Python)..."
    docker build -t product-service:latest ./microservices/product-service/
    
    # Build Order Service
    print_status "Building Order Service (Go)..."
    docker build -t order-service:latest ./microservices/order-service/
    
    # Build Payment Service
    print_status "Building Payment Service (Java)..."
    docker build -t payment-service:latest ./microservices/payment-service/
    
    # Build Notification Service
    print_status "Building Notification Service (Go)..."
    docker build -t notification-service:latest ./microservices/notification-service/
    
    # Build Analytics Service
    print_status "Building Analytics Service (Python)..."
    docker build -t analytics-service:latest ./microservices/analytics-service/
    
    print_success "All microservices built successfully"
}

# Create necessary directories
create_directories() {
    print_status "Creating necessary directories..."
    
    mkdir -p logs/{kong,postgres,mongodb,nginx}
    mkdir -p ssl
    
    print_success "Directories created"
}

# Deploy with Docker Compose
deploy_services() {
    print_status "Deploying services with Docker Compose..."
    
    # Stop existing containers
    print_status "Stopping existing containers..."
    docker-compose down --remove-orphans
    
    # Start services
    print_status "Starting services..."
    docker-compose up -d
    
    print_success "Services deployed successfully"
}

# Wait for services to be ready
wait_for_services() {
    print_status "Waiting for services to be ready..."
    
    # Wait for databases
    print_status "Waiting for PostgreSQL..."
    timeout 60 bash -c 'until docker-compose exec -T postgres pg_isready -U postgres; do sleep 2; done'
    
    print_status "Waiting for MongoDB..."
    timeout 60 bash -c 'until docker-compose exec -T mongodb mongosh --eval "db.runCommand(\"ping\")" > /dev/null 2>&1; do sleep 2; done'
    
    print_status "Waiting for Redis..."
    timeout 60 bash -c 'until docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; do sleep 2; done'
    
    # Wait for microservices
    print_status "Waiting for microservices..."
    sleep 30
    
    print_success "All services are ready"
}

# Check service health
check_health() {
    print_status "Checking service health..."
    
    # Check API Gateway
    if curl -f http://localhost:8000/health > /dev/null 2>&1; then
        print_success "API Gateway is healthy"
    else
        print_warning "API Gateway health check failed"
    fi
    
    # Check User Service
    if curl -f http://localhost:3001/health > /dev/null 2>&1; then
        print_success "User Service is healthy"
    else
        print_warning "User Service health check failed"
    fi
    
    # Check Product Service
    if curl -f http://localhost:5001/health > /dev/null 2>&1; then
        print_success "Product Service is healthy"
    else
        print_warning "Product Service health check failed"
    fi
    
    # Check Order Service
    if curl -f http://localhost:5002/health > /dev/null 2>&1; then
        print_success "Order Service is healthy"
    else
        print_warning "Order Service health check failed"
    fi
    
    # Check Payment Service
    if curl -f http://localhost:8081/actuator/health > /dev/null 2>&1; then
        print_success "Payment Service is healthy"
    else
        print_warning "Payment Service health check failed"
    fi
    
    # Check Notification Service
    if curl -f http://localhost:3002/health > /dev/null 2>&1; then
        print_success "Notification Service is healthy"
    else
        print_warning "Notification Service health check failed"
    fi
    
    # Check Analytics Service
    if curl -f http://localhost:8001/health > /dev/null 2>&1; then
        print_success "Analytics Service is healthy"
    else
        print_warning "Analytics Service health check failed"
    fi
}

# Display service information
display_info() {
    print_success "Microservices Demo deployed successfully!"
    echo ""
    echo "Service URLs:"
    echo "  API Gateway:     http://localhost:8000"
    echo "  User Service:    http://localhost:3001"
    echo "  Product Service: http://localhost:5001"
    echo "  Order Service:   http://localhost:5002"
    echo "  Payment Service: http://localhost:8081"
    echo "  Notification:    http://localhost:3002"
    echo "  Analytics:       http://localhost:8001"
    echo ""
    echo "Monitoring URLs:"
    echo "  Prometheus:      http://localhost:9090"
    echo "  Grafana:         http://localhost:3000 (admin/admin123)"
    echo "  Jaeger:          http://localhost:16686"
    echo ""
    echo "Database URLs:"
    echo "  PostgreSQL:      localhost:5432"
    echo "  MongoDB:         localhost:27017"
    echo "  Redis:           localhost:6379"
    echo ""
    echo "Useful commands:"
    echo "  View logs:       docker-compose logs -f [service-name]"
    echo "  Stop services:   docker-compose down"
    echo "  Restart:         docker-compose restart [service-name]"
    echo "  Scale service:   docker-compose up -d --scale [service-name]=[count]"
}

# Main execution
main() {
    print_status "Starting Microservices Demo deployment with Docker Compose"
    echo ""
    
    check_prerequisites
    create_directories
    build_microservices
    deploy_services
    wait_for_services
    check_health
    display_info
}

# Handle script interruption
trap 'print_error "Deployment interrupted"; exit 1' INT TERM

# Run main function
main "$@"
