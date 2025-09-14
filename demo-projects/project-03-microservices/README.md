# Project 3: Microservices Architecture - Kubernetes + Docker

## 📋 Tổng quan dự án
- **Level**: Doanh nghiệp lớn
- **Stack**: Kubernetes + Docker + Microservices
- **Kiến trúc**: Microservices với service mesh
- **Mục đích**: Scalable microservices platform với high availability
- **Thời gian deploy**: 60-90 phút

## 🏗️ Kiến trúc hệ thống
```
Internet → Load Balancer (Nginx) → API Gateway (Kong) → Service Mesh (Istio)
                                                           ↓
    ┌─────────────────────────────────────────────────────────────┐
    │                    Microservices Layer                      │
    ├─────────────────┬─────────────────┬─────────────────────────┤
    │   User Service  │  Product Service│   Order Service         │
    │   (Node.js)     │   (Python)      │   (Go)                  │
    ├─────────────────┼─────────────────┼─────────────────────────┤
    │  Payment Service│  Notification   │   Analytics Service     │
    │   (Java)        │   Service (Go)  │   (Python)              │
    └─────────────────┴─────────────────┴─────────────────────────┘
                                                           ↓
    ┌─────────────────────────────────────────────────────────────┐
    │                    Data Layer                               │
    ├─────────────────┬─────────────────┬─────────────────────────┤
    │   PostgreSQL    │   MongoDB       │   Redis Cluster         │
    │   (Primary DB)  │   (Document DB) │   (Cache & Session)     │
    └─────────────────┴─────────────────┴─────────────────────────┘
```

## 📁 Cấu trúc dự án
```
project-03-microservices/
├── README.md
├── docker-compose.yml
├── k8s/
│   ├── namespace.yaml
│   ├── configmaps/
│   ├── secrets/
│   ├── services/
│   ├── deployments/
│   ├── ingress/
│   └── monitoring/
├── microservices/
│   ├── api-gateway/
│   ├── user-service/
│   ├── product-service/
│   ├── order-service/
│   ├── payment-service/
│   ├── notification-service/
│   └── analytics-service/
├── infrastructure/
│   ├── terraform/
│   ├── ansible/
│   └── helm/
├── monitoring/
│   ├── prometheus/
│   ├── grafana/
│   └── jaeger/
└── deploy/
    ├── deploy-k8s.sh
    ├── deploy-docker.sh
    └── monitoring/
```

## 🚀 Hướng dẫn Deploy

### Bước 1: Chuẩn bị Kubernetes Cluster
```bash
# Cài đặt kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Cài đặt minikube (cho local development)
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Cài đặt Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Cài đặt Istio
curl -L https://istio.io/downloadIstio | sh -
sudo mv istio-*/bin/istioctl /usr/local/bin/
```

### Bước 2: Khởi tạo Kubernetes Cluster
```bash
# Start minikube
minikube start --cpus=4 --memory=8192 --disk-size=20g

# Enable addons
minikube addons enable ingress
minikube addons enable metrics-server
minikube addons enable dashboard

# Verify cluster
kubectl get nodes
kubectl get pods --all-namespaces
```

### Bước 3: Deploy với Docker Compose (Development)
```bash
# Clone project
git clone <repository_url>
cd project-03-microservices

# Deploy all services
docker-compose up -d

# Check status
docker-compose ps
```

### Bước 4: Deploy với Kubernetes (Production)
```bash
# Create namespace
kubectl apply -f k8s/namespace.yaml

# Deploy secrets and configmaps
kubectl apply -f k8s/secrets/
kubectl apply -f k8s/configmaps/

# Deploy databases
kubectl apply -f k8s/deployments/databases/

# Deploy microservices
kubectl apply -f k8s/deployments/microservices/

# Deploy services
kubectl apply -f k8s/services/

# Deploy ingress
kubectl apply -f k8s/ingress/

# Deploy monitoring
kubectl apply -f k8s/monitoring/
```

