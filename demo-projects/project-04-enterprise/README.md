# Project 4: Enterprise Multi-tier Architecture - High Availability

## 📋 Tổng quan dự án
- **Level**: Doanh nghiệp lớn
- **Stack**: Multi-tier + Load Balancer + High Availability
- **Kiến trúc**: 3-tier architecture với redundancy
- **Mục đích**: Enterprise-grade application với 99.9% uptime
- **Thời gian deploy**: 90-120 phút

## 🏗️ Kiến trúc hệ thống
```
Internet → CDN (CloudFlare) → Load Balancer (HAProxy) → Web Tier (Nginx)
                                                           ↓
    ┌─────────────────────────────────────────────────────────────┐
    │                    Application Tier                        │
    ├─────────────────┬─────────────────┬─────────────────────────┤
    │   App Server 1  │   App Server 2  │   App Server 3          │
    │   (Node.js)     │   (Node.js)     │   (Node.js)             │
    ├─────────────────┼─────────────────┼─────────────────────────┤
    │   App Server 4  │   App Server 5  │   App Server 6          │
    │   (Python)      │   (Python)      │   (Python)              │
    └─────────────────┴─────────────────┴─────────────────────────┘
                                                           ↓
    ┌─────────────────────────────────────────────────────────────┐
    │                    Data Tier                               │
    ├─────────────────┬─────────────────┬─────────────────────────┤
    │   Primary DB    │   Read Replica  │   Cache Cluster         │
    │   (PostgreSQL)  │   (PostgreSQL)  │   (Redis Cluster)       │
    ├─────────────────┼─────────────────┼─────────────────────────┤
    │   Backup DB     │   Search Engine │   Message Queue         │
    │   (PostgreSQL)  │   (Elasticsearch)│  (RabbitMQ)            │
    └─────────────────┴─────────────────┴─────────────────────────┘
```

## 📁 Cấu trúc dự án
```
project-04-enterprise/
├── README.md
├── docker-compose.yml
├── docker-compose.prod.yml
├── infrastructure/
│   ├── terraform/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── ansible/
│   │   ├── playbooks/
│   │   ├── inventory/
│   │   └── roles/
│   └── kubernetes/
│       ├── namespace.yaml
│       ├── deployments/
│       └── services/
├── applications/
│   ├── web-frontend/
│   ├── api-backend/
│   ├── admin-panel/
│   └── mobile-api/
├── databases/
│   ├── postgres/
│   ├── redis/
│   ├── elasticsearch/
│   └── rabbitmq/
├── monitoring/
│   ├── prometheus/
│   ├── grafana/
│   ├── elk-stack/
│   └── alertmanager/
├── security/
│   ├── ssl/
│   ├── firewall/
│   └── waf/
└── deploy/
    ├── deploy.sh
    ├── deploy-prod.sh
    └── backup/
```

## 🚀 Hướng dẫn Deploy

### Bước 1: Chuẩn bị Infrastructure
```bash
# Cài đặt Terraform
wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
unzip terraform_1.5.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Cài đặt Ansible
sudo apt update
sudo apt install ansible -y

# Cài đặt Docker và Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Cài đặt Kubernetes (cho production)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

### Bước 2: Deploy với Terraform (Cloud Infrastructure)
```bash
# Clone project
git clone <repository_url>
cd project-04-enterprise

# Configure Terraform
cd infrastructure/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Initialize and deploy
terraform init
terraform plan
terraform apply

# Get outputs
terraform output
```

### Bước 3: Deploy với Ansible (Server Configuration)
```bash
# Configure Ansible
cd infrastructure/ansible
cp inventory/hosts.example inventory/hosts
# Edit inventory/hosts with your server IPs

# Run playbooks
ansible-playbook -i inventory/hosts playbooks/setup-servers.yml
ansible-playbook -i inventory/hosts playbooks/deploy-applications.yml
ansible-playbook -i inventory/hosts playbooks/configure-monitoring.yml
```

### Bước 4: Deploy với Docker Compose (Development)
```bash
# Deploy development environment
docker-compose up -d

# Check status
docker-compose ps
```

### Bước 5: Deploy với Kubernetes (Production)
```bash
# Deploy to Kubernetes
kubectl apply -f infrastructure/kubernetes/

# Check status
kubectl get pods --all-namespaces
kubectl get services --all-namespaces
```

## 🔧 Cấu hình chi tiết

### Load Balancer Configuration (HAProxy)
```haproxy
# haproxy/haproxy.cfg
global
    daemon
    maxconn 4096
    log stdout local0
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy

defaults
    mode http
    log global
    option httplog
    option dontlognull
    option log-health-checks
    option forwardfor
    option httpchk GET /health
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

