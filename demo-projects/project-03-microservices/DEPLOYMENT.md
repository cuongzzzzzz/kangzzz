# Microservices Demo - Deployment Guide

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- Kubernetes cluster (for K8s deployment)
- kubectl (for K8s deployment)
- Helm (for K8s deployment)

### Docker Compose Deployment (Recommended for Development)

1. **Clone and navigate to the project:**
   ```bash
   git clone <repository_url>
   cd project-03-microservices
   ```

2. **Deploy all services:**
   ```bash
   ./deploy/deploy-docker.sh
   ```

3. **Access the services:**
   - API Gateway: http://localhost:8000
   - Grafana: http://localhost:3000 (admin/admin123)
   - Prometheus: http://localhost:9090
   - Jaeger: http://localhost:16686

### Kubernetes Deployment (Production)

1. **Create namespace and secrets:**
   ```bash
   kubectl apply -f k8s/namespace.yaml
   kubectl apply -f k8s/secrets/
   ```

2. **Deploy databases:**
   ```bash
   kubectl apply -f k8s/deployments/postgres.yaml
   kubectl apply -f k8s/deployments/mongodb.yaml
   kubectl apply -f k8s/deployments/redis.yaml
   ```

3. **Deploy microservices:**
   ```bash
   kubectl apply -f k8s/deployments/
   ```

4. **Deploy monitoring:**
   ```bash
   kubectl apply -f k8s/monitoring/
   ```

5. **Deploy ingress:**
   ```bash
   kubectl apply -f k8s/ingress/
   ```

## 📊 Service Architecture

```
Internet → Nginx → Kong API Gateway → Microservices
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

## 🔧 Service Details

### User Service (Node.js + Express)
- **Port:** 3000
- **Database:** PostgreSQL
- **Cache:** Redis
- **Health Check:** `/health`
- **API:** `/api/users`

### Product Service (Python + Flask)
- **Port:** 5000
- **Database:** MongoDB
- **Cache:** Redis
- **Health Check:** `/health`
- **API:** `/api/products`

### Order Service (Go + Gin)
- **Port:** 5000
- **Database:** PostgreSQL
- **Cache:** Redis
- **Health Check:** `/health`
- **API:** `/api/orders`

### Payment Service (Java + Spring Boot)
- **Port:** 8080
- **Database:** PostgreSQL
- **Cache:** Redis
- **Health Check:** `/actuator/health`
- **API:** `/api/payments`

### Notification Service (Go + Gin)
- **Port:** 3000
- **Database:** PostgreSQL
- **Cache:** Redis
- **Health Check:** `/health`
- **API:** `/api/notifications`

### Analytics Service (Python + FastAPI)
- **Port:** 8000
- **Database:** PostgreSQL
- **Cache:** Redis
- **Health Check:** `/health`
- **API:** `/api/analytics`

## 🗄️ Database Schema

### PostgreSQL Databases
- **users:** User management
- **orders:** Order processing
- **payments:** Payment tracking
- **notifications:** Notification queue
- **analytics:** Event tracking

### MongoDB Collections
- **products:** Product catalog
- **categories:** Product categories
- **product_reviews:** Customer reviews
- **product_inventory:** Stock management

### Redis Usage
- Session storage
- Caching layer
- Rate limiting
- Message queuing

## 📈 Monitoring & Observability

### Prometheus Metrics
- HTTP request metrics
- Database connection metrics
- Memory and CPU usage
- Custom business metrics

### Grafana Dashboards
- Service overview
- Performance metrics
- Error rates
- Resource utilization

### Jaeger Tracing
- Distributed tracing
- Request flow visualization
- Performance bottleneck identification

## 🔒 Security Features

- **API Gateway:** Rate limiting, CORS, request validation
- **Authentication:** JWT tokens (configurable)
- **Database:** Encrypted connections
- **Secrets:** Kubernetes secrets management
- **Network:** Service mesh security policies

## 🚨 Troubleshooting

### Common Issues

1. **Service startup failures:**
   ```bash
   # Check logs
   docker-compose logs [service-name]
   kubectl logs -f deployment/[service-name] -n microservices
   ```

2. **Database connection issues:**
   ```bash
   # Check database status
   docker-compose exec postgres pg_isready -U postgres
   kubectl get pods -n microservices | grep postgres
   ```

3. **Memory/CPU issues:**
   ```bash
   # Check resource usage
   docker stats
   kubectl top pods -n microservices
   ```

### Health Checks

All services provide health check endpoints:
- **Docker:** `http://localhost:[port]/health`
- **Kubernetes:** `kubectl get pods -n microservices`

### Logs

- **Docker:** `docker-compose logs -f [service-name]`
- **Kubernetes:** `kubectl logs -f deployment/[service-name] -n microservices`

## 📝 API Documentation

### User Service
```bash
# Get all users
GET /api/users

# Get user by ID
GET /api/users/{id}

# Create user
POST /api/users
{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+1-555-0101"
}

# Update user
PUT /api/users/{id}

# Delete user
DELETE /api/users/{id}
```

### Product Service
```bash
# Get all products
GET /api/products

# Get product by ID
GET /api/products/{id}

# Create product
POST /api/products
{
  "name": "MacBook Pro",
  "description": "Apple MacBook Pro 16-inch",
  "price": 2499.99,
  "category": "Laptops",
  "stock": 50,
  "sku": "MBP16-M2-512"
}
```

### Order Service
```bash
# Get all orders
GET /api/orders

# Get order by ID
GET /api/orders/{id}

# Create order
POST /api/orders
{
  "user_id": 1,
  "product_id": 1,
  "quantity": 2,
  "total": 99.98,
  "status": "pending"
}
```

## 🔄 Scaling

### Docker Compose
```bash
# Scale specific service
docker-compose up -d --scale user-service=3

# Scale all services
docker-compose up -d --scale user-service=3 --scale product-service=3
```

### Kubernetes
```bash
# Scale deployment
kubectl scale deployment user-service --replicas=3 -n microservices

# Auto-scaling (if HPA is configured)
kubectl apply -f k8s/hpa/
```

## 🧪 Testing

### Load Testing
```bash
# Install hey (load testing tool)
go install github.com/rakyll/hey@latest

# Test API Gateway
hey -n 1000 -c 10 http://localhost:8000/api/users

# Test specific service
hey -n 1000 -c 10 http://localhost:3001/api/users
```

### Integration Testing
```bash
# Run integration tests
docker-compose exec user-service npm test
docker-compose exec product-service python -m pytest
```

## 📚 Additional Resources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kong API Gateway](https://docs.konghq.com/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Jaeger Documentation](https://www.jaegertracing.io/docs/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
