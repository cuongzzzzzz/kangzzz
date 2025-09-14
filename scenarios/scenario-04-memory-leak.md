# Tình huống 4: Memory Leak - RAM Bị Cạn Kiệt

## 🚨 Mô tả tình huống
- RAM usage tăng liên tục theo thời gian
- Server bị swap, chậm dần
- Ứng dụng crash với "Out of Memory" error
- System không phản hồi, cần restart
- Monitoring báo memory usage > 90%

## 🔍 Các bước chẩn đoán

### Bước 1: Kiểm tra memory usage tổng quan
```bash
# Xem memory usage
free -h                           # Hiển thị memory usage (RAM + swap) với đơn vị human-readable
cat /proc/meminfo                 # Xem chi tiết memory info từ kernel (total, available, cached, buffers, etc.)

# Xem memory usage real-time
htop                              # Top với giao diện đẹp, hiển thị memory usage real-time
top                               # Hiển thị processes + memory usage, tự động refresh

# Xem swap usage
swapon -s                         # Hiển thị swap devices đang active và usage
cat /proc/swaps                   # Xem swap info từ kernel (device, type, size, used, priority)
```

### Bước 2: Tìm processes sử dụng nhiều memory
```bash
# Top 10 processes sử dụng nhiều RAM
ps aux --sort=-%mem | head -10    # Liệt kê tất cả processes, sort theo memory usage giảm dần, lấy 10 đầu

# Xem memory usage theo user
ps aux --sort=-%mem | grep <username>  # Tìm processes của user cụ thể, sort theo memory usage

# Xem memory usage của processes cụ thể
ps -o pid,ppid,cmd,%mem,%cpu,etime -p <PID>  # Hiển thị thông tin chi tiết của process theo PID
```

### Bước 3: Phân tích memory usage chi tiết
```bash
# Xem memory map của process
cat /proc/<PID>/smaps

# Xem memory status của process
cat /proc/<PID>/status | grep -i mem

# Xem memory usage theo thời gian
watch -n 1 'ps aux --sort=-%mem | head -5'

# Xem memory leaks với valgrind
valgrind --tool=memcheck --leak-check=full <program>
```

## 🛠️ Các nguyên nhân thường gặp và cách giải quyết

### 1. Application memory leak
```bash
# Tìm processes có memory tăng liên tục
ps aux --sort=-%mem | head -20

# Kill process có vấn đề
kill -9 <PID>

# Restart application
systemctl restart <service_name>

# Kiểm tra application logs
tail -f /var/log/<app>/error.log
journalctl -u <service_name> -f
```

### 2. Database memory issues
```bash
# MySQL memory usage
mysql -e "SHOW VARIABLES LIKE '%buffer%';"
mysql -e "SHOW VARIABLES LIKE '%cache%';"
mysql -e "SHOW PROCESSLIST;"

# Kiểm tra MySQL memory usage
ps aux | grep mysql
cat /proc/$(pgrep mysqld)/status | grep -i mem

# Restart MySQL
systemctl restart mysql

# PostgreSQL memory usage
psql -c "SELECT * FROM pg_stat_activity;"
psql -c "SELECT * FROM pg_stat_database;"

# Restart PostgreSQL
systemctl restart postgresql
```

### 3. Web server memory issues
```bash
# Nginx memory usage
ps aux | grep nginx
systemctl status nginx

# Restart Nginx
systemctl restart nginx

# Apache memory usage
ps aux | grep apache
systemctl status apache2

# Restart Apache
systemctl restart apache2

# Kiểm tra PHP-FPM (nếu có)
ps aux | grep php-fpm
systemctl restart php7.4-fpm
```

### 4. System memory issues
```bash
# Kiểm tra kernel memory
cat /proc/meminfo | grep -i kernel

# Kiểm tra shared memory
ipcs -m
ipcs -s

# Clear shared memory
ipcrm -a

# Kiểm tra buffer cache
free -h
sync
echo 3 > /proc/sys/vm/drop_caches
```

### 5. Docker containers memory leak
```bash
# Xem memory usage của containers
docker stats

# Xem memory usage chi tiết
docker stats --no-stream --format "table {{.Container}}\t{{.MemUsage}}\t{{.MemPerc}}"

# Restart container có vấn đề
docker restart <container_name>

# Kill container sử dụng nhiều memory
docker kill <container_name>

# Clean up unused containers
docker container prune -f
```

## 🚀 Các lệnh khôi phục nhanh