# Frontend
frontend web_frontend
    bind *:80
    bind *:443 ssl crt /etc/ssl/certs/enterprise.pem
    redirect scheme https if !{ ssl_fc }
    
    # Security headers
    http-response set-header X-Frame-Options DENY
    http-response set-header X-Content-Type-Options nosniff
    http-response set-header X-XSS-Protection "1; mode=block"
    http-response set-header Strict-Transport-Security "max-age=31536000; includeSubDomains"
    
    # Rate limiting
    stick-table type ip size 100k expire 30s store http_req_rate(10s)
    http-request track-sc0 src
    http-request deny if { sc_http_req_rate(0) gt 100 }
    
    # Routing
    use_backend web_servers if { path_beg / }
    use_backend api_servers if { path_beg /api/ }
    use_backend admin_servers if { path_beg /admin/ }

# Backend - Web Servers
backend web_servers
    balance roundrobin
    option httpchk GET /health
    http-check expect status 200
    
    server web1 web1:80 check inter 2000ms rise 2 fall 3
    server web2 web2:80 check inter 2000ms rise 2 fall 3
    server web3 web3:80 check inter 2000ms rise 2 fall 3

# Backend - API Servers
backend api_servers
    balance roundrobin
    option httpchk GET /api/health
    http-check expect status 200
    
    server api1 api1:3000 check inter 2000ms rise 2 fall 3
    server api2 api2:3000 check inter 2000ms rise 2 fall 3
    server api3 api3:3000 check inter 2000ms rise 2 fall 3

# Backend - Admin Servers
backend admin_servers
    balance roundrobin
    option httpchk GET /admin/health
    http-check expect status 200
    
    server admin1 admin1:8080 check inter 2000ms rise 2 fall 3
    server admin2 admin2:8080 check inter 2000ms rise 2 fall 3

# Statistics
stats enable
stats uri /stats
stats refresh 30s
stats admin if TRUE
```

### Database Configuration (PostgreSQL Cluster)
```yaml
# databases/postgres/postgresql.conf
# Primary Database Configuration
listen_addresses = '*'
port = 5432
max_connections = 200
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200

# Replication
wal_level = replica
max_wal_senders = 3
max_replication_slots = 3
hot_standby = on
hot_standby_feedback = on

# Logging
log_destination = 'stderr'
logging_collector = on
log_directory = '/var/log/postgresql'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_rotation_age = 1d
log_rotation_size = 100MB
log_min_duration_statement = 1000
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on
log_temp_files = 0
log_autovacuum_min_duration = 0
log_error_verbosity = default
```

### Redis Cluster Configuration
```conf
# databases/redis/redis.conf
# Cluster Configuration
port 7000
cluster-enabled yes
cluster-config-file nodes-7000.conf
cluster-node-timeout 5000
appendonly yes
appendfilename "appendonly-7000.aof"

# Memory Management
maxmemory 2gb
maxmemory-policy allkeys-lru

# Persistence
save 900 1
save 300 10
save 60 10000

# Security
requirepass your-redis-password
masterauth your-redis-password

# Logging
loglevel notice
logfile /var/log/redis/redis-7000.log

# Network
bind 0.0.0.0
protected-mode no
```

### Monitoring Configuration (Prometheus)
```yaml
# monitoring/prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'enterprise'
    replica: 'prometheus-1'

rule_files:
  - "alert_rules.yml"
  - "recording_rules.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  # Prometheus itself
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Node Exporter
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  # HAProxy
  - job_name: 'haproxy'
    static_configs:
      - targets: ['haproxy:8404']

  # PostgreSQL
  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres-exporter:9187']

  # Redis
  - job_name: 'redis'
    static_configs:
      - targets: ['redis-exporter:9121']

  # Nginx
  - job_name: 'nginx'
    static_configs:
      - targets: ['nginx-exporter:9113']

  # Application Services
  - job_name: 'web-servers'
    static_configs:
      - targets:
        - 'web1:80'
        - 'web2:80'
        - 'web3:80'
    metrics_path: /metrics
    scrape_interval: 30s

  - job_name: 'api-servers'
    static_configs:
      - targets:
        - 'api1:3000'
        - 'api2:3000'
        - 'api3:3000'
    metrics_path: /metrics
    scrape_interval: 30s

  - job_name: 'admin-servers'
    static_configs:
      - targets:
        - 'admin1:8080'
        - 'admin2:8080'
    metrics_path: /metrics
    scrape_interval: 30s
```

## 📊 High Availability Features

### Database Failover
```bash
# PostgreSQL Primary-Replica Setup
# 1. Setup primary database
docker run -d --name postgres-primary \
  -e POSTGRES_DB=enterprise \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_REPLICATION_USER=replicator \
  -e POSTGRES_REPLICATION_PASSWORD=replicator_password \
  -v postgres_primary_data:/var/lib/postgresql/data \
  -v postgres_primary_config:/etc/postgresql \
  postgres:15

# 2. Setup replica database
docker run -d --name postgres-replica \
  -e POSTGRES_DB=enterprise \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_MASTER_HOST=postgres-primary \
  -e POSTGRES_MASTER_PORT=5432 \
  -e POSTGRES_REPLICATION_USER=replicator \
  -e POSTGRES_REPLICATION_PASSWORD=replicator_password \
  -v postgres_replica_data:/var/lib/postgresql/data \
  -v postgres_replica_config:/etc/postgresql \
  postgres:15

