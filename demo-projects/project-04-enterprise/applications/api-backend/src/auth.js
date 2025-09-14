const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const winston = require('winston');

class Auth {
  constructor() {
    this.jwtSecret = process.env.JWT_SECRET || 'your-secret-key';
    this.jwtExpiry = process.env.JWT_EXPIRY || '24h';
    this.bcryptRounds = parseInt(process.env.BCRYPT_ROUNDS) || 10;

    this.logger = winston.createLogger({
      level: 'info',
      format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
      ),
      defaultMeta: { service: 'auth' },
      transports: [
        new winston.transports.Console()
      ]
    });
  }

  async hashPassword(password) {
    try {
      const salt = await bcrypt.genSalt(this.bcryptRounds);
      const hash = await bcrypt.hash(password, salt);
      return hash;
    } catch (error) {
      this.logger.error('Password hashing error:', error);
      throw new Error('Password hashing failed');
    }
  }

  async comparePassword(password, hash) {
    try {
      const isValid = await bcrypt.compare(password, hash);
      return isValid;
    } catch (error) {
      this.logger.error('Password comparison error:', error);
      throw new Error('Password comparison failed');
    }
  }

  generateToken(payload) {
    try {
      const token = jwt.sign(payload, this.jwtSecret, {
        expiresIn: this.jwtExpiry,
        issuer: 'enterprise-api',
        audience: 'enterprise-client'
      });
      return token;
    } catch (error) {
      this.logger.error('Token generation error:', error);
      throw new Error('Token generation failed');
    }
  }

  verifyToken(token) {
    try {
      const decoded = jwt.verify(token, this.jwtSecret, {
        issuer: 'enterprise-api',
        audience: 'enterprise-client'
      });
      return decoded;
    } catch (error) {
      this.logger.error('Token verification error:', error);
      throw new Error('Invalid token');
    }
  }

  generateRefreshToken(payload) {
    try {
      const refreshToken = jwt.sign(payload, this.jwtSecret, {
        expiresIn: '7d',
        issuer: 'enterprise-api',
        audience: 'enterprise-client'
      });
      return refreshToken;
    } catch (error) {
      this.logger.error('Refresh token generation error:', error);
      throw new Error('Refresh token generation failed');
    }
  }

  verifyRefreshToken(token) {
    try {
      const decoded = jwt.verify(token, this.jwtSecret, {
        issuer: 'enterprise-api',
        audience: 'enterprise-client'
      });
      return decoded;
    } catch (error) {
      this.logger.error('Refresh token verification error:', error);
      throw new Error('Invalid refresh token');
    }
  }

  extractTokenFromHeader(authHeader) {
    if (!authHeader) {
      throw new Error('Authorization header missing');
    }

    const parts = authHeader.split(' ');
    if (parts.length !== 2 || parts[0] !== 'Bearer') {
      throw new Error('Invalid authorization header format');
    }

    return parts[1];
  }

  generatePasswordResetToken(userId) {
    try {
      const payload = {
        userId,
        type: 'password_reset',
        timestamp: Date.now()
      };
      
      const token = jwt.sign(payload, this.jwtSecret, {
        expiresIn: '1h',
        issuer: 'enterprise-api',
        audience: 'enterprise-client'
      });
      
      return token;
    } catch (error) {
      this.logger.error('Password reset token generation error:', error);
      throw new Error('Password reset token generation failed');
    }
  }

  verifyPasswordResetToken(token) {
    try {
      const decoded = jwt.verify(token, this.jwtSecret, {
        issuer: 'enterprise-api',
        audience: 'enterprise-client'
      });
      
      if (decoded.type !== 'password_reset') {
        throw new Error('Invalid token type');
      }
      
      return decoded;
    } catch (error) {
      this.logger.error('Password reset token verification error:', error);
      throw new Error('Invalid password reset token');
    }
  }

  generateApiKey(userId, permissions = []) {
    try {
      const payload = {
        userId,
        type: 'api_key',
        permissions,
        timestamp: Date.now()
      };
      
      const apiKey = jwt.sign(payload, this.jwtSecret, {
        expiresIn: '365d',
        issuer: 'enterprise-api',
        audience: 'enterprise-client'
      });
      
      return apiKey;
    } catch (error) {
      this.logger.error('API key generation error:', error);
      throw new Error('API key generation failed');
    }
  }

  verifyApiKey(apiKey) {
    try {
      const decoded = jwt.verify(apiKey, this.jwtSecret, {
        issuer: 'enterprise-api',
        audience: 'enterprise-client'
      });
      
      if (decoded.type !== 'api_key') {
        throw new Error('Invalid token type');
      }
      
      return decoded;
    } catch (error) {
      this.logger.error('API key verification error:', error);
      throw new Error('Invalid API key');
    }
  }

  // Middleware for protecting routes
  authenticateToken(req, res, next) {
    try {
      const authHeader = req.headers['authorization'];
      const token = this.extractTokenFromHeader(authHeader);
      const decoded = this.verifyToken(token);
      
      req.user = decoded;
      next();
    } catch (error) {
      this.logger.error('Authentication middleware error:', error);
      return res.status(401).json({ error: 'Unauthorized' });
    }
  }

  // Middleware for role-based access control
  requireRole(roles) {
    return (req, res, next) => {
      try {
        if (!req.user) {
          return res.status(401).json({ error: 'Authentication required' });
        }

        const userRole = req.user.role || 'user';
        if (!roles.includes(userRole)) {
          return res.status(403).json({ error: 'Insufficient permissions' });
        }

        next();
      } catch (error) {
        this.logger.error('Role-based access control error:', error);
        return res.status(500).json({ error: 'Internal server error' });
      }
    };
  }

  // Middleware for API key authentication
  authenticateApiKey(req, res, next) {
    try {
      const apiKey = req.headers['x-api-key'];
      if (!apiKey) {
        return res.status(401).json({ error: 'API key required' });
      }

      const decoded = this.verifyApiKey(apiKey);
      req.apiKey = decoded;
      next();
    } catch (error) {
      this.logger.error('API key authentication error:', error);
      return res.status(401).json({ error: 'Invalid API key' });
    }
  }
}

module.exports = Auth;
