#!/bin/bash

# Enterprise Production Deployment Script
# This script deploys the enterprise application to production with enhanced security and monitoring

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="enterprise-prod"
DOCKER_COMPOSE_FILE="docker-compose.prod.yml"
BACKUP_DIR="/backup/enterprise"
LOG_DIR="/var/log/enterprise"
ENVIRONMENT="production"

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

check_production_requirements() {
    log_info "Checking production requirements..."
    
    # Check if running as root or with sudo
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root or with sudo for production deployment"
        exit 1
    fi
    
    # Check available disk space (minimum 10GB)
    AVAILABLE_SPACE=$(df / | awk 'NR==2 {print $4}')
    if [ "$AVAILABLE_SPACE" -lt 10485760 ]; then
        log_error "Insufficient disk space. Minimum 10GB required."
        exit 1
    fi
    
    # Check available memory (minimum 4GB)
    AVAILABLE_MEMORY=$(free -m | awk 'NR==2{print $7}')
    if [ "$AVAILABLE_MEMORY" -lt 4096 ]; then
        log_warning "Low available memory. Production requires at least 4GB RAM."
    fi
    
    log_success "Production requirements check passed"
}

setup_firewall() {
    log_info "Setting up firewall rules..."
    
    # Allow SSH
    ufw allow 22/tcp
    
    # Allow HTTP and HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # Allow monitoring ports
    ufw allow 9090/tcp  # Prometheus
    ufw allow 3000/tcp  # Grafana
    ufw allow 9093/tcp  # AlertManager
    ufw allow 5601/tcp  # Kibana
    
    # Allow database ports (restrict to internal network)
    ufw allow from 10.0.0.0/8 to any port 5432
    ufw allow from 172.16.0.0/12 to any port 5432
    ufw allow from 192.168.0.0/16 to any port 5432
    
    # Enable firewall
    ufw --force enable
    
    log_success "Firewall configured"
}

setup_ssl_certificates() {
    log_info "Setting up SSL certificates..."
    
    # Create SSL directory
    mkdir -p /etc/ssl/enterprise
    
    # Check if Let's Encrypt certificates exist
    if [ -f "/etc/letsencrypt/live/your-domain.com/fullchain.pem" ]; then
        log_info "Using Let's Encrypt certificates"
        cp /etc/letsencrypt/live/your-domain.com/fullchain.pem /etc/ssl/enterprise/enterprise.crt
        cp /etc/letsencrypt/live/your-domain.com/privkey.pem /etc/ssl/enterprise/enterprise.key
    else
        log_warning "Let's Encrypt certificates not found. Generating self-signed certificates."
        # Generate self-signed certificate
        openssl req -x509 -newkey rsa:4096 -keyout /etc/ssl/enterprise/enterprise.key -out /etc/ssl/enterprise/enterprise.crt -days 365 -nodes \
            -subj "/C=US/ST=State/L=City/O=Enterprise/OU=IT/CN=your-domain.com"
    fi
    
    # Combine certificate and key
    cat /etc/ssl/enterprise/enterprise.crt /etc/ssl/enterprise/enterprise.key > /etc/ssl/enterprise/enterprise.pem
    
    # Set proper permissions
    chmod 600 /etc/ssl/enterprise/enterprise.key
    chmod 644 /etc/ssl/enterprise/enterprise.crt
    chmod 644 /etc/ssl/enterprise/enterprise.pem
    
    log_success "SSL certificates configured"
}

setup_log_rotation() {
    log_info "Setting up log rotation..."
    
    cat > /etc/logrotate.d/enterprise << EOF
/var/log/enterprise/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        docker-compose -f /opt/enterprise/docker-compose.prod.yml restart
    endscript
}
EOF
    
    log_success "Log rotation configured"
}

setup_monitoring() {
    log_info "Setting up monitoring..."
    
    # Create monitoring user
    useradd -r -s /bin/false monitoring
    
    # Create monitoring directories
    mkdir -p /opt/enterprise/monitoring/{prometheus,grafana,alertmanager}
    
    # Set up Prometheus data directory
    mkdir -p /opt/enterprise/data/prometheus
    chown -R monitoring:monitoring /opt/enterprise/data/prometheus
    
    # Set up Grafana data directory
    mkdir -p /opt/enterprise/data/grafana
    chown -R monitoring:monitoring /opt/enterprise/data/grafana
    
    log_success "Monitoring setup completed"
}

