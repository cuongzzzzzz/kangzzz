-- PostgreSQL initialization script for microservices demo
-- This script creates all necessary databases and tables

-- Create databases
CREATE DATABASE users;
CREATE DATABASE orders;
CREATE DATABASE payments;
CREATE DATABASE notifications;
CREATE DATABASE analytics;

-- Connect to users database
\c users;

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index on email for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Insert sample users
INSERT INTO users (name, email, phone) VALUES
('John Doe', 'john.doe@example.com', '+1-555-0101'),
('Jane Smith', 'jane.smith@example.com', '+1-555-0102'),
('Bob Johnson', 'bob.johnson@example.com', '+1-555-0103'),
('Alice Brown', 'alice.brown@example.com', '+1-555-0104'),
('Charlie Wilson', 'charlie.wilson@example.com', '+1-555-0105')
ON CONFLICT (email) DO NOTHING;

-- Connect to orders database
\c orders;

-- Create orders table
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    total DECIMAL(10,2) NOT NULL CHECK (total > 0),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);

-- Insert sample orders
INSERT INTO orders (user_id, product_id, quantity, total, status) VALUES
(1, 1, 2, 99.98, 'pending'),
(2, 2, 1, 49.99, 'processing'),
(3, 3, 3, 149.97, 'shipped'),
(4, 1, 1, 49.99, 'delivered'),
(5, 4, 2, 199.98, 'pending')
ON CONFLICT DO NOTHING;

-- Connect to payments database
\c payments;

-- Create payments table
CREATE TABLE IF NOT EXISTS payments (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    currency VARCHAR(3) DEFAULT 'USD',
    payment_method VARCHAR(20) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'refunded')),
    transaction_id VARCHAR(100) UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_payments_order_id ON payments(order_id);
CREATE INDEX IF NOT EXISTS idx_payments_user_id ON payments(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_transaction_id ON payments(transaction_id);

-- Insert sample payments
INSERT INTO payments (order_id, user_id, amount, currency, payment_method, status, transaction_id, description) VALUES
(1, 1, 99.98, 'USD', 'credit_card', 'completed', 'txn_001', 'Payment for order #1'),
(2, 2, 49.99, 'USD', 'paypal', 'processing', 'txn_002', 'Payment for order #2'),
(3, 3, 149.97, 'USD', 'credit_card', 'completed', 'txn_003', 'Payment for order #3'),
(4, 4, 49.99, 'USD', 'bank_transfer', 'completed', 'txn_004', 'Payment for order #4'),
(5, 5, 199.98, 'USD', 'credit_card', 'pending', 'txn_005', 'Payment for order #5')
ON CONFLICT (transaction_id) DO NOTHING;

-- Connect to notifications database
\c notifications;

-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    channel VARCHAR(20) NOT NULL CHECK (channel IN ('email', 'sms', 'push')),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed', 'delivered')),
    sent_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_status ON notifications(status);
CREATE INDEX IF NOT EXISTS idx_notifications_channel ON notifications(channel);

-- Insert sample notifications
INSERT INTO notifications (user_id, type, title, message, channel, status) VALUES
(1, 'order_confirmation', 'Order Confirmed', 'Your order #1 has been confirmed and is being processed.', 'email', 'sent'),
(2, 'payment_received', 'Payment Received', 'We have received your payment of $49.99.', 'email', 'sent'),
(3, 'shipping_update', 'Order Shipped', 'Your order #3 has been shipped and is on its way.', 'email', 'sent'),
(4, 'delivery_confirmation', 'Order Delivered', 'Your order #4 has been delivered successfully.', 'email', 'delivered'),
(5, 'payment_reminder', 'Payment Reminder', 'Please complete your payment for order #5.', 'email', 'pending')
ON CONFLICT DO NOTHING;

-- Connect to analytics database
\c analytics;

-- Create analytics_data table
CREATE TABLE IF NOT EXISTS analytics_data (
    id SERIAL PRIMARY KEY,
    event_type VARCHAR(100) NOT NULL,
    user_id INTEGER NOT NULL,
    data JSONB NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_analytics_event_type ON analytics_data(event_type);
CREATE INDEX IF NOT EXISTS idx_analytics_user_id ON analytics_data(user_id);
CREATE INDEX IF NOT EXISTS idx_analytics_timestamp ON analytics_data(timestamp);
CREATE INDEX IF NOT EXISTS idx_analytics_data_gin ON analytics_data USING GIN(data);

-- Insert sample analytics data
INSERT INTO analytics_data (event_type, user_id, data) VALUES
('page_view', 1, '{"page": "/products", "duration": 45}'),
('product_view', 1, '{"product_id": 1, "product_name": "Laptop"}'),
('add_to_cart', 1, '{"product_id": 1, "quantity": 2}'),
('checkout_start', 1, '{"cart_value": 99.98}'),
('order_complete', 1, '{"order_id": 1, "total": 99.98}'),
('page_view', 2, '{"page": "/home", "duration": 30}'),
('product_view', 2, '{"product_id": 2, "product_name": "Phone"}'),
('add_to_cart', 2, '{"product_id": 2, "quantity": 1}'),
('checkout_start', 2, '{"cart_value": 49.99}'),
('order_complete', 2, '{"order_id": 2, "total": 49.99}'),
('page_view', 3, '{"page": "/products", "duration": 60}'),
('product_view', 3, '{"product_id": 3, "product_name": "Tablet"}'),
('add_to_cart', 3, '{"product_id": 3, "quantity": 3}'),
('checkout_start', 3, '{"cart_value": 149.97}'),
('order_complete', 3, '{"order_id": 3, "total": 149.97}')
ON CONFLICT DO NOTHING;

-- Create a function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at columns
\c users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

\c orders;
CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

\c payments;
CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

\c notifications;
CREATE TRIGGER update_notifications_updated_at BEFORE UPDATE ON notifications FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Grant permissions (if needed)
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;

-- Display summary
\c users;
SELECT 'Users database initialized' as status, COUNT(*) as user_count FROM users;

\c orders;
SELECT 'Orders database initialized' as status, COUNT(*) as order_count FROM orders;

\c payments;
SELECT 'Payments database initialized' as status, COUNT(*) as payment_count FROM payments;

\c notifications;
SELECT 'Notifications database initialized' as status, COUNT(*) as notification_count FROM notifications;

\c analytics;
SELECT 'Analytics database initialized' as status, COUNT(*) as analytics_count FROM analytics_data;
