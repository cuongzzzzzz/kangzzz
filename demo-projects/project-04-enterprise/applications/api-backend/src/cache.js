const redis = require('redis');
const winston = require('winston');

class Cache {
  constructor() {
    this.client = redis.createClient({
      host: process.env.REDIS_HOST || 'redis-master',
      port: process.env.REDIS_PORT || 6379,
      password: process.env.REDIS_PASSWORD || 'password',
      retry_strategy: (options) => {
        if (options.error && options.error.code === 'ECONNREFUSED') {
          return new Error('The server refused the connection');
        }
        if (options.total_retry_time > 1000 * 60 * 60) {
          return new Error('Retry time exhausted');
        }
        if (options.attempt > 10) {
          return undefined;
        }
        return Math.min(options.attempt * 100, 3000);
      }
    });

    this.logger = winston.createLogger({
      level: 'info',
      format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
      ),
      defaultMeta: { service: 'cache' },
      transports: [
        new winston.transports.Console()
      ]
    });

    this.client.on('error', (err) => {
      this.logger.error('Redis Client Error:', err);
    });

    this.client.on('connect', () => {
      this.logger.info('Redis Client Connected');
    });

    this.client.on('ready', () => {
      this.logger.info('Redis Client Ready');
    });

    this.client.on('end', () => {
      this.logger.info('Redis Client Disconnected');
    });
  }

  async connect() {
    try {
      await this.client.connect();
      this.logger.info('Cache connected successfully');
    } catch (error) {
      this.logger.error('Cache connection failed:', error);
      throw error;
    }
  }

  async checkConnection() {
    try {
      const pong = await this.client.ping();
      return pong === 'PONG';
    } catch (error) {
      this.logger.error('Cache health check failed:', error);
      return false;
    }
  }

  async get(key) {
    try {
      const value = await this.client.get(key);
      return value ? JSON.parse(value) : null;
    } catch (error) {
      this.logger.error('Cache get error:', error);
      return null;
    }
  }

  async set(key, value, ttl = 3600) {
    try {
      const serializedValue = JSON.stringify(value);
      await this.client.setEx(key, ttl, serializedValue);
      return true;
    } catch (error) {
      this.logger.error('Cache set error:', error);
      return false;
    }
  }

  async del(key) {
    try {
      const result = await this.client.del(key);
      return result > 0;
    } catch (error) {
      this.logger.error('Cache delete error:', error);
      return false;
    }
  }

  async exists(key) {
    try {
      const result = await this.client.exists(key);
      return result === 1;
    } catch (error) {
      this.logger.error('Cache exists error:', error);
      return false;
    }
  }

  async expire(key, ttl) {
    try {
      const result = await this.client.expire(key, ttl);
      return result === 1;
    } catch (error) {
      this.logger.error('Cache expire error:', error);
      return false;
    }
  }

  async ttl(key) {
    try {
      const result = await this.client.ttl(key);
      return result;
    } catch (error) {
      this.logger.error('Cache TTL error:', error);
      return -1;
    }
  }

  async keys(pattern = '*') {
    try {
      const result = await this.client.keys(pattern);
      return result;
    } catch (error) {
      this.logger.error('Cache keys error:', error);
      return [];
    }
  }

  async clear() {
    try {
      await this.client.flushAll();
      this.logger.info('Cache cleared successfully');
      return true;
    } catch (error) {
      this.logger.error('Cache clear error:', error);
      return false;
    }
  }

  async getStatus() {
    try {
      const info = await this.client.info();
      const memory = await this.client.memory('usage');
      const dbSize = await this.client.dbSize();
      
      return {
        status: 'connected',
        memory: memory,
        dbSize: dbSize,
        info: this.parseRedisInfo(info)
      };
    } catch (error) {
      this.logger.error('Cache status error:', error);
      return {
        status: 'disconnected',
        error: error.message
      };
    }
  }

  parseRedisInfo(info) {
    const lines = info.split('\r\n');
    const result = {};
    
    lines.forEach(line => {
      if (line && !line.startsWith('#')) {
        const [key, value] = line.split(':');
        if (key && value) {
          result[key] = value;
        }
      }
    });
    
    return result;
  }

  // Cache patterns for common operations
  async cacheUser(userId, userData, ttl = 3600) {
    const key = `user:${userId}`;
    return await this.set(key, userData, ttl);
  }

  async getCachedUser(userId) {
    const key = `user:${userId}`;
    return await this.get(key);
  }

  async cacheUsers(users, ttl = 1800) {
    const key = 'users:all';
    return await this.set(key, users, ttl);
  }

  async getCachedUsers() {
    const key = 'users:all';
    return await this.get(key);
  }

  async cacheProduct(productId, productData, ttl = 3600) {
    const key = `product:${productId}`;
    return await this.set(key, productData, ttl);
  }

  async getCachedProduct(productId) {
    const key = `product:${productId}`;
    return await this.get(key);
  }

  async cacheProducts(products, ttl = 1800) {
    const key = 'products:all';
    return await this.set(key, products, ttl);
  }

  async getCachedProducts() {
    const key = 'products:all';
    return await this.get(key);
  }

  async invalidateUserCache(userId) {
    const keys = [
      `user:${userId}`,
      'users:all'
    ];
    
    for (const key of keys) {
      await this.del(key);
    }
  }

  async invalidateProductCache(productId) {
    const keys = [
      `product:${productId}`,
      'products:all'
    ];
    
    for (const key of keys) {
      await this.del(key);
    }
  }

  async close() {
    try {
      await this.client.quit();
      this.logger.info('Cache connection closed');
    } catch (error) {
      this.logger.error('Error closing cache connection:', error);
    }
  }
}

module.exports = Cache;
