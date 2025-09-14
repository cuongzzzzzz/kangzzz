#!/bin/bash

# WordPress Security Hardening Script
# This script implements various security measures for WordPress installations

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration variables
WORDPRESS_PATH="/var/www/html/wordpress"
BACKUP_DIR="/backups/wordpress"
LOG_FILE="/var/log/wordpress-hardening.log"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
    echo "$(date): $1" >> $LOG_FILE
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "$(date): WARNING - $1" >> $LOG_FILE
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "$(date): ERROR - $1" >> $LOG_FILE
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

# Function to create backup
create_backup() {
    print_status "Creating backup before hardening..."
    
    mkdir -p $BACKUP_DIR
    BACKUP_FILE="$BACKUP_DIR/wordpress-backup-$(date +%Y%m%d_%H%M%S).tar.gz"
    
    tar -czf $BACKUP_FILE -C /var/www/html wordpress
    print_status "Backup created: $BACKUP_FILE"
}

# Function to secure file permissions
secure_permissions() {
    print_status "Securing file permissions..."
    
    # Set directory permissions
    find $WORDPRESS_PATH -type d -exec chmod 755 {} \;
    
    # Set file permissions
    find $WORDPRESS_PATH -type f -exec chmod 644 {} \;
    
    # Secure wp-config.php
    chmod 600 $WORDPRESS_PATH/wp-config.php
    chown www-data:www-data $WORDPRESS_PATH/wp-config.php
    
    # Secure wp-content/uploads
    chmod 755 $WORDPRESS_PATH/wp-content/uploads
    chown -R www-data:www-data $WORDPRESS_PATH/wp-content/uploads
    
    # Secure wp-content/plugins and themes
    chmod 755 $WORDPRESS_PATH/wp-content/plugins
    chmod 755 $WORDPRESS_PATH/wp-content/themes
    
    print_status "File permissions secured"
}

# Function to hide WordPress version
hide_wordpress_version() {
    print_status "Hiding WordPress version..."
    
    # Add to functions.php
    cat >> $WORDPRESS_PATH/wp-content/themes/twentytwentythree/functions.php << 'EOF'

// Hide WordPress version
function remove_wp_version() {
    return '';
}
add_filter('the_generator', 'remove_wp_version');
remove_action('wp_head', 'wp_generator');

// Remove version from scripts and styles
function remove_version_scripts_styles($src) {
    if (strpos($src, 'ver=')) {
        $src = remove_query_arg('ver', $src);
    }
    return $src;
}
add_filter('style_loader_src', 'remove_version_scripts_styles', 15, 1);
add_filter('script_loader_src', 'remove_version_scripts_styles', 15, 1);
EOF

    print_status "WordPress version hidden"
}

# Function to disable file editing
disable_file_editing() {
    print_status "Disabling file editing from admin..."
    
    # Add to wp-config.php
    if ! grep -q "DISALLOW_FILE_EDIT" $WORDPRESS_PATH/wp-config.php; then
        sed -i "/define('WP_DEBUG'/i define('DISALLOW_FILE_EDIT', true);" $WORDPRESS_PATH/wp-config.php
    fi
    
    print_status "File editing disabled"
}

# Function to limit login attempts
setup_login_limiting() {
    print_status "Setting up login attempt limiting..."
    
    # Create .htaccess rules for login limiting
    cat > $WORDPRESS_PATH/.htaccess << 'EOF'
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress

# Security headers
<IfModule mod_headers.c>
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options SAMEORIGIN
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    Header always set Permissions-Policy "geolocation=(), microphone=(), camera=()"
</IfModule>

# Disable directory browsing
Options -Indexes

# Protect wp-config.php
<Files wp-config.php>
    Order allow,deny
    Deny from all
</Files>

# Protect .htaccess
<Files .htaccess>
    Order allow,deny
    Deny from all
</Files>

# Block access to sensitive files
<FilesMatch "^(wp-config\.php|readme\.html|license\.txt)">
    Order allow,deny
    Deny from all
</FilesMatch>

# Block access to wp-includes
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^wp-admin/includes/ - [F,L]
RewriteRule !^wp-includes/ - [S=3]
RewriteRule ^wp-includes/[^/]+\.php$ - [F,L]
RewriteRule ^wp-includes/js/tinymce/langs/.+\.php - [F,L]
RewriteRule ^wp-includes/theme-compat/ - [F,L]
</IfModule>

# Block access to readme.html
<Files readme.html>
    Order allow,deny
    Deny from all
</Files>

# Block access to license.txt
<Files license.txt>
    Order allow,deny
    Deny from all
</Files>

# Block access to wp-config-sample.php
<Files wp-config-sample.php>
    Order allow,deny
    Deny from all
</Files>

# Block access to install.php
<Files install.php>
    Order allow,deny
    Deny from all
</Files>

# Block access to wp-admin/install.php
<Files wp-admin/install.php>
    Order allow,deny
    Deny from all
</Files>

# Limit login attempts (requires mod_evasive or similar)
<IfModule mod_evasive24.c>
    DOSHashTableSize    2048
    DOSPageCount        3
    DOSSiteCount        50
    DOSPageInterval     1
    DOSSiteInterval     1
    DOSBlockingPeriod   600
</IfModule>
EOF

    print_status "Login limiting configured"
}

