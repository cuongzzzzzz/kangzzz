# Tình huống 8: SSL Certificate Issues - Chứng Chỉ Bảo Mật Bị Lỗi

## 🚨 Mô tả tình huống
- Website hiển thị "Not Secure" hoặc "Certificate Error"
- SSL certificate hết hạn
- Certificate không được trust
- Mixed content warnings
- HTTPS không hoạt động
- Certificate chain không đúng

## 🔍 Các bước chẩn đoán

### Bước 1: Kiểm tra SSL certificate
```bash
# Kiểm tra certificate từ command line
openssl s_client -connect <domain>:443 -servername <domain>
openssl s_client -connect <domain>:443 -servername <domain> -showcerts

# Kiểm tra certificate với curl
curl -I https://<domain>
curl -v https://<domain>

# Kiểm tra certificate với wget
wget --spider https://<domain>
wget --spider --no-check-certificate https://<domain>
```

### Bước 2: Kiểm tra certificate details
```bash
# Xem certificate details
echo | openssl s_client -connect <domain>:443 -servername <domain> 2>/dev/null | openssl x509 -noout -text

# Xem certificate expiration
echo | openssl s_client -connect <domain>:443 -servername <domain> 2>/dev/null | openssl x509 -noout -dates

# Xem certificate issuer
echo | openssl s_client -connect <domain>:443 -servername <domain> 2>/dev/null | openssl x509 -noout -issuer

# Xem certificate subject
echo | openssl s_client -connect <domain>:443 -servername <domain> 2>/dev/null | openssl x509 -noout -subject
```

### Bước 3: Kiểm tra web server configuration
```bash
# Nginx SSL config
sudo nginx -t
sudo cat /etc/nginx/sites-available/<site>
sudo cat /etc/nginx/sites-enabled/<site>

# Apache SSL config
sudo apache2ctl configtest
sudo cat /etc/apache2/sites-available/<site>
sudo cat /etc/apache2/sites-enabled/<site>

# Kiểm tra SSL modules
sudo nginx -V 2>&1 | grep -o with-http_ssl_module
sudo apache2ctl -M | grep ssl
```

## 🛠️ Các nguyên nhân thường gặp và cách giải quyết

### 1. Certificate hết hạn
```bash
# Kiểm tra expiration date
echo | openssl s_client -connect <domain>:443 -servername <domain> 2>/dev/null | openssl x509 -noout -dates

# Renew certificate với Let's Encrypt
sudo certbot renew
sudo certbot renew --dry-run

# Renew specific certificate
sudo certbot renew --cert-name <domain>

# Force renewal
sudo certbot renew --force-renewal
```

### 2. Certificate không được trust
```bash
# Kiểm tra certificate chain
echo | openssl s_client -connect <domain>:443 -servername <domain> 2>/dev/null | openssl x509 -noout -text | grep -A 20 "Certificate chain"

# Download intermediate certificate
wget -O intermediate.crt https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem

# Combine certificates
cat <domain>.crt intermediate.crt > <domain>-fullchain.crt
```

### 3. Web server không load certificate
```bash
# Nginx - kiểm tra config
sudo nano /etc/nginx/sites-available/<site>

server {
    listen 443 ssl;
    server_name <domain>;
    
    ssl_certificate /path/to/<domain>.crt;
    ssl_certificate_key /path/to/<domain>.key;
    ssl_trusted_certificate /path/to/<domain>-fullchain.crt;
}

# Test và reload Nginx
sudo nginx -t
sudo systemctl reload nginx

# Apache - kiểm tra config
sudo nano /etc/apache2/sites-available/<site>

<VirtualHost *:443>
    ServerName <domain>
    SSLEngine on
    SSLCertificateFile /path/to/<domain>.crt
    SSLCertificateKeyFile /path/to/<domain>.key
    SSLCertificateChainFile /path/to/<domain>-fullchain.crt
</VirtualHost>

# Test và reload Apache
sudo apache2ctl configtest
sudo systemctl reload apache2
```

### 4. Mixed content issues
```bash
# Kiểm tra mixed content
curl -I https://<domain>
curl -I http://<domain>

# Redirect HTTP to HTTPS
# Nginx
server {
    listen 80;
    server_name <domain>;
    return 301 https://$server_name$request_uri;
}

# Apache
<VirtualHost *:80>
    ServerName <domain>
    Redirect permanent / https://<domain>/
</VirtualHost>
```

### 5. Certificate chain không đúng
```bash
# Kiểm tra certificate chain
openssl s_client -connect <domain>:443 -servername <domain> -showcerts

# Download proper intermediate certificate
wget -O intermediate.crt https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem

# Update certificate chain
sudo cp <domain>-fullchain.crt /etc/ssl/certs/
sudo systemctl reload nginx
sudo systemctl reload apache2
```

