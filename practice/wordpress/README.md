# WordPress Deployment Guide

A comprehensive guide for deploying WordPress applications to various server environments, including traditional LAMP stack and modern containerized approaches.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Deployment Methods](#deployment-methods)
  - [Traditional LAMP Stack](#traditional-lamp-stack)
  - [Docker Deployment](#docker-deployment)
  - [Cloud Deployment](#cloud-deployment)
- [Server Configuration](#server-configuration)
- [Security Hardening](#security-hardening)
- [Performance Optimization](#performance-optimization)
- [Monitoring & Maintenance](#monitoring--maintenance)
- [Troubleshooting](#troubleshooting)
- [Backup & Recovery](#backup--recovery)

## Overview

This guide provides step-by-step instructions for deploying WordPress applications across different environments, from development to production. It covers both traditional server deployments and modern containerized approaches.

### What You'll Learn

- Deploy WordPress on Ubuntu/CentOS servers
- Configure web servers (Apache/Nginx)
- Set up databases (MySQL/MariaDB)
- Implement security best practices
- Optimize performance
- Monitor and maintain WordPress installations
- Handle backups and disaster recovery

## Prerequisites

### System Requirements

**Minimum Requirements:**
- PHP 7.4 or higher (PHP 8.1+ recommended)
- MySQL 5.7+ or MariaDB 10.3+
- Web server (Apache 2.4+ or Nginx 1.18+)
- 512MB RAM (1GB+ recommended)
- 1GB disk space (10GB+ recommended)

**Recommended Requirements:**
- PHP 8.1+
- MySQL 8.0+ or MariaDB 10.6+
- Nginx 1.20+
- 2GB+ RAM
- 20GB+ SSD storage

### Software Dependencies

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y apache2 mysql-server php php-mysql php-curl php-gd php-mbstring php-xml php-zip unzip

# CentOS/RHEL
sudo yum update
sudo yum install -y httpd mysql-server php php-mysql php-curl php-gd php-mbstring php-xml php-zip unzip
```

## Deployment Methods

### Traditional LAMP Stack

#### 1. Server Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install LAMP stack
sudo apt install -y apache2 mysql-server php php-mysql php-curl php-gd php-mbstring php-xml php-zip

# Start and enable services
sudo systemctl start apache2 mysql
sudo systemctl enable apache2 mysql
```

#### 2. Database Configuration

```bash
# Secure MySQL installation
sudo mysql_secure_installation

# Create WordPress database
sudo mysql -u root -p
```

```sql
CREATE DATABASE wordpress_db;
CREATE USER 'wp_user'@'localhost' IDENTIFIED BY 'secure_password';
GRANT ALL PRIVILEGES ON wordpress_db.* TO 'wp_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

#### 3. WordPress Installation

```bash
# Download WordPress
cd /tmp
wget https://wordpress.org/latest.tar.gz
tar xzf latest.tar.gz

# Move to web directory
sudo mv wordpress /var/www/html/
sudo chown -R www-data:www-data /var/www/html/wordpress
sudo chmod -R 755 /var/www/html/wordpress
```

#### 4. Apache Configuration

```apache
# /etc/apache2/sites-available/wordpress.conf
<VirtualHost *:80>
    ServerName your-domain.com
    DocumentRoot /var/www/html/wordpress
    
    <Directory /var/www/html/wordpress>
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog ${APACHE_LOG_DIR}/wordpress_error.log
    CustomLog ${APACHE_LOG_DIR}/wordpress_access.log combined
</VirtualHost>
```

### Docker Deployment

#### 1. Docker Compose Setup

```yaml
# docker-compose.yml
version: '3.8'

services:
  wordpress:
    image: wordpress:latest
    container_name: wordpress
    restart: unless-stopped
    ports:
      - "8080:80"
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress_password
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - wordpress_data:/var/www/html
    depends_on:
      - db

  db:
    image: mysql:8.0
    container_name: wordpress_db
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress_password
      MYSQL_ROOT_PASSWORD: root_password
    volumes:
      - db_data:/var/lib/mysql

  phpmyadmin:
    image: phpmyadmin/phpmyadmin
    container_name: wordpress_phpmyadmin
    restart: unless-stopped
    ports:
      - "8081:80"
    environment:
      PMA_HOST: db
      PMA_USER: wordpress
      PMA_PASSWORD: wordpress_password
    depends_on:
      - db

volumes:
  wordpress_data:
  db_data:
```

#### 2. Deploy with Docker

```bash
# Start services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f wordpress
```

## Server Configuration

### Nginx Configuration

```nginx
# /etc/nginx/sites-available/wordpress
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;
    root /var/www/html/wordpress;
    index index.php index.html index.htm;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;

    # WordPress specific rules
    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    # Deny access to sensitive files
    location ~ /\.ht {
        deny all;
    }
    
    location ~ /wp-config.php {
        deny all;
    }
}
```

### PHP Configuration

```ini
# /etc/php/8.1/apache2/php.ini
upload_max_filesize = 64M
post_max_size = 64M
max_execution_time = 300
memory_limit = 256M
max_input_vars = 3000
```

## Security Hardening

### 1. File Permissions

```bash
# Set proper permissions
sudo find /var/www/html/wordpress -type d -exec chmod 755 {} \;
sudo find /var/www/html/wordpress -type f -exec chmod 644 {} \;
sudo chmod 600 /var/www/html/wordpress/wp-config.php
```

### 2. WordPress Security

```php
// wp-config.php security additions
define('DISALLOW_FILE_EDIT', true);
define('WP_DEBUG', false);
define('WP_DEBUG_LOG', false);
define('WP_DEBUG_DISPLAY', false);

// Security keys (generate at https://api.wordpress.org/secret-key/1.1/salt/)
define('AUTH_KEY',         'your-unique-phrase-here');
define('SECURE_AUTH_KEY',  'your-unique-phrase-here');
define('LOGGED_IN_KEY',    'your-unique-phrase-here');
define('NONCE_KEY',        'your-unique-phrase-here');
define('AUTH_SALT',        'your-unique-phrase-here');
define('SECURE_AUTH_SALT', 'your-unique-phrase-here');
define('LOGGED_IN_SALT',   'your-unique-phrase-here');
define('NONCE_SALT',       'your-unique-phrase-here');
```

### 3. SSL Configuration

```bash
# Install Certbot
sudo apt install certbot python3-certbot-apache

# Obtain SSL certificate
sudo certbot --apache -d your-domain.com -d www.your-domain.com

# Auto-renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

## Performance Optimization

### 1. Caching Setup

```bash
# Install Redis
sudo apt install redis-server

# Install Redis PHP extension
sudo apt install php-redis
```

### 2. WordPress Caching Plugin Configuration

```php
// wp-config.php caching additions
define('WP_CACHE', true);
define('WP_REDIS_HOST', '127.0.0.1');
define('WP_REDIS_PORT', 6379);
define('WP_REDIS_DATABASE', 0);
```

### 3. Database Optimization

```sql
-- Optimize WordPress tables
OPTIMIZE TABLE wp_posts;
OPTIMIZE TABLE wp_postmeta;
OPTIMIZE TABLE wp_comments;
OPTIMIZE TABLE wp_commentmeta;
OPTIMIZE TABLE wp_options;
```

## Monitoring & Maintenance

### 1. Log Monitoring

```bash
# Monitor Apache logs
sudo tail -f /var/log/apache2/access.log
sudo tail -f /var/log/apache2/error.log

# Monitor MySQL logs
sudo tail -f /var/log/mysql/error.log
```

### 2. Performance Monitoring

```bash
# Check server resources
htop
df -h
free -h

# Check WordPress specific metrics
wp-cli core check-update
wp-cli plugin list --status=inactive
```

## Troubleshooting

### Common Issues

#### 1. Permission Errors
```bash
sudo chown -R www-data:www-data /var/www/html/wordpress
sudo chmod -R 755 /var/www/html/wordpress
```

#### 2. Database Connection Issues
```bash
# Check MySQL status
sudo systemctl status mysql

# Test database connection
mysql -u wp_user -p -h localhost wordpress_db
```

#### 3. Memory Issues
```bash
# Increase PHP memory limit
echo "memory_limit = 512M" | sudo tee -a /etc/php/8.1/apache2/php.ini
sudo systemctl restart apache2
```

### Debug Mode

```php
// Enable WordPress debug mode
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', false);
define('SCRIPT_DEBUG', true);
```

## Backup & Recovery

### 1. Database Backup

```bash
#!/bin/bash
# backup-db.sh
DATE=$(date +%Y%m%d_%H%M%S)
mysqldump -u wp_user -p wordpress_db > /backups/wordpress_db_$DATE.sql
gzip /backups/wordpress_db_$DATE.sql
```

### 2. File Backup

```bash
#!/bin/bash
# backup-files.sh
DATE=$(date +%Y%m%d_%H%M%S)
tar -czf /backups/wordpress_files_$DATE.tar.gz /var/www/html/wordpress
```

### 3. Automated Backup Script

```bash
#!/bin/bash
# /usr/local/bin/wordpress-backup.sh

BACKUP_DIR="/backups/wordpress"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# Create backup directory
mkdir -p $BACKUP_DIR

# Database backup
mysqldump -u wp_user -p'password' wordpress_db | gzip > $BACKUP_DIR/db_$DATE.sql.gz

# Files backup
tar -czf $BACKUP_DIR/files_$DATE.tar.gz /var/www/html/wordpress

# Cleanup old backups
find $BACKUP_DIR -name "*.gz" -mtime +$RETENTION_DAYS -delete

echo "Backup completed: $DATE"
```

### 4. Restore Process

```bash
# Restore database
gunzip -c /backups/wordpress/db_20240101_120000.sql.gz | mysql -u wp_user -p wordpress_db

# Restore files
tar -xzf /backups/wordpress/files_20240101_120000.tar.gz -C /
```

## Quick Start Commands

```bash
# Traditional deployment
./deploy/traditional-deploy.sh

# Docker deployment
./deploy/docker-deploy.sh

# Security hardening
./security/harden-wordpress.sh

# Performance optimization
./config/optimize-performance.sh
```

## Additional Resources

- [WordPress Codex](https://codex.wordpress.org/)
- [WordPress Security](https://wordpress.org/support/article/hardening-wordpress/)
- [Performance Optimization](https://wordpress.org/support/article/optimization/)
- [Docker WordPress](https://hub.docker.com/_/wordpress)

---

**Note:** Always test deployments in a staging environment before applying to production. Keep regular backups and monitor your WordPress installation for security and performance issues.
