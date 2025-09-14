# Tình huống 3: CPU Usage Cao - Server Chậm

## 🚨 Mô tả tình huống
- Server phản hồi chậm, timeout
- CPU usage liên tục > 80-90%
- Load average cao
- Ứng dụng không phản hồi hoặc phản hồi rất chậm
- Users báo cáo website/app bị lag

## 🔍 Các bước chẩn đoán

### Bước 1: Kiểm tra CPU usage tổng quan
```bash
# Xem CPU usage real-time
top                               # Hiển thị processes real-time, sắp xếp theo CPU usage, tự động refresh
htop                              # Top với giao diện đẹp hơn, có thể scroll, filter, kill processes

# Xem load average
uptime                            # Hiển thị uptime + load average (1min, 5min, 15min)
cat /proc/loadavg                 # Xem load average từ kernel (processes running + waiting)

# Xem CPU info
lscpu                             # Hiển thị thông tin CPU architecture, cores, threads, cache
cat /proc/cpuinfo | grep "model name" | head -1  # Xem model CPU từ kernel info
```

### Bước 2: Tìm processes sử dụng nhiều CPU
```bash
# Top 10 processes sử dụng nhiều CPU
ps aux --sort=-%cpu | head -10    # Liệt kê tất cả processes, sort theo CPU usage giảm dần, lấy 10 đầu

# Top 10 processes sử dụng nhiều memory
ps aux --sort=-%mem | head -10    # Liệt kê tất cả processes, sort theo memory usage giảm dần, lấy 10 đầu

# Xem processes theo user
ps aux | grep <username>          # Tìm tất cả processes của user cụ thể

# Xem processes theo command
ps aux | grep <process_name>      # Tìm processes có tên command cụ thể
```

### Bước 3: Phân tích chi tiết processes
```bash
# Xem thông tin chi tiết process
ps -p <PID> -o pid,ppid,cmd,%cpu,%mem,etime

# Xem threads của process
ps -T -p <PID>

# Xem system calls của process
strace -p <PID>

# Xem file descriptors của process
lsof -p <PID>
```

## 🛠️ Các nguyên nhân thường gặp và cách giải quyết

### 1. Infinite loop hoặc runaway process
```bash
# Tìm process có CPU cao
top -o %CPU

# Kill process có vấn đề
kill -9 <PID>

# Kill process theo tên
killall <process_name>
pkill <process_name>

# Kill process của user cụ thể
pkill -u <username> <process_name>
```

### 2. Database queries chậm
```bash
# MySQL - xem processes đang chạy
mysql -e "SHOW PROCESSLIST;"
mysql -e "SHOW FULL PROCESSLIST;"

# Kill query chậm
mysql -e "KILL <query_id>;"

# Xem slow queries
mysql -e "SHOW VARIABLES LIKE 'slow_query_log';"
mysql -e "SHOW VARIABLES LIKE 'long_query_time';"

# PostgreSQL - xem active queries
psql -c "SELECT pid, now() - pg_stat_activity.query_start AS duration, query FROM pg_stat_activity WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes';"

# Kill query PostgreSQL
psql -c "SELECT pg_terminate_backend(<pid>);"
```

### 3. Web server overload
```bash
# Nginx - xem status
nginx -t
systemctl status nginx

# Xem Nginx processes
ps aux | grep nginx

# Restart Nginx
systemctl restart nginx
systemctl reload nginx

# Apache - xem status
systemctl status apache2
apache2ctl status

# Restart Apache
systemctl restart apache2
systemctl reload apache2
```

### 4. Memory leak dẫn đến swap
```bash
# Kiểm tra memory usage
free -h
cat /proc/meminfo

# Kiểm tra swap usage
swapon -s
cat /proc/swaps

# Xem processes sử dụng swap
for file in /proc/*/status ; do awk '/VmSwap|Name/{printf $2 " " $3}END{ print ""}' $file; done | sort -k 2 -nr | head -10

# Disable swap tạm thời
swapoff -a

# Enable swap lại
swapon -a
```

### 5. I/O bottleneck
```bash
# Kiểm tra I/O wait
iostat -x 1
iotop

# Xem disk usage
df -h
lsblk

# Kiểm tra disk I/O
iostat -d 1
sar -d 1
```

## 🚀 Các lệnh khôi phục nhanh

