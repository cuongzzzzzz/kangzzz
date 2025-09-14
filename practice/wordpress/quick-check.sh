#!/bin/bash

# Quick Database Connection Check
# Kiểm tra nhanh tình trạng kết nối database

echo "=== KIỂM TRA NHANH WORDPRESS DATABASE ==="
echo

# Kiểm tra containers
echo "1. Trạng thái containers:"
docker-compose ps
echo

# Kiểm tra database logs
echo "2. Database logs (10 dòng cuối):"
docker-compose logs db | tail -10
echo

# Kiểm tra WordPress logs
echo "3. WordPress logs (10 dòng cuối):"
docker-compose logs wordpress | tail -10
echo

# Kiểm tra kết nối database
echo "4. Test kết nối database:"
if docker-compose exec db mysqladmin ping -h localhost -u root -pwordpress123 2>/dev/null; then
    echo "✓ Database đang hoạt động"
else
    echo "✗ Database không phản hồi"
fi
echo

# Kiểm tra WordPress config
echo "5. WordPress database config:"
if docker-compose exec wordpress cat /var/www/html/wp-config.php 2>/dev/null | grep "DB_" | head -5; then
    echo "✓ WordPress config tồn tại"
else
    echo "✗ WordPress config không tìm thấy"
fi
echo

# Kiểm tra network
echo "6. Kiểm tra network:"
docker network ls | grep wordpress
echo

echo "=== KẾT THÚC KIỂM TRA ==="
