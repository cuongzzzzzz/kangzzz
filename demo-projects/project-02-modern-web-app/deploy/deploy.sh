#!/bin/bash

# Modern Web App Deployment Script
# This script automates the deployment process for the full-stack application

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="modern-webapp"
DOCKER_COMPOSE_FILE="docker-compose.yml"
DOCKER_COMPOSE_PROD_FILE="docker-compose.prod.yml"
ENV_FILE=".env"
BACKUP_DIR="/backup/$PROJECT_NAME"
LOG_FILE="/var/log/$PROJECT_NAME-deploy.log"

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

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root. Please run as a regular user with sudo privileges."
    fi
}

# Check system requirements
check_requirements() {
    log "Checking system requirements..."
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed. Please install Docker first."
    fi
    
    # Check if Docker Compose is installed
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose is not installed. Please install Docker Compose first."
    fi
    
    # Check if Node.js is installed (for local development)
    if ! command -v node &> /dev/null; then
        warning "Node.js is not installed. Some features may not work in development mode."
    fi
    
    # Check if user is in docker group
    if ! groups $USER | grep -q '\bdocker\b'; then
        warning "User $USER is not in docker group. You may need to run commands with sudo."
    fi
    
    # Check available disk space (at least 5GB for full stack)
    available_space=$(df / | awk 'NR==2 {print $4}')
    if [ $available_space -lt 5242880 ]; then  # 5GB in KB
        warning "Low disk space. Available: $(($available_space / 1024 / 1024))GB"
    fi
    
    # Check available memory (at least 4GB)
    total_memory=$(free -m | awk 'NR==2{print $2}')
    if [ $total_memory -lt 4096 ]; then
        warning "Low memory. Available: ${total_memory}MB (recommended: 4GB+)"
    fi
    
    success "System requirements check completed"
}

# Create necessary directories
create_directories() {
    log "Creating necessary directories..."
    
    mkdir -p logs/nginx logs/backend logs/frontend logs/mongodb logs/redis
    mkdir -p data/mongodb data/redis
    mkdir -p uploads
    mkdir -p ssl
    mkdir -p $BACKUP_DIR
    mkdir -p monitoring/grafana/provisioning/datasources
    mkdir -p monitoring/grafana/provisioning/dashboards
    
    # Set proper permissions
    chmod 755 logs/ data/ uploads/ ssl/
    chmod 755 $BACKUP_DIR
    
    success "Directories created successfully"
}

# Create environment files
create_env_files() {
    log "Creating environment files..."
    
    # Development environment
    if [ ! -f $ENV_FILE ]; then
        cat > $ENV_FILE << EOF
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
JWT_SECRET=your-super-secret-jwt-key-here-change-in-production
JWT_EXPIRES_IN=7d

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

# Session Configuration
SESSION_SECRET=your-session-secret-here

# Logging
LOG_LEVEL=info
EOF
        success "Development environment file created"
    else
        log "Environment file already exists"
    fi
    
    # Production environment
    if [ ! -f .env.production ]; then
        cp $ENV_FILE .env.production
        sed -i 's/development/production/g' .env.production
        sed -i 's/localhost/your-domain.com/g' .env.production
        sed -i 's/your-super-secret-jwt-key-here-change-in-production/CHANGE-THIS-IN-PRODUCTION/g' .env.production
        success "Production environment file created"
    fi
}

# Install frontend dependencies
install_frontend_deps() {
    log "Installing frontend dependencies..."
    
    if [ -d "frontend" ]; then
        cd frontend
        if [ ! -d "node_modules" ]; then
            npm install
            success "Frontend dependencies installed"
        else
            log "Frontend dependencies already installed"
        fi
        cd ..
    else
        warning "Frontend directory not found"
    fi
}

# Install backend dependencies
install_backend_deps() {
    log "Installing backend dependencies..."
    
    if [ -d "backend" ]; then
        cd backend
        if [ ! -d "node_modules" ]; then
            npm install
            success "Backend dependencies installed"
        else
            log "Backend dependencies already installed"
        fi
        cd ..
    else
        warning "Backend directory not found"
    fi
}

