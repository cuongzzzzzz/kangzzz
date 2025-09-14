#!/bin/bash

# WordPress Docker Deployment Script
# This script deploys WordPress using Docker and Docker Compose

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration variables
PROJECT_NAME="wordpress"
DOMAIN=""
DB_PASSWORD=""
WP_ADMIN_USER="admin"
WP_ADMIN_PASS=""
WP_ADMIN_EMAIL=""
WP_TITLE="My WordPress Site"
ENABLE_PHPMYADMIN=true
ENABLE_REDIS=false

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        print_status "Installation instructions: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        print_status "Installation instructions: https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    print_status "Docker and Docker Compose are installed"
}

# Function to generate random passwords
generate_passwords() {
    if [[ -z "$DB_PASSWORD" ]]; then
        DB_PASSWORD=$(openssl rand -base64 32)
        print_status "Generated database password: $DB_PASSWORD"
    fi
    
    if [[ -z "$WP_ADMIN_PASS" ]]; then
        WP_ADMIN_PASS=$(openssl rand -base64 16)
        print_status "Generated WordPress admin password: $WP_ADMIN_PASS"
    fi
}

# Function to create docker-compose.yml
create_docker_compose() {
    print_status "Creating docker-compose.yml..."
    
    cat > docker-compose.yml <<EOF
version: '3.8'

services:
  wordpress:
    image: wordpress:latest
    container_name: ${PROJECT_NAME}_wordpress
    restart: unless-stopped
    ports:
      - "8080:80"
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: ${DB_PASSWORD}
      WORDPRESS_DB_NAME: wordpress
      WORDPRESS_DEBUG: 0
    volumes:
      - wordpress_data:/var/www/html
      - ./config/uploads.ini:/usr/local/etc/php/conf.d/uploads.ini
    depends_on:
      - db
    networks:
      - wordpress_network
EOF

    # Add Redis if enabled
    if [[ "$ENABLE_REDIS" == true ]]; then
        cat >> docker-compose.yml <<EOF

  redis:
    image: redis:7-alpine
    container_name: ${PROJECT_NAME}_redis
    restart: unless-stopped
    volumes:
      - redis_data:/data
    networks:
      - wordpress_network
EOF
    fi

    # Add phpMyAdmin if enabled
    if [[ "$ENABLE_PHPMYADMIN" == true ]]; then
        cat >> docker-compose.yml <<EOF

  phpmyadmin:
    image: phpmyadmin/phpmyadmin
    container_name: ${PROJECT_NAME}_phpmyadmin
    restart: unless-stopped
    ports:
      - "8081:80"
    environment:
      PMA_HOST: db
      PMA_USER: wordpress
      PMA_PASSWORD: ${DB_PASSWORD}
    depends_on:
      - db
    networks:
      - wordpress_network
EOF
    fi

    # Add database service
    cat >> docker-compose.yml <<EOF

  db:
    image: mysql:8.0
    container_name: ${PROJECT_NAME}_db
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: ${DB_PASSWORD}
      MYSQL_ROOT_PASSWORD: ${DB_PASSWORD}
    volumes:
      - db_data:/var/lib/mysql
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - wordpress_network

volumes:
  wordpress_data:
  db_data:
EOF

    # Add Redis volume if enabled
    if [[ "$ENABLE_REDIS" == true ]]; then
        cat >> docker-compose.yml <<EOF
  redis_data:
EOF
    fi

    # Add networks
    cat >> docker-compose.yml <<EOF

networks:
  wordpress_network:
    driver: bridge
EOF

    print_status "docker-compose.yml created successfully"
}

# Function to create PHP upload configuration
create_php_config() {
    print_status "Creating PHP configuration..."
    
    mkdir -p config
    
    cat > config/uploads.ini <<EOF
; WordPress upload configuration
upload_max_filesize = 64M
post_max_size = 64M
max_execution_time = 300
memory_limit = 256M
max_input_vars = 3000
EOF

    print_status "PHP configuration created"
}

# Function to create database initialization script
create_db_init() {
    print_status "Creating database initialization script..."
    
    mkdir -p database
    
    cat > database/init.sql <<EOF
-- WordPress database initialization
-- This script runs when the database container starts for the first time

-- Create additional databases if needed
-- CREATE DATABASE IF NOT EXISTS wordpress_test;
-- CREATE DATABASE IF NOT EXISTS wordpress_staging;

-- Set up additional users if needed
-- CREATE USER IF NOT EXISTS 'wp_readonly'@'%' IDENTIFIED BY 'readonly_password';
-- GRANT SELECT ON wordpress.* TO 'wp_readonly'@'%';

-- Optimize MySQL settings for WordPress
SET GLOBAL innodb_buffer_pool_size = 256M;
SET GLOBAL max_connections = 200;
SET GLOBAL query_cache_size = 32M;
SET GLOBAL query_cache_type = 1;

-- Flush privileges
FLUSH PRIVILEGES;
EOF

    print_status "Database initialization script created"
}

