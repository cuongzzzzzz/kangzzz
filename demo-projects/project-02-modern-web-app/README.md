# Project 2: Modern Web App - Node.js + React + MongoDB

## 📋 Tổng quan dự án
- **Level**: Doanh nghiệp vừa
- **Stack**: MEAN (MongoDB + Express.js + Angular/React + Node.js)
- **Kiến trúc**: Full-stack JavaScript với API separation
- **Mục đích**: Modern web application với real-time features
- **Thời gian deploy**: 45-60 phút

## 🏗️ Kiến trúc hệ thống
```
Internet → Load Balancer (Nginx) → Frontend (React) → API Gateway (Express.js) → Microservices
                                                                                    ↓
                                                                              Database (MongoDB)
                                                                                    ↓
                                                                              Cache (Redis)
```

## 📁 Cấu trúc dự án
```
project-02-modern-web-app/
├── README.md
├── docker-compose.yml
├── docker-compose.prod.yml
├── frontend/
│   ├── package.json
│   ├── Dockerfile
│   ├── public/
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   ├── services/
│   │   └── utils/
│   └── nginx.conf
├── backend/
│   ├── package.json
│   ├── Dockerfile
│   ├── src/
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── routes/
│   │   ├── middleware/
│   │   └── services/
│   └── tests/
├── database/
│   ├── init-mongo.js
│   └── seed-data.js
├── nginx/
│   ├── nginx.conf
│   └── ssl/
├── redis/
│   └── redis.conf
└── deploy/
    ├── deploy.sh
    ├── deploy-prod.sh
    └── monitoring/
        ├── prometheus.yml
        └── grafana/
```

## 🚀 Hướng dẫn Deploy

### Bước 1: Chuẩn bị Server
```bash
# Cập nhật hệ thống
sudo apt update && sudo apt upgrade -y

# Cài đặt Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Cài đặt Docker và Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Cài đặt Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Cài đặt PM2 cho production
sudo npm install -g pm2

# Logout và login lại
```

### Bước 2: Clone và Setup Project
```bash
# Clone project
git clone <repository_url>
cd project-02-modern-web-app

# Cài đặt dependencies
cd frontend && npm install
cd ../backend && npm install
cd ..

# Tạo thư mục cần thiết
mkdir -p logs/nginx logs/backend logs/frontend
mkdir -p data/mongodb data/redis
mkdir -p ssl
```

### Bước 3: Cấu hình Environment
```bash
# Tạo file .env cho development
cat > .env << EOF
# Application Configuration
NODE_ENV=development
PORT=3000
FRONTEND_URL=http://localhost:3000
BACKEND_URL=http://localhost:5000

# Database Configuration
MONGODB_URI=mongodb://mongodb:27017/modernwebapp
MONGODB_DATABASE=modernwebapp

# Redis Configuration
REDIS_URL=redis://redis:6379
REDIS_PASSWORD=

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-here
JWT_EXPIRES_IN=7d

# Email Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password

# File Upload
UPLOAD_DIR=uploads
MAX_FILE_SIZE=10485760

# API Keys
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
EOF

# Tạo file .env.production
cp .env .env.production
sed -i 's/development/production/g' .env.production
sed -i 's/localhost/your-domain.com/g' .env.production
```

### Bước 4: Deploy Development Environment
```bash
# Build và start services
docker-compose up -d --build

# Kiểm tra status
docker-compose ps

# Xem logs
docker-compose logs -f
```

### Bước 5: Deploy Production Environment
```bash
# Sử dụng production compose file
docker-compose -f docker-compose.prod.yml up -d --build

# Kiểm tra status
docker-compose -f docker-compose.prod.yml ps
```

### Bước 6: Cấu hình Domain và SSL
```bash
# Cài đặt Certbot
sudo apt install certbot python3-certbot-nginx

# Cấu hình Nginx
sudo cp nginx/nginx.conf /etc/nginx/sites-available/modern-webapp
sudo ln -s /etc/nginx/sites-available/modern-webapp /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# Tạo SSL certificate
sudo certbot --nginx -d your-domain.com

# Test SSL
curl -I https://your-domain.com
```

## 🔧 Cấu hình chi tiết

### Frontend Configuration (React)
```javascript
// frontend/src/config/api.js
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000/api';

export const apiConfig = {
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
};

// frontend/src/services/api.js
import axios from 'axios';
import { apiConfig } from '../config/api';

const api = axios.create(apiConfig);

// Request interceptor
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export default api;
```

### Backend Configuration (Express.js)
```javascript
// backend/src/app.js
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const mongoose = require('mongoose');
const redis = require('redis');

const app = express();

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.FRONTEND_URL,
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use('/api/', limiter);

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Database connection
mongoose.connect(process.env.MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

// Redis connection
const redisClient = redis.createClient({
  url: process.env.REDIS_URL
});

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/users', require('./routes/users'));
app.use('/api/products', require('./routes/products'));

// Error handling
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: 'Something went wrong!' });
});

module.exports = app;
```

