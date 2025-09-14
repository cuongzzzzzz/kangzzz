#!/bin/bash

# WordPress Database Troubleshooting Script
# This script helps diagnose and fix database connection issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_status "Starting WordPress database troubleshooting..."

# Step 1: Check if containers are running
print_status "Checking container status..."
docker-compose ps

# Step 2: Check database container logs
print_status "Checking database container logs..."
docker-compose logs db | tail -20

# Step 3: Check WordPress container logs
print_status "Checking WordPress container logs..."
docker-compose logs wordpress | tail -20

# Step 4: Test database connectivity
print_status "Testing database connectivity..."
if docker-compose exec db mysqladmin ping -h localhost -u root -pwordpress123; then
    print_status "Database is responding to ping"
else
    print_error "Database is not responding to ping"
fi

# Step 5: Check if database exists
print_status "Checking if WordPress database exists..."
if docker-compose exec db mysql -u root -pwordpress123 -e "SHOW DATABASES LIKE 'wordpress';" | grep -q wordpress; then
    print_status "WordPress database exists"
else
    print_warning "WordPress database does not exist"
fi

# Step 6: Check WordPress configuration
print_status "Checking WordPress configuration..."
if docker-compose exec wordpress cat /var/www/html/wp-config.php | grep -q "DB_PASSWORD"; then
    print_status "WordPress configuration file exists"
    docker-compose exec wordpress cat /var/www/html/wp-config.php | grep "DB_"
else
    print_error "WordPress configuration file not found or incomplete"
fi

# Step 7: Restart services if needed
print_status "Restarting services..."
docker-compose down
docker-compose up -d

# Step 8: Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 30

# Step 9: Check final status
print_status "Final status check..."
docker-compose ps

print_status "Troubleshooting complete!"
print_status "If issues persist, check the logs above for specific error messages."
