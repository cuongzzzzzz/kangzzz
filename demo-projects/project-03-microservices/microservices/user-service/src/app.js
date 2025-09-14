const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { Pool } = require('pg');
const redis = require('redis');
const Joi = require('joi');
const winston = require('winston');
require('dotenv').config();

const app = express();

// Configure logger
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: '/var/log/user-service.log' })
  ]
});

// Database connection
const pool = new Pool({
  host: process.env.POSTGRES_HOST || 'postgres-service',
  port: process.env.POSTGRES_PORT || 5432,
  database: process.env.POSTGRES_DB || 'users',
  user: process.env.POSTGRES_USER || 'postgres',
  password: process.env.POSTGRES_PASSWORD || 'password',
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Redis connection
const redisClient = redis.createClient({
  host: process.env.REDIS_HOST || 'redis-service',
  port: process.env.REDIS_PORT || 6379,
  retry_strategy: (options) => {
    if (options.error && options.error.code === 'ECONNREFUSED') {
      logger.error('Redis connection refused');
      return new Error('Redis connection refused');
    }
    if (options.total_retry_time > 1000 * 60 * 60) {
      logger.error('Redis retry time exhausted');
      return new Error('Retry time exhausted');
    }
    if (options.attempt > 10) {
      logger.error('Redis max retry attempts reached');
      return undefined;
    }
    return Math.min(options.attempt * 100, 3000);
  }
});

redisClient.on('error', (err) => {
  logger.error('Redis Client Error:', err);
});

redisClient.on('connect', () => {
  logger.info('Redis Client Connected');
});

// Validation schemas
const userSchema = Joi.object({
  name: Joi.string().min(2).max(100).required(),
  email: Joi.string().email().required(),
  phone: Joi.string().pattern(/^\+?[\d\s\-\(\)]+$/).optional()
});

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(limiter);

// Request logging middleware
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.path}`, {
    ip: req.ip,
    userAgent: req.get('User-Agent'),
    timestamp: new Date().toISOString()
  });
  next();
});

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
      uptime: process.uptime(),
      version: process.env.npm_package_version || '1.0.0'
    });
  } catch (error) {
    logger.error('Health check failed:', error);
    res.status(503).json({
      status: 'unhealthy',
      service: 'user-service',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Get all users
app.get('/api/users', async (req, res) => {
  try {
    const { rows } = await pool.query(
      'SELECT id, name, email, phone, created_at, updated_at FROM users ORDER BY created_at DESC'
    );
    
    logger.info(`Retrieved ${rows.length} users`);
    res.json(rows);
  } catch (error) {
    logger.error('Error getting users:', error);
    res.status(500).json({ 
      error: 'Internal server error',
      message: 'Failed to retrieve users'
    });
  }
});

// Get user by ID
app.get('/api/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Validate ID
    if (!/^\d+$/.test(id)) {
      return res.status(400).json({ error: 'Invalid user ID format' });
    }
    
    // Check cache first
    const cached = await redisClient.get(`user:${id}`);
    if (cached) {
      logger.info(`User ${id} retrieved from cache`);
      return res.json(JSON.parse(cached));
    }
    
    const { rows } = await pool.query(
      'SELECT id, name, email, phone, created_at, updated_at FROM users WHERE id = $1',
      [id]
    );
    
    if (rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    // Cache for 5 minutes
    await redisClient.setex(`user:${id}`, 300, JSON.stringify(rows[0]));
    
    logger.info(`User ${id} retrieved from database`);
    res.json(rows[0]);
  } catch (error) {
    logger.error(`Error getting user ${req.params.id}:`, error);
    res.status(500).json({ 
      error: 'Internal server error',
      message: 'Failed to retrieve user'
    });
  }
});

// Create new user
app.post('/api/users', async (req, res) => {
  try {
    // Validate input
    const { error, value } = userSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ 
        error: 'Validation error',
        details: error.details[0].message
      });
    }
    
    const { name, email, phone } = value;
    
    // Check if email already exists
    const existingUser = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
    if (existingUser.rows.length > 0) {
      return res.status(409).json({ error: 'Email already exists' });
    }
    
    const { rows } = await pool.query(
      'INSERT INTO users (name, email, phone) VALUES ($1, $2, $3) RETURNING id, name, email, phone, created_at, updated_at',
      [name, email, phone]
    );
    
    // Invalidate cache
    await redisClient.del('users:*');
    
    logger.info(`User created with ID: ${rows[0].id}`);
    res.status(201).json(rows[0]);
  } catch (error) {
    logger.error('Error creating user:', error);
    res.status(500).json({ 
      error: 'Internal server error',
      message: 'Failed to create user'
    });
  }
});

// Update user
app.put('/api/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Validate ID
    if (!/^\d+$/.test(id)) {
      return res.status(400).json({ error: 'Invalid user ID format' });
    }
    
    // Validate input
    const { error, value } = userSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ 
        error: 'Validation error',
        details: error.details[0].message
      });
    }
    
    const { name, email, phone } = value;
    
    const { rows } = await pool.query(
      'UPDATE users SET name = $1, email = $2, phone = $3, updated_at = CURRENT_TIMESTAMP WHERE id = $4 RETURNING id, name, email, phone, created_at, updated_at',
      [name, email, phone, id]
    );
    
    if (rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    // Invalidate cache
    await redisClient.del(`user:${id}`);
    await redisClient.del('users:*');
    
    logger.info(`User ${id} updated`);
    res.json(rows[0]);
  } catch (error) {
    logger.error(`Error updating user ${req.params.id}:`, error);
    res.status(500).json({ 
      error: 'Internal server error',
      message: 'Failed to update user'
    });
  }
});

// Delete user
app.delete('/api/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Validate ID
    if (!/^\d+$/.test(id)) {
      return res.status(400).json({ error: 'Invalid user ID format' });
    }
    
    const { rows } = await pool.query('DELETE FROM users WHERE id = $1 RETURNING id', [id]);
    
    if (rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    // Invalidate cache
    await redisClient.del(`user:${id}`);
    await redisClient.del('users:*');
    
    logger.info(`User ${id} deleted`);
    res.status(204).send();
  } catch (error) {
    logger.error(`Error deleting user ${req.params.id}:`, error);
    res.status(500).json({ 
      error: 'Internal server error',
      message: 'Failed to delete user'
    });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  logger.error('Unhandled error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: 'An unexpected error occurred'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

const PORT = process.env.PORT || 3000;

// Graceful shutdown
process.on('SIGTERM', async () => {
  logger.info('SIGTERM received, shutting down gracefully');
  await pool.end();
  await redisClient.quit();
  process.exit(0);
});

process.on('SIGINT', async () => {
  logger.info('SIGINT received, shutting down gracefully');
  await pool.end();
  await redisClient.quit();
  process.exit(0);
});

app.listen(PORT, () => {
  logger.info(`User service running on port ${PORT}`);
});

module.exports = app;
