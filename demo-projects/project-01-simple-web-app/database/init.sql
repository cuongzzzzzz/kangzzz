-- Simple Web App Database Schema
-- This script initializes the database with required tables and sample data

-- Create database if it doesn't exist
CREATE DATABASE IF NOT EXISTS simple_webapp;
USE simple_webapp;

-- Create products table
CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    category VARCHAR(100),
    sku VARCHAR(100) UNIQUE,
    stock_quantity INT DEFAULT 0,
    image_url VARCHAR(500),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_name (name),
    INDEX idx_category (category),
    INDEX idx_price (price),
    INDEX idx_created_at (created_at)
);

-- Create categories table
CREATE TABLE categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    parent_id INT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE SET NULL,
    INDEX idx_name (name),
    INDEX idx_parent_id (parent_id)
);

-- Create users table (for future authentication)
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    role ENUM('admin', 'user', 'moderator') DEFAULT 'user',
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_role (role)
);

-- Create orders table (for future e-commerce features)
CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    order_number VARCHAR(50) NOT NULL UNIQUE,
    total_amount DECIMAL(10,2) NOT NULL,
    status ENUM('pending', 'processing', 'shipped', 'delivered', 'cancelled') DEFAULT 'pending',
    shipping_address TEXT,
    billing_address TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_order_number (order_number),
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
);

-- Create order_items table
CREATE TABLE order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    INDEX idx_order_id (order_id),
    INDEX idx_product_id (product_id)
);

-- Insert sample categories
INSERT INTO categories (name, description) VALUES
('Electronics', 'Electronic devices and accessories'),
('Clothing', 'Fashion and apparel'),
('Home & Garden', 'Home improvement and garden supplies'),
('Sports', 'Sports equipment and accessories'),
('Books', 'Books and educational materials'),
('Toys', 'Toys and games'),
('Health & Beauty', 'Health and beauty products'),
('Automotive', 'Car parts and accessories');