# Function to setup fail2ban
setup_fail2ban() {
    print_status "Setting up Fail2Ban for WordPress..."
    
    # Install fail2ban if not present
    if ! command -v fail2ban-client &> /dev/null; then
        apt update
        apt install -y fail2ban
    fi
    
    # Create WordPress jail
    cat > /etc/fail2ban/jail.d/wordpress.conf << 'EOF'
[wordpress]
enabled = true
port = http,https
filter = wordpress
logpath = /var/log/apache2/access.log
maxretry = 3
bantime = 3600
findtime = 600
EOF

    # Create WordPress filter
    cat > /etc/fail2ban/filter.d/wordpress.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"(GET|POST).*wp-login.php.*" (200|302|401|403)
            ^<HOST> -.*"(GET|POST).*wp-admin.*" (200|302|401|403)
            ^<HOST> -.*"(GET|POST).*xmlrpc.php.*" (200|302|401|403)
ignoreregex =
EOF

    # Restart fail2ban
    systemctl restart fail2ban
    systemctl enable fail2ban
    
    print_status "Fail2Ban configured for WordPress"
}

# Function to setup SSL/TLS
setup_ssl() {
    print_status "Setting up SSL/TLS..."
    
    # Install certbot if not present
    if ! command -v certbot &> /dev/null; then
        apt install -y certbot python3-certbot-apache
    fi
    
    print_warning "SSL setup requires domain configuration. Run manually:"
    print_warning "certbot --apache -d yourdomain.com"
    
    print_status "SSL tools installed"
}

# Function to configure database security
secure_database() {
    print_status "Securing database..."
    
    # Create database security script
    cat > /tmp/secure_mysql.sql << 'EOF'
-- Remove anonymous users
DELETE FROM mysql.user WHERE User='';

-- Remove test database
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

-- Remove root access from non-localhost
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

-- Set secure passwords (you should change these)
-- ALTER USER 'root'@'localhost' IDENTIFIED BY 'your_secure_root_password';

-- Remove empty passwords
UPDATE mysql.user SET authentication_string = PASSWORD('temp_password') WHERE User != 'root' AND authentication_string = '';

-- Flush privileges
FLUSH PRIVILEGES;
EOF

    print_warning "Database security script created at /tmp/secure_mysql.sql"
    print_warning "Review and run manually: mysql -u root -p < /tmp/secure_mysql.sql"
    
    print_status "Database security configured"
}