### Emergency memory cleanup
```bash
# 1. Clear page cache
sync
echo 1 > /proc/sys/vm/drop_caches

# 2. Clear dentries and inodes
echo 2 > /proc/sys/vm/drop_caches

# 3. Clear page cache, dentries and inodes
echo 3 > /proc/sys/vm/drop_caches

# 4. Kill processes sử dụng nhiều memory
ps aux --sort=-%mem | head -5 | awk '{print $2}' | xargs kill -9

# 5. Restart services quan trọng
systemctl restart nginx mysql postgresql
```

### Memory optimization
```bash
# Tăng swap nếu cần
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Disable swap nếu đang gây chậm
swapoff -a

# Enable swap lại
swapon -a
```

### Process memory limits
```bash
# Set memory limit cho process
ulimit -v 1048576  # 1GB virtual memory

# Set memory limit trong systemd
nano /etc/systemd/system/myapp.service
# MemoryLimit=512M

# Set memory limit cho Docker container
docker run --memory=512m <image>
```

## 📊 Monitoring và Analysis

### Memory monitoring
```bash
# Monitor memory usage real-time
watch -n 1 'free -h && echo "---" && ps aux --sort=-%mem | head -5'

# Monitor memory usage theo thời gian
sar -r 1 60  # Monitor 60 giây

# Monitor memory usage của process cụ thể
while true; do ps -p <PID> -o pid,ppid,cmd,%mem,%cpu,etime; sleep 1; done
```

### Memory leak detection
```bash
# Sử dụng valgrind để detect memory leaks
valgrind --tool=memcheck --leak-check=full --show-leak-kinds=all <program>

# Sử dụng AddressSanitizer (nếu compile được)
gcc -fsanitize=address -g <program.c>
./a.out

# Monitor memory usage của process theo thời gian
while true; do
    echo "$(date): $(ps -p <PID> -o %mem --no-headers)%"
    sleep 10
done
```

### Log analysis
```bash
# Tìm memory-related errors
grep -i "out of memory" /var/log/syslog
grep -i "memory" /var/log/syslog | tail -20
grep -i "oom" /var/log/syslog

# Tìm application memory errors
grep -i "memory" /var/log/nginx/error.log
grep -i "memory" /var/log/mysql/error.log
grep -i "memory" /var/log/<app>/error.log
```

## 🔧 Advanced Solutions

### Application profiling
```bash
# Python memory profiling
pip install memory-profiler
python -m memory_profiler <script.py>

# Node.js memory profiling
node --inspect <script.js>
# Mở Chrome DevTools để xem memory usage

# Java memory profiling
jmap -histo <PID>
jstat -gc <PID> 1s
```

### Memory optimization
```bash
# Tối ưu MySQL memory
nano /etc/mysql/mysql.conf.d/mysqld.cnf
# innodb_buffer_pool_size = 256M
# query_cache_size = 0
# tmp_table_size = 64M
# max_heap_table_size = 64M

# Tối ưu PostgreSQL memory
nano /etc/postgresql/*/main/postgresql.conf
# shared_buffers = 128MB
# effective_cache_size = 512MB
# work_mem = 4MB
```

### Container memory limits
```bash
# Docker Compose với memory limits
version: '3.8'
services:
  app:
    image: myapp
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M

# Docker run với memory limits
docker run --memory=512m --memory-swap=1g <image>
```

## 📝 Checklist khôi phục

- [ ] Kiểm tra memory usage tổng quan
- [ ] Tìm processes sử dụng nhiều memory
- [ ] Phân tích nguyên nhân memory leak
- [ ] Clear system caches
- [ ] Kill/restart processes có vấn đề
- [ ] Kiểm tra database memory usage
- [ ] Optimize memory settings
- [ ] Thiết lập memory monitoring
- [ ] Test ứng dụng sau khi khôi phục
- [ ] Document incident và solution

## 🎯 Best Practices

1. **Thiết lập memory monitoring** và alerts
2. **Set memory limits** cho applications và containers
3. **Regular memory profiling** của applications
4. **Optimize database memory settings**
5. **Use memory-efficient algorithms** trong code
6. **Implement proper garbage collection** strategies
7. **Monitor memory usage trends** theo thời gian
8. **Set up automatic restarts** khi memory usage cao

---

*Tình huống này cần xử lý nhanh để tránh system crash. Luôn monitor memory usage và optimize applications định kỳ.*
