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
	"gopkg.in/gomail.v2"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

// Notification represents a notification in the system
type Notification struct {
	ID        uint       `json:"id" gorm:"primaryKey"`
	UserID    uint       `json:"user_id" gorm:"not null"`
	Type      string     `json:"type" gorm:"not null"`
	Title     string     `json:"title" gorm:"not null"`
	Message   string     `json:"message" gorm:"not null"`
	Channel   string     `json:"channel" gorm:"not null"` // email, sms, push
	Status    string     `json:"status" gorm:"default:'pending'"`
	SentAt    *time.Time `json:"sent_at"`
	CreatedAt time.Time  `json:"created_at"`
	UpdatedAt time.Time  `json:"updated_at"`
}

// NotificationService handles notification operations
type NotificationService struct {
	db     *gorm.DB
	redis  *redis.Client
	logger *logrus.Logger
	mailer *gomail.Dialer
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

	notificationsSent = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "notifications_sent_total",
			Help: "Total number of notifications sent",
		},
		[]string{"type", "channel", "status"},
	)
)

func init() {
	prometheus.MustRegister(httpRequestsTotal)
	prometheus.MustRegister(httpRequestDuration)
	prometheus.MustRegister(notificationsSent)
}

// NewNotificationService creates a new notification service instance
func NewNotificationService() *NotificationService {
	logger := logrus.New()
	logger.SetFormatter(&logrus.JSONFormatter{})
	logger.SetLevel(logrus.InfoLevel)

	// Database connection
	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=disable",
		getEnv("POSTGRES_HOST", "postgres-service"),
		getEnv("POSTGRES_USER", "postgres"),
		getEnv("POSTGRES_PASSWORD", "password"),
		getEnv("POSTGRES_DB", "notifications"),
		getEnv("POSTGRES_PORT", "5432"),
	)

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		logger.Fatal("Failed to connect to database:", err)
	}

	// Auto migrate
	if err := db.AutoMigrate(&Notification{}); err != nil {
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

	// Email configuration
	mailer := gomail.NewDialer(
		getEnv("SMTP_HOST", "smtp.gmail.com"),
		getEnvAsInt("SMTP_PORT", 587),
		getEnv("SMTP_USER", ""),
		getEnv("SMTP_PASS", ""),
	)

	return &NotificationService{
		db:     db,
		redis:  rdb,
		logger: logger,
		mailer: mailer,
	}
}

// HealthCheck returns the health status of the service
func (s *NotificationService) HealthCheck(c *gin.Context) {
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
		"service":   "notification-service",
		"timestamp": time.Now().UTC().Format(time.RFC3339),
		"version":   "1.0.0",
	})
}

// GetNotifications returns all notifications
func (s *NotificationService) GetNotifications(c *gin.Context) {
	var notifications []Notification

	// Check cache first
	ctx := s.redis.Context()
	cached, err := s.redis.Get(ctx, "notifications:all").Result()
	if err == nil {
		s.logger.Info("Notifications retrieved from cache")
		c.Data(200, "application/json", []byte(cached))
		return
	}

	// Get from database
	if err := s.db.Find(&notifications).Error; err != nil {
		s.logger.Error("Failed to get notifications:", err)
		c.JSON(500, gin.H{"error": "Internal server error"})
		return
	}

	// Cache for 5 minutes
	notificationsJSON, _ := json.Marshal(notifications)
	s.redis.Set(ctx, "notifications:all", notificationsJSON, 5*time.Minute)

	s.logger.Info(fmt.Sprintf("Retrieved %d notifications from database", len(notifications)))
	c.JSON(200, notifications)
}

// GetNotification returns a specific notification by ID
func (s *NotificationService) GetNotification(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(400, gin.H{"error": "Invalid notification ID"})
		return
	}

	// Check cache first
	ctx := s.redis.Context()
	cached, err := s.redis.Get(ctx, fmt.Sprintf("notification:%d", id)).Result()
	if err == nil {
		s.logger.Info(fmt.Sprintf("Notification %d retrieved from cache", id))
		c.Data(200, "application/json", []byte(cached))
		return
	}

	var notification Notification
	if err := s.db.First(&notification, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(404, gin.H{"error": "Notification not found"})
			return
		}
		s.logger.Error(fmt.Sprintf("Failed to get notification %d:", id), err)
		c.JSON(500, gin.H{"error": "Internal server error"})
		return
	}

	// Cache for 10 minutes
	notificationJSON, _ := json.Marshal(notification)
	s.redis.Set(ctx, fmt.Sprintf("notification:%d", id), notificationJSON, 10*time.Minute)

	s.logger.Info(fmt.Sprintf("Notification %d retrieved from database", id))
	c.JSON(200, notification)
}

// CreateNotification creates a new notification
func (s *NotificationService) CreateNotification(c *gin.Context) {
	var notification Notification
	if err := c.ShouldBindJSON(&notification); err != nil {
		c.JSON(400, gin.H{"error": "Invalid request data", "details": err.Error()})
		return
	}

	// Validate required fields
	if notification.UserID == 0 || notification.Type == "" || notification.Title == "" || notification.Message == "" {
		c.JSON(400, gin.H{"error": "Missing required fields: user_id, type, title, and message must be provided"})
		return
	}

	// Set default values
	if notification.Channel == "" {
		notification.Channel = "email"
	}
	if notification.Status == "" {
		notification.Status = "pending"
	}

	notification.CreatedAt = time.Now()
	notification.UpdatedAt = time.Now()

	if err := s.db.Create(&notification).Error; err != nil {
		s.logger.Error("Failed to create notification:", err)
		c.JSON(500, gin.H{"error": "Internal server error"})
		return
	}

	// Invalidate cache
	ctx := s.redis.Context()
	s.redis.Del(ctx, "notifications:all")

	s.logger.Info(fmt.Sprintf("Notification created with ID: %d", notification.ID))
	c.JSON(201, notification)
}

