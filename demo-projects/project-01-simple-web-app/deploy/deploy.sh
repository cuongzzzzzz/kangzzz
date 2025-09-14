#!/bin/bash

# Simple Web App Deployment Script
# This script automates the deployment process

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="simple-webapp"
DOCKER_COMPOSE_FILE="docker-compose.yml"
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
    
    # Check if user is in docker group
    if ! groups $USER | grep -q '\bdocker\b'; then
        warning "User $USER is not in docker group. You may need to run commands with sudo."
    fi
    
    # Check available disk space (at least 2GB)
    available_space=$(df / | awk 'NR==2 {print $4}')
    if [ $available_space -lt 2097152 ]; then  # 2GB in KB
        warning "Low disk space. Available: $(($available_space / 1024 / 1024))GB"
    fi
    
    success "System requirements check completed"
}

# Create necessary directories
create_directories() {
    log "Creating necessary directories..."
    
    mkdir -p logs/nginx logs/apache logs/mysql
    mkdir -p $BACKUP_DIR
    mkdir -p /var/log
    
    # Set proper permissions
    chmod 755 logs/
    chmod 755 $BACKUP_DIR
    
    success "Directories created successfully"
}

# Create environment file if it doesn't exist
create_env_file() {
    if [ ! -f $ENV_FILE ]; then
        log "Creating environment file..."
        cat > $ENV_FILE << EOF
# Database Configuration
MYSQL_ROOT_PASSWORD=rootpassword123
MYSQL_DATABASE=simple_webapp
MYSQL_USER=webapp_user
MYSQL_PASSWORD=webapp_password123

# Application Configuration
APP_NAME=Simple Web App
APP_URL=http://localhost
APP_DEBUG=true

# Server Configuration
NGINX_PORT=80
APACHE_PORT=8080
MYSQL_PORT=3306
EOF
        success "Environment file created"
    else
        log "Environment file already exists"
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
            log "Backing up database..."
            docker-compose exec -T mysql mysqldump -u root -p$MYSQL_ROOT_PASSWORD simple_webapp > $current_backup_dir/database.sql 2>/dev/null || warning "Database backup failed"
        fi
        
        # Backup application files
        if [ -d "src" ]; then
            log "Backing up application files..."
            tar -czf $current_backup_dir/application.tar.gz src/ 2>/dev/null || warning "Application backup failed"
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
    if ! docker-compose ps | grep -q "Up"; then
        error "Failed to start containers. Check logs with: docker-compose logs"
    fi
    
    success "Containers started successfully"
}

# Verify deployment
verify_deployment() {
    log "Verifying deployment..."
    
    # Check if all containers are running
    running_containers=$(docker-compose ps | grep "Up" | wc -l)
    expected_containers=4  # nginx, apache, mysql, phpmyadmin
    
    if [ $running_containers -lt $expected_containers ]; then
        error "Not all containers are running. Expected: $expected_containers, Running: $running_containers"
    fi
    
    # Check if web server is responding
    sleep 10
    if curl -f http://localhost/health >/dev/null 2>&1; then
        success "Web server is responding"
    else
        warning "Web server health check failed. Check logs with: docker-compose logs nginx"
    fi
    
    # Check database connection
    if docker-compose exec mysql mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SELECT 1;" >/dev/null 2>&1; then
        success "Database connection successful"
    else
        warning "Database connection failed. Check logs with: docker-compose logs mysql"
    fi
    
    success "Deployment verification completed"
}

# Show deployment information
show_info() {
    log "Deployment completed successfully!"
    echo
    echo "=========================================="
    echo "  Simple Web App Deployment Information"
    echo "=========================================="
    echo
    echo "🌐 Web Application:"
    echo "   URL: http://localhost"
    echo "   Health Check: http://localhost/health"
    echo
    echo "🗄️  Database:"
    echo "   Host: localhost:3306"
    echo "   Database: simple_webapp"
    echo "   Username: webapp_user"
    echo "   Password: webapp_password123"
    echo
    echo "🔧 Admin Tools:"
    echo "   phpMyAdmin: http://localhost:8081"
    echo "   Username: root"
    echo "   Password: rootpassword123"
    echo
    echo "📊 Container Status:"
    docker-compose ps
    echo
    echo "📝 Useful Commands:"
    echo "   View logs: docker-compose logs -f"
    echo "   Stop app: docker-compose down"
    echo "   Restart app: docker-compose restart"
    echo "   Update app: ./deploy/deploy.sh"
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

# Main deployment function
main() {
    log "Starting Simple Web App deployment..."
    
    check_root
    check_requirements
    create_directories
    create_env_file
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
        echo "  help       Show this help message"
        ;;
    *)
        main
        ;;
esac
