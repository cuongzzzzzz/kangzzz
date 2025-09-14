# Tình huống 2: Disk Đầy - Không thể ghi file

## 🚨 Mô tả tình huống
- Ứng dụng báo lỗi "No space left on device"
- Không thể tạo file mới hoặc ghi log
- Database không thể ghi dữ liệu
- Website trả về lỗi 500
- System logs báo disk space low

## 🔍 Các bước chẩn đoán

### Bước 1: Kiểm tra disk usage tổng quan
```bash
# Xem disk space tổng quan
df -h                              # Hiển thị disk usage của tất cả filesystems với đơn vị human-readable (KB, MB, GB)

# Xem disk usage chi tiết hơn
df -hT                             # Hiển thị disk usage + filesystem type (ext4, xfs, tmpfs, etc.)

# Kiểm tra inode usage (có thể đầy inode dù còn space)
df -i                              # Hiển thị inode usage - có thể hết inode dù còn disk space

# Xem disk usage theo filesystem
lsblk                              # Hiển thị cây cấu trúc block devices (disks, partitions, mounts)
```

### Bước 2: Tìm thư mục sử dụng nhiều space nhất
```bash
# Xem size của các thư mục trong root
du -sh /* 2>/dev/null | sort -hr | head -10  # Tính size tất cả thư mục trong root, sort giảm dần, lấy 10 đầu

# Xem size chi tiết của thư mục cụ thể
du -sh /var/* 2>/dev/null | sort -hr         # Tính size tất cả thư mục trong /var, sort giảm dần
du -sh /home/* 2>/dev/null | sort -hr        # Tính size tất cả thư mục trong /home, sort giảm dần
du -sh /opt/* 2>/dev/null | sort -hr         # Tính size tất cả thư mục trong /opt, sort giảm dần

# Tìm thư mục lớn nhất với depth limit
du -h --max-depth=1 /var | sort -hr          # Tính size chỉ 1 level deep trong /var, sort giảm dần
du -h --max-depth=2 /var | sort -hr          # Tính size chỉ 2 levels deep trong /var, sort giảm dần
```

### Bước 3: Tìm file lớn nhất
```bash
# Tìm file lớn hơn 100MB
find / -type f -size +100M 2>/dev/null | head -20

# Tìm file lớn hơn 1GB
find / -type f -size +1G 2>/dev/null

# Tìm file lớn nhất trong thư mục cụ thể
find /var -type f -size +50M 2>/dev/null | xargs ls -lh
find /home -type f -size +100M 2>/dev/null | xargs ls -lh
```

## 🛠️ Các nguyên nhân thường gặp và cách giải quyết

### 1. Log files quá lớn
```bash
# Kiểm tra log files
ls -lh /var/log/*.log
du -sh /var/log/

# Xem log files lớn nhất
find /var/log -name "*.log" -type f -exec ls -lh {} \; | sort -k5 -hr | head -10

# Xóa log files cũ (giữ lại 7 ngày)
find /var/log -name "*.log" -mtime +7 -delete
find /var/log -name "*.log.*" -mtime +7 -delete

# Rotate logs
logrotate -f /etc/logrotate.conf

# Xóa systemd logs cũ
journalctl --vacuum-time=7d
journalctl --vacuum-size=100M
```

### 2. Database logs và data
```bash
# MySQL logs
du -sh /var/lib/mysql/
ls -lh /var/lib/mysql/*.log

# Xóa MySQL binary logs cũ
mysql -e "PURGE BINARY LOGS BEFORE DATE_SUB(NOW(), INTERVAL 7 DAY);"

# PostgreSQL logs
du -sh /var/lib/postgresql/
find /var/lib/postgresql -name "*.log" -mtime +7 -delete

# MongoDB logs
du -sh /var/lib/mongodb/
find /var/lib/mongodb -name "*.log" -mtime +7 -delete
```

### 3. Docker containers và images
```bash
# Kiểm tra Docker disk usage
docker system df

# Xóa unused containers
docker container prune -f

# Xóa unused images
docker image prune -a -f

# Xóa unused volumes
docker volume prune -f

# Xóa unused networks
docker network prune -f

# Xóa tất cả unused data
docker system prune -a -f

# Xóa build cache
docker builder prune -a -f
```

### 4. Package cache và temporary files
```bash
# APT cache
du -sh /var/cache/apt/
apt clean
apt autoremove

# YUM cache (CentOS/RHEL)
yum clean all
yum autoremove

# Temporary files
rm -rf /tmp/*
rm -rf /var/tmp/*
find /tmp -type f -mtime +7 -delete
find /var/tmp -type f -mtime +7 -delete
```

