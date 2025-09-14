const express = require('express');
const mongoose = require('mongoose');
const redis = require('redis');
const router = express.Router();

// Health check endpoint
router.get('/', async (req, res) => {
  const health = {
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
    version: process.env.npm_package_version || '1.0.0',
    services: {}
  };

  // Check MongoDB connection
  try {
    await mongoose.connection.db.admin().ping();
    health.services.mongodb = {
      status: 'OK',
      connection: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected'
    };
  } catch (error) {
    health.services.mongodb = {
      status: 'ERROR',
      error: error.message
    };
    health.status = 'ERROR';
  }

  // Check Redis connection
  try {
    const redisClient = redis.createClient({ url: process.env.REDIS_URL });
    await redisClient.ping();
    await redisClient.quit();
    health.services.redis = {
      status: 'OK',
      connection: 'connected'
    };
  } catch (error) {
    health.services.redis = {
      status: 'ERROR',
      error: error.message
    };
    health.status = 'ERROR';
  }

  // Check memory usage
  const memoryUsage = process.memoryUsage();
  health.memory = {
    rss: Math.round(memoryUsage.rss / 1024 / 1024) + ' MB',
    heapTotal: Math.round(memoryUsage.heapTotal / 1024 / 1024) + ' MB',
    heapUsed: Math.round(memoryUsage.heapUsed / 1024 / 1024) + ' MB',
    external: Math.round(memoryUsage.external / 1024 / 1024) + ' MB'
  };

  // Check CPU usage
  const cpuUsage = process.cpuUsage();
  health.cpu = {
    user: cpuUsage.user,
    system: cpuUsage.system
  };

  const statusCode = health.status === 'OK' ? 200 : 503;
  res.status(statusCode).json(health);
});

// Detailed health check
router.get('/detailed', async (req, res) => {
  const detailedHealth = {
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
    version: process.env.npm_package_version || '1.0.0',
    services: {},
    system: {},
    database: {}
  };

  // MongoDB detailed check
  try {
    const mongoStats = await mongoose.connection.db.stats();
    detailedHealth.services.mongodb = {
      status: 'OK',
      connection: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected',
      database: mongoose.connection.name,
      collections: mongoStats.collections,
      dataSize: mongoStats.dataSize,
      storageSize: mongoStats.storageSize,
      indexes: mongoStats.indexes
    };
  } catch (error) {
    detailedHealth.services.mongodb = {
      status: 'ERROR',
      error: error.message
    };
    detailedHealth.status = 'ERROR';
  }

  // Redis detailed check
  try {
    const redisClient = redis.createClient({ url: process.env.REDIS_URL });
    const info = await redisClient.info();
    await redisClient.quit();
    
    const redisInfo = {};
    info.split('\r\n').forEach(line => {
      if (line && !line.startsWith('#')) {
        const [key, value] = line.split(':');
        if (key && value) {
          redisInfo[key] = value;
        }
      }
    });

    detailedHealth.services.redis = {
      status: 'OK',
      connection: 'connected',
      version: redisInfo.redis_version,
      uptime: redisInfo.uptime_in_seconds,
      memory: redisInfo.used_memory_human,
      connected_clients: redisInfo.connected_clients
    };
  } catch (error) {
    detailedHealth.services.redis = {
      status: 'ERROR',
      error: error.message
    };
    detailedHealth.status = 'ERROR';
  }

  // System information
  detailedHealth.system = {
    platform: process.platform,
    arch: process.arch,
    nodeVersion: process.version,
    pid: process.pid,
    memory: process.memoryUsage(),
    cpu: process.cpuUsage(),
    loadAverage: process.platform !== 'win32' ? require('os').loadavg() : null
  };

  const statusCode = detailedHealth.status === 'OK' ? 200 : 503;
  res.status(statusCode).json(detailedHealth);
});

// Readiness probe
router.get('/ready', async (req, res) => {
  try {
    // Check if all critical services are ready
    const mongoReady = mongoose.connection.readyState === 1;
    
    let redisReady = false;
    try {
      const redisClient = redis.createClient({ url: process.env.REDIS_URL });
      await redisClient.ping();
      await redisClient.quit();
      redisReady = true;
    } catch (error) {
      // Redis not ready
    }

    if (mongoReady && redisReady) {
      res.status(200).json({ status: 'READY' });
    } else {
      res.status(503).json({ 
        status: 'NOT_READY',
        services: {
          mongodb: mongoReady ? 'ready' : 'not_ready',
          redis: redisReady ? 'ready' : 'not_ready'
        }
      });
    }
  } catch (error) {
    res.status(503).json({ 
      status: 'NOT_READY',
      error: error.message 
    });
  }
});

// Liveness probe
router.get('/live', (req, res) => {
  res.status(200).json({ 
    status: 'ALIVE',
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

module.exports = router;
