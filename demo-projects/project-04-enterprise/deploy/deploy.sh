#!/bin/bash

# Enterprise Multi-tier Architecture Deployment Script
# This script deploys the complete enterprise application stack

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="enterprise"
DOCKER_COMPOSE_FILE="docker-compose.yml"
BACKUP_DIR="./backup"
LOG_DIR="./logs"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_dependencies() {
    log_info "Checking dependencies..."
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check if Docker Compose is installed
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    # Check Docker daemon
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running. Please start Docker first."
        exit 1
    fi
    
    log_success "All dependencies are available"
}

create_directories() {
    log_info "Creating necessary directories..."
    
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$LOG_DIR"/{haproxy,postgres,redis,elasticsearch,rabbitmq,nginx}
    
    log_success "Directories created"
}

generate_ssl_certificates() {
    log_info "Generating SSL certificates..."
    
    if [ ! -d "./ssl" ]; then
        mkdir -p ./ssl
    fi
    
    if [ ! -f "./ssl/enterprise.pem" ]; then
        # Generate self-signed certificate for development
        openssl req -x509 -newkey rsa:4096 -keyout ./ssl/enterprise.key -out ./ssl/enterprise.crt -days 365 -nodes \
            -subj "/C=US/ST=State/L=City/O=Enterprise/OU=IT/CN=localhost"
        
        # Combine certificate and key
        cat ./ssl/enterprise.crt ./ssl/enterprise.key > ./ssl/enterprise.pem
        
        log_success "SSL certificates generated"
    else
        log_info "SSL certificates already exist"
    fi
}

backup_existing_data() {
    log_info "Creating backup of existing data..."
    
    if [ -d "./data" ]; then
        tar -czf "$BACKUP_DIR/backup-$(date +%Y%m%d-%H%M%S).tar.gz" ./data
        log_success "Backup created"
    else
        log_info "No existing data to backup"
    fi
}

build_images() {
    log_info "Building Docker images..."
    
    # Build web frontend
    log_info "Building web frontend..."
    docker build -t enterprise-web-frontend ./applications/web-frontend/
    
    # Build API backend
    log_info "Building API backend..."
    docker build -t enterprise-api-backend ./applications/api-backend/
    
    # Build admin panel
    log_info "Building admin panel..."
    docker build -t enterprise-admin-panel ./applications/admin-panel/
    
    log_success "All images built successfully"
}

start_services() {
    log_info "Starting services..."
    
    # Start database services first
    log_info "Starting database services..."
    docker-compose up -d postgres-primary postgres-replica redis-master redis-slave
    
    # Wait for databases to be ready
    log_info "Waiting for databases to be ready..."
    sleep 30
    
    # Start application services
    log_info "Starting application services..."
    docker-compose up -d web1 web2 web3 api1 api2 api3 admin1 admin2
    
    # Wait for applications to be ready
    log_info "Waiting for applications to be ready..."
    sleep 30
    
    # Start load balancer
    log_info "Starting load balancer..."
    docker-compose up -d haproxy
    
    # Start monitoring services
    log_info "Starting monitoring services..."
    docker-compose up -d prometheus grafana alertmanager
    
    # Start logging services
    log_info "Starting logging services..."
    docker-compose up -d elasticsearch-logs logstash kibana
    
    # Start additional services
    log_info "Starting additional services..."
    docker-compose up -d elasticsearch rabbitmq
    
    log_success "All services started"
}

wait_for_services() {
    log_info "Waiting for services to be healthy..."
    
    # Wait for load balancer
    log_info "Waiting for load balancer..."
    timeout 60 bash -c 'until curl -f http://localhost/health >/dev/null 2>&1; do sleep 2; done'
    
    # Wait for API services
    log_info "Waiting for API services..."
    timeout 60 bash -c 'until curl -f http://localhost/api/health >/dev/null 2>&1; do sleep 2; done'
    
    # Wait for admin panel
    log_info "Waiting for admin panel..."
    timeout 60 bash -c 'until curl -f http://localhost/admin/health >/dev/null 2>&1; do sleep 2; done'
    
    log_success "All services are healthy"
}