### Bước 5: Cấu hình Service Mesh (Istio)
```bash
# Install Istio
istioctl install --set values.defaultRevision=default

# Enable sidecar injection for namespace
kubectl label namespace microservices istio-injection=enabled

# Deploy Istio addons
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.19/samples/addons/prometheus.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.19/samples/addons/grafana.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.19/samples/addons/jaeger.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.19/samples/addons/kiali.yaml
```

## 🔧 Cấu hình chi tiết

### API Gateway Configuration (Kong)
```yaml
# k8s/deployments/api-gateway.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
  namespace: microservices
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api-gateway
  template:
    metadata:
      labels:
        app: api-gateway
    spec:
      containers:
      - name: kong
        image: kong:3.0
        ports:
        - containerPort: 8000
        - containerPort: 8001
        env:
        - name: KONG_DATABASE
          value: "off"
        - name: KONG_DECLARATIVE_CONFIG
          value: "/kong/declarative/kong.yml"
        - name: KONG_PROXY_ACCESS_LOG
          value: "/dev/stdout"
        - name: KONG_ADMIN_ACCESS_LOG
          value: "/dev/stdout"
        - name: KONG_PROXY_ERROR_LOG
          value: "/dev/stderr"
        - name: KONG_ADMIN_ERROR_LOG
          value: "/dev/stderr"
        - name: KONG_ADMIN_LISTEN
          value: "0.0.0.0:8001"
        volumeMounts:
        - name: kong-config
          mountPath: /kong/declarative
      volumes:
      - name: kong-config
        configMap:
          name: kong-config
```

### User Service (Node.js)
```javascript
// microservices/user-service/src/app.js
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { Pool } = require('pg');
const redis = require('redis');

const app = express();

// Database connection
const pool = new Pool({
  host: process.env.POSTGRES_HOST || 'postgres-service',
  port: process.env.POSTGRES_PORT || 5432,
  database: process.env.POSTGRES_DB || 'users',
  user: process.env.POSTGRES_USER || 'postgres',
  password: process.env.POSTGRES_PASSWORD || 'password',
});

// Redis connection
const redisClient = redis.createClient({
  host: process.env.REDIS_HOST || 'redis-service',
  port: process.env.REDIS_PORT || 6379,
});

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use(limiter);

// Health check
app.get('/health', async (req, res) => {
  try {
    // Check database connection
    await pool.query('SELECT 1');
    
    // Check Redis connection
    await redisClient.ping();
    
    res.json({
      status: 'healthy',
      service: 'user-service',
      timestamp: new Date().toISOString(),
      uptime: process.uptime()
    });
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      service: 'user-service',
      error: error.message
    });
  }
});

// Routes
app.get('/api/users', async (req, res) => {
  try {
    const { rows } = await pool.query('SELECT * FROM users ORDER BY created_at DESC');
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Check cache first
    const cached = await redisClient.get(`user:${id}`);
    if (cached) {
      return res.json(JSON.parse(cached));
    }
    
    const { rows } = await pool.query('SELECT * FROM users WHERE id = $1', [id]);
    if (rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    // Cache for 5 minutes
    await redisClient.setex(`user:${id}`, 300, JSON.stringify(rows[0]));
    
    res.json(rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/users', async (req, res) => {
  try {
    const { name, email, phone } = req.body;
    const { rows } = await pool.query(
      'INSERT INTO users (name, email, phone) VALUES ($1, $2, $3) RETURNING *',
      [name, email, phone]
    );
    
    // Invalidate cache
    await redisClient.del('users:*');
    
    res.status(201).json(rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`User service running on port ${PORT}`);
});
```

