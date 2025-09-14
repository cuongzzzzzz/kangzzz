package main

import (
	"encoding/json"
	"fmt"
	"os"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/go-redis/redis/v8"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/sirupsen/logrus"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

// Order represents an order in the system
type Order struct {
	ID        uint      `json:"id" gorm:"primaryKey"`
	UserID    uint      `json:"user_id" gorm:"not null"`
	ProductID uint      `json:"product_id" gorm:"not null"`
	Quantity  int       `json:"quantity" gorm:"not null"`
	Total     float64   `json:"total" gorm:"not null"`
	Status    string    `json:"status" gorm:"default:'pending'"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// OrderService handles order operations
type OrderService struct {
	db     *gorm.DB
	redis  *redis.Client
	logger *logrus.Logger
}

// Prometheus metrics
var (
	httpRequestsTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "http_requests_total",
			Help: "Total number of HTTP requests",
		},
		[]string{"method", "endpoint", "status"},
	)

	httpRequestDuration = prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name: "http_request_duration_seconds",
			Help: "Duration of HTTP requests",
		},
		[]string{"method", "endpoint"},
	)
)

func init() {
	prometheus.MustRegister(httpRequestsTotal)
	prometheus.MustRegister(httpRequestDuration)
}

// NewOrderService creates a new order service instance
func NewOrderService() *OrderService {
	logger := logrus.New()
	logger.SetFormatter(&logrus.JSONFormatter{})
	logger.SetLevel(logrus.InfoLevel)

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
		logger.Fatal("Failed to connect to database:", err)
	}

	// Auto migrate
	if err := db.AutoMigrate(&Order{}); err != nil {
		logger.Fatal("Failed to migrate database:", err)
	}

	// Redis connection
	rdb := redis.NewClient(&redis.Options{
		Addr: fmt.Sprintf("%s:%s",
			getEnv("REDIS_HOST", "redis-service"),
			getEnv("REDIS_PORT", "6379"),
		),
		Password: "",
		DB:       0,
	})

	// Test Redis connection
	ctx := rdb.Context()
	if err := rdb.Ping(ctx).Err(); err != nil {
		logger.Warn("Failed to connect to Redis:", err)
	} else {
		logger.Info("Connected to Redis")
	}

	return &OrderService{
		db:     db,
		redis:  rdb,
		logger: logger,
	}
}

// HealthCheck returns the health status of the service
func (s *OrderService) HealthCheck(c *gin.Context) {
	// Check database
	sqlDB, err := s.db.DB()
	if err != nil {
		s.logger.Error("Database health check failed:", err)
		c.JSON(503, gin.H{"status": "unhealthy", "error": err.Error()})
		return
	}

	if err := sqlDB.Ping(); err != nil {
		s.logger.Error("Database ping failed:", err)
		c.JSON(503, gin.H{"status": "unhealthy", "error": err.Error()})
		return
	}

	// Check Redis
	ctx := s.redis.Context()
	if err := s.redis.Ping(ctx).Err(); err != nil {
		s.logger.Warn("Redis ping failed:", err)
		// Don't fail health check for Redis, just log warning
	}

	c.JSON(200, gin.H{
		"status":    "healthy",
		"service":   "order-service",
		"timestamp": time.Now().UTC().Format(time.RFC3339),
		"version":   "1.0.0",
	})
}

// GetOrders returns all orders
func (s *OrderService) GetOrders(c *gin.Context) {
	var orders []Order

	// Check cache first
	ctx := s.redis.Context()
	cached, err := s.redis.Get(ctx, "orders:all").Result()
	if err == nil {
		s.logger.Info("Orders retrieved from cache")
		c.Data(200, "application/json", []byte(cached))
		return
	}

	// Get from database
	if err := s.db.Find(&orders).Error; err != nil {
		s.logger.Error("Failed to get orders:", err)
		c.JSON(500, gin.H{"error": "Internal server error"})
		return
	}

	// Cache for 5 minutes
	ordersJSON, _ := json.Marshal(orders)
	s.redis.Set(ctx, "orders:all", ordersJSON, 5*time.Minute)

	s.logger.Info(fmt.Sprintf("Retrieved %d orders from database", len(orders)))
	c.JSON(200, orders)
}

// GetOrder returns a specific order by ID
func (s *OrderService) GetOrder(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(400, gin.H{"error": "Invalid order ID"})
		return
	}

	// Check cache first
	ctx := s.redis.Context()
	cached, err := s.redis.Get(ctx, fmt.Sprintf("order:%d", id)).Result()
	if err == nil {
		s.logger.Info(fmt.Sprintf("Order %d retrieved from cache", id))
		c.Data(200, "application/json", []byte(cached))
		return
	}

	var order Order
	if err := s.db.First(&order, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(404, gin.H{"error": "Order not found"})
			return
		}
		s.logger.Error(fmt.Sprintf("Failed to get order %d:", id), err)
		c.JSON(500, gin.H{"error": "Internal server error"})
		return
	}

	// Cache for 10 minutes
	orderJSON, _ := json.Marshal(order)
	s.redis.Set(ctx, fmt.Sprintf("order:%d", id), orderJSON, 10*time.Minute)

	s.logger.Info(fmt.Sprintf("Order %d retrieved from database", id))
	c.JSON(200, order)
}

// CreateOrder creates a new order
func (s *OrderService) CreateOrder(c *gin.Context) {
	var order Order
	if err := c.ShouldBindJSON(&order); err != nil {
		c.JSON(400, gin.H{"error": "Invalid request data", "details": err.Error()})
		return
	}

	// Validate required fields
	if order.UserID == 0 || order.ProductID == 0 || order.Quantity <= 0 {
		c.JSON(400, gin.H{"error": "Missing required fields: user_id, product_id, and quantity must be provided"})
		return
	}

	// Set default status if not provided
	if order.Status == "" {
		order.Status = "pending"
	}

	order.CreatedAt = time.Now()
	order.UpdatedAt = time.Now()

	if err := s.db.Create(&order).Error; err != nil {
		s.logger.Error("Failed to create order:", err)
		c.JSON(500, gin.H{"error": "Internal server error"})
		return
	}

	// Invalidate cache
	ctx := s.redis.Context()
	s.redis.Del(ctx, "orders:all")

	s.logger.Info(fmt.Sprintf("Order created with ID: %d", order.ID))
	c.JSON(201, order)
}

// UpdateOrder updates an existing order
func (s *OrderService) UpdateOrder(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(400, gin.H{"error": "Invalid order ID"})
		return
	}

	var order Order
	if err := s.db.First(&order, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(404, gin.H{"error": "Order not found"})
			return
		}
		s.logger.Error(fmt.Sprintf("Failed to get order %d:", id), err)
		c.JSON(500, gin.H{"error": "Internal server error"})
		return
	}

	var updateData Order
	if err := c.ShouldBindJSON(&updateData); err != nil {
		c.JSON(400, gin.H{"error": "Invalid request data", "details": err.Error()})
		return
	}

	// Update fields
	if updateData.Quantity > 0 {
		order.Quantity = updateData.Quantity
	}
	if updateData.Total > 0 {
		order.Total = updateData.Total
	}
	if updateData.Status != "" {
		order.Status = updateData.Status
	}

	order.UpdatedAt = time.Now()

	if err := s.db.Save(&order).Error; err != nil {
		s.logger.Error(fmt.Sprintf("Failed to update order %d:", id), err)
		c.JSON(500, gin.H{"error": "Internal server error"})
		return
	}

	// Invalidate cache
	ctx := s.redis.Context()
	s.redis.Del(ctx, fmt.Sprintf("order:%d", id))
	s.redis.Del(ctx, "orders:all")

	s.logger.Info(fmt.Sprintf("Order %d updated", id))
	c.JSON(200, order)
}

// DeleteOrder deletes an order
func (s *OrderService) DeleteOrder(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(400, gin.H{"error": "Invalid order ID"})
		return
	}

	var order Order
	if err := s.db.First(&order, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(404, gin.H{"error": "Order not found"})
			return
		}
		s.logger.Error(fmt.Sprintf("Failed to get order %d:", id), err)
		c.JSON(500, gin.H{"error": "Internal server error"})
		return
	}

	if err := s.db.Delete(&order).Error; err != nil {
		s.logger.Error(fmt.Sprintf("Failed to delete order %d:", id), err)
		c.JSON(500, gin.H{"error": "Internal server error"})
		return
	}

	// Invalidate cache
	ctx := s.redis.Context()
	s.redis.Del(ctx, fmt.Sprintf("order:%d", id))
	s.redis.Del(ctx, "orders:all")

	s.logger.Info(fmt.Sprintf("Order %d deleted", id))
	c.JSON(200, gin.H{"message": "Order deleted successfully"})
}

// Metrics middleware
func metricsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()

		c.Next()

		duration := time.Since(start).Seconds()
		httpRequestDuration.WithLabelValues(c.Request.Method, c.FullPath()).Observe(duration)
		httpRequestsTotal.WithLabelValues(c.Request.Method, c.FullPath(), fmt.Sprintf("%d", c.Writer.Status())).Inc()
	}
}

// getEnv gets an environment variable or returns a default value
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func main() {
	service := NewOrderService()

	// Set Gin mode
	if getEnv("GIN_MODE", "release") == "release" {
		gin.SetMode(gin.ReleaseMode)
	}

	r := gin.Default()

	// Middleware
	r.Use(gin.Logger())
	r.Use(gin.Recovery())
	r.Use(metricsMiddleware())

	// Routes
	r.GET("/health", service.HealthCheck)
	r.GET("/metrics", gin.WrapH(promhttp.Handler()))
	r.GET("/api/orders", service.GetOrders)
	r.GET("/api/orders/:id", service.GetOrder)
	r.POST("/api/orders", service.CreateOrder)
	r.PUT("/api/orders/:id", service.UpdateOrder)
	r.DELETE("/api/orders/:id", service.DeleteOrder)

	// 404 handler
	r.NoRoute(func(c *gin.Context) {
		c.JSON(404, gin.H{"error": "Route not found"})
	})

	port := getEnv("PORT", "5000")
	service.logger.Info(fmt.Sprintf("Order service running on port %s", port))

	if err := r.Run(":" + port); err != nil {
		service.logger.Fatal("Failed to start server:", err)
	}
}