### Database Configuration (MongoDB)
```javascript
// database/init-mongo.js
db = db.getSiblingDB('modernwebapp');

// Create collections
db.createCollection('users');
db.createCollection('products');
db.createCollection('orders');
db.createCollection('categories');

// Create indexes
db.users.createIndex({ "email": 1 }, { unique: true });
db.users.createIndex({ "username": 1 }, { unique: true });
db.products.createIndex({ "name": "text", "description": "text" });
db.products.createIndex({ "category": 1 });
db.products.createIndex({ "price": 1 });
db.orders.createIndex({ "userId": 1 });
db.orders.createIndex({ "createdAt": -1 });

// Insert sample data
db.categories.insertMany([
  { name: 'Electronics', description: 'Electronic devices and accessories' },
  { name: 'Clothing', description: 'Fashion and apparel' },
  { name: 'Home & Garden', description: 'Home improvement supplies' },
  { name: 'Sports', description: 'Sports equipment and accessories' }
]);

db.products.insertMany([
  {
    name: 'MacBook Pro 16"',
    description: 'High-performance laptop for professionals',
    price: 2499.99,
    category: 'Electronics',
    stock: 50,
    images: ['https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=400'],
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    name: 'iPhone 15 Pro',
    description: 'Latest iPhone with advanced features',
    price: 999.99,
    category: 'Electronics',
    stock: 100,
    images: ['https://images.unsplash.com/photo-1592899677977-9c10b588e209?w=400'],
    createdAt: new Date(),
    updatedAt: new Date()
  }
]);
```

## 📊 Monitoring và Analytics

### Health Check Endpoints
```javascript
// backend/src/routes/health.js
const express = require('express');
const mongoose = require('mongoose');
const redis = require('redis');
const router = express.Router();

router.get('/health', async (req, res) => {
  const health = {
    status: 'OK',
    timestamp: new Date().toISOString(),
    services: {}
  };

  // Check MongoDB
  try {
    await mongoose.connection.db.admin().ping();
    health.services.mongodb = 'OK';
  } catch (error) {
    health.services.mongodb = 'ERROR';
    health.status = 'ERROR';
  }

  // Check Redis
  try {
    const redisClient = redis.createClient({ url: process.env.REDIS_URL });
    await redisClient.ping();
    health.services.redis = 'OK';
  } catch (error) {
    health.services.redis = 'ERROR';
    health.status = 'ERROR';
  }

  res.status(health.status === 'OK' ? 200 : 503).json(health);
});

module.exports = router;
```

### Prometheus Monitoring
```yaml
# monitoring/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['localhost:9100']

  - job_name: 'backend-api'
    static_configs:
      - targets: ['backend:5000']
    metrics_path: '/metrics'

  - job_name: 'mongodb-exporter'
    static_configs:
      - targets: ['mongodb-exporter:9216']
```

## 🚨 Troubleshooting

### Common Issues
1. **Port conflicts**: Kiểm tra ports 3000, 5000, 27017, 6379
2. **Memory issues**: Tăng memory limit cho Node.js containers
3. **Database connection**: Kiểm tra MongoDB và Redis connections
4. **CORS issues**: Cấu hình CORS cho frontend-backend communication

### Debug Commands
```bash
# Xem logs chi tiết
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f mongodb

# Vào container để debug
docker-compose exec backend bash
docker-compose exec frontend bash

# Kiểm tra database
docker-compose exec mongodb mongo modernwebapp --eval "db.stats()"

# Kiểm tra Redis
docker-compose exec redis redis-cli ping
```

## 📈 Performance Optimization

### Frontend Optimization
```javascript
// frontend/src/components/LazyComponent.js
import React, { Suspense, lazy } from 'react';

const LazyComponent = lazy(() => import('./HeavyComponent'));

const App = () => (
  <Suspense fallback={<div>Loading...</div>}>
    <LazyComponent />
  </Suspense>
);

// frontend/src/utils/cache.js
class Cache {
  constructor(ttl = 300000) { // 5 minutes
    this.cache = new Map();
    this.ttl = ttl;
  }

  set(key, value) {
    this.cache.set(key, {
      value,
      timestamp: Date.now()
    });
  }

  get(key) {
    const item = this.cache.get(key);
    if (!item) return null;

    if (Date.now() - item.timestamp > this.ttl) {
      this.cache.delete(key);
      return null;
    }

    return item.value;
  }
}

export default new Cache();
```

### Backend Optimization
```javascript
// backend/src/middleware/cache.js
const redis = require('redis');

const redisClient = redis.createClient({
  url: process.env.REDIS_URL
});

const cache = (duration = 300) => {
  return async (req, res, next) => {
    const key = `cache:${req.originalUrl}`;
    
    try {
      const cached = await redisClient.get(key);
      if (cached) {
        return res.json(JSON.parse(cached));
      }
      
      res.sendResponse = res.json;
      res.json = (body) => {
        redisClient.setex(key, duration, JSON.stringify(body));
        res.sendResponse(body);
      };
      
      next();
    } catch (error) {
      next();
    }
  };
};

module.exports = cache;
```

## 📝 Checklist khôi phục

- [ ] Kiểm tra system requirements
- [ ] Cài đặt dependencies
- [ ] Cấu hình environment variables
- [ ] Build và start containers
- [ ] Kiểm tra database connections
- [ ] Test API endpoints
- [ ] Cấu hình domain và SSL
- [ ] Setup monitoring
- [ ] Test production deployment
- [ ] Document deployment process

## 🎯 Next Steps

1. **CI/CD Pipeline**: GitHub Actions hoặc GitLab CI
2. **Container Orchestration**: Kubernetes deployment
3. **Microservices**: Split monolith thành microservices
4. **Event Streaming**: Apache Kafka cho real-time events
5. **Advanced Monitoring**: ELK stack cho logging

---

*Dự án này phù hợp cho doanh nghiệp vừa cần modern web application với real-time features và scalability.*