# Function to create environment file
create_env_file() {
    print_status "Creating .env file..."
    
    cat > .env <<EOF
# WordPress Docker Environment Configuration
PROJECT_NAME=${PROJECT_NAME}
DOMAIN=${DOMAIN}
DB_PASSWORD=${DB_PASSWORD}
WP_ADMIN_USER=${WP_ADMIN_USER}
WP_ADMIN_PASS=${WP_ADMIN_PASS}
WP_ADMIN_EMAIL=${WP_ADMIN_EMAIL}
WP_TITLE=${WP_TITLE}
ENABLE_PHPMYADMIN=${ENABLE_PHPMYADMIN}
ENABLE_REDIS=${ENABLE_REDIS}
EOF

    print_status ".env file created"
}

# Function to create Nginx configuration for production
create_nginx_config() {
    if [[ -n "$DOMAIN" ]]; then
        print_status "Creating Nginx configuration for production..."
        
        mkdir -p nginx
        
        cat > nginx/wordpress.conf <<EOF
upstream wordpress {
    server wordpress:80;
}

server {
    listen 80;
    server_name ${DOMAIN} www.${DOMAIN};
    
    # Redirect HTTP to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${DOMAIN} www.${DOMAIN};
    
    # SSL configuration (you'll need to add your certificates)
    # ssl_certificate /etc/nginx/ssl/cert.pem;
    # ssl_certificate_key /etc/nginx/ssl/key.pem;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss;
    
    # WordPress specific rules
    location / {
        proxy_pass http://wordpress;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Static files caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        proxy_pass http://wordpress;
        proxy_set_header Host \$host;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

        print_status "Nginx configuration created"
    fi
}

# Function to create backup script
create_backup_script() {
    print_status "Creating backup script..."
    
    cat > backup.sh <<'EOF'
#!/bin/bash

# WordPress Docker Backup Script
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)
PROJECT_NAME="wordpress"

# Create backup directory
mkdir -p $BACKUP_DIR

echo "Starting backup process..."

# Backup database
echo "Backing up database..."
docker-compose exec -T db mysqldump -u wordpress -p$DB_PASSWORD wordpress | gzip > $BACKUP_DIR/db_$DATE.sql.gz

# Backup WordPress files
echo "Backing up WordPress files..."
docker-compose exec -T wordpress tar -czf - /var/www/html | cat > $BACKUP_DIR/files_$DATE.tar.gz

# Cleanup old backups (keep last 7 days)
find $BACKUP_DIR -name "*.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
echo "Database: $BACKUP_DIR/db_$DATE.sql.gz"
echo "Files: $BACKUP_DIR/files_$DATE.tar.gz"
EOF

    chmod +x backup.sh
    print_status "Backup script created"
}

# Function to create restore script
create_restore_script() {
    print_status "Creating restore script..."
    
    cat > restore.sh <<'EOF'
#!/bin/bash

# WordPress Docker Restore Script
BACKUP_DIR="./backups"

if [ $# -eq 0 ]; then
    echo "Usage: $0 <backup_timestamp>"
    echo "Available backups:"
    ls -la $BACKUP_DIR/*.gz 2>/dev/null | awk '{print $9}' | sed 's/.*_\([0-9]\{8\}_[0-9]\{6\}\)\.gz/\1/' | sort -r
    exit 1
fi

TIMESTAMP=$1
DB_BACKUP="$BACKUP_DIR/db_$TIMESTAMP.sql.gz"
FILES_BACKUP="$BACKUP_DIR/files_$TIMESTAMP.tar.gz"

if [ ! -f "$DB_BACKUP" ] || [ ! -f "$FILES_BACKUP" ]; then
    echo "Error: Backup files not found for timestamp $TIMESTAMP"
    exit 1
fi

echo "Starting restore process for $TIMESTAMP..."

# Stop WordPress container
docker-compose stop wordpress

# Restore database
echo "Restoring database..."
gunzip -c $DB_BACKUP | docker-compose exec -T db mysql -u wordpress -p$DB_PASSWORD wordpress

# Restore WordPress files
echo "Restoring WordPress files..."
gunzip -c $FILES_BACKUP | docker-compose exec -T wordpress tar -xzf - -C /

# Start WordPress container
docker-compose start wordpress

echo "Restore completed successfully!"
EOF

    chmod +x restore.sh
    print_status "Restore script created"
}

# Function to start the deployment
start_deployment() {
    print_status "Starting WordPress Docker deployment..."
    
    # Pull latest images
    print_status "Pulling Docker images..."
    docker-compose pull
    
    # Start services
    print_status "Starting services..."
    docker-compose up -d
    
    # Wait for services to be ready
    print_status "Waiting for services to be ready..."
    sleep 30
    
    # Check if services are running
    if docker-compose ps | grep -q "Up"; then
        print_status "Services started successfully"
    else
        print_error "Some services failed to start"
        docker-compose logs
        exit 1
    fi
}

# Function to complete WordPress setup
complete_wordpress_setup() {
    print_status "Completing WordPress setup..."
    
    # Wait for WordPress to be ready
    sleep 10
    
    # Install WP-CLI in the WordPress container
    docker-compose exec wordpress bash -c "curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp"
    
    # Complete WordPress installation
    docker-compose exec wordpress wp core install \
        --url="http://localhost:8080" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASS" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email
    
    print_status "WordPress setup completed"
}

# Function to display final information
display_final_info() {
    print_status "WordPress Docker deployment completed successfully!"
    echo
    echo "=========================================="
    echo "WordPress Installation Details:"
    echo "=========================================="
    echo "WordPress URL: http://localhost:8080"
    echo "Admin URL: http://localhost:8080/wp-admin"
    echo "Admin Username: $WP_ADMIN_USER"
    echo "Admin Password: $WP_ADMIN_PASS"
    echo "Admin Email: $WP_ADMIN_EMAIL"
    echo
    if [[ "$ENABLE_PHPMYADMIN" == true ]]; then
        echo "phpMyAdmin URL: http://localhost:8081"
        echo "phpMyAdmin Username: wordpress"
        echo "phpMyAdmin Password: $DB_PASSWORD"
        echo
    fi
    echo "Database Details:"
    echo "Database Name: wordpress"
    echo "Database User: wordpress"
    echo "Database Password: $DB_PASSWORD"
    echo
    echo "Useful Commands:"
    echo "  Start services: docker-compose up -d"
    echo "  Stop services: docker-compose down"
    echo "  View logs: docker-compose logs -f"
    echo "  Backup: ./backup.sh"
    echo "  Restore: ./restore.sh <timestamp>"
    echo "=========================================="
    echo
    print_warning "Please save the above information securely!"
}

# Main execution
main() {
    echo "WordPress Docker Deployment Script"
    echo "=================================="
    echo
    
    # Get user input
    read -p "Enter your domain name (optional, for production): " DOMAIN
    read -p "Enter WordPress admin username [admin]: " WP_ADMIN_USER
    WP_ADMIN_USER=${WP_ADMIN_USER:-admin}
    read -s -p "Enter WordPress admin password (leave empty for auto-generated): " WP_ADMIN_PASS
    echo
    read -p "Enter WordPress admin email: " WP_ADMIN_EMAIL
    read -p "Enter WordPress site title [My WordPress Site]: " WP_TITLE
    WP_TITLE=${WP_TITLE:-My WordPress Site}
    
    read -p "Enable phpMyAdmin? [y/N]: " ENABLE_PHPMYADMIN_INPUT
    ENABLE_PHPMYADMIN_INPUT=${ENABLE_PHPMYADMIN_INPUT:-n}
    if [[ "$ENABLE_PHPMYADMIN_INPUT" =~ ^[Yy]$ ]]; then
        ENABLE_PHPMYADMIN=true
    else
        ENABLE_PHPMYADMIN=false
    fi
    
    read -p "Enable Redis caching? [y/N]: " ENABLE_REDIS_INPUT
    ENABLE_REDIS_INPUT=${ENABLE_REDIS_INPUT:-n}
    if [[ "$ENABLE_REDIS_INPUT" =~ ^[Yy]$ ]]; then
        ENABLE_REDIS=true
    else
        ENABLE_REDIS=false
    fi
    
    # Validate inputs
    if [[ -z "$WP_ADMIN_EMAIL" ]]; then
        print_error "Admin email is required"
        exit 1
    fi
    
    # Run deployment steps
    check_docker
    generate_passwords
    create_docker_compose
    create_php_config
    create_db_init
    create_env_file
    create_nginx_config
    create_backup_script
    create_restore_script
    start_deployment
    complete_wordpress_setup
    display_final_info
}

# Run main function
main "$@"