create_production_compose() {
    log_info "Creating production Docker Compose file..."
    
    cat > docker-compose.prod.yml << 'EOF'
version: '3.8'

services:
  # Load Balancer - HAProxy
  haproxy:
    image: haproxy:2.8-alpine
    container_name: enterprise-haproxy-prod
    ports:
      - "80:80"
      - "443:443"
      - "8404:8404"
    volumes:
      - ./haproxy/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro
      - /etc/ssl/enterprise:/etc/ssl/certs:ro
      - /var/log/enterprise/haproxy:/var/log
    depends_on:
      - web1
      - web2
      - web3
      - api1
      - api2
      - api3
    networks:
      - enterprise-network
    restart: always
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M

  # Web Servers
  web1:
    image: enterprise-web-frontend:latest
    container_name: enterprise-web1-prod
    environment:
      - NODE_ENV=production
      - API_URL=http://api1:3000
    depends_on:
      - api1
    networks:
      - enterprise-network
    restart: always
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M

  web2:
    image: enterprise-web-frontend:latest
    container_name: enterprise-web2-prod
    environment:
      - NODE_ENV=production
      - API_URL=http://api2:3000
    depends_on:
      - api2
    networks:
      - enterprise-network
    restart: always
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M

  web3:
    image: enterprise-web-frontend:latest
    container_name: enterprise-web3-prod
    environment:
      - NODE_ENV=production
      - API_URL=http://api3:3000
    depends_on:
      - api3
    networks:
      - enterprise-network
    restart: always
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M

  # API Servers
  api1:
    image: enterprise-api-backend:latest
    container_name: enterprise-api1-prod
    environment:
      - NODE_ENV=production
      - PORT=3000
      - POSTGRES_HOST=postgres-primary
      - POSTGRES_PORT=5432
      - POSTGRES_DB=enterprise
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - REDIS_HOST=redis-master
      - REDIS_PORT=6379
      - REDIS_PASSWORD=${REDIS_PASSWORD}
      - JWT_SECRET=${JWT_SECRET}
    depends_on:
      - postgres-primary
      - redis-master
    networks:
      - enterprise-network
    restart: always
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M

  api2:
    image: enterprise-api-backend:latest
    container_name: enterprise-api2-prod
    environment:
      - NODE_ENV=production
      - PORT=3000
      - POSTGRES_HOST=postgres-primary
      - POSTGRES_PORT=5432
      - POSTGRES_DB=enterprise
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - REDIS_HOST=redis-master
      - REDIS_PORT=6379
      - REDIS_PASSWORD=${REDIS_PASSWORD}
      - JWT_SECRET=${JWT_SECRET}
    depends_on:
      - postgres-primary
      - redis-master
    networks:
      - enterprise-network
    restart: always
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M

  api3:
    image: enterprise-api-backend:latest
    container_name: enterprise-api3-prod
    environment:
      - NODE_ENV=production
      - PORT=3000
      - POSTGRES_HOST=postgres-primary
      - POSTGRES_PORT=5432
      - POSTGRES_DB=enterprise
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - REDIS_HOST=redis-master
      - REDIS_PORT=6379
      - REDIS_PASSWORD=${REDIS_PASSWORD}
      - JWT_SECRET=${JWT_SECRET}
    depends_on:
      - postgres-primary
      - redis-master
    networks:
      - enterprise-network
    restart: always
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M

  # Admin Servers
  admin1:
    image: enterprise-admin-panel:latest
    container_name: enterprise-admin1-prod
    environment:
      - FLASK_ENV=production
      - POSTGRES_HOST=postgres-primary
      - POSTGRES_PORT=5432
      - POSTGRES_DB=enterprise
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - REDIS_HOST=redis-master
      - REDIS_PORT=6379
      - REDIS_PASSWORD=${REDIS_PASSWORD}
      - JWT_SECRET_KEY=${JWT_SECRET}
    depends_on:
      - postgres-primary
      - redis-master
    networks:
      - enterprise-network
    restart: always
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M

  admin2:
    image: enterprise-admin-panel:latest
    container_name: enterprise-admin2-prod
    environment:
      - FLASK_ENV=production
      - POSTGRES_HOST=postgres-primary
      - POSTGRES_PORT=5432
      - POSTGRES_DB=enterprise
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - REDIS_HOST=redis-master
      - REDIS_PORT=6379
      - REDIS_PASSWORD=${REDIS_PASSWORD}
      - JWT_SECRET_KEY=${JWT_SECRET}
    depends_on:
      - postgres-primary
      - redis-master
    networks:
      - enterprise-network
    restart: always
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M

  # Database Services
  postgres-primary:
    image: postgres:15-alpine
    container_name: enterprise-postgres-primary-prod
    environment:
      - POSTGRES_DB=enterprise
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_REPLICATION_USER=replicator
      - POSTGRES_REPLICATION_PASSWORD=${POSTGRES_REPLICATION_PASSWORD}
    volumes:
      - postgres_primary_data:/var/lib/postgresql/data
      - ./databases/postgres/postgresql.conf:/etc/postgresql/postgresql.conf:ro
      - ./databases/postgres/pg_hba.conf:/etc/postgresql/pg_hba.conf:ro
      - /var/log/enterprise/postgres:/var/log/postgresql
    command: postgres -c config_file=/etc/postgresql/postgresql.conf
    networks:
      - enterprise-network
    restart: always
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G

  postgres-replica:
    image: postgres:15-alpine
    container_name: enterprise-postgres-replica-prod
    environment:
      - POSTGRES_DB=enterprise
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_MASTER_HOST=postgres-primary
      - POSTGRES_MASTER_PORT=5432
      - POSTGRES_REPLICATION_USER=replicator
      - POSTGRES_REPLICATION_PASSWORD=${POSTGRES_REPLICATION_PASSWORD}
    volumes:
      - postgres_replica_data:/var/lib/postgresql/data
      - ./databases/postgres/postgresql-replica.conf:/etc/postgresql/postgresql.conf:ro
      - /var/log/enterprise/postgres:/var/log/postgresql
    command: postgres -c config_file=/etc/postgresql/postgresql.conf
    depends_on:
      - postgres-primary
    networks:
      - enterprise-network
    restart: always
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G

  redis-master:
    image: redis:7-alpine
    container_name: enterprise-redis-master-prod
    environment:
      - REDIS_PASSWORD=${REDIS_PASSWORD}
    volumes:
      - redis_master_data:/data
      - ./databases/redis/redis-master.conf:/usr/local/etc/redis/redis.conf:ro
    command: redis-server /usr/local/etc/redis/redis.conf
    networks:
      - enterprise-network
    restart: always
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M

  redis-slave:
    image: redis:7-alpine
    container_name: enterprise-redis-slave-prod
    environment:
      - REDIS_PASSWORD=${REDIS_PASSWORD}
      - REDIS_MASTER_HOST=redis-master
      - REDIS_MASTER_PORT=6379
      - REDIS_MASTER_PASSWORD=${REDIS_PASSWORD}
    volumes:
      - redis_slave_data:/data
      - ./databases/redis/redis-slave.conf:/usr/local/etc/redis/redis.conf:ro
    command: redis-server /usr/local/etc/redis/redis.conf
    depends_on:
      - redis-master
    networks:
      - enterprise-network
    restart: always
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M

  # Monitoring Services
  prometheus:
    image: prom/prometheus:latest
    container_name: enterprise-prometheus-prod
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=30d'
      - '--web.enable-lifecycle'
    networks:
      - enterprise-network
    restart: always
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M

  grafana:
    image: grafana/grafana:latest
    container_name: enterprise-grafana-prod
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
      - ./monitoring/grafana/provisioning:/etc/grafana/provisioning:ro
      - ./monitoring/grafana/dashboards:/var/lib/grafana/dashboards:ro
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_INSTALL_PLUGINS=grafana-piechart-panel,grafana-worldmap-panel
    depends_on:
      - prometheus
    networks:
      - enterprise-network
    restart: always
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M

  alertmanager:
    image: prom/alertmanager:latest
    container_name: enterprise-alertmanager-prod
    ports:
      - "9093:9093"
    volumes:
      - ./monitoring/alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro
      - alertmanager_data:/alertmanager
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
      - '--web.external-url=http://localhost:9093'
    networks:
      - enterprise-network
    restart: always
    deploy:
      resources:
        limits:
          memory: 256M
        reservations:
          memory: 128M

volumes:
  postgres_primary_data:
    driver: local
  postgres_replica_data:
    driver: local
  redis_master_data:
    driver: local
  redis_slave_data:
    driver: local
  prometheus_data:
    driver: local
  grafana_data:
    driver: local
  alertmanager_data:
    driver: local

networks:
  enterprise-network:
    driver: bridge
EOF
    
    log_success "Production Docker Compose file created"
}