### Product Service (Python)
```python
# microservices/product-service/app.py
from flask import Flask, jsonify, request
from flask_cors import CORS
import pymongo
import redis
import os
import logging
from datetime import datetime

app = Flask(__name__)
CORS(app)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# MongoDB connection
mongo_client = pymongo.MongoClient(
    host=os.getenv('MONGODB_HOST', 'mongodb-service'),
    port=int(os.getenv('MONGODB_PORT', 27017)),
    username=os.getenv('MONGODB_USER', 'root'),
    password=os.getenv('MONGODB_PASSWORD', 'password')
)
db = mongo_client[os.getenv('MONGODB_DB', 'products')]
products_collection = db.products

# Redis connection
redis_client = redis.Redis(
    host=os.getenv('REDIS_HOST', 'redis-service'),
    port=int(os.getenv('REDIS_PORT', 6379)),
    decode_responses=True
)

@app.route('/health')
def health_check():
    try:
        # Check MongoDB connection
        mongo_client.admin.command('ping')
        
        # Check Redis connection
        redis_client.ping()
        
        return jsonify({
            'status': 'healthy',
            'service': 'product-service',
            'timestamp': datetime.utcnow().isoformat(),
            'uptime': 'N/A'  # Would need to track this
        }), 200
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        return jsonify({
            'status': 'unhealthy',
            'service': 'product-service',
            'error': str(e)
        }), 503

@app.route('/api/products')
def get_products():
    try:
        # Check cache first
        cached = redis_client.get('products:all')
        if cached:
            return jsonify(cached)
        
        # Get from database
        products = list(products_collection.find({}, {'_id': 0}))
        
        # Cache for 5 minutes
        redis_client.setex('products:all', 300, jsonify(products).get_data(as_text=True))
        
        return jsonify(products)
    except Exception as e:
        logger.error(f"Error getting products: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/products/<product_id>')
def get_product(product_id):
    try:
        # Check cache first
        cached = redis_client.get(f'product:{product_id}')
        if cached:
            return jsonify(cached)
        
        # Get from database
        product = products_collection.find_one({'id': product_id}, {'_id': 0})
        if not product:
            return jsonify({'error': 'Product not found'}), 404
        
        # Cache for 10 minutes
        redis_client.setex(f'product:{product_id}', 600, jsonify(product).get_data(as_text=True))
        
        return jsonify(product)
    except Exception as e:
        logger.error(f"Error getting product {product_id}: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/products', methods=['POST'])
def create_product():
    try:
        data = request.get_json()
        data['created_at'] = datetime.utcnow().isoformat()
        data['updated_at'] = datetime.utcnow().isoformat()
        
        result = products_collection.insert_one(data)
        
        # Invalidate cache
        redis_client.delete('products:all')
        
        return jsonify({'id': str(result.inserted_id), 'message': 'Product created'}), 201
    except Exception as e:
        logger.error(f"Error creating product: {str(e)}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.getenv('PORT', 5000)))
```

