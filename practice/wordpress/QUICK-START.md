# WordPress Quick Start Guide

This guide provides quick setup instructions for WordPress deployment using the provided scripts and configurations.

## 🚀 Quick Deployment Options

### Option 1: Traditional LAMP Stack (Recommended for Production)

```bash
# 1. Navigate to the wordpress directory
cd /path/to/practice/wordpress

# 2. Run the traditional deployment script
sudo ./deploy/traditional-deploy.sh

# 3. Follow the interactive prompts
# - Enter your domain name
# - Set admin credentials
# - Configure email settings
```

**What it does:**
- Installs Apache, MySQL, PHP
- Downloads and configures WordPress
- Sets up database and user
- Configures virtual host
- Optimizes PHP settings
- Installs WP-CLI

### Option 2: Docker Deployment (Recommended for Development)

```bash
# 1. Navigate to the wordpress directory
cd /path/to/practice/wordpress

# 2. Run the Docker deployment script
./deploy/docker-deploy.sh

# 3. Follow the interactive prompts
# - Choose domain (optional)
# - Set admin credentials
# - Enable phpMyAdmin
# - Enable Redis caching
```

**What it does:**
- Creates Docker Compose configuration
- Sets up WordPress, MySQL, Redis containers
- Configures PHP and database
- Sets up backup and restore scripts
- Provides development tools

## 🔧 Post-Deployment Configuration

### 1. Access Your WordPress Site

**Traditional Deployment:**
- URL: `http://your-domain.com` or `http://localhost`
- Admin: `http://your-domain.com/wp-admin`

**Docker Deployment:**
- URL: `http://localhost:8080`
- Admin: `http://localhost:8080/wp-admin`
- phpMyAdmin: `http://localhost:8081` (if enabled)

### 2. Security Hardening

```bash
# Run security hardening script
sudo ./security/harden-wordpress.sh
```

**What it does:**
- Secures file permissions
- Hides WordPress version
- Disables file editing
- Sets up Fail2Ban
- Configures firewall
- Enables log monitoring

### 3. Set Up Backups

```bash
# Configure automated backups
sudo crontab -e

# Add this line for daily backups at 2 AM
0 2 * * * /path/to/practice/wordpress/scripts/backup.sh
```

## 📁 Directory Structure

```
practice/wordpress/
├── README.md                    # Main documentation
├── QUICK-START.md              # This file
├── deploy/                     # Deployment scripts
│   ├── traditional-deploy.sh   # LAMP stack deployment
│   └── docker-deploy.sh        # Docker deployment
├── config/                     # Configuration files
│   ├── nginx-wordpress.conf    # Nginx configuration
│   ├── apache-wordpress.conf   # Apache configuration
│   └── php-wordpress.ini       # PHP configuration
├── docker/                     # Docker configurations
│   ├── docker-compose.dev.yml  # Development setup
│   └── docker-compose.prod.yml # Production setup
├── security/                   # Security scripts
│   └── harden-wordpress.sh     # Security hardening
├── scripts/                    # Utility scripts
│   └── backup.sh               # Backup script
└── docs/                       # Additional documentation
    └── DEPLOYMENT-GUIDE.md     # Detailed deployment guide
```

## 🛠️ Common Commands

### Traditional Deployment

```bash
# Start services
sudo systemctl start apache2 mysql

# Stop services
sudo systemctl stop apache2 mysql

# Check status
sudo systemctl status apache2 mysql

# View logs
sudo tail -f /var/log/apache2/error.log
sudo tail -f /var/log/mysql/error.log
```

### Docker Deployment

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f wordpress

# Access WordPress container
docker-compose exec wordpress bash

# Run WP-CLI commands
docker-compose exec wordpress wp --info
```

### Backup & Restore

```bash
# Manual backup
sudo ./scripts/backup.sh

# Restore from backup
sudo ./backups/restore_YYYYMMDD_HHMMSS.sh

# List available backups
ls -la /backups/wordpress/
```

## 🔍 Troubleshooting

### Common Issues

1. **Permission Denied**
   ```bash
   sudo chown -R www-data:www-data /var/www/html/wordpress
   sudo chmod -R 755 /var/www/html/wordpress
   ```

2. **Database Connection Error**
   ```bash
   sudo systemctl restart mysql
   mysql -u wp_user -p -h localhost wordpress_db
   ```

3. **White Screen of Death**
   ```bash
   # Enable debug mode in wp-config.php
   define('WP_DEBUG', true);
   define('WP_DEBUG_LOG', true);
   ```

4. **Docker Issues**
   ```bash
   docker-compose down
   docker-compose up -d --force-recreate
   ```

### Log Locations

- **Apache:** `/var/log/apache2/`
- **MySQL:** `/var/log/mysql/`
- **PHP:** `/var/log/php_errors.log`
- **WordPress:** `/wp-content/debug.log`
- **Docker:** `docker-compose logs`

## 📚 Next Steps

1. **Configure SSL Certificate**
   ```bash
   sudo certbot --apache -d your-domain.com
   ```

2. **Set Up Monitoring**
   - Install monitoring tools
   - Configure alerts
   - Set up performance monitoring

3. **Optimize Performance**
   - Enable caching
   - Optimize images
   - Configure CDN

4. **Security Enhancements**
   - Install security plugins
   - Set up 2FA
   - Configure firewall rules

## 🆘 Getting Help

- Check the main [README.md](README.md) for detailed documentation
- Review [DEPLOYMENT-GUIDE.md](docs/DEPLOYMENT-GUIDE.md) for advanced topics
- Check log files for error messages
- Use WP-CLI for WordPress-specific commands

## 📝 Notes

- Always test in a staging environment before production
- Keep regular backups
- Monitor security and performance
- Update WordPress, plugins, and themes regularly
- Document any custom configurations

---

**Happy WordPress Deploying! 🎉**