# Backup existing data
backup_data() {
    if [ -f $DOCKER_COMPOSE_FILE ]; then
        log "Creating backup of existing data..."
        
        # Create backup directory with timestamp
        backup_timestamp=$(date +%Y%m%d_%H%M%S)
        current_backup_dir="$BACKUP_DIR/backup_$backup_timestamp"
        mkdir -p $current_backup_dir
        
        # Backup database if containers are running
        if docker-compose ps | grep -q "Up"; then
            log "Backing up MongoDB..."
            docker-compose exec -T mongodb mongodump --db modernwebapp --archive > $current_backup_dir/mongodb_backup.archive 2>/dev/null || warning "MongoDB backup failed"
            
            log "Backing up Redis..."
            docker-compose exec -T redis redis-cli --rdb /tmp/redis_backup.rdb 2>/dev/null || warning "Redis backup failed"
            docker cp $(docker-compose ps -q redis):/tmp/redis_backup.rdb $current_backup_dir/ 2>/dev/null || warning "Redis backup copy failed"
        fi
        
        # Backup application files
        if [ -d "frontend" ]; then
            log "Backing up frontend files..."
            tar -czf $current_backup_dir/frontend.tar.gz frontend/ 2>/dev/null || warning "Frontend backup failed"
        fi
        
        if [ -d "backend" ]; then
            log "Backing up backend files..."
            tar -czf $current_backup_dir/backend.tar.gz backend/ 2>/dev/null || warning "Backend backup failed"
        fi
        
        # Backup configuration files
        cp $DOCKER_COMPOSE_FILE $current_backup_dir/ 2>/dev/null || true
        cp $ENV_FILE $current_backup_dir/ 2>/dev/null || true
        
        success "Backup completed: $current_backup_dir"
    fi
}

# Stop existing containers
stop_containers() {
    log "Stopping existing containers..."
    
    if [ -f $DOCKER_COMPOSE_FILE ]; then
        docker-compose down --remove-orphans 2>/dev/null || warning "Failed to stop some containers"
    fi
    
    if [ -f $DOCKER_COMPOSE_PROD_FILE ]; then
        docker-compose -f $DOCKER_COMPOSE_PROD_FILE down --remove-orphans 2>/dev/null || warning "Failed to stop some production containers"
    fi
    
    success "Containers stopped"
}

# Build and start containers
start_containers() {
    log "Building and starting containers..."
    
    # Build images
    docker-compose build --no-cache
    
    # Start services
    docker-compose up -d
    
    # Wait for services to be ready
    log "Waiting for services to be ready..."
    sleep 30
    
    # Check if containers are running
    running_containers=$(docker-compose ps | grep "Up" | wc -l)
    expected_containers=8  # frontend, backend, mongodb, redis, nginx, mongo-express, redis-commander, prometheus, grafana
    
    if [ $running_containers -lt $expected_containers ]; then
        warning "Not all containers are running. Expected: $expected_containers, Running: $running_containers"
        docker-compose ps
    fi
    
    success "Containers started successfully"
}

# Verify deployment
verify_deployment() {
    log "Verifying deployment..."
    
    # Check if all containers are running
    running_containers=$(docker-compose ps | grep "Up" | wc -l)
    expected_containers=8
    
    if [ $running_containers -lt $expected_containers ]; then
        error "Not all containers are running. Expected: $expected_containers, Running: $running_containers"
    fi
    
    # Check if web server is responding
    sleep 10
    if curl -f http://localhost/health >/dev/null 2>&1; then
        success "Backend API is responding"
    else
        warning "Backend API health check failed. Check logs with: docker-compose logs backend"
    fi
    
    # Check if frontend is responding
    if curl -f http://localhost:3000 >/dev/null 2>&1; then
        success "Frontend is responding"
    else
        warning "Frontend health check failed. Check logs with: docker-compose logs frontend"
    fi
    
    # Check database connection
    if docker-compose exec mongodb mongosh --eval "db.runCommand('ping')" >/dev/null 2>&1; then
        success "MongoDB connection successful"
    else
        warning "MongoDB connection failed. Check logs with: docker-compose logs mongodb"
    fi
    
    # Check Redis connection
    if docker-compose exec redis redis-cli ping >/dev/null 2>&1; then
        success "Redis connection successful"
    else
        warning "Redis connection failed. Check logs with: docker-compose logs redis"
    fi
    
    success "Deployment verification completed"
}

