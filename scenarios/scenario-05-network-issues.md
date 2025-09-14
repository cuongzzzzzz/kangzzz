# Tình huống 5: Network Issues - Kết Nối Mạng Bị Lỗi

## 🚨 Mô tả tình huống
- Không thể truy cập website/API từ bên ngoài
- SSH connection bị timeout hoặc refused
- Database connection bị lỗi
- Load balancer không hoạt động
- DNS resolution không hoạt động
- Firewall block traffic

## 🔍 Các bước chẩn đoán

### Bước 1: Kiểm tra kết nối cơ bản
```bash
# Ping test
ping google.com                    # Gửi ICMP packets đến Google để test kết nối internet
ping 8.8.8.8                      # Ping Google DNS server (8.8.8.8) để test kết nối mạng
ping <server_ip>                  # Ping server cụ thể để test kết nối đến server

# Kiểm tra DNS resolution
nslookup google.com               # Query DNS server để resolve domain name thành IP address
dig google.com                    # Tool DNS lookup mạnh hơn, hiển thị chi tiết DNS response
host google.com                   # Tool DNS lookup đơn giản, hiển thị IP address của domain

# Kiểm tra routing
traceroute google.com             # Trace route từ server đến Google, hiển thị các hop
mtr google.com                    # My Traceroute - tool trace route với statistics real-time
```

### Bước 2: Kiểm tra network interfaces
```bash
# Xem network interfaces
ip addr show                      # Hiển thị tất cả network interfaces với IP addresses (modern command)
ifconfig                          # Hiển thị network interfaces (legacy command, deprecated)
ip link show                      # Hiển thị trạng thái của network interfaces (up/down)

# Xem routing table
ip route show                     # Hiển thị routing table (modern command)
route -n                          # Hiển thị routing table với numeric addresses (legacy command)
netstat -rn                       # Hiển thị routing table với numeric addresses (legacy command)

# Xem ARP table
arp -a                            # Hiển thị ARP table (IP to MAC address mapping)
ip neigh show                     # Hiển thị neighbor table (modern ARP command)
```

### Bước 3: Kiểm tra ports và services
```bash
# Xem ports đang listen
netstat -tulpn
ss -tulpn
lsof -i

# Kiểm tra port cụ thể
telnet <server_ip> 80
telnet <server_ip> 443
telnet <server_ip> 22

# Test connection
nc -zv <server_ip> 80
nc -zv <server_ip> 443
```

## 🛠️ Các nguyên nhân thường gặp và cách giải quyết

### 1. Network interface down
```bash
# Kiểm tra status interface
ip link show
ifconfig

# Bật interface
sudo ip link set <interface> up
sudo ifup <interface>

# Restart network service
sudo systemctl restart networking
sudo systemctl restart NetworkManager

# Cấu hình interface
sudo nano /etc/netplan/50-cloud-init.yaml
sudo netplan apply
```

### 2. Firewall blocking traffic
```bash
# Kiểm tra UFW status
sudo ufw status
sudo ufw status verbose

# Cho phép ports cần thiết
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3306/tcp

# Tắt firewall tạm thời (cẩn thận!)
sudo ufw disable

# Bật firewall lại
sudo ufw enable
```

### Bước 3: Kiểm tra iptables
```bash
# Xem iptables rules
sudo iptables -L
sudo iptables -L -n -v

# Xóa tất cả rules (cẩn thận!)
sudo iptables -F
sudo iptables -X
sudo iptables -t nat -F
sudo iptables -t nat -X

# Reset iptables về default
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT
```

### 4. DNS issues
```bash
# Kiểm tra DNS config
cat /etc/resolv.conf
cat /etc/systemd/resolved.conf

# Restart DNS service
sudo systemctl restart systemd-resolved
sudo systemctl restart dnsmasq

# Flush DNS cache
sudo systemctl flush-dns
sudo resolvectl flush-caches

# Test DNS với different servers
nslookup google.com 8.8.8.8
nslookup google.com 1.1.1.1
```

### 5. Service không listen trên port
```bash
# Kiểm tra service status
sudo systemctl status nginx
sudo systemctl status apache2
sudo systemctl status mysql

# Restart services
sudo systemctl restart nginx
sudo systemctl restart apache2
sudo systemctl restart mysql

# Kiểm tra config files
sudo nginx -t
sudo apache2ctl configtest
```

