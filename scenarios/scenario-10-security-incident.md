# Tình huống 10: Security Incident - Sự Cố Bảo Mật

## 🚨 Mô tả tình huống
- Server bị tấn công hoặc compromise
- Unauthorized access được phát hiện
- Malware hoặc virus được tìm thấy
- Suspicious network traffic
- Data breach hoặc data theft
- System bị deface hoặc vandalized

## 🔍 Các bước chẩn đoán

### Bước 1: Kiểm tra system status
```bash
# Kiểm tra processes đang chạy
ps aux --sort=-%cpu | head -20
ps aux --sort=-%mem | head -20

# Kiểm tra network connections
netstat -tulpn
ss -tulpn
lsof -i

# Kiểm tra logged in users
who
w
last
lastb
```

### Bước 2: Kiểm tra system logs
```bash
# Xem system logs
sudo journalctl -f
sudo tail -f /var/log/syslog
sudo tail -f /var/log/auth.log

# Xem failed login attempts
sudo grep "Failed password" /var/log/auth.log
sudo grep "Invalid user" /var/log/auth.log
sudo grep "Connection refused" /var/log/auth.log

# Xem suspicious activities
sudo grep -i "hack\|attack\|malware\|virus" /var/log/syslog
sudo grep -i "unauthorized\|intrusion" /var/log/syslog
```

### Bước 3: Kiểm tra file integrity
```bash
# Kiểm tra file permissions
find /etc -type f -perm -002 2>/dev/null
find /var/www -type f -perm -002 2>/dev/null
find /home -type f -perm -002 2>/dev/null

# Kiểm tra suspicious files
find / -name "*.php" -mtime -1 2>/dev/null
find / -name "*.sh" -mtime -1 2>/dev/null
find / -name "*.py" -mtime -1 2>/dev/null

# Kiểm tra file sizes
find /var/www -type f -size +10M 2>/dev/null
find /tmp -type f -size +1M 2>/dev/null
```

## 🛠️ Các nguyên nhân thường gặp và cách giải quyết

### 1. Unauthorized access
```bash
# Kiểm tra active sessions
who
w
ps aux | grep ssh

# Kill suspicious sessions
sudo pkill -u <username>
sudo kill -9 <PID>

# Block suspicious IPs
sudo iptables -A INPUT -s <suspicious_ip> -j DROP
sudo ufw deny from <suspicious_ip>

# Change passwords
sudo passwd <username>
sudo passwd root
```

### 2. Malware detection
```bash
# Tìm suspicious processes
ps aux | grep -E "(wget|curl|nc|netcat|python|perl|php)"
ps aux | grep -E "(backdoor|shell|reverse)"

# Kill suspicious processes
sudo kill -9 <PID>
sudo pkill -f <process_name>

# Tìm suspicious files
find / -name "*.php" -exec grep -l "eval\|base64\|system\|exec" {} \; 2>/dev/null
find / -name "*.sh" -exec grep -l "wget\|curl\|nc" {} \; 2>/dev/null
```

### 3. Network intrusion
```bash
# Kiểm tra network connections
netstat -tulpn | grep ESTABLISHED
ss -tulpn | grep ESTABLISHED

# Kiểm tra listening ports
netstat -tulpn | grep LISTEN
ss -tulpn | grep LISTEN

# Block suspicious connections
sudo iptables -A INPUT -p tcp --dport <port> -j DROP
sudo ufw deny <port>
```

### 4. File system compromise
```bash
# Tìm modified files
find /etc -type f -mtime -1 2>/dev/null
find /var/www -type f -mtime -1 2>/dev/null
find /home -type f -mtime -1 2>/dev/null

# Tìm suspicious file permissions
find / -type f -perm -002 2>/dev/null
find / -type f -perm -4000 2>/dev/null
find / -type f -perm -2000 2>/dev/null

# Restore files từ backup
sudo cp /backup/etc/nginx/nginx.conf /etc/nginx/nginx.conf
sudo cp /backup/var/www/index.html /var/www/index.html
```

### 5. Database compromise
```bash
# Kiểm tra database users
mysql -u root -p -e "SELECT User, Host FROM mysql.user;"
psql -U postgres -c "SELECT usename, usesuper FROM pg_user;"

# Kiểm tra database logs
sudo tail -f /var/log/mysql/error.log
sudo tail -f /var/log/postgresql/postgresql-*.log

# Reset database passwords
mysql -u root -p -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'new_password';"
psql -U postgres -c "ALTER USER postgres PASSWORD 'new_password';"
```