## 🚀 Các lệnh khôi phục nhanh

### Emergency SSL fix
```bash
# 1. Kiểm tra certificate status
echo | openssl s_client -connect <domain>:443 -servername <domain> 2>/dev/null | openssl x509 -noout -dates

# 2. Renew certificate nếu hết hạn
sudo certbot renew

# 3. Test web server config
sudo nginx -t
sudo apache2ctl configtest

# 4. Reload web server
sudo systemctl reload nginx
sudo systemctl reload apache2

# 5. Test HTTPS
curl -I https://<domain>
```

### Certificate installation
```bash
# Install certificate manually
sudo cp <domain>.crt /etc/ssl/certs/
sudo cp <domain>.key /etc/ssl/private/
sudo cp <domain>-fullchain.crt /etc/ssl/certs/

# Set proper permissions
sudo chmod 644 /etc/ssl/certs/<domain>.crt
sudo chmod 600 /etc/ssl/private/<domain>.key
sudo chmod 644 /etc/ssl/certs/<domain>-fullchain.crt

# Update web server config
sudo nano /etc/nginx/sites-available/<site>
sudo nano /etc/apache2/sites-available/<site>
```

### SSL configuration optimization
```bash
# Nginx SSL optimization
sudo nano /etc/nginx/sites-available/<site>

server {
    listen 443 ssl http2;
    server_name <domain>;
    
    ssl_certificate /etc/ssl/certs/<domain>-fullchain.crt;
    ssl_certificate_key /etc/ssl/private/<domain>.key;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
}
```

## 📊 Monitoring và Analysis

### SSL monitoring
```bash
# Check certificate expiration
echo | openssl s_client -connect <domain>:443 -servername <domain> 2>/dev/null | openssl x509 -noout -dates

# Check SSL grade
curl -I https://<domain>
curl -v https://<domain>

# Check SSL configuration
nmap --script ssl-enum-ciphers -p 443 <domain>
nmap --script ssl-cert -p 443 <domain>
```

### Certificate validation
```bash
# Validate certificate chain
openssl verify -CAfile /etc/ssl/certs/ca-certificates.crt <domain>.crt

# Check certificate against CA
openssl verify -CAfile /etc/ssl/certs/ca-certificates.crt <domain>-fullchain.crt

# Test SSL connection
openssl s_client -connect <domain>:443 -servername <domain> -verify_return_error
```

### Log analysis
```bash
# Xem SSL logs
sudo tail -f /var/log/nginx/error.log | grep ssl
sudo tail -f /var/log/apache2/error.log | grep ssl

# Xem certificate logs
sudo tail -f /var/log/letsencrypt/letsencrypt.log
sudo journalctl -u certbot
```

## 🔧 Advanced Solutions

### Let's Encrypt automation
```bash
# Cài đặt certbot
sudo apt install certbot python3-certbot-nginx
sudo apt install certbot python3-certbot-apache

# Obtain certificate
sudo certbot --nginx -d <domain>
sudo certbot --apache -d <domain>

# Auto-renewal setup
sudo crontab -e
# 0 12 * * * /usr/bin/certbot renew --quiet
```

### Wildcard certificate
```bash
# Obtain wildcard certificate
sudo certbot certonly --manual --preferred-challenges dns -d <domain> -d *.<domain>

# DNS challenge setup
# Add TXT record: _acme-challenge.<domain> with value provided by certbot
```

### Certificate management
```bash
# List certificates
sudo certbot certificates

# Revoke certificate
sudo certbot revoke --cert-path /etc/letsencrypt/live/<domain>/cert.pem

# Delete certificate
sudo certbot delete --cert-name <domain>
```

## 📝 Checklist khôi phục

- [ ] Kiểm tra certificate expiration
- [ ] Kiểm tra certificate chain
- [ ] Kiểm tra web server configuration
- [ ] Renew certificate nếu cần
- [ ] Update certificate files
- [ ] Test web server config
- [ ] Reload web server
- [ ] Test HTTPS functionality
- [ ] Monitor SSL performance
- [ ] Document incident và solution

## 🎯 Best Practices

1. **Thiết lập certificate monitoring** và alerts
2. **Implement auto-renewal** cho certificates
3. **Use proper certificate chain** và intermediate certificates
4. **Implement HSTS** và security headers
5. **Regular certificate audits** và validation
6. **Backup certificates** và private keys
7. **Test SSL configuration** định kỳ
8. **Monitor SSL performance** và grade

---

*Tình huống này cần xử lý nhanh để restore HTTPS functionality. Luôn monitor certificate expiration và implement auto-renewal.*
