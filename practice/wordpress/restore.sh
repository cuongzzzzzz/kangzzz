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
