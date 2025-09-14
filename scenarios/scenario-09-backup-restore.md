# Tình huống 9: Backup & Restore - Khôi Phục Dữ Liệu

## 🚨 Mô tả tình huống
- Dữ liệu bị mất hoặc corrupt
- Cần khôi phục từ backup
- Backup không hoạt động hoặc không tồn tại
- Cần restore toàn bộ hệ thống
- Database cần khôi phục từ point-in-time
- Files và configurations bị mất

## 🔍 Các bước chẩn đoán

### Bước 1: Kiểm tra backup status
```bash
# Kiểm tra backup files
ls -la /backup/
ls -la /var/backups/
ls -la /opt/backups/

# Kiểm tra backup logs
tail -f /var/log/backup.log
journalctl -u backup
journalctl -u rsync

# Kiểm tra backup scripts
ls -la /usr/local/bin/backup*
ls -la /etc/cron.d/backup*
```

### Bước 2: Kiểm tra dữ liệu hiện tại
```bash
# Kiểm tra disk space
df -h
du -sh /var/www/
du -sh /var/lib/mysql/
du -sh /var/lib/postgresql/

# Kiểm tra database status
sudo systemctl status mysql
sudo systemctl status postgresql
mysql -u root -p -e "SHOW DATABASES;"
psql -U postgres -c "\l"
```

### Bước 3: Kiểm tra backup integrity
```bash
# Kiểm tra backup files
file /backup/database_backup.sql
file /backup/files_backup.tar.gz

# Kiểm tra backup size
ls -lh /backup/
du -sh /backup/*

# Test backup files
tar -tzf /backup/files_backup.tar.gz | head -10
mysql -u root -p -e "SHOW DATABASES;" < /backup/database_backup.sql
```

## 🛠️ Các nguyên nhân thường gặp và cách giải quyết

### 1. Backup không tồn tại
```bash
# Tìm backup files
find / -name "*backup*" -type f 2>/dev/null
find / -name "*.sql" -type f 2>/dev/null
find / -name "*.tar.gz" -type f 2>/dev/null

# Kiểm tra backup locations
ls -la /var/backups/
ls -la /opt/backups/
ls -la /home/*/backup/
ls -la /root/backup/
```

### 2. Backup bị corrupt
```bash
# Kiểm tra backup integrity
tar -tzf /backup/files_backup.tar.gz > /dev/null
echo $?  # 0 = OK, 1 = Error

# Test database backup
mysql -u root -p -e "SHOW DATABASES;" < /backup/database_backup.sql
echo $?  # 0 = OK, 1 = Error

# Repair backup nếu có thể
tar -tzf /backup/files_backup.tar.gz | grep -v "tar:"
```

### 3. Backup không đầy đủ
```bash
# Kiểm tra backup content
tar -tzf /backup/files_backup.tar.gz | wc -l
tar -tzf /backup/files_backup.tar.gz | grep -E "(var/www|etc|home)"

# Kiểm tra database backup
grep -c "CREATE TABLE" /backup/database_backup.sql
grep -c "INSERT INTO" /backup/database_backup.sql
```

### 4. Restore process bị lỗi
```bash
# Kiểm tra permissions
ls -la /backup/
ls -la /var/www/
ls -la /var/lib/mysql/

# Kiểm tra disk space
df -h
du -sh /backup/
du -sh /var/www/
```

## 🚀 Các lệnh khôi phục nhanh

### Emergency restore
```bash
# 1. Stop services
sudo systemctl stop nginx
sudo systemctl stop apache2
sudo systemctl stop mysql
sudo systemctl stop postgresql

# 2. Backup current state
sudo cp -r /var/www /var/www.backup.$(date +%Y%m%d_%H%M%S)
sudo cp -r /var/lib/mysql /var/lib/mysql.backup.$(date +%Y%m%d_%H%M%S)

# 3. Restore files
sudo tar -xzf /backup/files_backup.tar.gz -C /
sudo chown -R www-data:www-data /var/www/
sudo chmod -R 755 /var/www/

# 4. Restore database
mysql -u root -p < /backup/database_backup.sql
psql -U postgres < /backup/postgresql_backup.sql

# 5. Start services
sudo systemctl start mysql
sudo systemctl start postgresql
sudo systemctl start nginx
sudo systemctl start apache2
```

### Database restore
```bash
# MySQL restore
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS <database_name>;"
mysql -u root -p <database_name> < /backup/database_backup.sql

# MySQL restore với specific database
mysql -u root -p -e "DROP DATABASE IF EXISTS <database_name>;"
mysql -u root -p -e "CREATE DATABASE <database_name>;"
mysql -u root -p <database_name> < /backup/database_backup.sql

# PostgreSQL restore
psql -U postgres -c "CREATE DATABASE <database_name>;"
psql -U postgres <database_name> < /backup/postgresql_backup.sql

# MongoDB restore
mongorestore --db <database_name> /backup/mongodb_backup/
mongorestore --db <database_name> --drop /backup/mongodb_backup/
```

