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
