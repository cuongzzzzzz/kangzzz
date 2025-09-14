#!/bin/bash

# WordPress Backup Script
# This script creates automated backups of WordPress files and database

set -e  # Exit on any error

# Configuration
BACKUP_DIR="/backups/wordpress"
WORDPRESS_PATH="/var/www/html/wordpress"
DB_NAME="wordpress_db"
DB_USER="wp_user"
DB_PASS=""
RETENTION_DAYS=30
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/var/log/wordpress-backup.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# Function to create backup directory
create_backup_dir() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        mkdir -p "$BACKUP_DIR"
        print_status "Created backup directory: $BACKUP_DIR"
    fi
}

# Function to backup database
backup_database() {
    print_status "Starting database backup..."
    
    local db_backup_file="$BACKUP_DIR/db_$DATE.sql.gz"
    
    if mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" | gzip > "$db_backup_file"; then
        print_status "Database backup completed: $db_backup_file"
        
        # Verify backup
        if [[ -f "$db_backup_file" && -s "$db_backup_file" ]]; then
            print_status "Database backup verified successfully"
        else
            print_error "Database backup verification failed"
            exit 1
        fi
    else
        print_error "Database backup failed"
        exit 1
    fi
}

# Function to backup WordPress files
backup_files() {
    print_status "Starting WordPress files backup..."
    
    local files_backup_file="$BACKUP_DIR/files_$DATE.tar.gz"
    
    if tar -czf "$files_backup_file" -C /var/www/html wordpress; then
        print_status "Files backup completed: $files_backup_file"
        
        # Verify backup
        if [[ -f "$files_backup_file" && -s "$files_backup_file" ]]; then
            print_status "Files backup verified successfully"
        else
            print_error "Files backup verification failed"
            exit 1
        fi
    else
        print_error "Files backup failed"
        exit 1
    fi
}

# Function to backup wp-config.php separately
backup_wp_config() {
    print_status "Backing up wp-config.php..."
    
    local config_backup_file="$BACKUP_DIR/wp-config_$DATE.php"
    
    if cp "$WORDPRESS_PATH/wp-config.php" "$config_backup_file"; then
        chmod 600 "$config_backup_file"
        print_status "wp-config.php backed up: $config_backup_file"
    else
        print_warning "Failed to backup wp-config.php"
    fi
}

