# Server Management & SSH Setup Cheatsheet

## 📋 Mục lục
- [Lấy thông tin IP và mạng](#lấy-thông-tin-ip-và-mạng)
- [Cài đặt và cấu hình SSH Server](#cài-đặt-và-cấu-hình-ssh-server)
- [SSH với Password Authentication](#ssh-với-password-authentication)
- [SSH với Key-based Authentication](#ssh-với-key-based-authentication)
- [Cấu hình SSH Client](#cấu-hình-ssh-client)
- [Bảo mật SSH](#bảo-mật-ssh)
- [Troubleshooting SSH](#troubleshooting-ssh)
- [Advanced SSH Features](#advanced-ssh-features)

---

## Lấy thông tin IP và mạng

### Lấy IP Address
```bash
# Các cách lấy IP address
ip addr show                    # Hiển thị tất cả network interfaces
ip addr show eth0              # Hiển thị interface cụ thể
hostname -I                    # Lấy IP address chính
ifconfig | grep inet           # Lấy IP (deprecated nhưng vẫn dùng)
ip route get 8.8.8.8          # Lấy IP được dùng để kết nối ra ngoài

# Lấy IP public (từ internet)
curl -s https://ipinfo.io/ip           # Lấy IP public
curl -s https://ifconfig.me            # Lấy IP public (alternative)
curl -s https://api.ipify.org          # Lấy IP public (alternative)
wget -qO- https://ipinfo.io/ip         # Lấy IP public với wget

# Lấy thông tin mạng chi tiết
ip addr show | grep inet               # Chỉ hiển thị IP addresses
ip route show                          # Hiển thị routing table
ss -tulpn | grep :22                   # Kiểm tra SSH port
netstat -tulpn | grep :22              # Kiểm tra SSH port (alternative)
```

### Cấu hình mạng
```bash
# Cấu hình IP tĩnh (Ubuntu/Debian)
sudo nano /etc/netplan/01-netcfg.yaml

# Ví dụ cấu hình:
# network:
#   version: 2
#   ethernets:
#     eth0:
#       dhcp4: false
#       addresses:
#         - 192.168.1.100/24
#       gateway4: 192.168.1.1
#       nameservers:
#         addresses: [8.8.8.8, 8.8.4.4]

sudo netplan apply                  # Áp dụng cấu hình

# Cấu hình IP tĩnh (CentOS/RHEL)
sudo nano /etc/sysconfig/network-scripts/ifcfg-eth0

# Ví dụ cấu hình:
# BOOTPROTO=static
# IPADDR=192.168.1.100
# NETMASK=255.255.255.0
# GATEWAY=192.168.1.1
# DNS1=8.8.8.8
# DNS2=8.8.4.4

sudo systemctl restart network       # Restart network service
```

---

## Cài đặt và cấu hình SSH Server

### Cài đặt SSH Server
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install openssh-server -y

# CentOS/RHEL
sudo yum install openssh-server -y
# hoặc
sudo dnf install openssh-server -y

# Kiểm tra trạng thái
sudo systemctl status ssh
sudo systemctl status sshd          # CentOS/RHEL
```

### Khởi động và enable SSH
```bash
# Ubuntu/Debian
sudo systemctl start ssh
sudo systemctl enable ssh

# CentOS/RHEL
sudo systemctl start sshd
sudo systemctl enable sshd

# Kiểm tra port SSH
sudo ss -tulpn | grep :22
sudo netstat -tulpn | grep :22
```

### Cấu hình SSH Server
```bash
# Backup cấu hình gốc
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Chỉnh sửa cấu hình SSH
sudo nano /etc/ssh/sshd_config

# Restart SSH service sau khi chỉnh sửa
sudo systemctl restart ssh          # Ubuntu/Debian
sudo systemctl restart sshd         # CentOS/RHEL
```

---

## SSH với Password Authentication

### Cấu hình Password Authentication
```bash
# Chỉnh sửa file cấu hình SSH
sudo nano /etc/ssh/sshd_config

# Các cấu hình cần thiết:
Port 22                              # Port SSH (có thể đổi)
PermitRootLogin no                   # Không cho phép root login trực tiếp
PasswordAuthentication yes           # Cho phép đăng nhập bằng password
PubkeyAuthentication yes             # Cho phép đăng nhập bằng key
PermitEmptyPasswords no              # Không cho phép password rỗng
MaxAuthTries 3                       # Số lần thử đăng nhập tối đa
ClientAliveInterval 300              # Kiểm tra kết nối mỗi 5 phút
ClientAliveCountMax 2                # Số lần không phản hồi trước khi disconnect

# Restart SSH service
sudo systemctl restart ssh
```

### Tạo user mới cho SSH
```bash
# Tạo user mới
sudo adduser newuser

# Thêm user vào sudo group (nếu cần)
sudo usermod -aG sudo newuser

# Kiểm tra user đã tạo
id newuser
groups newuser
```

### Kết nối SSH từ client
```bash
# Kết nối SSH cơ bản
ssh username@server_ip

# Kết nối với port tùy chỉnh
ssh -p 2222 username@server_ip

# Kết nối với verbose output (debug)
ssh -v username@server_ip

# Kết nối và chạy lệnh từ xa
ssh username@server_ip "ls -la"
```

---

## SSH với Key-based Authentication

### Tạo SSH Key Pair
```bash
# Tạo SSH key pair (RSA 4096-bit)
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# Tạo SSH key pair (Ed25519 - recommended)
ssh-keygen -t ed25519 -C "your_email@example.com"

# Tạo SSH key với passphrase
ssh-keygen -t rsa -b 4096 -C "your_email@example.com" -f ~/.ssh/id_rsa_server

# Xem public key
cat ~/.ssh/id_rsa.pub
cat ~/.ssh/id_ed25519.pub
```

### Copy SSH Key lên server
```bash
# Cách 1: Sử dụng ssh-copy-id (recommended)
ssh-copy-id username@server_ip

# Cách 2: Copy thủ công
cat ~/.ssh/id_rsa.pub | ssh username@server_ip "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

# Cách 3: Sử dụng scp
scp ~/.ssh/id_rsa.pub username@server_ip:~/.ssh/
ssh username@server_ip "cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys"
```

### Cấu hình SSH Key trên server
```bash
# Tạo thư mục .ssh nếu chưa có
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Tạo file authorized_keys
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Thêm public key vào authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQ..." >> ~/.ssh/authorized_keys

# Kiểm tra quyền file
ls -la ~/.ssh/
```

### Cấu hình SSH Server cho Key Authentication
```bash
# Chỉnh sửa file cấu hình SSH
sudo nano /etc/ssh/sshd_config

# Các cấu hình cần thiết:
PubkeyAuthentication yes             # Cho phép key authentication
AuthorizedKeysFile .ssh/authorized_keys  # Đường dẫn file authorized_keys
PasswordAuthentication no            # Tắt password authentication (sau khi setup key)
PermitRootLogin no                   # Không cho phép root login
MaxAuthTries 3                       # Số lần thử đăng nhập tối đa

# Restart SSH service
sudo systemctl restart ssh
```

### Kết nối SSH với Key
```bash
# Kết nối với key mặc định
ssh username@server_ip

# Kết nối với key cụ thể
ssh -i ~/.ssh/id_rsa_server username@server_ip

# Kết nối với key và port tùy chỉnh
ssh -i ~/.ssh/id_rsa_server -p 2222 username@server_ip

# Kết nối với verbose output
ssh -v -i ~/.ssh/id_rsa_server username@server_ip
```

---

## Cấu hình SSH Client

### SSH Config File
```bash
# Tạo hoặc chỉnh sửa SSH config
nano ~/.ssh/config

# Ví dụ cấu hình:
Host myserver
    HostName 192.168.1.100
    User myuser
    Port 22
    IdentityFile ~/.ssh/id_rsa_server
    ServerAliveInterval 60
    ServerAliveCountMax 3

Host production
    HostName prod.example.com
    User admin
    Port 2222
    IdentityFile ~/.ssh/id_rsa_prod
    StrictHostKeyChecking yes
    UserKnownHostsFile ~/.ssh/known_hosts

# Sử dụng config
ssh myserver
ssh production
```

### SSH Agent
```bash
# Khởi động SSH agent
eval "$(ssh-agent -s)"

# Thêm key vào SSH agent
ssh-add ~/.ssh/id_rsa
ssh-add ~/.ssh/id_ed25519

# Liệt kê keys trong agent
ssh-add -l

# Xóa tất cả keys khỏi agent
ssh-add -D

# Thêm key với thời gian hết hạn
ssh-add -t 3600 ~/.ssh/id_rsa
```

---

## Bảo mật SSH

### Hardening SSH Server
```bash
# Chỉnh sửa file cấu hình SSH
sudo nano /etc/ssh/sshd_config

# Các cấu hình bảo mật:
Port 2222                           # Đổi port SSH mặc định
PermitRootLogin no                  # Không cho phép root login
PasswordAuthentication no           # Tắt password authentication
PubkeyAuthentication yes            # Chỉ cho phép key authentication
PermitEmptyPasswords no             # Không cho phép password rỗng
MaxAuthTries 3                      # Giới hạn số lần thử đăng nhập
MaxSessions 2                       # Giới hạn số session đồng thời
ClientAliveInterval 300             # Kiểm tra kết nối mỗi 5 phút
ClientAliveCountMax 2               # Disconnect sau 2 lần không phản hồi
LoginGraceTime 60                   # Thời gian chờ đăng nhập
AllowUsers username1 username2      # Chỉ cho phép user cụ thể
DenyUsers baduser                   # Chặn user cụ thể
Protocol 2                          # Chỉ sử dụng SSH protocol version 2
X11Forwarding no                    # Tắt X11 forwarding
AllowTcpForwarding no               # Tắt TCP forwarding
GatewayPorts no                     # Tắt gateway ports
```

### Firewall Configuration
```bash
# Ubuntu/Debian - UFW
sudo ufw enable
sudo ufw allow 2222/tcp              # Cho phép SSH port
sudo ufw allow from 192.168.1.0/24  # Cho phép từ subnet cụ thể
sudo ufw deny 22                     # Chặn port SSH mặc định
sudo ufw status

# CentOS/RHEL - firewalld
sudo systemctl enable firewalld
sudo systemctl start firewalld
sudo firewall-cmd --permanent --add-port=2222/tcp
sudo firewall-cmd --permanent --remove-service=ssh
sudo firewall-cmd --reload
sudo firewall-cmd --list-all
```

### Fail2Ban Setup
```bash
# Cài đặt fail2ban
sudo apt install fail2ban -y        # Ubuntu/Debian
sudo yum install fail2ban -y        # CentOS/RHEL

# Cấu hình fail2ban cho SSH
sudo nano /etc/fail2ban/jail.local

# Nội dung file:
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = 2222
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600

# Khởi động fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
sudo fail2ban-client status
```

---

## Troubleshooting SSH

### Kiểm tra kết nối SSH
```bash
# Kiểm tra SSH service
sudo systemctl status ssh
sudo systemctl status sshd

# Kiểm tra port SSH
sudo ss -tulpn | grep :22
sudo netstat -tulpn | grep :22

# Kiểm tra log SSH
sudo tail -f /var/log/auth.log       # Ubuntu/Debian
sudo tail -f /var/log/secure         # CentOS/RHEL

# Test kết nối với verbose
ssh -vvv username@server_ip
```

### Các lỗi thường gặp
```bash
# Lỗi "Permission denied (publickey)"
# Kiểm tra:
ls -la ~/.ssh/authorized_keys        # Quyền file
cat ~/.ssh/authorized_keys           # Nội dung file
ssh-add -l                           # Keys trong agent

# Lỗi "Connection refused"
# Kiểm tra:
sudo systemctl status ssh            # SSH service
sudo ss -tulpn | grep :22           # Port listening
sudo ufw status                      # Firewall

# Lỗi "Host key verification failed"
# Xóa host key cũ:
ssh-keygen -R server_ip
ssh-keygen -R [server_ip]:2222

# Lỗi "Too many authentication failures"
# Chỉ định key cụ thể:
ssh -i ~/.ssh/id_rsa username@server_ip
```

### Debug SSH Connection
```bash
# Debug với verbose output
ssh -vvv username@server_ip

# Test với telnet
telnet server_ip 22

# Kiểm tra DNS resolution
nslookup server_ip
dig server_ip

# Kiểm tra routing
traceroute server_ip
mtr server_ip
```

---

## Advanced SSH Features

### SSH Tunneling
```bash
# Local Port Forwarding
ssh -L 8080:localhost:80 username@server_ip

# Remote Port Forwarding
ssh -R 9090:localhost:80 username@server_ip

# Dynamic Port Forwarding (SOCKS Proxy)
ssh -D 1080 username@server_ip

# Background tunneling
ssh -f -N -L 8080:localhost:80 username@server_ip
```

### SSH Multiplexing
```bash
# Cấu hình SSH multiplexing
nano ~/.ssh/config

# Thêm vào config:
Host *
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h-%p
    ControlPersist 600

# Tạo thư mục sockets
mkdir -p ~/.ssh/sockets
```

### SCP và SFTP
```bash
# Copy file từ local lên server
scp file.txt username@server_ip:/path/to/destination/

# Copy file từ server về local
scp username@server_ip:/path/to/file.txt ./

# Copy thư mục
scp -r directory/ username@server_ip:/path/to/destination/

# SFTP
sftp username@server_ip
sftp> put file.txt
sftp> get file.txt
sftp> ls
sftp> quit
```

### SSH Key Management
```bash
# Backup SSH keys
tar -czf ssh_keys_backup.tar.gz ~/.ssh/

# Restore SSH keys
tar -xzf ssh_keys_backup.tar.gz -C ~/

# Rotate SSH keys
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_new
ssh-copy-id -i ~/.ssh/id_rsa_new.pub username@server_ip

# Revoke old key
ssh username@server_ip "sed -i '/old_key_fingerprint/d' ~/.ssh/authorized_keys"
```

---

## 🔧 Tips và Best Practices

### Security Best Practices
```bash
# 1. Luôn sử dụng SSH keys thay vì passwords
# 2. Đổi port SSH mặc định (22)
# 3. Sử dụng fail2ban để chống brute force
# 4. Cập nhật SSH server thường xuyên
# 5. Sử dụng strong passphrases cho SSH keys
# 6. Backup SSH keys an toàn
# 7. Monitor SSH logs thường xuyên
# 8. Sử dụng 2FA khi có thể
```

### Performance Optimization
```bash
# Cấu hình SSH cho performance tốt hơn
nano ~/.ssh/config

# Thêm vào config:
Host *
    Compression yes
    ServerAliveInterval 60
    ServerAliveCountMax 3
    TCPKeepAlive yes
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h-%p
    ControlPersist 600
```

### Monitoring SSH
```bash
# Monitor SSH connections
who
w
last
lastb

# Monitor SSH logs
sudo tail -f /var/log/auth.log | grep ssh
sudo grep "Failed password" /var/log/auth.log
sudo grep "Accepted" /var/log/auth.log
```

---

## 📚 Tài liệu tham khảo

- [OpenSSH Manual](https://www.openssh.com/manual.html)
- [SSH Key Management Best Practices](https://www.ssh.com/academy/ssh/key-management)
- [SSH Security Hardening](https://www.ssh.com/academy/ssh/sshd_config)
- [Fail2Ban Documentation](https://www.fail2ban.org/wiki/index.php/Main_Page)

---

*Cheatsheet này cung cấp hướng dẫn đầy đủ để quản lý server, lấy thông tin IP, và thiết lập SSH với cả password và key-based authentication. Luôn nhớ áp dụng các biện pháp bảo mật phù hợp cho môi trường production.*
