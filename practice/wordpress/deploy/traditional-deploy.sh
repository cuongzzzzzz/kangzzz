#!/bin/bash

# WordPress Traditional LAMP Stack Deployment Script
# This script deploys WordPress using Apache, MySQL, and PHP

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration variables
DOMAIN=""
DB_NAME="wordpress_db"
DB_USER="wp_user"
DB_PASS=""
WP_ADMIN_USER="admin"
WP_ADMIN_PASS=""
WP_ADMIN_EMAIL=""
WP_TITLE="My WordPress Site"

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

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root for security reasons"
        exit 1
    fi
}

# Function to check if sudo is available
check_sudo() {
    if ! command -v sudo &> /dev/null; then
        print_error "sudo is required but not installed"
        exit 1
    fi
}

# Function to detect OS
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        print_error "Cannot detect OS version"
        exit 1
    fi
    
    print_status "Detected OS: $OS $VER"
}

# Function to install dependencies
install_dependencies() {
    print_status "Installing system dependencies..."
    
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        sudo apt update
        sudo apt install -y apache2 mysql-server php php-mysql php-curl php-gd php-mbstring php-xml php-zip unzip wget curl
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        sudo yum update -y
        sudo yum install -y httpd mysql-server php php-mysql php-curl php-gd php-mbstring php-xml php-zip unzip wget curl
    else
        print_error "Unsupported OS: $OS"
        exit 1
    fi
}

# Function to configure MySQL
configure_mysql() {
    print_status "Configuring MySQL..."
    
    # Start MySQL service
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        sudo systemctl start mysql
        sudo systemctl enable mysql
    else
        sudo systemctl start mysqld
        sudo systemctl enable mysqld
    fi
    
    # Generate random password if not provided
    if [[ -z "$DB_PASS" ]]; then
        DB_PASS=$(openssl rand -base64 32)
        print_status "Generated database password: $DB_PASS"
    fi
    
    # Create database and user
    sudo mysql -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"
    sudo mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
    sudo mysql -e "FLUSH PRIVILEGES;"
    
    print_status "MySQL configured successfully"
}

# Function to configure Apache
configure_apache() {
    print_status "Configuring Apache..."
    
    # Enable required modules
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        sudo a2enmod rewrite
        sudo a2enmod ssl
        sudo systemctl restart apache2
    else
        sudo systemctl start httpd
        sudo systemctl enable httpd
    fi
    
    print_status "Apache configured successfully"
}