## 🚀 Các lệnh khôi phục nhanh

### Emergency response
```bash
# 1. Isolate system
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT DROP

# 2. Kill suspicious processes
sudo pkill -f "wget\|curl\|nc\|netcat"
sudo pkill -f "python\|perl\|php"

# 3. Block suspicious IPs
sudo iptables -A INPUT -s <suspicious_ip> -j DROP
sudo ufw deny from <suspicious_ip>

# 4. Change passwords
sudo passwd root
sudo passwd <username>
```

### System lockdown
```bash
# Disable unnecessary services
sudo systemctl stop apache2
sudo systemctl stop nginx
sudo systemctl stop mysql
sudo systemctl stop postgresql

# Disable network interfaces
sudo ip link set <interface> down

# Set read-only filesystem
sudo mount -o remount,ro /
```

### Malware removal
```bash
# Tìm và xóa suspicious files
find / -name "*.php" -exec grep -l "eval\|base64\|system\|exec" {} \; 2>/dev/null | xargs rm -f
find / -name "*.sh" -exec grep -l "wget\|curl\|nc" {} \; 2>/dev/null | xargs rm -f

# Tìm và xóa suspicious processes
ps aux | grep -E "(wget|curl|nc|netcat|python|perl|php)" | awk '{print $2}' | xargs kill -9

# Clear temporary files
rm -rf /tmp/*
rm -rf /var/tmp/*
```

## 📊 Monitoring và Analysis

### Security monitoring
```bash
# Monitor system resources
htop
top
iotop

# Monitor network traffic
iftop
nethogs
netstat -i

# Monitor file system
inotifywait -m -r /var/www/
inotifywait -m -r /etc/
```

### Log analysis
```bash
# Analyze auth logs
sudo grep "Failed password" /var/log/auth.log | tail -20
sudo grep "Invalid user" /var/log/auth.log | tail -20
sudo grep "Connection refused" /var/log/auth.log | tail -20

# Analyze system logs
sudo grep -i "error\|warning\|critical" /var/log/syslog | tail -20
sudo grep -i "hack\|attack\|malware\|virus" /var/log/syslog | tail -20

# Analyze web logs
sudo tail -f /var/log/nginx/access.log | grep -E "(404|500|403)"
sudo tail -f /var/log/apache2/access.log | grep -E "(404|500|403)"
```

### Forensic analysis
```bash
# Tìm file modifications
find / -type f -mtime -1 -exec ls -la {} \; 2>/dev/null

# Tìm suspicious file permissions
find / -type f -perm -002 -exec ls -la {} \; 2>/dev/null
find / -type f -perm -4000 -exec ls -la {} \; 2>/dev/null

# Tìm suspicious network connections
netstat -tulpn | grep -E "(ESTABLISHED|LISTEN)"
ss -tulpn | grep -E "(ESTABLISHED|LISTEN)"
```

## 🔧 Advanced Solutions

### Security hardening
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install security tools
sudo apt install fail2ban rkhunter chkrootkit
sudo apt install ufw iptables-persistent

# Configure fail2ban
sudo nano /etc/fail2ban/jail.local

[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3

# Start fail2ban
sudo systemctl start fail2ban
sudo systemctl enable fail2ban
```

### Network security
```bash
# Configure firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# Configure iptables
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -A INPUT -j DROP
```

### File integrity monitoring
```bash
# Install AIDE
sudo apt install aide

# Initialize AIDE database
sudo aideinit
sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# Run AIDE check
sudo aide --check

# Update AIDE database
sudo aide --update
sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
```

## 📝 Checklist khôi phục

- [ ] Isolate compromised system
- [ ] Kill suspicious processes
- [ ] Block suspicious IPs
- [ ] Change all passwords
- [ ] Remove malware và suspicious files
- [ ] Restore files từ backup
- [ ] Update system và security patches
- [ ] Configure security tools
- [ ] Monitor system activity
- [ ] Document incident và response

## 🎯 Best Practices

1. **Thiết lập security monitoring** và alerts
2. **Implement proper access controls** và authentication
3. **Regular security updates** và patches
4. **Use strong passwords** và multi-factor authentication
5. **Implement network segmentation** và firewall rules
6. **Regular security audits** và vulnerability assessments
7. **Have incident response plan** và procedures
8. **Train team** về security awareness

---

*Tình huống này cần xử lý nhanh và cẩn thận để minimize damage. Luôn document incident và implement preventive measures.*