### Order Service (Go)
```go
// microservices/order-service/main.go
package main

import (
    "encoding/json"
    "fmt"
    "log"
    "net/http"
    "os"
    "strconv"
    "time"

    "github.com/gin-gonic/gin"
    "github.com/go-redis/redis/v8"
    "gorm.io/driver/postgres"
    "gorm.io/gorm"
)

type Order struct {
    ID        uint      `json:"id" gorm:"primaryKey"`
    UserID    uint      `json:"user_id"`
    ProductID uint      `json:"product_id"`
    Quantity  int       `json:"quantity"`
    Total     float64   `json:"total"`
    Status    string    `json:"status"`
    CreatedAt time.Time `json:"created_at"`
    UpdatedAt time.Time `json:"updated_at"`
}

type OrderService struct {
    db    *gorm.DB
    redis *redis.Client
}

func NewOrderService() *OrderService {
    // Database connection
    dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=disable",
        getEnv("POSTGRES_HOST", "postgres-service"),
        getEnv("POSTGRES_USER", "postgres"),
        getEnv("POSTGRES_PASSWORD", "password"),
        getEnv("POSTGRES_DB", "orders"),
        getEnv("POSTGRES_PORT", "5432"),
    )
    
    db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
    if err != nil {
        log.Fatal("Failed to connect to database:", err)
    }
    
    // Auto migrate
    db.AutoMigrate(&Order{})
    
    // Redis connection
    rdb := redis.NewClient(&redis.Options{
        Addr: fmt.Sprintf("%s:%s",
            getEnv("REDIS_HOST", "redis-service"),
            getEnv("REDIS_PORT", "6379"),
        ),
    })
    
    return &OrderService{
        db:    db,
        redis: rdb,
    }
}

func (s *OrderService) HealthCheck(c *gin.Context) {
    // Check database
    sqlDB, err := s.db.DB()
    if err != nil {
        c.JSON(503, gin.H{"status": "unhealthy", "error": err.Error()})
        return
    }
    
    if err := sqlDB.Ping(); err != nil {
        c.JSON(503, gin.H{"status": "unhealthy", "error": err.Error()})
        return
    }
    
    // Check Redis
    if err := s.redis.Ping(c.Request.Context()).Err(); err != nil {
        c.JSON(503, gin.H{"status": "unhealthy", "error": err.Error()})
        return
    }
    
    c.JSON(200, gin.H{
        "status":    "healthy",
        "service":   "order-service",
        "timestamp": time.Now().UTC().Format(time.RFC3339),
    })
}

func (s *OrderService) GetOrders(c *gin.Context) {
    var orders []Order
    
    // Check cache first
    cached, err := s.redis.Get(c.Request.Context(), "orders:all").Result()
    if err == nil {
        c.Data(200, "application/json", []byte(cached))
        return
    }
    
    // Get from database
    if err := s.db.Find(&orders).Error; err != nil {
        c.JSON(500, gin.H{"error": err.Error()})
        return
    }
    
    // Cache for 5 minutes
    ordersJSON, _ := json.Marshal(orders)
    s.redis.Set(c.Request.Context(), "orders:all", ordersJSON, 5*time.Minute)
    
    c.JSON(200, orders)
}

func (s *OrderService) GetOrder(c *gin.Context) {
    id, err := strconv.Atoi(c.Param("id"))
    if err != nil {
        c.JSON(400, gin.H{"error": "Invalid order ID"})
        return
    }
    
    // Check cache first
    cached, err := s.redis.Get(c.Request.Context(), fmt.Sprintf("order:%d", id)).Result()
    if err == nil {
        c.Data(200, "application/json", []byte(cached))
        return
    }
    
    var order Order
    if err := s.db.First(&order, id).Error; err != nil {
        c.JSON(404, gin.H{"error": "Order not found"})
        return
    }
    
    // Cache for 10 minutes
    orderJSON, _ := json.Marshal(order)
    s.redis.Set(c.Request.Context(), fmt.Sprintf("order:%d", id), orderJSON, 10*time.Minute)
    
    c.JSON(200, order)
}

func (s *OrderService) CreateOrder(c *gin.Context) {
    var order Order
    if err := c.ShouldBindJSON(&order); err != nil {
        c.JSON(400, gin.H{"error": err.Error()})
        return
    }
    
    order.CreatedAt = time.Now()
    order.UpdatedAt = time.Now()
    
    if err := s.db.Create(&order).Error; err != nil {
        c.JSON(500, gin.H{"error": err.Error()})
        return
    }
    
    // Invalidate cache
    s.redis.Del(c.Request.Context(), "orders:all")
    
    c.JSON(201, order)
}

func getEnv(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}

func main() {
    service := NewOrderService()
    
    r := gin.Default()
    
    // Middleware
    r.Use(gin.Logger())
    r.Use(gin.Recovery())
    
    // Routes
    r.GET("/health", service.HealthCheck)
    r.GET("/api/orders", service.GetOrders)
    r.GET("/api/orders/:id", service.GetOrder)
    r.POST("/api/orders", service.CreateOrder)
    
    port := getEnv("PORT", "5000")
    log.Printf("Order service running on port %s", port)
    log.Fatal(r.Run(":" + port))
}
```

## 📊 Monitoring và Observability