# 3. Configure automatic failover
# Use pg_auto_failover for automatic failover
```

### Load Balancer Health Checks
```bash
# Health check script
#!/bin/bash
# health-check.sh

# Check web servers
for server in web1 web2 web3; do
    if ! curl -f http://$server/health >/dev/null 2>&1; then
        echo "CRITICAL: $server is down"
        # Send alert
        curl -X POST -H 'Content-type: application/json' \
          --data '{"text":"CRITICAL: '$server' is down"}' \
          $SLACK_WEBHOOK_URL
    fi
done

# Check API servers
for server in api1 api2 api3; do
    if ! curl -f http://$server/api/health >/dev/null 2>&1; then
        echo "CRITICAL: $server is down"
        # Send alert
        curl -X POST -H 'Content-type: application/json' \
          --data '{"text":"CRITICAL: '$server' is down"}' \
          $SLACK_WEBHOOK_URL
    fi
done

# Check database
if ! pg_isready -h postgres-primary -p 5432 >/dev/null 2>&1; then
    echo "CRITICAL: Primary database is down"
    # Trigger failover
    ./failover.sh
fi
```

### Backup Strategy
```bash
#!/bin/bash
# backup/backup.sh

# Database backup
pg_dump -h postgres-primary -U postgres enterprise > /backup/db_$(date +%Y%m%d_%H%M%S).sql

# Application backup
tar -czf /backup/app_$(date +%Y%m%d_%H%M%S).tar.gz /var/www/enterprise/

# Configuration backup
tar -czf /backup/config_$(date +%Y%m%d_%H%M%S).tar.gz /etc/nginx/ /etc/haproxy/ /etc/ssl/

# Upload to S3
aws s3 cp /backup/ s3://enterprise-backups/ --recursive --exclude "*" --include "*.sql" --include "*.tar.gz"

# Cleanup old backups (keep 30 days)
find /backup -name "*.sql" -mtime +30 -delete
find /backup -name "*.tar.gz" -mtime +30 -delete
```

## 🚨 Disaster Recovery

### RTO (Recovery Time Objective): 15 minutes
### RPO (Recovery Point Objective): 5 minutes

### Recovery Procedures
```bash
# 1. Database Recovery
# Restore from backup
pg_restore -h postgres-primary -U postgres -d enterprise /backup/db_latest.sql

# 2. Application Recovery
# Deploy from backup
tar -xzf /backup/app_latest.tar.gz -C /var/www/

# 3. Configuration Recovery
# Restore configuration
tar -xzf /backup/config_latest.tar.gz -C /

# 4. Service Recovery
# Restart services
systemctl restart nginx
systemctl restart haproxy
systemctl restart postgresql
```

## 📈 Performance Optimization

### CDN Configuration (CloudFlare)
```javascript
// CloudFlare Page Rules
// 1. Cache static assets
// URL: *.your-domain.com/static/*
// Settings: Cache Level: Cache Everything, Edge Cache TTL: 1 month

// 2. Cache API responses
// URL: *.your-domain.com/api/*
// Settings: Cache Level: Cache Everything, Edge Cache TTL: 5 minutes

// 3. Security
// URL: *.your-domain.com/*
// Settings: Security Level: High, Browser Cache TTL: 4 hours
```

### Application Optimization
```javascript
// Node.js Application Optimization
const cluster = require('cluster');
const numCPUs = require('os').cpus().length;

if (cluster.isMaster) {
  // Fork workers
  for (let i = 0; i < numCPUs; i++) {
    cluster.fork();
  }
  
  cluster.on('exit', (worker, code, signal) => {
    console.log(`Worker ${worker.process.pid} died`);
    cluster.fork();
  });
} else {
  // Worker process
  const express = require('express');
  const app = express();
  
  // Enable compression
  app.use(compression());
  
  // Enable caching
  app.use(express.static('public', {
    maxAge: '1d',
    etag: true
  }));
  
  // Rate limiting
  const rateLimit = require('express-rate-limit');
  app.use(rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100 // limit each IP to 100 requests per windowMs
  }));
  
  app.listen(3000);
}
```

## 📝 Checklist khôi phục

- [ ] Infrastructure setup với Terraform
- [ ] Server configuration với Ansible
- [ ] Database cluster setup
- [ ] Load balancer configuration
- [ ] Application deployment
- [ ] Monitoring setup
- [ ] Security configuration
- [ ] Backup strategy implementation
- [ ] Disaster recovery testing
- [ ] Performance optimization

## 🎯 Next Steps

1. **Multi-region deployment** cho global availability
2. **Advanced monitoring** với APM tools
3. **Security hardening** với WAF và DDoS protection
4. **Compliance** với SOC2, ISO27001
5. **Cost optimization** với auto-scaling

---

*Dự án này phù hợp cho doanh nghiệp lớn cần enterprise-grade application với high availability, scalability và security.*
