#!/bin/bash

# WordPress Database Connection Fix Script
# Script này sẽ kiểm tra và sửa lỗi kết nối database

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_status "Bắt đầu sửa lỗi kết nối database WordPress..."

# Bước 1: Dừng tất cả containers
print_step "1. Dừng tất cả containers..."
docker-compose down

# Bước 2: Xóa volumes cũ (cẩn thận với dữ liệu)
print_step "2. Xóa volumes cũ để tránh xung đột..."
read -p "Bạn có muốn xóa dữ liệu cũ không? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker volume prune -f
    print_warning "Đã xóa tất cả volumes cũ"
else
    print_status "Giữ nguyên volumes cũ"
fi

# Bước 3: Kiểm tra file cấu hình
print_step "3. Kiểm tra file cấu hình..."
if [ -f "docker-compose.yml" ]; then
    print_status "File docker-compose.yml tồn tại"
    
    # Kiểm tra password consistency
    WP_PASS=$(grep "WORDPRESS_DB_PASSWORD:" docker-compose.yml | cut -d' ' -f2)
    MYSQL_PASS=$(grep "MYSQL_PASSWORD:" docker-compose.yml | cut -d' ' -f2)
    ROOT_PASS=$(grep "MYSQL_ROOT_PASSWORD:" docker-compose.yml | cut -d' ' -f2)
    
    echo "WordPress DB Password: $WP_PASS"
    echo "MySQL Password: $MYSQL_PASS"
    echo "MySQL Root Password: $ROOT_PASS"
    
    if [ "$WP_PASS" = "$MYSQL_PASS" ] && [ "$MYSQL_PASS" = "$ROOT_PASS" ]; then
        print_status "✓ Passwords khớp nhau"
    else
        print_error "✗ Passwords không khớp nhau!"
        print_status "Sửa file docker-compose.yml..."
        
        # Sửa passwords để khớp nhau
        sed -i 's/WORDPRESS_DB_PASSWORD: .*/WORDPRESS_DB_PASSWORD: wordpress123/' docker-compose.yml
        sed -i 's/MYSQL_PASSWORD: .*/MYSQL_PASSWORD: wordpress123/' docker-compose.yml
        sed -i 's/MYSQL_ROOT_PASSWORD: .*/MYSQL_ROOT_PASSWORD: wordpress123/' docker-compose.yml
        sed -i 's/-p[^"]*"/-pwordpress123"/' docker-compose.yml
        
        print_status "Đã sửa passwords thành wordpress123"
    fi
else
    print_error "File docker-compose.yml không tồn tại!"
    exit 1
fi

# Bước 4: Kiểm tra file init.sql
print_step "4. Kiểm tra file database init..."
if [ -f "database/init.sql" ]; then
    print_status "File database/init.sql tồn tại"
else
    print_warning "Tạo file database/init.sql..."
    mkdir -p database
    cat > database/init.sql << 'EOF'
-- WordPress Database Initialization
CREATE DATABASE IF NOT EXISTS wordpress;
USE wordpress;

-- Create WordPress user if not exists
CREATE USER IF NOT EXISTS 'wordpress'@'%' IDENTIFIED BY 'wordpress123';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'%';
FLUSH PRIVILEGES;
EOF
    print_status "Đã tạo file database/init.sql"
fi

# Bước 5: Kiểm tra file uploads.ini
print_step "5. Kiểm tra file PHP config..."
if [ -f "config/uploads.ini" ]; then
    print_status "File config/uploads.ini tồn tại"
else
    print_warning "Tạo file config/uploads.ini..."
    mkdir -p config
    cat > config/uploads.ini << 'EOF'
file_uploads = On
memory_limit = 256M
upload_max_filesize = 64M
post_max_size = 64M
max_execution_time = 300
EOF
    print_status "Đã tạo file config/uploads.ini"
fi

# Bước 6: Khởi động lại services
print_step "6. Khởi động lại services..."
docker-compose up -d

# Bước 7: Chờ database sẵn sàng
print_step "7. Chờ database sẵn sàng..."
print_status "Đang chờ database khởi động (có thể mất 30-60 giây)..."

# Chờ database healthy
for i in {1..30}; do
    if docker-compose exec db mysqladmin ping -h localhost -u root -pwordpress123 >/dev/null 2>&1; then
        print_status "✓ Database đã sẵn sàng!"
        break
    else
        echo -n "."
        sleep 2
    fi
    
    if [ $i -eq 30 ]; then
        print_error "✗ Database không khởi động được sau 60 giây"
        print_status "Kiểm tra logs database:"
        docker-compose logs db
        exit 1
    fi
done

# Bước 8: Kiểm tra WordPress
print_step "8. Kiểm tra WordPress..."
sleep 10

if curl -s http://localhost:8080 >/dev/null; then
    print_status "✓ WordPress đang chạy tại http://localhost:8080"
else
    print_warning "WordPress chưa sẵn sàng, kiểm tra logs:"
    docker-compose logs wordpress | tail -20
fi

# Bước 9: Hiển thị thông tin kết nối
print_step "9. Thông tin kết nối:"
echo "=================================="
echo "WordPress URL: http://localhost:8080"
echo "Database Host: localhost:3306"
echo "Database Name: wordpress"
echo "Database User: wordpress"
echo "Database Password: wordpress123"
echo "=================================="

print_status "Hoàn thành! Kiểm tra WordPress tại http://localhost:8080"