create_environment_file() {
    log_info "Creating environment file..."
    
    cat > .env.prod << EOF
# Production Environment Variables
POSTGRES_PASSWORD=$(openssl rand -base64 32)
POSTGRES_REPLICATION_PASSWORD=$(openssl rand -base64 32)
REDIS_PASSWORD=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -base64 64)
GRAFANA_PASSWORD=$(openssl rand -base64 16)

# Security
NODE_ENV=production
FLASK_ENV=production

# Database
POSTGRES_HOST=postgres-primary
POSTGRES_PORT=5432
POSTGRES_DB=enterprise
POSTGRES_USER=postgres

# Cache
REDIS_HOST=redis-master
REDIS_PORT=6379

# Monitoring
PROMETHEUS_RETENTION=30d
GRAFANA_ADMIN_PASSWORD=\${GRAFANA_PASSWORD}
EOF
    
    log_success "Environment file created"
    log_warning "Please review and update the .env.prod file with your specific configuration"
}

deploy_services() {
    log_info "Deploying services to production..."
    
    # Copy project files to production directory
    mkdir -p /opt/enterprise
    cp -r . /opt/enterprise/
    cd /opt/enterprise
    
    # Create production compose file
    create_production_compose
    
    # Create environment file
    create_environment_file
    
    # Build production images
    log_info "Building production images..."
    docker build -t enterprise-web-frontend:latest ./applications/web-frontend/
    docker build -t enterprise-api-backend:latest ./applications/api-backend/
    docker build -t enterprise-admin-panel:latest ./applications/admin-panel/
    
    # Start services
    log_info "Starting production services..."
    docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d
    
    log_success "Production deployment completed"
}