# Function to download and install WordPress
install_wordpress() {
    print_status "Installing WordPress..."
    
    # Create web directory
    sudo mkdir -p /var/www/html/wordpress
    
    # Download WordPress
    cd /tmp
    wget -q https://wordpress.org/latest.tar.gz
    tar -xzf latest.tar.gz
    
    # Move WordPress files
    sudo mv wordpress/* /var/www/html/wordpress/
    sudo rm -rf wordpress latest.tar.gz
    
    # Set permissions
    sudo chown -R www-data:www-data /var/www/html/wordpress
    sudo chmod -R 755 /var/www/html/wordpress
    
    print_status "WordPress files installed successfully"
}

# Function to create wp-config.php
create_wp_config() {
    print_status "Creating wp-config.php..."
    
    # Generate WordPress salts
    SALTS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
    
    # Create wp-config.php
    sudo tee /var/www/html/wordpress/wp-config.php > /dev/null <<EOF
<?php
define('DB_NAME', '$DB_NAME');
define('DB_USER', '$DB_USER');
define('DB_PASSWORD', '$DB_PASS');
define('DB_HOST', 'localhost');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

$SALTS

\$table_prefix = 'wp_';

define('WP_DEBUG', false);
define('WP_DEBUG_LOG', false);
define('WP_DEBUG_DISPLAY', false);
define('DISALLOW_FILE_EDIT', true);

if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

require_once ABSPATH . 'wp-settings.php';
EOF

    # Secure wp-config.php
    sudo chmod 600 /var/www/html/wordpress/wp-config.php
    sudo chown www-data:www-data /var/www/html/wordpress/wp-config.php
    
    print_status "wp-config.php created successfully"
}

# Function to create Apache virtual host
create_virtual_host() {
    if [[ -n "$DOMAIN" ]]; then
        print_status "Creating Apache virtual host for $DOMAIN..."
        
        sudo tee /etc/apache2/sites-available/wordpress.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerName $DOMAIN
    ServerAlias www.$DOMAIN
    DocumentRoot /var/www/html/wordpress
    
    <Directory /var/www/html/wordpress>
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/wordpress_error.log
    CustomLog \${APACHE_LOG_DIR}/wordpress_access.log combined
</VirtualHost>
EOF

        # Enable site
        sudo a2ensite wordpress.conf
        sudo a2dissite 000-default.conf
        sudo systemctl reload apache2
        
        print_status "Virtual host created for $DOMAIN"
    fi
}

# Function to optimize PHP
optimize_php() {
    print_status "Optimizing PHP configuration..."
    
    # Find PHP version
    PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
    
    # Update PHP configuration
    sudo tee -a /etc/php/$PHP_VERSION/apache2/php.ini > /dev/null <<EOF

; WordPress optimizations
upload_max_filesize = 64M
post_max_size = 64M
max_execution_time = 300
memory_limit = 256M
max_input_vars = 3000
EOF

    # Restart Apache
    sudo systemctl restart apache2
    
    print_status "PHP optimized successfully"
}

# Function to install WP-CLI
install_wp_cli() {
    print_status "Installing WP-CLI..."
    
    cd /tmp
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    
    # Move to system path
    sudo mv wp-cli.phar /usr/local/bin/wp
    sudo chmod +x /usr/local/bin/wp
    
    print_status "WP-CLI installed successfully"
}

# Function to complete WordPress setup
complete_wordpress_setup() {
    print_status "Completing WordPress setup..."
    
    cd /var/www/html/wordpress
    
    # Generate admin password if not provided
    if [[ -z "$WP_ADMIN_PASS" ]]; then
        WP_ADMIN_PASS=$(openssl rand -base64 16)
        print_status "Generated admin password: $WP_ADMIN_PASS"
    fi
    
    # Set default email if not provided
    if [[ -z "$WP_ADMIN_EMAIL" ]]; then
        WP_ADMIN_EMAIL="admin@$DOMAIN"
    fi
    
    # Install WordPress via WP-CLI
    sudo -u www-data wp core install \
        --url="http://$DOMAIN" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASS" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email
    
    print_status "WordPress setup completed successfully"
}

# Function to display final information
display_final_info() {
    print_status "WordPress deployment completed successfully!"
    echo
    echo "=========================================="
    echo "WordPress Installation Details:"
    echo "=========================================="
    echo "Site URL: http://$DOMAIN"
    echo "Admin URL: http://$DOMAIN/wp-admin"
    echo "Admin Username: $WP_ADMIN_USER"
    echo "Admin Password: $WP_ADMIN_PASS"
    echo "Admin Email: $WP_ADMIN_EMAIL"
    echo
    echo "Database Details:"
    echo "Database Name: $DB_NAME"
    echo "Database User: $DB_USER"
    echo "Database Password: $DB_PASS"
    echo
    echo "Files Location: /var/www/html/wordpress"
    echo "Apache Config: /etc/apache2/sites-available/wordpress.conf"
    echo "=========================================="
    echo
    print_warning "Please save the above information securely!"
    print_warning "Consider setting up SSL certificate for production use."
}

# Main execution
main() {
    echo "WordPress Traditional LAMP Stack Deployment Script"
    echo "=================================================="
    echo
    
    # Get user input
    read -p "Enter your domain name (e.g., example.com): " DOMAIN
    read -p "Enter WordPress admin username [admin]: " WP_ADMIN_USER
    WP_ADMIN_USER=${WP_ADMIN_USER:-admin}
    read -s -p "Enter WordPress admin password (leave empty for auto-generated): " WP_ADMIN_PASS
    echo
    read -p "Enter WordPress admin email: " WP_ADMIN_EMAIL
    read -p "Enter WordPress site title [My WordPress Site]: " WP_TITLE
    WP_TITLE=${WP_TITLE:-My WordPress Site}
    
    # Validate inputs
    if [[ -z "$DOMAIN" ]]; then
        print_error "Domain name is required"
        exit 1
    fi
    
    if [[ -z "$WP_ADMIN_EMAIL" ]]; then
        print_error "Admin email is required"
        exit 1
    fi
    
    # Run deployment steps
    check_root
    check_sudo
    detect_os
    install_dependencies
    configure_mysql
    configure_apache
    install_wordpress
    create_wp_config
    create_virtual_host
    optimize_php
    install_wp_cli
    complete_wordpress_setup
    display_final_info
}

# Run main function
main "$@"
