const { Pool } = require('pg');
const winston = require('winston');

class Database {
  constructor() {
    this.pool = new Pool({
      host: process.env.POSTGRES_HOST || 'postgres-primary',
      port: process.env.POSTGRES_PORT || 5432,
      database: process.env.POSTGRES_DB || 'enterprise',
      user: process.env.POSTGRES_USER || 'postgres',
      password: process.env.POSTGRES_PASSWORD || 'password',
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 2000,
    });

    this.logger = winston.createLogger({
      level: 'info',
      format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
      ),
      defaultMeta: { service: 'database' },
      transports: [
        new winston.transports.Console()
      ]
    });
  }

  async connect() {
    try {
      await this.pool.connect();
      this.logger.info('Database connected successfully');
      await this.initializeTables();
    } catch (error) {
      this.logger.error('Database connection failed:', error);
      throw error;
    }
  }

  async checkConnection() {
    try {
      const client = await this.pool.connect();
      await client.query('SELECT 1');
      client.release();
      return true;
    } catch (error) {
      this.logger.error('Database health check failed:', error);
      return false;
    }
  }

  async initializeTables() {
    const createUsersTable = `
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `;

    const createProductsTable = `
      CREATE TABLE IF NOT EXISTS products (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        description TEXT,
        price DECIMAL(10,2) NOT NULL,
        stock INTEGER DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `;

    const createOrdersTable = `
      CREATE TABLE IF NOT EXISTS orders (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id),
        total DECIMAL(10,2) NOT NULL,
        status VARCHAR(50) DEFAULT 'pending',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `;

    try {
      await this.pool.query(createUsersTable);
      await this.pool.query(createProductsTable);
      await this.pool.query(createOrdersTable);
      this.logger.info('Database tables initialized');
    } catch (error) {
      this.logger.error('Failed to initialize tables:', error);
      throw error;
    }
  }

  async getUserByEmail(email) {
    const query = 'SELECT * FROM users WHERE email = $1';
    const result = await this.pool.query(query, [email]);
    return result.rows[0];
  }

  async getUserById(id) {
    const query = 'SELECT id, name, email, created_at FROM users WHERE id = $1';
    const result = await this.pool.query(query, [id]);
    return result.rows[0];
  }

  async getUsers() {
    const query = 'SELECT id, name, email, created_at FROM users ORDER BY created_at DESC';
    const result = await this.pool.query(query);
    return result.rows;
  }

  async createUser(userData) {
    const { name, email, password } = userData;
    const query = `
      INSERT INTO users (name, email, password) 
      VALUES ($1, $2, $3) 
      RETURNING id, name, email, created_at
    `;
    const result = await this.pool.query(query, [name, email, password]);
    return result.rows[0];
  }

  async updateUser(id, userData) {
    const { name, email } = userData;
    const query = `
      UPDATE users 
      SET name = $1, email = $2, updated_at = CURRENT_TIMESTAMP 
      WHERE id = $3 
      RETURNING id, name, email, updated_at
    `;
    const result = await this.pool.query(query, [name, email, id]);
    return result.rows[0];
  }

  async deleteUser(id) {
    const query = 'DELETE FROM users WHERE id = $1 RETURNING id';
    const result = await this.pool.query(query, [id]);
    return result.rows[0];
  }

  async getProducts() {
    const query = 'SELECT * FROM products ORDER BY created_at DESC';
    const result = await this.pool.query(query);
    return result.rows;
  }

  async getProductById(id) {
    const query = 'SELECT * FROM products WHERE id = $1';
    const result = await this.pool.query(query, [id]);
    return result.rows[0];
  }

  async createProduct(productData) {
    const { name, description, price, stock } = productData;
    const query = `
      INSERT INTO products (name, description, price, stock) 
      VALUES ($1, $2, $3, $4) 
      RETURNING *
    `;
    const result = await this.pool.query(query, [name, description, price, stock]);
    return result.rows[0];
  }

  async updateProduct(id, productData) {
    const { name, description, price, stock } = productData;
    const query = `
      UPDATE products 
      SET name = $1, description = $2, price = $3, stock = $4, updated_at = CURRENT_TIMESTAMP 
      WHERE id = $5 
      RETURNING *
    `;
    const result = await this.pool.query(query, [name, description, price, stock, id]);
    return result.rows[0];
  }

  async deleteProduct(id) {
    const query = 'DELETE FROM products WHERE id = $1 RETURNING id';
    const result = await this.pool.query(query, [id]);
    return result.rows[0];
  }

  async getOrders() {
    const query = `
      SELECT o.*, u.name as user_name, u.email as user_email 
      FROM orders o 
      JOIN users u ON o.user_id = u.id 
      ORDER BY o.created_at DESC
    `;
    const result = await this.pool.query(query);
    return result.rows;
  }

  async getOrderById(id) {
    const query = `
      SELECT o.*, u.name as user_name, u.email as user_email 
      FROM orders o 
      JOIN users u ON o.user_id = u.id 
      WHERE o.id = $1
    `;
    const result = await this.pool.query(query, [id]);
    return result.rows[0];
  }

  async createOrder(orderData) {
    const { user_id, total, status } = orderData;
    const query = `
      INSERT INTO orders (user_id, total, status) 
      VALUES ($1, $2, $3) 
      RETURNING *
    `;
    const result = await this.pool.query(query, [user_id, total, status]);
    return result.rows[0];
  }

  async updateOrder(id, orderData) {
    const { status } = orderData;
    const query = `
      UPDATE orders 
      SET status = $1, updated_at = CURRENT_TIMESTAMP 
      WHERE id = $2 
      RETURNING *
    `;
    const result = await this.pool.query(query, [status, id]);
    return result.rows[0];
  }

  async close() {
    try {
      await this.pool.end();
      this.logger.info('Database connection closed');
    } catch (error) {
      this.logger.error('Error closing database connection:', error);
    }
  }
}

module.exports = Database;