run_health_checks() {
    log_info "Running health checks..."
    
    # Check load balancer
    if curl -f http://localhost/health >/dev/null 2>&1; then
        log_success "Load balancer is healthy"
    else
        log_error "Load balancer health check failed"
    fi
    
    # Check API services
    if curl -f http://localhost/api/health >/dev/null 2>&1; then
        log_success "API services are healthy"
    else
        log_error "API services health check failed"
    fi
    
    # Check admin panel
    if curl -f http://localhost/admin/health >/dev/null 2>&1; then
        log_success "Admin panel is healthy"
    else
        log_error "Admin panel health check failed"
    fi
    
    # Check monitoring services
    if curl -f http://localhost:9090/-/healthy >/dev/null 2>&1; then
        log_success "Prometheus is healthy"
    else
        log_warning "Prometheus health check failed"
    fi
    
    if curl -f http://localhost:3000/api/health >/dev/null 2>&1; then
        log_success "Grafana is healthy"
    else
        log_warning "Grafana health check failed"
    fi
}

show_service_urls() {
    log_info "Service URLs:"
    echo ""
    echo "🌐 Web Application:     http://localhost"
    echo "🔧 API Endpoints:       http://localhost/api"
    echo "⚙️  Admin Panel:        http://localhost/admin"
    echo "📊 Prometheus:          http://localhost:9090"
    echo "📈 Grafana:             http://localhost:3000 (admin/admin123)"
    echo "🚨 AlertManager:        http://localhost:9093"
    echo "🔍 Kibana:              http://localhost:5601"
    echo "🐰 RabbitMQ:            http://localhost:15672 (admin/admin123)"
    echo "📈 HAProxy Stats:       http://localhost:8404"
    echo ""
}

cleanup() {
    log_info "Cleaning up..."
    
    # Stop all services
    docker-compose down
    
    # Remove unused images
    docker image prune -f
    
    log_success "Cleanup completed"
}

show_help() {
    echo "Enterprise Multi-tier Architecture Deployment Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -c, --cleanup       Clean up and remove all services"
    echo "  -b, --build-only    Only build images, don't start services"
    echo "  -s, --start-only    Only start services (assumes images are built)"
    echo "  --no-backup         Skip backup of existing data"
    echo "  --no-ssl            Skip SSL certificate generation"
    echo ""
}

# Parse command line arguments
BUILD_ONLY=false
START_ONLY=false
NO_BACKUP=false
NO_SSL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -c|--cleanup)
            cleanup
            exit 0
            ;;
        -b|--build-only)
            BUILD_ONLY=true
            shift
            ;;
        -s|--start-only)
            START_ONLY=true
            shift
            ;;
        --no-backup)
            NO_BACKUP=true
            shift
            ;;
        --no-ssl)
            NO_SSL=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Main deployment process
main() {
    log_info "Starting Enterprise Multi-tier Architecture Deployment"
    echo ""
    
    check_dependencies
    create_directories
    
    if [ "$NO_BACKUP" = false ]; then
        backup_existing_data
    fi
    
    if [ "$NO_SSL" = false ]; then
        generate_ssl_certificates
    fi
    
    if [ "$START_ONLY" = false ]; then
        build_images
    fi
    
    if [ "$BUILD_ONLY" = false ]; then
        start_services
        wait_for_services
        run_health_checks
        show_service_urls
        
        log_success "Deployment completed successfully!"
        echo ""
        log_info "To view logs: docker-compose logs -f"
        log_info "To stop services: docker-compose down"
        log_info "To restart services: docker-compose restart"
    else
        log_success "Image building completed!"
    fi
}

# Run main function
main "$@"