### File restore
```bash
# Restore specific files
tar -xzf /backup/files_backup.tar.gz -C /tmp/
cp -r /tmp/var/www/* /var/www/
cp -r /tmp/etc/nginx/* /etc/nginx/
cp -r /tmp/etc/apache2/* /etc/apache2/

# Restore với permissions
tar -xzf /backup/files_backup.tar.gz -C /
sudo chown -R www-data:www-data /var/www/
sudo chmod -R 755 /var/www/
sudo chown -R root:root /etc/nginx/
sudo chmod -R 644 /etc/nginx/
```

## 📊 Monitoring và Analysis

### Backup monitoring
```bash
# Kiểm tra backup status
ls -la /backup/
du -sh /backup/*
find /backup -name "*.sql" -mtime -1
find /backup -name "*.tar.gz" -mtime -1

# Kiểm tra backup logs
tail -f /var/log/backup.log
journalctl -u backup -f
```

### Backup validation
```bash
# Validate backup files
tar -tzf /backup/files_backup.tar.gz > /dev/null
echo $?  # 0 = OK, 1 = Error

# Validate database backup
mysql -u root -p -e "SHOW DATABASES;" < /backup/database_backup.sql
echo $?  # 0 = OK, 1 = Error

# Check backup integrity
md5sum /backup/files_backup.tar.gz
md5sum /backup/database_backup.sql
```

### Restore testing
```bash
# Test restore trong test environment
# 1. Tạo test database
mysql -u root -p -e "CREATE DATABASE test_restore;"
mysql -u root -p test_restore < /backup/database_backup.sql

# 2. Test restore files
mkdir /tmp/test_restore
tar -xzf /backup/files_backup.tar.gz -C /tmp/test_restore/

# 3. Verify restore
mysql -u root -p test_restore -e "SHOW TABLES;"
ls -la /tmp/test_restore/var/www/
```

## 🔧 Advanced Solutions

### Automated backup setup
```bash
# Tạo backup script
sudo nano /usr/local/bin/backup.sh

#!/bin/bash
BACKUP_DIR="/backup"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/var/log/backup.log"

# Database backup
mysqldump -u root -p<password> --all-databases > $BACKUP_DIR/mysql_backup_$DATE.sql
pg_dumpall -U postgres > $BACKUP_DIR/postgresql_backup_$DATE.sql

# Files backup
tar -czf $BACKUP_DIR/files_backup_$DATE.tar.gz /var/www/ /etc/nginx/ /etc/apache2/

# Cleanup old backups
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "$(date): Backup completed" >> $LOG_FILE

# Make executable
sudo chmod +x /usr/local/bin/backup.sh

# Setup cron job
sudo crontab -e
# 0 2 * * * /usr/local/bin/backup.sh
```

### Incremental backup
```bash
# Rsync incremental backup
rsync -av --delete /var/www/ /backup/www/
rsync -av --delete /etc/nginx/ /backup/nginx/
rsync -av --delete /etc/apache2/ /backup/apache2/

# Tar incremental backup
tar -czf /backup/incremental_$(date +%Y%m%d_%H%M%S).tar.gz --newer-mtime="1 day ago" /var/www/
```

### Backup encryption
```bash
# Encrypt backup files
gpg --symmetric --cipher-algo AES256 /backup/database_backup.sql
gpg --symmetric --cipher-algo AES256 /backup/files_backup.tar.gz

# Decrypt backup files
gpg --decrypt /backup/database_backup.sql.gpg > /backup/database_backup.sql
gpg --decrypt /backup/files_backup.tar.gz.gpg > /backup/files_backup.tar.gz
```

## 📝 Checklist khôi phục

- [ ] Kiểm tra backup status và availability
- [ ] Kiểm tra backup integrity
- [ ] Stop services cần thiết
- [ ] Backup current state
- [ ] Restore files và databases
- [ ] Set proper permissions
- [ ] Start services
- [ ] Test functionality
- [ ] Monitor system performance
- [ ] Document incident và solution

## 🎯 Best Practices

1. **Thiết lập automated backups** với proper scheduling
2. **Test restore procedures** định kỳ
3. **Implement backup encryption** cho sensitive data
4. **Store backups offsite** hoặc cloud storage
5. **Monitor backup status** và alerts
6. **Document backup procedures** và recovery steps
7. **Implement incremental backups** để save space
8. **Regular backup validation** và integrity checks

---

*Tình huống này cần xử lý cẩn thận để tránh data loss. Luôn test restore procedures và maintain multiple backup copies.*