# Show deployment information
show_info() {
    log "Deployment completed successfully!"
    echo
    echo "=========================================="
    echo "  Modern Web App Deployment Information"
    echo "=========================================="
    echo
    echo "🌐 Frontend Application:"
    echo "   URL: http://localhost:3000"
    echo "   Health Check: http://localhost:3000/health"
    echo
    echo "🔧 Backend API:"
    echo "   URL: http://localhost:5000"
    echo "   Health Check: http://localhost:5000/health"
    echo "   API Docs: http://localhost:5000/api-docs"
    echo
    echo "🗄️  Database:"
    echo "   MongoDB: mongodb://localhost:27017/modernwebapp"
    echo "   Redis: redis://localhost:6379"
    echo
    echo "🔧 Admin Tools:"
    echo "   Mongo Express: http://localhost:8081"
    echo "   Redis Commander: http://localhost:8082"
    echo "   Grafana: http://localhost:3001 (admin/admin123)"
    echo "   Prometheus: http://localhost:9090"
    echo
    echo "📊 Container Status:"
    docker-compose ps
    echo
    echo "📝 Useful Commands:"
    echo "   View logs: docker-compose logs -f"
    echo "   Stop app: docker-compose down"
    echo "   Restart app: docker-compose restart"
    echo "   Update app: ./deploy/deploy.sh"
    echo "   Production deploy: ./deploy/deploy-prod.sh"
    echo
    echo "🔍 Debug Commands:"
    echo "   Backend logs: docker-compose logs -f backend"
    echo "   Frontend logs: docker-compose logs -f frontend"
    echo "   Database logs: docker-compose logs -f mongodb"
    echo "   Redis logs: docker-compose logs -f redis"
    echo
    echo "=========================================="
}

# Cleanup old backups
cleanup_backups() {
    log "Cleaning up old backups..."
    
    # Keep only last 5 backups
    cd $BACKUP_DIR
    ls -t | tail -n +6 | xargs -r rm -rf
    cd - > /dev/null
    
    success "Old backups cleaned up"
}

# Deploy production environment
deploy_production() {
    log "Deploying production environment..."
    
    # Check if production compose file exists
    if [ ! -f $DOCKER_COMPOSE_PROD_FILE ]; then
        error "Production compose file not found: $DOCKER_COMPOSE_PROD_FILE"
    fi
    
    # Build and start production containers
    docker-compose -f $DOCKER_COMPOSE_PROD_FILE build --no-cache
    docker-compose -f $DOCKER_COMPOSE_PROD_FILE up -d
    
    # Wait for services to be ready
    log "Waiting for production services to be ready..."
    sleep 45
    
    # Check if containers are running
    running_containers=$(docker-compose -f $DOCKER_COMPOSE_PROD_FILE ps | grep "Up" | wc -l)
    expected_containers=10  # More containers in production
    
    if [ $running_containers -lt $expected_containers ]; then
        warning "Not all production containers are running. Expected: $expected_containers, Running: $running_containers"
        docker-compose -f $DOCKER_COMPOSE_PROD_FILE ps
    fi
    
    success "Production deployment completed"
}

# Main deployment function
main() {
    log "Starting Modern Web App deployment..."
    
    check_root
    check_requirements
    create_directories
    create_env_files
    install_frontend_deps
    install_backend_deps
    backup_data
    stop_containers
    start_containers
    verify_deployment
    cleanup_backups
    show_info
    
    success "Deployment completed successfully!"
}

# Handle script arguments
case "${1:-}" in
    "backup")
        backup_data
        ;;
    "stop")
        stop_containers
        ;;
    "start")
        start_containers
        ;;
    "restart")
        stop_containers
        start_containers
        ;;
    "logs")
        docker-compose logs -f
        ;;
    "status")
        docker-compose ps
        ;;
    "prod")
        deploy_production
        ;;
    "frontend")
        install_frontend_deps
        docker-compose up -d frontend
        ;;
    "backend")
        install_backend_deps
        docker-compose up -d backend
        ;;
    "db")
        docker-compose up -d mongodb redis
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo
        echo "Commands:"
        echo "  (no args)  Full deployment"
        echo "  backup     Create backup of current data"
        echo "  stop       Stop all containers"
        echo "  start      Start all containers"
        echo "  restart    Restart all containers"
        echo "  logs       Show container logs"
        echo "  status     Show container status"
        echo "  prod       Deploy production environment"
        echo "  frontend   Deploy only frontend"
        echo "  backend    Deploy only backend"
        echo "  db         Deploy only database services"
        echo "  help       Show this help message"
        ;;
    *)
        main
        ;;
esac