setup_backup() {
    log_info "Setting up backup system..."
    
    # Create backup script
    cat > /opt/enterprise/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/backup/enterprise"
DATE=$(date +%Y%m%d_%H%M%S)

# Database backup
docker exec enterprise-postgres-primary-prod pg_dump -U postgres enterprise > "$BACKUP_DIR/db_$DATE.sql"

# Application backup
tar -czf "$BACKUP_DIR/app_$DATE.tar.gz" /opt/enterprise/

# Cleanup old backups (keep 30 days)
find "$BACKUP_DIR" -name "*.sql" -mtime +30 -delete
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 -delete
EOF
    
    chmod +x /opt/enterprise/backup.sh
    
    # Add to crontab
    echo "0 2 * * * /opt/enterprise/backup.sh" | crontab -
    
    log_success "Backup system configured"
}

# Main deployment process
main() {
    log_info "Starting Enterprise Production Deployment"
    echo ""
    
    check_production_requirements
    setup_firewall
    setup_ssl_certificates
    setup_log_rotation
    setup_monitoring
    deploy_services
    setup_backup
    
    log_success "Production deployment completed successfully!"
    echo ""
    log_info "Production URLs:"
    echo "🌐 Web Application:     https://your-domain.com"
    echo "🔧 API Endpoints:       https://your-domain.com/api"
    echo "⚙️  Admin Panel:        https://your-domain.com/admin"
    echo "📊 Prometheus:          https://your-domain.com:9090"
    echo "📈 Grafana:             https://your-domain.com:3000"
    echo "🚨 AlertManager:        https://your-domain.com:9093"
    echo ""
    log_info "To view logs: docker-compose -f /opt/enterprise/docker-compose.prod.yml logs -f"
    log_info "To stop services: docker-compose -f /opt/enterprise/docker-compose.prod.yml down"
    log_info "To restart services: docker-compose -f /opt/enterprise/docker-compose.prod.yml restart"
}

# Run main function
main "$@"