### Prometheus Configuration
```yaml
# k8s/monitoring/prometheus-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: microservices
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      evaluation_interval: 15s

    rule_files:
      - "alert_rules.yml"

    alerting:
      alertmanagers:
        - static_configs:
            - targets:
              - alertmanager:9093

    scrape_configs:
      - job_name: 'prometheus'
        static_configs:
          - targets: ['localhost:9090']

      - job_name: 'kubernetes-pods'
        kubernetes_sd_configs:
          - role: pod
        relabel_configs:
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
            action: keep
            regex: true
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
            action: replace
            target_label: __metrics_path__
            regex: (.+)
          - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
            action: replace
            regex: ([^:]+)(?::\d+)?;(\d+)
            replacement: $1:$2
            target_label: __address__
          - action: labelmap
            regex: __meta_kubernetes_pod_label_(.+)
          - source_labels: [__meta_kubernetes_namespace]
            action: replace
            target_label: kubernetes_namespace
          - source_labels: [__meta_kubernetes_pod_name]
            action: replace
            target_label: kubernetes_pod_name

      - job_name: 'microservices'
        static_configs:
          - targets:
            - 'user-service:3000'
            - 'product-service:5000'
            - 'order-service:5000'
            - 'payment-service:8080'
            - 'notification-service:3000'
            - 'analytics-service:8000'
```

### Grafana Dashboards
```json
{
  "dashboard": {
    "title": "Microservices Overview",
    "panels": [
      {
        "title": "Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total[5m])) by (service)",
            "legendFormat": "{{service}}"
          }
        ]
      },
      {
        "title": "Response Time",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service))",
            "legendFormat": "{{service}} p95"
          }
        ]
      },
      {
        "title": "Error Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total{status=~\"5..\"}[5m])) by (service)",
            "legendFormat": "{{service}} errors"
          }
        ]
      }
    ]
  }
}
```

## 🚨 Troubleshooting

### Common Issues
1. **Pod startup failures**: Kiểm tra resource limits và health checks
2. **Service discovery issues**: Verify service names và namespaces
3. **Database connection problems**: Check secrets và network policies
4. **Memory/CPU limits**: Monitor resource usage và adjust limits

### Debug Commands
```bash
# Check pod status
kubectl get pods -n microservices

# View pod logs
kubectl logs -f deployment/user-service -n microservices

# Check service endpoints
kubectl get endpoints -n microservices

# Check ingress
kubectl get ingress -n microservices

# Port forward for local testing
kubectl port-forward service/api-gateway 8080:8000 -n microservices
```

## 📈 Scaling và Performance

### Horizontal Pod Autoscaler
```yaml
# k8s/hpa/user-service-hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: user-service-hpa
  namespace: microservices
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: user-service
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### Service Mesh Configuration
```yaml
# k8s/istio/virtual-service.yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: microservices-vs
  namespace: microservices
spec:
  hosts:
  - api-gateway
  http:
  - match:
    - uri:
        prefix: /api/users
    route:
    - destination:
        host: user-service
        port:
          number: 3000
  - match:
    - uri:
        prefix: /api/products
    route:
    - destination:
        host: product-service
        port:
          number: 5000
  - match:
    - uri:
        prefix: /api/orders
    route:
    - destination:
        host: order-service
        port:
          number: 5000
```

## 📝 Checklist khôi phục

- [ ] Kiểm tra Kubernetes cluster status
- [ ] Deploy namespace và RBAC
- [ ] Deploy databases (PostgreSQL, MongoDB, Redis)
- [ ] Deploy microservices
- [ ] Deploy API Gateway
- [ ] Deploy monitoring stack
- [ ] Configure service mesh
- [ ] Test service communication
- [ ] Setup load balancing
- [ ] Configure auto-scaling

## 🎯 Next Steps

1. **CI/CD Pipeline**: GitOps với ArgoCD
2. **Service Mesh**: Advanced Istio configuration
3. **Security**: Network policies và service mesh security
4. **Backup**: Database backup strategies
5. **Disaster Recovery**: Multi-cluster setup

---

*Dự án này phù hợp cho doanh nghiệp lớn cần scalable microservices platform với high availability và advanced monitoring.*