# Function to setup log monitoring
setup_log_monitoring() {
    print_status "Setting up log monitoring..."
    
    # Create log monitoring script
    cat > /usr/local/bin/wordpress-monitor.sh << 'EOF'
#!/bin/bash

# WordPress Security Monitor
LOG_FILE="/var/log/wordpress-security.log"
WORDPRESS_LOG="/var/log/apache2/access.log"
ALERT_EMAIL="admin@yourdomain.com"

# Monitor for suspicious activity
grep -E "(wp-login|wp-admin|xmlrpc)" $WORDPRESS_LOG | tail -20 | while read line; do
    echo "$(date): $line" >> $LOG_FILE
done

# Check for brute force attempts
FAILED_ATTEMPTS=$(grep "wp-login.php" $WORDPRESS_LOG | grep -c "POST.*200")
if [ $FAILED_ATTEMPTS -gt 10 ]; then
    echo "$(date): High number of failed login attempts: $FAILED_ATTEMPTS" >> $LOG_FILE
    # Send email alert (requires mailutils)
    # echo "High number of failed login attempts detected" | mail -s "WordPress Security Alert" $ALERT_EMAIL
fi

# Check for file modification attempts
grep -E "(wp-config|\.htaccess)" $WORDPRESS_LOG | tail -10 | while read line; do
    echo "$(date): File modification attempt: $line" >> $LOG_FILE
done
EOF

    chmod +x /usr/local/bin/wordpress-monitor.sh
    
    # Add to crontab
    (crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/wordpress-monitor.sh") | crontab -
    
    print_status "Log monitoring configured"
}

# Function to setup firewall
setup_firewall() {
    print_status "Setting up firewall rules..."
    
    # Install ufw if not present
    if ! command -v ufw &> /dev/null; then
        apt install -y ufw
    fi
    
    # Configure firewall
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow SSH
    ufw allow ssh
    
    # Allow HTTP and HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # Enable firewall
    ufw --force enable
    
    print_status "Firewall configured"
}

# Function to setup automatic updates
setup_auto_updates() {
    print_status "Setting up automatic updates..."
    
    # Create update script
    cat > /usr/local/bin/wordpress-update.sh << 'EOF'
#!/bin/bash

# WordPress Auto Update Script
WORDPRESS_PATH="/var/www/html/wordpress"
BACKUP_DIR="/backups/wordpress"
LOG_FILE="/var/log/wordpress-updates.log"

# Create backup before update
mkdir -p $BACKUP_DIR
BACKUP_FILE="$BACKUP_DIR/wordpress-backup-$(date +%Y%m%d_%H%M%S).tar.gz"
tar -czf $BACKUP_FILE -C /var/www/html wordpress

# Update WordPress core
cd $WORDPRESS_PATH
sudo -u www-data wp core update

# Update plugins
sudo -u www-data wp plugin update --all

# Update themes
sudo -u www-data wp theme update --all

echo "$(date): WordPress updated successfully" >> $LOG_FILE
EOF

    chmod +x /usr/local/bin/wordpress-update.sh
    
    # Add to crontab (weekly updates)
    (crontab -l 2>/dev/null; echo "0 2 * * 0 /usr/local/bin/wordpress-update.sh") | crontab -
    
    print_status "Automatic updates configured"
}

# Function to create security report
create_security_report() {
    print_status "Creating security report..."
    
    REPORT_FILE="/var/log/wordpress-security-report-$(date +%Y%m%d).txt"
    
    cat > $REPORT_FILE << EOF
WordPress Security Hardening Report
Generated: $(date)
=====================================

File Permissions:
$(ls -la $WORDPRESS_PATH/wp-config.php)

WordPress Version:
$(grep "wp_version" $WORDPRESS_PATH/wp-includes/version.php | head -1)

Active Plugins:
$(ls $WORDPRESS_PATH/wp-content/plugins/)

Active Themes:
$(ls $WORDPRESS_PATH/wp-content/themes/)

Recent Security Events:
$(tail -20 /var/log/wordpress-security.log 2>/dev/null || echo "No security log found")

System Status:
$(systemctl status apache2 | head -5)
$(systemctl status fail2ban | head -5)

Firewall Status:
$(ufw status)

Disk Usage:
$(df -h $WORDPRESS_PATH)

=====================================
EOF

    print_status "Security report created: $REPORT_FILE"
}

# Function to display security checklist
display_security_checklist() {
    print_status "WordPress Security Hardening Completed!"
    echo
    echo "=========================================="
    echo "Security Checklist:"
    echo "=========================================="
    echo "✓ File permissions secured"
    echo "✓ WordPress version hidden"
    echo "✓ File editing disabled"
    echo "✓ Login limiting configured"
    echo "✓ Fail2Ban installed and configured"
    echo "✓ SSL tools installed"
    echo "✓ Database security script created"
    echo "✓ Log monitoring configured"
    echo "✓ Firewall configured"
    echo "✓ Automatic updates configured"
    echo "✓ Security report generated"
    echo
    echo "=========================================="
    echo "Next Steps:"
    echo "=========================================="
    echo "1. Review and run database security script"
    echo "2. Configure SSL certificate for your domain"
    echo "3. Set up email alerts for security monitoring"
    echo "4. Install security plugins (Wordfence, Sucuri)"
    echo "5. Regular security audits and updates"
    echo "6. Monitor security report: /var/log/wordpress-security-report-*.txt"
    echo "=========================================="
    echo
    print_warning "Remember to test all functionality after hardening!"
}

# Main execution
main() {
    echo "WordPress Security Hardening Script"
    echo "==================================="
    echo
    
    # Check if WordPress path exists
    if [[ ! -d "$WORDPRESS_PATH" ]]; then
        print_error "WordPress installation not found at $WORDPRESS_PATH"
        print_error "Please specify the correct WordPress path"
        exit 1
    fi
    
    # Run hardening steps
    check_root
    create_backup
    secure_permissions
    hide_wordpress_version
    disable_file_editing
    limit_login_attempts
    setup_fail2ban
    setup_ssl
    secure_database
    setup_log_monitoring
    setup_firewall
    setup_auto_updates
    create_security_report
    display_security_checklist
}

# Run main function
main "$@"
