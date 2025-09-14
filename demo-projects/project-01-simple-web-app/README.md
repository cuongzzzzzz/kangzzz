# Project 1: Simple Web App - LAMP Stack

## 📋 Tổng quan dự án
- **Level**: Doanh nghiệp nhỏ
- **Stack**: LAMP (Linux + Apache + MySQL + PHP)
- **Kiến trúc**: Monolithic
- **Mục đích**: Website đơn giản với CRUD operations
- **Thời gian deploy**: 30-45 phút

## 🏗️ Kiến trúc hệ thống
```
Internet → Load Balancer (Nginx) → Web Server (Apache) → Database (MySQL)
                                    ↓
                              File Storage (Local)
```

## 📁 Cấu trúc dự án
```
project-01-simple-web-app/
├── README.md
├── docker-compose.yml
├── Dockerfile
├── nginx/
│   └── default.conf
├── src/
│   ├── index.php
│   ├── config/
│   │   └── database.php
│   ├── includes/
│   │   ├── header.php
│   │   └── footer.php
│   ├── pages/
│   │   ├── products.php
│   │   ├── add-product.php
│   │   └── edit-product.php
│   └── assets/
│       ├── css/
│       │   └── style.css
│       └── js/
│           └── main.js
├── database/
│   └── init.sql
└── deploy/
    ├── deploy.sh
    └── requirements.txt
```

## 🚀 Hướng dẫn Deploy

### Bước 1: Chuẩn bị Server
```bash
# Cập nhật hệ thống
sudo apt update && sudo apt upgrade -y

# Cài đặt Docker và Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Logout và login lại để apply Docker group
```

### Bước 2: Clone và Setup Project
```bash
# Clone project
git clone <repository_url>
cd project-01-simple-web-app

# Tạo thư mục logs
mkdir -p logs/nginx logs/apache logs/mysql

# Set permissions
chmod +x deploy/deploy.sh
```

### Bước 3: Cấu hình Environment
```bash
# Tạo file .env
cat > .env << EOF
# Database Configuration
MYSQL_ROOT_PASSWORD=rootpassword123
MYSQL_DATABASE=simple_webapp
MYSQL_USER=webapp_user
MYSQL_PASSWORD=webapp_password123

# Application Configuration
APP_NAME=Simple Web App
APP_URL=http://your-domain.com
APP_DEBUG=true

# Server Configuration
NGINX_PORT=80
APACHE_PORT=8080
MYSQL_PORT=3306
EOF
```

### Bước 4: Deploy với Docker Compose
```bash
# Build và start services
docker-compose up -d --build

# Kiểm tra status
docker-compose ps

# Xem logs
docker-compose logs -f
```

### Bước 5: Cấu hình Domain và SSL
```bash
# Cài đặt Certbot
sudo apt install certbot python3-certbot-nginx

# Cấu hình domain
sudo nano /etc/hosts
# Thêm: your-server-ip your-domain.com

# Tạo SSL certificate
sudo certbot --nginx -d your-domain.com

# Test SSL
curl -I https://your-domain.com
```

## 🔧 Cấu hình chi tiết

### Nginx Configuration
```nginx
# nginx/default.conf
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://apache:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /static/ {
        alias /var/www/html/assets/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### Apache Configuration
```apache
# Apache virtual host
<VirtualHost *:8080>
    DocumentRoot /var/www/html
    ServerName your-domain.com
    
    <Directory /var/www/html>
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```

### Database Schema
```sql
-- database/init.sql
CREATE DATABASE IF NOT EXISTS simple_webapp;
USE simple_webapp;

CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    category VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

INSERT INTO products (name, description, price, category) VALUES
('Laptop Dell XPS 13', 'High-performance laptop for professionals', 1299.99, 'Electronics'),
('iPhone 14 Pro', 'Latest iPhone with advanced camera system', 999.99, 'Electronics'),
('Nike Air Max 270', 'Comfortable running shoes', 150.00, 'Sports'),
('Coffee Maker', 'Automatic coffee maker with timer', 89.99, 'Home');
```

## 📊 Monitoring và Maintenance

### Health Checks
```bash
# Kiểm tra services
docker-compose ps
docker-compose logs nginx
docker-compose logs apache
docker-compose logs mysql

# Test database connection
docker-compose exec mysql mysql -u root -p -e "SHOW DATABASES;"

# Test web application
curl -I http://your-domain.com
curl -I https://your-domain.com
```

### Backup Script
```bash
#!/bin/bash
# deploy/backup.sh
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backup/simple-webapp"

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup database
docker-compose exec mysql mysqldump -u root -p$MYSQL_ROOT_PASSWORD simple_webapp > $BACKUP_DIR/database_$DATE.sql

# Backup application files
docker-compose exec apache tar -czf /tmp/app_$DATE.tar.gz /var/www/html
docker cp $(docker-compose ps -q apache):/tmp/app_$DATE.tar.gz $BACKUP_DIR/

# Cleanup old backups (keep 7 days)
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
```

## 🚨 Troubleshooting

### Common Issues
1. **Port conflicts**: Kiểm tra ports 80, 8080, 3306 có bị sử dụng không
2. **Permission issues**: Đảm bảo Docker user có quyền truy cập
3. **Database connection**: Kiểm tra MySQL container và credentials
4. **SSL issues**: Kiểm tra domain configuration và certificate

### Debug Commands
```bash
# Xem logs chi tiết
docker-compose logs -f --tail=100

# Vào container để debug
docker-compose exec apache bash
docker-compose exec mysql bash

# Kiểm tra network
docker network ls
docker network inspect project-01-simple-web-app_default
```

## 📈 Scaling và Optimization

### Performance Tuning
```bash
# Tối ưu MySQL
docker-compose exec mysql mysql -u root -p -e "
SET GLOBAL innodb_buffer_pool_size = 256M;
SET GLOBAL max_connections = 100;
SET GLOBAL query_cache_size = 32M;
"

# Tối ưu Apache
# Thêm vào Apache config:
# ServerLimit 16
# MaxRequestWorkers 400
# ThreadsPerChild 25
```

### Load Balancing
```bash
# Scale Apache containers
docker-compose up -d --scale apache=3

# Cấu hình Nginx load balancing
upstream apache_backend {
    server apache_1:8080;
    server apache_2:8080;
    server apache_3:8080;
}
```

## 🎯 Next Steps

1. **CI/CD Pipeline**: Thiết lập GitHub Actions hoặc GitLab CI
2. **Monitoring**: Thêm Prometheus + Grafana
3. **Logging**: Centralized logging với ELK stack
4. **Security**: Implement WAF và security headers
5. **Caching**: Thêm Redis cho caching

---

*Dự án này phù hợp cho doanh nghiệp nhỏ cần website đơn giản với chi phí thấp và dễ maintain.*
