#!/bin/bash

# Modern Web App - Complete Deployment Script
# This script deploys the entire Modern Web App stack

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="modern-webapp"
COMPOSE_FILE="docker-compose.yml"
PROD_COMPOSE_FILE="docker-compose.prod.yml"
ENV_FILE=".env"

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
    
    # Check if Node.js is installed (for local development)
    if ! command -v node &> /dev/null; then
        log_warning "Node.js is not installed. Some features may not work in development mode."
    fi
    
    log_success "Dependencies check completed"
}

create_directories() {
    log_info "Creating necessary directories..."
    
    # Create directories for logs
    mkdir -p logs/nginx logs/backend logs/frontend logs/mongodb logs/redis
    
    # Create directories for data
    mkdir -p data/mongodb data/redis
    
    # Create directories for SSL certificates
    mkdir -p ssl
    
    # Create directories for uploads
    mkdir -p uploads
    
    log_success "Directories created"
}

setup_environment() {
    log_info "Setting up environment configuration..."
    
    if [ ! -f "$ENV_FILE" ]; then
        log_info "Creating .env file from template..."
        cat > "$ENV_FILE" << EOF
# Application Configuration
NODE_ENV=development
PORT=5000
FRONTEND_URL=http://localhost:3000
BACKEND_URL=http://localhost:5000

# Database Configuration
MONGODB_URI=mongodb://mongodb:27017/modernwebapp
MONGODB_DATABASE=modernwebapp

# Redis Configuration
REDIS_URL=redis://redis:6379
REDIS_PASSWORD=

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-here-change-in-production-$(date +%s)
JWT_EXPIRES_IN=7d

# Session Configuration
SESSION_SECRET=your-session-secret-here-change-in-production-$(date +%s)

# Email Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password

# File Upload
UPLOAD_DIR=uploads
MAX_FILE_SIZE=10485760

# API Keys
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
EOF
        log_success ".env file created"
    else
        log_info ".env file already exists"
    fi
}

build_services() {
    log_info "Building Docker services..."
    
    # Build all services
    docker-compose -f "$COMPOSE_FILE" build --no-cache
    
    log_success "Services built successfully"
}

start_services() {
    log_info "Starting services..."
    
    # Start all services
    docker-compose -f "$COMPOSE_FILE" up -d
    
    log_success "Services started"
}

wait_for_services() {
    log_info "Waiting for services to be ready..."
    
    # Wait for MongoDB
    log_info "Waiting for MongoDB..."
    until docker-compose -f "$COMPOSE_FILE" exec -T mongodb mongosh --eval "db.adminCommand('ping')" &> /dev/null; do
        sleep 2
    done
    log_success "MongoDB is ready"
    
    # Wait for Redis
    log_info "Waiting for Redis..."
    until docker-compose -f "$COMPOSE_FILE" exec -T redis redis-cli ping &> /dev/null; do
        sleep 2
    done
    log_success "Redis is ready"
    
    # Wait for Backend
    log_info "Waiting for Backend API..."
    until curl -f http://localhost:5000/health &> /dev/null; do
        sleep 2
    done
    log_success "Backend API is ready"
    
    # Wait for Frontend
    log_info "Waiting for Frontend..."
    until curl -f http://localhost:3000 &> /dev/null; do
        sleep 2
    done
    log_success "Frontend is ready"
}

check_services() {
    log_info "Checking service status..."
    
    # Check if all containers are running
    if docker-compose -f "$COMPOSE_FILE" ps | grep -q "Up"; then
        log_success "All services are running"
    else
        log_error "Some services are not running"
        docker-compose -f "$COMPOSE_FILE" ps
        exit 1
    fi
}

show_status() {
    log_info "Service Status:"
    docker-compose -f "$COMPOSE_FILE" ps
    
    echo ""
    log_info "Application URLs:"
    echo "  Frontend: http://localhost:3000"
    echo "  Backend API: http://localhost:5000"
    echo "  API Documentation: http://localhost:5000/api-docs"
    echo "  Health Check: http://localhost:5000/health"
    echo ""
    echo "Admin Tools:"
    echo "  Mongo Express: http://localhost:8081"
    echo "  Redis Commander: http://localhost:8082"
    echo "  Prometheus: http://localhost:9090"
    echo "  Grafana: http://localhost:3001"
    echo ""
    echo "Default Credentials:"
    echo "  Mongo Express: admin / admin123"
    echo "  Grafana: admin / admin123"
}

cleanup() {
    log_info "Cleaning up..."
    
    # Stop and remove containers
    docker-compose -f "$COMPOSE_FILE" down -v
    
    # Remove unused images
    docker image prune -f
    
    log_success "Cleanup completed"
}

deploy_production() {
    log_info "Deploying to production..."
    
    # Check if production compose file exists
    if [ ! -f "$PROD_COMPOSE_FILE" ]; then
        log_error "Production compose file not found: $PROD_COMPOSE_FILE"
        exit 1
    fi
    
    # Create production environment file
    if [ ! -f ".env.production" ]; then
        log_info "Creating production environment file..."
        cp "$ENV_FILE" ".env.production"
        # Update production-specific values
        sed -i 's/NODE_ENV=development/NODE_ENV=production/g' ".env.production"
        sed -i 's/localhost/your-domain.com/g' ".env.production"
    fi
    
    # Deploy with production compose file
    docker-compose -f "$PROD_COMPOSE_FILE" up -d --build
    
    log_success "Production deployment completed"
}

# Main script
main() {
    echo "=========================================="
    echo "Modern Web App - Complete Deployment"
    echo "=========================================="
    
    case "${1:-deploy}" in
        "deploy")
            check_dependencies
            create_directories
            setup_environment
            build_services
            start_services
            wait_for_services
            check_services
            show_status
            ;;
        "start")
            log_info "Starting existing services..."
            docker-compose -f "$COMPOSE_FILE" start
            show_status
            ;;
        "stop")
            log_info "Stopping services..."
            docker-compose -f "$COMPOSE_FILE" stop
            ;;
        "restart")
            log_info "Restarting services..."
            docker-compose -f "$COMPOSE_FILE" restart
            wait_for_services
            show_status
            ;;
        "logs")
            docker-compose -f "$COMPOSE_FILE" logs -f
            ;;
        "status")
            show_status
            ;;
        "cleanup")
            cleanup
            ;;
        "production")
            deploy_production
            ;;
        "help")
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  deploy     - Full deployment (default)"
            echo "  start      - Start existing services"
            echo "  stop       - Stop services"
            echo "  restart    - Restart services"
            echo "  logs       - Show logs"
            echo "  status     - Show status"
            echo "  cleanup    - Clean up everything"
            echo "  production - Deploy to production"
            echo "  help       - Show this help"
            ;;
        *)
            log_error "Unknown command: $1"
            echo "Use '$0 help' for available commands"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