// SendNotification sends a notification
func (s *NotificationService) SendNotification(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(400, gin.H{"error": "Invalid notification ID"})
		return
	}

	var notification Notification
	if err := s.db.First(&notification, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(404, gin.H{"error": "Notification not found"})
			return
		}
		s.logger.Error(fmt.Sprintf("Failed to get notification %d:", id), err)
		c.JSON(500, gin.H{"error": "Internal server error"})
		return
	}

	// Send notification based on channel
	var sendErr error
	switch notification.Channel {
	case "email":
		sendErr = s.sendEmail(notification)
	case "sms":
		sendErr = s.sendSMS(notification)
	case "push":
		sendErr = s.sendPush(notification)
	default:
		c.JSON(400, gin.H{"error": "Unsupported notification channel"})
		return
	}

	if sendErr != nil {
		notification.Status = "failed"
		notificationsSent.WithLabelValues(notification.Type, notification.Channel, "failed").Inc()
		s.logger.Error(fmt.Sprintf("Failed to send notification %d:", id), sendErr)
	} else {
		now := time.Now()
		notification.Status = "sent"
		notification.SentAt = &now
		notificationsSent.WithLabelValues(notification.Type, notification.Channel, "sent").Inc()
		s.logger.Info(fmt.Sprintf("Notification %d sent successfully", id))
	}

	notification.UpdatedAt = time.Now()
	s.db.Save(&notification)

	// Invalidate cache
	ctx := s.redis.Context()
	s.redis.Del(ctx, fmt.Sprintf("notification:%d", id))
	s.redis.Del(ctx, "notifications:all")

	c.JSON(200, notification)
}

// sendEmail sends an email notification
func (s *NotificationService) sendEmail(notification Notification) error {
	m := gomail.NewMessage()
	m.SetHeader("From", getEnv("SMTP_USER", "noreply@example.com"))
	m.SetHeader("To", fmt.Sprintf("user%d@example.com", notification.UserID)) // In real app, get from user service
	m.SetHeader("Subject", notification.Title)
	m.SetBody("text/html", notification.Message)

	return s.mailer.DialAndSend(m)
}

// sendSMS sends an SMS notification (mock implementation)
func (s *NotificationService) sendSMS(notification Notification) error {
	// Mock SMS sending - in real app, integrate with SMS provider
	s.logger.Info(fmt.Sprintf("SMS sent to user %d: %s", notification.UserID, notification.Message))
	return nil
}

// sendPush sends a push notification (mock implementation)
func (s *NotificationService) sendPush(notification Notification) error {
	// Mock push notification - in real app, integrate with FCM/APNS
	s.logger.Info(fmt.Sprintf("Push notification sent to user %d: %s", notification.UserID, notification.Message))
	return nil
}

// GetNotificationsByUser returns notifications for a specific user
func (s *NotificationService) GetNotificationsByUser(c *gin.Context) {
	userID, err := strconv.Atoi(c.Param("userId"))
	if err != nil {
		c.JSON(400, gin.H{"error": "Invalid user ID"})
		return
	}

	// Check cache first
	ctx := s.redis.Context()
	cached, err := s.redis.Get(ctx, fmt.Sprintf("notifications:user:%d", userID)).Result()
	if err == nil {
		s.logger.Info(fmt.Sprintf("Notifications for user %d retrieved from cache", userID))
		c.Data(200, "application/json", []byte(cached))
		return
	}

	var notifications []Notification
	if err := s.db.Where("user_id = ?", userID).Find(&notifications).Error; err != nil {
		s.logger.Error(fmt.Sprintf("Failed to get notifications for user %d:", userID), err)
		c.JSON(500, gin.H{"error": "Internal server error"})
		return
	}

	// Cache for 5 minutes
	notificationsJSON, _ := json.Marshal(notifications)
	s.redis.Set(ctx, fmt.Sprintf("notifications:user:%d", userID), notificationsJSON, 5*time.Minute)

	s.logger.Info(fmt.Sprintf("Retrieved %d notifications for user %d from database", len(notifications), userID))
	c.JSON(200, notifications)
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

// getEnvAsInt gets an environment variable as integer or returns a default value
func getEnvAsInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}

func main() {
	service := NewNotificationService()

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
	r.GET("/api/notifications", service.GetNotifications)
	r.GET("/api/notifications/:id", service.GetNotification)
	r.POST("/api/notifications", service.CreateNotification)
	r.POST("/api/notifications/:id/send", service.SendNotification)
	r.GET("/api/notifications/user/:userId", service.GetNotificationsByUser)

	// 404 handler
	r.NoRoute(func(c *gin.Context) {
		c.JSON(404, gin.H{"error": "Route not found"})
	})

	port := getEnv("PORT", "3000")
	service.logger.Info(fmt.Sprintf("Notification service running on port %s", port))

	if err := r.Run(":" + port); err != nil {
		service.logger.Fatal("Failed to start server:", err)
	}
}
