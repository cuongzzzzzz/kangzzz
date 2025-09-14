# Tình huống 1: Server Down - Không thể truy cập

## 🚨 Mô tả tình huống
- Server production đột nhiên không phản hồi
- Website/API trả về lỗi 502, 503 hoặc timeout
- Không thể SSH vào server
- Monitoring alerts báo server down

## 🔍 Các bước chẩn đoán

### Bước 1: Kiểm tra kết nối cơ bản
```bash
# Ping server để kiểm tra kết nối mạng
ping <server_ip>                    # Gửi ICMP packets để test kết nối mạng cơ bản
ping <domain_name>                  # Test kết nối qua domain name (kiểm tra cả DNS và network)

# Kiểm tra port SSH có mở không
telnet <server_ip> 22               # Kết nối TCP đến port 22 (SSH) để test port accessibility
nmap -p 22 <server_ip>              # Scan port 22 để xem có mở không, hiển thị trạng thái port

# Kiểm tra DNS resolution
nslookup <domain_name>              # Query DNS server để resolve domain name thành IP address
dig <domain_name>                   # Tool DNS lookup mạnh hơn, hiển thị chi tiết DNS response
```

### Bước 2: Kiểm tra từ console/physical access
```bash
# Nếu có thể truy cập console, kiểm tra:
# 1. Server có boot được không
# 2. Có lỗi gì trong quá trình khởi động
# 3. Kiểm tra log system

# Xem log khởi động
dmesg | tail -50                    # Hiển thị 50 dòng cuối của kernel ring buffer (boot messages)
journalctl -b | tail -50            # Xem systemd journal của lần boot hiện tại, 50 dòng cuối

# Kiểm tra trạng thái services
systemctl status                    # Hiển thị trạng thái tất cả systemd services
systemctl --failed                  # Chỉ hiển thị các services bị failed (không start được)
```

### Bước 3: Kiểm tra tài nguyên hệ thống
```bash
# Kiểm tra CPU usage
top                               # Hiển thị processes real-time, sắp xếp theo CPU usage
htop                              # Top với giao diện đẹp hơn, có thể scroll và filter
ps aux --sort=-%cpu | head -10    # Liệt kê processes, sort theo CPU usage giảm dần, lấy 10 đầu

# Kiểm tra memory
free -h                           # Hiển thị memory usage (RAM + swap) với đơn vị human-readable
cat /proc/meminfo                 # Xem chi tiết memory info từ kernel (tổng RAM, available, cached, etc.)

# Kiểm tra disk space
df -h                             # Hiển thị disk usage của tất cả filesystems với đơn vị human-readable
du -sh /* | sort -hr | head -10   # Tính size của tất cả thư mục trong root, sort giảm dần, lấy 10 lớn nhất

# Kiểm tra I/O
iostat -x 1                       # Hiển thị I/O statistics mỗi giây (disk read/write, wait time)
iotop                             # Hiển thị I/O usage real-time theo processes
```

## 🛠️ Các nguyên nhân thường gặp và cách giải quyết

### 1. Server bị overload (CPU/Memory cao)
```bash
# Xem processes sử dụng nhiều tài nguyên
ps aux --sort=-%cpu | head -10    # Liệt kê processes theo CPU usage giảm dần, lấy 10 đầu
ps aux --sort=-%mem | head -10    # Liệt kê processes theo memory usage giảm dần, lấy 10 đầu

# Kill processes có vấn đề
kill -9 <PID>                     # Force kill process theo Process ID (SIGKILL - không thể bị ignore)
killall <process_name>            # Kill tất cả processes có tên cụ thể

# Restart services quan trọng
systemctl restart nginx           # Khởi động lại Nginx web server
systemctl restart apache2         # Khởi động lại Apache web server
systemctl restart mysql           # Khởi động lại MySQL database server
systemctl restart postgresql      # Khởi động lại PostgreSQL database server
```

### 2. Disk đầy
```bash
# Tìm file lớn nhất
find / -type f -size +100M 2>/dev/null | head -10  # Tìm files > 100MB, redirect errors, lấy 10 đầu
find / -type f -size +1G 2>/dev/null               # Tìm files > 1GB, redirect errors

# Xóa log files cũ
find /var/log -name "*.log" -mtime +30 -delete     # Tìm và xóa log files cũ hơn 30 ngày
journalctl --vacuum-time=7d                        # Xóa systemd journal entries cũ hơn 7 ngày

# Xóa cache
apt clean                                          # Xóa package cache (downloaded .deb files)
apt autoremove                                     # Xóa packages không cần thiết (orphaned packages)
docker system prune -a                             # Xóa tất cả unused Docker data (containers, images, networks)

# Xóa file tạm
rm -rf /tmp/*
rm -rf /var/tmp/*
```