-- Insert sample products
INSERT INTO products (name, description, price, category, sku, stock_quantity, image_url) VALUES
('Dell XPS 13 Laptop', 'High-performance ultrabook with 13-inch display, Intel i7 processor, 16GB RAM, and 512GB SSD. Perfect for professionals and students.', 1299.99, 'Electronics', 'DELL-XPS13-001', 25, 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=400'),
('iPhone 14 Pro', 'Latest iPhone with A16 Bionic chip, Pro camera system, and Dynamic Island. Available in Space Black, Silver, Gold, and Deep Purple.', 999.99, 'Electronics', 'APPLE-IPHONE14P-001', 50, 'https://images.unsplash.com/photo-1592899677977-9c10b588e209?w=400'),
('Nike Air Max 270', 'Comfortable running shoes with Max Air cushioning and breathable mesh upper. Available in multiple colors and sizes.', 150.00, 'Sports', 'NIKE-AM270-001', 100, 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400'),
('Coffee Maker Deluxe', 'Automatic coffee maker with programmable timer, 12-cup capacity, and built-in grinder. Perfect for coffee enthusiasts.', 89.99, 'Home & Garden', 'COFFEE-DELUXE-001', 30, 'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=400'),
('Wireless Bluetooth Headphones', 'Noise-cancelling wireless headphones with 30-hour battery life and premium sound quality. Perfect for music lovers.', 199.99, 'Electronics', 'HEADPHONES-BT-001', 75, 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400'),
('Yoga Mat Premium', 'Non-slip yoga mat made from eco-friendly materials. Perfect for yoga, pilates, and other fitness activities.', 49.99, 'Sports', 'YOGA-MAT-001', 60, 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400'),
('Smart Watch Series 8', 'Advanced smartwatch with health monitoring, GPS, and water resistance. Track your fitness and stay connected.', 399.99, 'Electronics', 'SMARTWATCH-8-001', 40, 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400'),
('Gaming Mechanical Keyboard', 'RGB backlit mechanical keyboard with Cherry MX switches. Perfect for gaming and professional typing.', 129.99, 'Electronics', 'KEYBOARD-MECH-001', 35, 'https://images.unsplash.com/photo-1541140532154-b024d705b90a?w=400'),
('Organic Green Tea', 'Premium organic green tea leaves from Japan. Rich in antioxidants and perfect for daily consumption.', 24.99, 'Health & Beauty', 'TEA-GREEN-001', 200, 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=400'),
('Wireless Mouse Pro', 'Ergonomic wireless mouse with precision tracking and long battery life. Perfect for office and gaming use.', 79.99, 'Electronics', 'MOUSE-WIRELESS-001', 80, 'https://images.unsplash.com/photo-1527864550417-7fd91fc51a46?w=400');

-- Insert sample admin user
INSERT INTO users (username, email, password_hash, first_name, last_name, role) VALUES
('admin', 'admin@simplewebapp.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Admin', 'User', 'admin'),
('demo', 'demo@simplewebapp.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Demo', 'User', 'user');

-- Create views for common queries
CREATE VIEW product_summary AS
SELECT 
    p.id,
    p.name,
    p.price,
    p.category,
    p.stock_quantity,
    p.is_active,
    p.created_at,
    c.name as category_name
FROM products p
LEFT JOIN categories c ON p.category = c.name
WHERE p.is_active = TRUE;

CREATE VIEW low_stock_products AS
SELECT 
    id,
    name,
    stock_quantity,
    category
FROM products
WHERE stock_quantity < 10 AND is_active = TRUE
ORDER BY stock_quantity ASC;

-- Create stored procedures
DELIMITER //

CREATE PROCEDURE GetProductsByCategory(IN category_name VARCHAR(100))
BEGIN
    SELECT * FROM products 
    WHERE category = category_name AND is_active = TRUE
    ORDER BY created_at DESC;
END //

CREATE PROCEDURE SearchProducts(IN search_term VARCHAR(255))
BEGIN
    SELECT * FROM products 
    WHERE (name LIKE CONCAT('%', search_term, '%') 
           OR description LIKE CONCAT('%', search_term, '%')
           OR category LIKE CONCAT('%', search_term, '%'))
    AND is_active = TRUE
    ORDER BY 
        CASE 
            WHEN name LIKE CONCAT(search_term, '%') THEN 1
            WHEN name LIKE CONCAT('%', search_term, '%') THEN 2
            ELSE 3
        END,
        created_at DESC;
END //

CREATE PROCEDURE GetProductStats()
BEGIN
    SELECT 
        COUNT(*) as total_products,
        COUNT(CASE WHEN is_active = TRUE THEN 1 END) as active_products,
        COUNT(CASE WHEN stock_quantity < 10 THEN 1 END) as low_stock_products,
        AVG(price) as average_price,
        MAX(price) as highest_price,
        MIN(price) as lowest_price
    FROM products;
END //

DELIMITER ;

-- Create triggers for audit logging
DELIMITER //

CREATE TRIGGER products_audit_insert
AFTER INSERT ON products
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, action, record_id, old_values, new_values, created_at)
    VALUES ('products', 'INSERT', NEW.id, NULL, JSON_OBJECT('name', NEW.name, 'price', NEW.price), NOW());
END //

CREATE TRIGGER products_audit_update
AFTER UPDATE ON products
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, action, record_id, old_values, new_values, created_at)
    VALUES ('products', 'UPDATE', NEW.id, 
            JSON_OBJECT('name', OLD.name, 'price', OLD.price), 
            JSON_OBJECT('name', NEW.name, 'price', NEW.price), 
            NOW());
END //

DELIMITER ;

-- Create audit_log table for tracking changes
CREATE TABLE audit_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    action ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    record_id INT NOT NULL,
    old_values JSON,
    new_values JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_table_name (table_name),
    INDEX idx_record_id (record_id),
    INDEX idx_created_at (created_at)
);

-- Insert some sample orders for demonstration
INSERT INTO orders (user_id, order_number, total_amount, status, shipping_address) VALUES
(2, 'ORD-001', 1299.99, 'delivered', '123 Main St, City, State 12345'),
(2, 'ORD-002', 249.99, 'shipped', '456 Oak Ave, City, State 12345');

INSERT INTO order_items (order_id, product_id, quantity, unit_price, total_price) VALUES
(1, 1, 1, 1299.99, 1299.99),
(2, 3, 1, 150.00, 150.00),
(2, 6, 2, 49.99, 99.98);

-- Create indexes for better performance
CREATE INDEX idx_products_name_category ON products(name, category);
CREATE INDEX idx_products_price_range ON products(price);
CREATE INDEX idx_orders_user_status ON orders(user_id, status);
CREATE INDEX idx_order_items_order_product ON order_items(order_id, product_id);

-- Grant permissions to webapp user
GRANT SELECT, INSERT, UPDATE, DELETE ON simple_webapp.* TO 'webapp_user'@'%';
GRANT EXECUTE ON simple_webapp.* TO 'webapp_user'@'%';

-- Flush privileges
FLUSH PRIVILEGES;