### 5. Application logs và data
```bash
# Nginx logs
du -sh /var/log/nginx/
find /var/log/nginx -name "*.log" -mtime +7 -delete

# Apache logs
du -sh /var/log/apache2/
find /var/log/apache2 -name "*.log" -mtime +7 -delete

# Application logs
find /var/www -name "*.log" -mtime +7 -delete
find /opt -name "*.log" -mtime +7 -delete
find /home -name "*.log" -mtime +7 -delete
```

## 🚀 Các lệnh khôi phục nhanh

### Emergency cleanup
```bash
# Tạo space ngay lập tức
# 1. Xóa log files cũ
find /var/log -name "*.log" -mtime +1 -delete
find /var/log -name "*.log.*" -mtime +1 -delete

# 2. Xóa temporary files
rm -rf /tmp/*
rm -rf /var/tmp/*

# 3. Clean package cache
apt clean
apt autoremove

# 4. Clean Docker
docker system prune -a -f

# 5. Xóa core dumps
find / -name "core.*" -type f -delete
```

### Tìm và xóa file lớn nhất
```bash
# Tìm 10 file lớn nhất
find / -type f -exec ls -s {} \; | sort -n -r | head -10

# Xóa file cụ thể (cẩn thận!)
rm -f /path/to/large/file

# Xóa file theo pattern
find /var/log -name "*.log" -size +100M -delete
find /tmp -name "*.tmp" -mtime +1 -delete
```

### Resize disk (nếu có thể)
```bash
# Kiểm tra disk layout
lsblk
fdisk -l

# Resize partition (cẩn thận!)
# Chỉ làm khi có backup và hiểu rõ hệ thống
resize2fs /dev/sda1
```

## 📊 Monitoring và Prevention

### Thiết lập monitoring disk space
```bash
# Script kiểm tra disk space
#!/bin/bash
# disk-monitor.sh
THRESHOLD=80
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')

if [ $DISK_USAGE -gt $THRESHOLD ]; then
    echo "WARNING: Disk usage is ${DISK_USAGE}%"
    # Send alert
    mail -s "Disk Space Alert" admin@company.com << EOF
    Disk usage on $(hostname) is ${DISK_USAGE}%
    EOF
fi
```

### Thiết lập log rotation
```bash
# Cấu hình logrotate
sudo nano /etc/logrotate.d/myapp

/var/log/myapp/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 www-data www-data
    postrotate
        systemctl reload nginx
    endscript
}
```

### Thiết lập cleanup cron jobs
```bash
# Thêm vào crontab
crontab -e

# Clean logs mỗi ngày lúc 2AM
0 2 * * * find /var/log -name "*.log" -mtime +7 -delete

# Clean temp files mỗi ngày
0 3 * * * find /tmp -type f -mtime +1 -delete

# Clean Docker mỗi tuần
0 4 * * 0 docker system prune -a -f

# Clean package cache mỗi tuần
0 5 * * 0 apt clean && apt autoremove -y
```

## 🔧 Advanced Solutions

### Mount thêm disk
```bash
# Kiểm tra disk có sẵn
lsblk
fdisk -l

# Format disk mới
mkfs.ext4 /dev/sdb1

# Mount disk
mkdir /mnt/extra
mount /dev/sdb1 /mnt/extra

# Mount permanent
echo "/dev/sdb1 /mnt/extra ext4 defaults 0 2" >> /etc/fstab
```

### Move data sang disk khác
```bash
# Move logs sang disk khác
mkdir /mnt/extra/logs
mv /var/log/* /mnt/extra/logs/
ln -s /mnt/extra/logs /var/log

# Move Docker data
systemctl stop docker
mv /var/lib/docker /mnt/extra/
ln -s /mnt/extra/docker /var/lib/docker
systemctl start docker
```

### Sử dụng LVM để extend disk
```bash
# Kiểm tra LVM
pvdisplay
vgdisplay
lvdisplay

# Extend logical volume
lvextend -L +10G /dev/vg0/lv0
resize2fs /dev/vg0/lv0
```

## 📝 Checklist khôi phục

- [ ] Kiểm tra disk usage tổng quan
- [ ] Tìm thư mục sử dụng nhiều space nhất
- [ ] Xóa log files cũ
- [ ] Clean package cache
- [ ] Clean Docker data
- [ ] Xóa temporary files
- [ ] Kiểm tra database logs
- [ ] Thiết lập log rotation
- [ ] Thiết lập monitoring
- [ ] Test ứng dụng sau khi cleanup

## 🎯 Best Practices

1. **Thiết lập log rotation** cho tất cả services
2. **Monitor disk space** thường xuyên
3. **Clean up định kỳ** với cron jobs
4. **Sử dụng separate disk** cho logs và data
5. **Compress old logs** thay vì xóa
6. **Backup trước khi cleanup** dữ liệu quan trọng
7. **Document cleanup procedures** cho team

---

*Tình huống này cần xử lý nhanh để tránh data loss. Luôn backup dữ liệu quan trọng trước khi xóa bất kỳ file nào.*