### 3. Service bị crash
```bash
# Kiểm tra status services
systemctl status nginx
systemctl status apache2
systemctl status mysql
systemctl status postgresql

# Xem logs chi tiết
journalctl -u nginx -f
journalctl -u mysql -f
tail -f /var/log/nginx/error.log
tail -f /var/log/mysql/error.log

# Restart services
systemctl restart <service_name>
systemctl reload <service_name>
```

### 4. Network issues
```bash
# Kiểm tra network interfaces
ip addr show
ip route show

# Restart network
systemctl restart networking
systemctl restart NetworkManager

# Kiểm tra firewall
ufw status
iptables -L
```

### 5. Kernel panic hoặc hardware issues
```bash
# Xem kernel logs
dmesg | grep -i error
dmesg | grep -i panic
dmesg | grep -i oom

# Kiểm tra hardware
lscpu
lspci
lsusb
smartctl -a /dev/sda
```

## 🚀 Các lệnh khôi phục nhanh

### Khởi động lại server
```bash
# Graceful restart
sudo reboot

# Force restart (nếu cần)
sudo shutdown -r now

# Emergency restart
echo 1 > /proc/sys/kernel/sysrq
echo b > /proc/sysrq-trigger
```

### Khôi phục services
```bash
# Restart tất cả services quan trọng
systemctl restart nginx apache2 mysql postgresql redis

# Enable auto-start
systemctl enable nginx apache2 mysql postgresql redis

# Kiểm tra status
systemctl is-active nginx
systemctl is-enabled nginx
```

### Load balancer failover
```bash
# Nếu có load balancer, chuyển traffic sang server khác
# Cập nhật DNS records
# Cập nhật load balancer config
```

## 📊 Monitoring và Alerting

### Thiết lập monitoring cơ bản
```bash
# Cài đặt monitoring tools
apt install htop iotop nethogs

# Script kiểm tra server health
#!/bin/bash
# health-check.sh
echo "=== Server Health Check ==="
echo "Date: $(date)"
echo "Uptime: $(uptime)"
echo "Load: $(cat /proc/loadavg)"
echo "Memory: $(free -h)"
echo "Disk: $(df -h)"
echo "Services:"
systemctl is-active nginx mysql postgresql
```

### Log monitoring
```bash
# Theo dõi logs real-time
tail -f /var/log/syslog
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
tail -f /var/log/mysql/error.log

# Tìm errors trong logs
grep -i error /var/log/syslog | tail -20
grep -i "out of memory" /var/log/syslog
grep -i "connection refused" /var/log/nginx/error.log
```

## 🔧 Preventive Measures

### Thiết lập auto-restart
```bash
# Cấu hình systemd để auto-restart
sudo nano /etc/systemd/system/myapp.service

[Unit]
Description=My Application
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/myapp
ExecStart=/usr/bin/python3 app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target

# Enable service
systemctl enable myapp.service
systemctl start myapp.service
```

### Thiết lập monitoring
```bash
# Cài đặt monitoring tools
apt install prometheus-node-exporter
apt install grafana-server

# Cấu hình alerts
# Thiết lập email/SMS alerts khi server down
```

## 📝 Checklist khôi phục

- [ ] Kiểm tra kết nối mạng
- [ ] Truy cập console/physical server
- [ ] Kiểm tra tài nguyên hệ thống (CPU, RAM, Disk)
- [ ] Kiểm tra status services
- [ ] Xem logs để tìm nguyên nhân
- [ ] Restart services cần thiết
- [ ] Kiểm tra firewall và network
- [ ] Test ứng dụng sau khi khôi phục
- [ ] Cập nhật monitoring và alerts
- [ ] Document lại incident

## 🎯 Best Practices

1. **Luôn có backup server** hoặc load balancer
2. **Thiết lập monitoring** và alerts sớm
3. **Document procedures** để xử lý nhanh
4. **Test recovery procedures** định kỳ
5. **Keep logs** để phân tích sau
6. **Have contact list** của team và vendors
7. **Prepare runbooks** cho các tình huống thường gặp

---

*Tình huống này cần xử lý nhanh để minimize downtime. Luôn ưu tiên khôi phục service trước, sau đó mới phân tích nguyên nhân chi tiết.*