### 6. Load balancer issues
```bash
# Kiểm tra load balancer status
sudo systemctl status haproxy
sudo systemctl status nginx

# Test load balancer config
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
sudo nginx -t

# Restart load balancer
sudo systemctl restart haproxy
sudo systemctl restart nginx
```

## 🚀 Các lệnh khôi phục nhanh

### Emergency network fix
```bash
# 1. Restart network service
sudo systemctl restart networking
sudo systemctl restart NetworkManager

# 2. Reset network interfaces
sudo ip link set <interface> down
sudo ip link set <interface> up

# 3. Flush routing table
sudo ip route flush table main
sudo systemctl restart networking

# 4. Restart services quan trọng
sudo systemctl restart nginx apache2 mysql postgresql
```

### Port và service recovery
```bash
# Kiểm tra và mở ports cần thiết
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3306/tcp

# Restart firewall
sudo ufw reload

# Kiểm tra services
sudo systemctl is-active nginx
sudo systemctl is-active apache2
sudo systemctl is-active mysql
```

### DNS recovery
```bash
# Reset DNS config
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf

# Restart DNS service
sudo systemctl restart systemd-resolved
sudo systemctl flush-dns
```

## 📊 Monitoring và Analysis

### Network monitoring
```bash
# Monitor network traffic
iftop
nethogs
nload

# Monitor network connections
netstat -i
ss -s
ss -tuln

# Monitor bandwidth
vnstat
vnstat -l

# Monitor network errors
cat /proc/net/dev
cat /proc/net/snmp
```

### Log analysis
```bash
# Xem network logs
sudo journalctl -u networking
sudo journalctl -u NetworkManager

# Xem firewall logs
sudo journalctl -u ufw
sudo dmesg | grep -i firewall

# Xem service logs
sudo journalctl -u nginx
sudo journalctl -u apache2
sudo journalctl -u mysql
```

### Network testing
```bash
# Test connectivity
ping -c 4 google.com
ping -c 4 8.8.8.8

# Test specific ports
nc -zv google.com 80
nc -zv google.com 443

# Test DNS resolution
dig google.com
nslookup google.com

# Test routing
traceroute google.com
mtr google.com
```

## 🔧 Advanced Solutions

### Network configuration
```bash
# Cấu hình static IP
sudo nano /etc/netplan/50-cloud-init.yaml

network:
  version: 2
  ethernets:
    eth0:
      addresses:
        - 192.168.1.100/24
      gateway4: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]

sudo netplan apply
```

### Load balancer configuration
```bash
# Nginx load balancer
sudo nano /etc/nginx/sites-available/load-balancer

upstream backend {
    server 192.168.1.10:80;
    server 192.168.1.11:80;
    server 192.168.1.12:80;
}

server {
    listen 80;
    location / {
        proxy_pass http://backend;
    }
}

# HAProxy configuration
sudo nano /etc/haproxy/haproxy.cfg

backend web_servers
    balance roundrobin
    server web1 192.168.1.10:80 check
    server web2 192.168.1.11:80 check
    server web3 192.168.1.12:80 check
```

### Firewall rules
```bash
# UFW rules
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3306/tcp
sudo ufw enable

# iptables rules
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 3306 -j ACCEPT
sudo iptables -A INPUT -j DROP
```

## 📝 Checklist khôi phục

- [ ] Kiểm tra kết nối cơ bản (ping, DNS)
- [ ] Kiểm tra network interfaces
- [ ] Kiểm tra routing table
- [ ] Kiểm tra ports và services
- [ ] Kiểm tra firewall rules
- [ ] Kiểm tra DNS configuration
- [ ] Restart network services
- [ ] Test connectivity sau khi fix
- [ ] Monitor network performance
- [ ] Document incident và solution

## 🎯 Best Practices

1. **Thiết lập network monitoring** và alerts
2. **Document network topology** và configurations
3. **Test network connectivity** định kỳ
4. **Backup network configurations** trước khi thay đổi
5. **Use load balancers** cho high availability
6. **Implement proper firewall rules** và security
7. **Monitor network performance** và bandwidth usage
8. **Have network troubleshooting procedures** ready

---

*Tình huống này cần xử lý nhanh để restore connectivity. Luôn test network connectivity sau khi thay đổi configuration.*
