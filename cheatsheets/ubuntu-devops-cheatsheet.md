# Ubuntu DevOps Cheatsheet

## 📋 Mục lục
- [Quản lý hệ thống](#quản-lý-hệ-thống)
- [Quản lý gói và dịch vụ](#quản-lý-gói-và-dịch-vụ)
- [Quản lý người dùng và quyền](#quản-lý-người-dùng-và-quyền)
- [Mạng và kết nối](#mạng-và-kết-nối)
- [Quản lý file và thư mục](#quản-lý-file-và-thư-mục)
- [Monitoring và logs](#monitoring-và-logs)
- [Bảo mật](#bảo-mật)
- [Git và version control](#git-và-version-control)
- [SSH và remote access](#ssh-và-remote-access)
- [System maintenance](#system-maintenance)

---

## Quản lý hệ thống

### Thông tin hệ thống
```bash
# Xem thông tin hệ điều hành
uname -a                    # Hiển thị thông tin kernel và hệ thống
lsb_release -a             # Hiển thị thông tin phiên bản Ubuntu
cat /etc/os-release        # Xem thông tin chi tiết về OS
hostnamectl                # Xem thông tin hostname và OS

# Thông tin phần cứng
lscpu                      # Thông tin CPU
free -h                    # Thông tin RAM (human readable)
df -h                      # Thông tin disk space
lsblk                      # Liệt kê tất cả block devices
lspci                      # Liệt kê PCI devices
lsusb                      # Liệt kê USB devices
```

### Quản lý tiến trình
```bash
# Xem và quản lý tiến trình
ps aux                     # Liệt kê tất cả tiến trình
top                        # Xem tiến trình real-time
htop                       # Top với giao diện đẹp hơn (cần cài đặt)
pgrep <process_name>       # Tìm PID của tiến trình theo tên
pkill <process_name>       # Kill tiến trình theo tên
kill -9 <PID>              # Force kill tiến trình
killall <process_name>     # Kill tất cả tiến trình có tên
```

### Quản lý bộ nhớ và CPU
```bash
# Monitoring tài nguyên
vmstat 1                   # Thống kê virtual memory mỗi giây
iostat 1                   # Thống kê I/O mỗi giây
sar -u 1                   # Thống kê CPU usage
sar -r 1                   # Thống kê memory usage
sar -d 1                   # Thống kê disk I/O
```

---

## Quản lý gói và dịch vụ

### APT Package Manager
```bash
# Cập nhật hệ thống
sudo apt update            # Cập nhật danh sách package
sudo apt upgrade           # Cập nhật tất cả packages
sudo apt dist-upgrade      # Cập nhật và xử lý dependencies
sudo apt autoremove        # Xóa packages không cần thiết
sudo apt autoclean         # Dọn dẹp cache packages

# Cài đặt và gỡ bỏ packages
sudo apt install <package> # Cài đặt package
sudo apt remove <package>  # Gỡ bỏ package (giữ config)
sudo apt purge <package>   # Gỡ bỏ package và config
sudo apt search <keyword>  # Tìm kiếm packages
apt list --installed       # Liệt kê packages đã cài
apt show <package>         # Xem thông tin package

# Quản lý repositories
sudo add-apt-repository <repo>  # Thêm repository
sudo apt-key adv --keyserver <server> --recv-keys <key>  # Thêm GPG key
```

### Systemd Services
```bash
# Quản lý services
sudo systemctl start <service>     # Khởi động service
sudo systemctl stop <service>      # Dừng service
sudo systemctl restart <service>   # Khởi động lại service
sudo systemctl reload <service>    # Reload config của service
sudo systemctl enable <service>    # Tự động khởi động khi boot
sudo systemctl disable <service>   # Tắt tự động khởi động
sudo systemctl status <service>    # Xem trạng thái service
sudo systemctl list-units          # Liệt kê tất cả units
sudo systemctl daemon-reload       # Reload systemd config

# Xem logs của service
sudo journalctl -u <service>       # Logs của service cụ thể
sudo journalctl -f                 # Theo dõi logs real-time
sudo journalctl --since "1 hour ago"  # Logs từ 1 giờ trước
```

---

## Quản lý người dùng và quyền

### User Management
```bash
# Quản lý users
sudo adduser <username>            # Tạo user mới
sudo deluser <username>            # Xóa user
sudo usermod -aG <group> <user>    # Thêm user vào group
sudo gpasswd -d <user> <group>     # Xóa user khỏi group
id <username>                      # Xem thông tin user và groups
groups <username>                  # Xem groups của user
whoami                             # Xem user hiện tại
w                                   # Xem users đang đăng nhập
last                                # Xem lịch sử đăng nhập

# Quản lý groups
sudo addgroup <groupname>          # Tạo group mới
sudo delgroup <groupname>          # Xóa group
getent group <groupname>           # Xem thông tin group
```

### File Permissions
```bash
# Thay đổi quyền file/folder
chmod 755 <file>                   # rwxr-xr-x (owner: rwx, group: rx, other: rx)
chmod +x <file>                    # Thêm quyền execute
chmod -x <file>                    # Bỏ quyền execute
chmod u+x <file>                   # Thêm execute cho owner
chmod g+w <file>                   # Thêm write cho group
chmod o-r <file>                   # Bỏ read cho others

# Thay đổi ownership
sudo chown <user>:<group> <file>   # Thay đổi owner và group
sudo chown <user> <file>           # Chỉ thay đổi owner
sudo chgrp <group> <file>          # Chỉ thay đổi group
sudo chown -R <user>:<group> <dir> # Recursive cho thư mục

# Xem quyền
ls -la                             # Xem quyền chi tiết
stat <file>                        # Xem thông tin chi tiết file
```

---

## Mạng và kết nối

### Network Configuration
```bash
# Thông tin mạng
ip addr show                       # Xem tất cả network interfaces
ip route show                      # Xem routing table
ifconfig                           # Xem network interfaces (deprecated)
netstat -tulpn                     # Xem ports đang listen
ss -tulpn                          # Thay thế netstat (modern)
lsof -i :<port>                    # Xem process sử dụng port

# Quản lý network
sudo ip link set <interface> up    # Bật network interface
sudo ip link set <interface> down  # Tắt network interface
sudo ip addr add <ip>/<mask> dev <interface>  # Thêm IP address
sudo ip route add default via <gateway>       # Thêm default gateway

# DNS
cat /etc/resolv.conf               # Xem DNS servers
nslookup <domain>                  # Query DNS
dig <domain>                       # DNS lookup tool
host <domain>                      # Hostname lookup
```

### Firewall (UFW)
```bash
# Quản lý firewall
sudo ufw status                    # Xem trạng thái firewall
sudo ufw enable                    # Bật firewall
sudo ufw disable                   # Tắt firewall
sudo ufw allow <port>              # Cho phép port
sudo ufw allow <port>/<protocol>   # Cho phép port với protocol
sudo ufw deny <port>               # Chặn port
sudo ufw allow from <ip>           # Cho phép từ IP
sudo ufw delete <rule_number>      # Xóa rule
sudo ufw reset                     # Reset tất cả rules
```

---

## Quản lý file và thư mục

### File Operations
```bash
# Tạo và xóa
touch <file>                       # Tạo file rỗng
mkdir -p <dir>                     # Tạo thư mục (tạo parent nếu cần)
rm <file>                          # Xóa file
rm -rf <dir>                       # Xóa thư mục và nội dung
rmdir <dir>                        # Xóa thư mục rỗng

# Copy và move
cp <source> <dest>                 # Copy file
cp -r <source> <dest>              # Copy thư mục
mv <source> <dest>                 # Move/rename file
rsync -av <source> <dest>          # Sync files (advanced copy)

# Tìm kiếm
find <path> -name "<pattern>"      # Tìm file theo tên
find <path> -type f -name "*.txt"  # Tìm file .txt
find <path> -size +100M            # Tìm file > 100MB
find <path> -mtime -7              # Tìm file modified trong 7 ngày
locate <pattern>                   # Tìm file nhanh (cần updatedb)
grep -r "<pattern>" <path>         # Tìm text trong files
grep -i "<pattern>" <file>         # Tìm không phân biệt hoa thường
```

### Archive và Compression
```bash
# Tar
tar -czf <archive.tar.gz> <files>  # Tạo tar.gz archive
tar -xzf <archive.tar.gz>          # Extract tar.gz
tar -tf <archive.tar.gz>           # List contents
tar -czf backup.tar.gz --exclude='*.log' <dir>  # Exclude files

# Zip
zip -r <archive.zip> <files>       # Tạo zip archive
unzip <archive.zip>                # Extract zip
unzip -l <archive.zip>             # List contents

# Compression
gzip <file>                        # Compress file
gunzip <file.gz>                   # Decompress file
bzip2 <file>                       # Compress với bzip2
bunzip2 <file.bz2>                 # Decompress bzip2
```

---

## Monitoring và logs

### System Monitoring
```bash
# CPU và Memory
htop                               # Interactive process viewer
top                                # Process viewer
free -h                            # Memory usage
vmstat 1                           # Virtual memory stats
iostat 1                           # I/O statistics
sar -u 1                           # CPU utilization
sar -r 1                           # Memory utilization

# Disk usage
df -h                              # Disk space usage
du -h <path>                       # Directory size
du -sh *                           # Size of all items in current dir
du -h --max-depth=1                # Size of subdirectories
ncdu <path>                        # Interactive disk usage (cần cài)

# Network monitoring
iftop                              # Network traffic monitor
nethogs                            # Network usage by process
ss -tulpn                          # Socket statistics
netstat -i                         # Network interface statistics
```

### Log Management
```bash
# System logs
sudo journalctl                    # Systemd logs
sudo journalctl -f                 # Follow logs
sudo journalctl -u <service>       # Service logs
sudo journalctl --since "1 hour ago"  # Logs từ thời điểm
sudo journalctl --until "2023-01-01"  # Logs đến thời điểm

# Traditional logs
tail -f /var/log/syslog            # Follow system log
tail -f /var/log/auth.log          # Follow auth log
tail -f /var/log/nginx/access.log  # Follow nginx access log
grep "ERROR" /var/log/syslog       # Tìm errors trong log
less /var/log/syslog               # View log file
```

---

## Bảo mật

### SSH Security
```bash
# SSH configuration
sudo nano /etc/ssh/sshd_config     # Edit SSH config
sudo systemctl restart ssh         # Restart SSH service
ssh-keygen -t rsa -b 4096          # Generate SSH key
ssh-copy-id <user>@<host>          # Copy SSH key to remote host
ssh -i <key_file> <user>@<host>    # SSH with specific key

# SSH key management
ssh-add <key_file>                 # Add key to ssh-agent
ssh-add -l                         # List loaded keys
ssh-add -D                         # Remove all keys
```

### Security Tools
```bash
# Firewall
sudo ufw status                    # Check firewall status
sudo ufw enable                    # Enable firewall
sudo ufw allow ssh                 # Allow SSH
sudo ufw allow 80/tcp              # Allow HTTP
sudo ufw allow 443/tcp             # Allow HTTPS

# Security updates
sudo apt update && sudo apt upgrade  # Update system
sudo unattended-upgrades --dry-run   # Check auto-updates
sudo apt list --upgradable           # List available updates

# File integrity
md5sum <file>                      # Calculate MD5 hash
sha256sum <file>                   # Calculate SHA256 hash
chmod 600 <file>                   # Secure file permissions
```

---

## Git và version control

### Git Basics
```bash
# Repository management
git init                           # Initialize repository
git clone <url>                    # Clone repository
git remote add origin <url>        # Add remote repository
git remote -v                      # List remotes

# Basic workflow
git add <file>                     # Add file to staging
git add .                          # Add all changes
git commit -m "message"            # Commit changes
git push origin <branch>           # Push to remote
git pull origin <branch>           # Pull from remote

# Branching
git branch                         # List branches
git branch <branch_name>           # Create branch
git checkout <branch>              # Switch branch
git checkout -b <branch>           # Create and switch branch
git merge <branch>                 # Merge branch
git branch -d <branch>             # Delete branch

# Status and history
git status                         # Check status
git log --oneline                  # View commit history
git diff                           # View changes
git show <commit>                  # Show commit details
```

---

## SSH và remote access

### SSH Commands
```bash
# Basic SSH
ssh <user>@<host>                  # Connect to remote host
ssh -p <port> <user>@<host>        # Connect with custom port
ssh -i <key_file> <user>@<host>    # Connect with specific key
ssh -X <user>@<host>               # Enable X11 forwarding

# SSH tunneling
ssh -L <local_port>:<remote_host>:<remote_port> <user>@<host>  # Local port forwarding
ssh -R <remote_port>:<local_host>:<local_port> <user>@<host>   # Remote port forwarding
ssh -D <port> <user>@<host>        # Dynamic port forwarding (SOCKS proxy)

# SSH config
nano ~/.ssh/config                 # Edit SSH config
ssh <alias>                        # Connect using alias from config
```

### SCP và SFTP
```bash
# SCP (Secure Copy)
scp <file> <user>@<host>:<path>    # Copy file to remote
scp <user>@<host>:<path> <file>    # Copy file from remote
scp -r <dir> <user>@<host>:<path>  # Copy directory recursively
scp -P <port> <file> <user>@<host>:<path>  # Copy with custom port

# SFTP
sftp <user>@<host>                 # Connect to SFTP
put <local_file> <remote_path>     # Upload file
get <remote_file> <local_path>     # Download file
ls                                 # List remote directory
cd <path>                          # Change remote directory
```

---

## System maintenance

### Backup và Restore
```bash
# File backup
rsync -av <source> <dest>          # Sync files
rsync -av --delete <source> <dest> # Sync with deletion
tar -czf backup.tar.gz <files>     # Create backup archive
dd if=<source> of=<dest> bs=4M     # Disk cloning

# System backup
sudo dpkg --get-selections > packages.txt  # Export package list
sudo apt-key exportall > apt-keys.asc      # Export APT keys
sudo tar -czf /backup/system-backup.tar.gz /etc /home /opt  # System backup
```

### System Cleanup
```bash
# Clean package cache
sudo apt clean                     # Clean package cache
sudo apt autoremove                # Remove unused packages
sudo apt autoclean                 # Clean old package files

# Clean logs
sudo journalctl --vacuum-time=7d   # Remove logs older than 7 days
sudo find /var/log -name "*.log" -mtime +30 -delete  # Delete old log files

# Clean temporary files
sudo rm -rf /tmp/*                 # Clean /tmp directory
sudo find /var/tmp -type f -mtime +7 -delete  # Clean old temp files
```

### Performance Tuning
```bash
# Kernel parameters
sudo sysctl -a                     # View all kernel parameters
sudo sysctl -w <parameter>=<value> # Set kernel parameter
echo '<parameter>=<value>' | sudo tee -a /etc/sysctl.conf  # Make permanent

# Process limits
ulimit -a                          # View current limits
ulimit -n <number>                 # Set file descriptor limit
echo '* soft nofile 65536' | sudo tee -a /etc/security/limits.conf
```

---

## 🔧 Tips và Tricks

### Useful Aliases
```bash
# Thêm vào ~/.bashrc
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias h='history'
alias j='jobs -l'
alias ps='ps auxf'
alias psgrep='ps aux | grep -v grep | grep -i -e VSZ -e'
alias mkdir='mkdir -pv'
alias wget='wget -c'
alias histg='history | grep'
alias myip='curl -s https://ipinfo.io/ip'
```

### One-liners hữu ích
```bash
# Tìm file lớn nhất
find . -type f -exec ls -s {} \; | sort -n -r | head -10

# Đếm số file trong thư mục
find . -type f | wc -l

# Tìm file trống
find . -type f -empty

# Xóa file cũ hơn 30 ngày
find . -type f -mtime +30 -delete

# Monitor network connections
watch -n 1 'netstat -tuln'

# Xem top 10 processes sử dụng CPU
ps aux --sort=-%cpu | head -10

# Xem top 10 processes sử dụng RAM
ps aux --sort=-%mem | head -10
```

---

## 📚 Tài liệu tham khảo

- [Ubuntu Server Guide](https://ubuntu.com/server/docs)
- [Linux Command Line](https://linuxcommand.org/)
- [Bash Reference Manual](https://www.gnu.org/software/bash/manual/)
- [Systemd Documentation](https://systemd.io/)

---

*Cheatsheet này được tạo để hỗ trợ các DevOps engineers làm việc với Ubuntu. Hãy thường xuyên cập nhật và bổ sung thêm các lệnh hữu ích khác!*