# Function to create backup manifest
create_manifest() {
    print_status "Creating backup manifest..."
    
    local manifest_file="$BACKUP_DIR/manifest_$DATE.txt"
    
    cat > "$manifest_file" << EOF
WordPress Backup Manifest
========================
Date: $(date)
Backup ID: $DATE
WordPress Path: $WORDPRESS_PATH
Database: $DB_NAME

Files Included:
- WordPress core files
- wp-content directory
- wp-config.php (separate backup)

Database Tables:
$(mysql -u "$DB_USER" -p"$DB_PASS" -e "SHOW TABLES FROM $DB_NAME;" | tail -n +2)

Backup Files:
- Database: db_$DATE.sql.gz
- Files: files_$DATE.tar.gz
- Config: wp-config_$DATE.php

File Sizes:
$(ls -lh "$BACKUP_DIR"/*$DATE* | awk '{print $5, $9}')

Total Backup Size:
$(du -sh "$BACKUP_DIR"/*$DATE* | awk '{sum+=$1} END {print sum "K"}')

========================
EOF

    print_status "Manifest created: $manifest_file"
}

# Function to cleanup old backups
cleanup_old_backups() {
    print_status "Cleaning up old backups (older than $RETENTION_DAYS days)..."
    
    local deleted_count=0
    
    # Delete old database backups
    while IFS= read -r -d '' file; do
        rm -f "$file"
        ((deleted_count++))
    done < <(find "$BACKUP_DIR" -name "db_*.sql.gz" -mtime +$RETENTION_DAYS -print0)
    
    # Delete old files backups
    while IFS= read -r -d '' file; do
        rm -f "$file"
        ((deleted_count++))
    done < <(find "$BACKUP_DIR" -name "files_*.tar.gz" -mtime +$RETENTION_DAYS -print0)
    
    # Delete old config backups
    while IFS= read -r -d '' file; do
        rm -f "$file"
        ((deleted_count++))
    done < <(find "$BACKUP_DIR" -name "wp-config_*.php" -mtime +$RETENTION_DAYS -print0)
    
    # Delete old manifests
    while IFS= read -r -d '' file; do
        rm -f "$file"
        ((deleted_count++))
    done < <(find "$BACKUP_DIR" -name "manifest_*.txt" -mtime +$RETENTION_DAYS -print0)
    
    print_status "Cleaned up $deleted_count old backup files"
}

# Function to send notification (if configured)
send_notification() {
    local status="$1"
    local message="$2"
    
    # Check if mail is configured
    if command -v mail &> /dev/null; then
        echo "$message" | mail -s "WordPress Backup $status" admin@yourdomain.com
    fi
    
    # Log to system log
    logger "WordPress Backup $status: $message"
}

# Function to verify backup integrity
verify_backup() {
    print_status "Verifying backup integrity..."
    
    local db_backup="$BACKUP_DIR/db_$DATE.sql.gz"
    local files_backup="$BACKUP_DIR/files_$DATE.tar.gz"
    
    # Verify database backup
    if [[ -f "$db_backup" ]]; then
        if gunzip -t "$db_backup" 2>/dev/null; then
            print_status "Database backup integrity verified"
        else
            print_error "Database backup integrity check failed"
            return 1
        fi
    fi
    
    # Verify files backup
    if [[ -f "$files_backup" ]]; then
        if tar -tzf "$files_backup" >/dev/null 2>&1; then
            print_status "Files backup integrity verified"
        else
            print_error "Files backup integrity check failed"
            return 1
        fi
    fi
    
    return 0
}

# Function to display backup summary
display_summary() {
    print_status "Backup completed successfully!"
    echo
    echo "=========================================="
    echo "Backup Summary"
    echo "=========================================="
    echo "Backup ID: $DATE"
    echo "Date: $(date)"
    echo "Backup Directory: $BACKUP_DIR"
    echo
    echo "Files Created:"
    ls -lh "$BACKUP_DIR"/*$DATE* | awk '{print "  " $5, $9}'
    echo
    echo "Total Size:"
    du -sh "$BACKUP_DIR"/*$DATE* | awk '{sum+=$1} END {print "  " sum "K"}'
    echo "=========================================="
}

# Function to create restore script
create_restore_script() {
    local restore_script="$BACKUP_DIR/restore_$DATE.sh"
    
    cat > "$restore_script" << EOF
#!/bin/bash

# WordPress Restore Script for Backup $DATE
# Generated: $(date)

set -e

BACKUP_DIR="$BACKUP_DIR"
DATE="$DATE"
WORDPRESS_PATH="$WORDPRESS_PATH"
DB_NAME="$DB_NAME"
DB_USER="$DB_USER"
DB_PASS="$DB_PASS"

echo "WordPress Restore Script for Backup $DATE"
echo "=========================================="

# Check if backup files exist
if [[ ! -f "\$BACKUP_DIR/db_\$DATE.sql.gz" ]]; then
    echo "Error: Database backup not found"
    exit 1
fi

if [[ ! -f "\$BACKUP_DIR/files_\$DATE.tar.gz" ]]; then
    echo "Error: Files backup not found"
    exit 1
fi

# Stop web server
systemctl stop apache2

# Restore database
echo "Restoring database..."
gunzip -c "\$BACKUP_DIR/db_\$DATE.sql.gz" | mysql -u "\$DB_USER" -p"\$DB_PASS" "\$DB_NAME"

# Restore files
echo "Restoring files..."
tar -xzf "\$BACKUP_DIR/files_\$DATE.tar.gz" -C /var/www/html

# Set permissions
chown -R www-data:www-data "\$WORDPRESS_PATH"
chmod -R 755 "\$WORDPRESS_PATH"
chmod 600 "\$WORDPRESS_PATH/wp-config.php"

# Start web server
systemctl start apache2

echo "Restore completed successfully!"
EOF

    chmod +x "$restore_script"
    print_status "Restore script created: $restore_script"
}

# Main execution
main() {
    echo "WordPress Backup Script"
    echo "======================"
    echo
    
    # Check if running as root
    check_root
    
    # Create backup directory
    create_backup_dir
    
    # Start backup process
    print_status "Starting WordPress backup process..."
    
    # Backup database
    backup_database
    
    # Backup WordPress files
    backup_files
    
    # Backup wp-config.php separately
    backup_wp_config
    
    # Create backup manifest
    create_manifest
    
    # Verify backup integrity
    if verify_backup; then
        print_status "Backup integrity verified"
    else
        print_error "Backup integrity verification failed"
        exit 1
    fi
    
    # Cleanup old backups
    cleanup_old_backups
    
    # Create restore script
    create_restore_script
    
    # Display summary
    display_summary
    
    # Send notification
    send_notification "SUCCESS" "WordPress backup completed successfully. Backup ID: $DATE"
}

# Run main function
main "$@"