### Emergency CPU reduction
```bash
# 1. Kill processes có CPU cao nhất
ps aux --sort=-%cpu | head -5 | awk '{print $2}' | xargs kill -9

# 2. Restart services quan trọng
systemctl restart nginx apache2 mysql postgresql

# 3. Clear cache
sync
echo 3 > /proc/sys/vm/drop_caches

# 4. Disable swap nếu đang sử dụng
swapoff -a
```

### Process management
```bash
# Thay đổi priority của process
nice -n 19 <command>              # Chạy với priority thấp nhất
renice 19 <PID>                   # Thay đổi priority của process đang chạy

# Limit CPU usage của process
cpulimit -p <PID> -l 50           # Giới hạn 50% CPU

# Kill processes theo pattern
pkill -f "python.*script.py"      # Kill Python processes
pkill -f "java.*application"      # Kill Java processes
```

### Service optimization
```bash
# Giảm số worker processes
# Nginx
nano /etc/nginx/nginx.conf
# worker_processes 1;  # Thay vì auto

# Apache
nano /etc/apache2/apache2.conf
# MaxRequestWorkers 50  # Giảm số workers

# MySQL
nano /etc/mysql/mysql.conf.d/mysqld.cnf
# max_connections = 50  # Giảm connections
```

## 📊 Monitoring và Analysis

### Real-time monitoring
```bash
# Monitor CPU usage
watch -n 1 'ps aux --sort=-%cpu | head -10'

# Monitor load average
watch -n 1 'uptime && cat /proc/loadavg'

# Monitor system resources
htop
top -o %CPU

# Monitor I/O
iotop
iostat -x 1
```

### Log analysis
```bash
# Xem system logs
journalctl -f
tail -f /var/log/syslog

# Xem application logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
tail -f /var/log/mysql/error.log

# Tìm errors liên quan đến CPU
grep -i "cpu" /var/log/syslog
grep -i "load" /var/log/syslog
grep -i "timeout" /var/log/nginx/error.log
```

### Performance profiling
```bash
# Profile system calls
strace -c -p <PID>

# Profile CPU usage
perf top -p <PID>

# Monitor network connections
netstat -tulpn
ss -tulpn

# Monitor file descriptors
lsof | wc -l
lsof -p <PID> | wc -l
```

## 🔧 Advanced Solutions

### Process isolation
```bash
# Sử dụng systemd để limit resources
nano /etc/systemd/system/myapp.service

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
# Resource limits
CPUQuota=50%
MemoryLimit=512M
TasksMax=100

[Install]
WantedBy=multi-user.target
```

### Load balancing
```bash
# Cấu hình Nginx load balancing
nano /etc/nginx/sites-available/load-balancer

upstream backend {
    server 127.0.0.1:8001;
    server 127.0.0.1:8002;
    server 127.0.0.1:8003;
}

server {
    listen 80;
    location / {
        proxy_pass http://backend;
    }
}
```

### Database optimization
```bash
# MySQL optimization
mysql -e "SET GLOBAL max_connections = 100;"
mysql -e "SET GLOBAL query_cache_size = 0;"
mysql -e "SET GLOBAL innodb_buffer_pool_size = 1G;"

# PostgreSQL optimization
psql -c "ALTER SYSTEM SET max_connections = 100;"
psql -c "ALTER SYSTEM SET shared_buffers = '256MB';"
psql -c "SELECT pg_reload_conf();"
```

## 📝 Checklist khôi phục

- [ ] Kiểm tra CPU usage tổng quan
- [ ] Tìm processes sử dụng nhiều CPU
- [ ] Phân tích nguyên nhân gây CPU cao
- [ ] Kill processes có vấn đề
- [ ] Restart services quan trọng
- [ ] Kiểm tra database queries
- [ ] Optimize service configurations
- [ ] Thiết lập monitoring
- [ ] Test ứng dụng sau khi khôi phục
- [ ] Document incident và solution

## 🎯 Best Practices

1. **Thiết lập monitoring** CPU usage và load average
2. **Set resource limits** cho applications
3. **Optimize database queries** và indexes
4. **Use load balancing** cho high traffic
5. **Implement caching** để giảm CPU load
6. **Regular performance testing** và optimization
7. **Set up alerts** khi CPU usage cao
8. **Document performance baselines** để so sánh

---

*Tình huống này cần xử lý nhanh để tránh service degradation. Luôn monitor và optimize performance định kỳ.*
