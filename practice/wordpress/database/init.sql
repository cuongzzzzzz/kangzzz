-- WordPress database initialization
-- This script runs when the database container starts for the first time

-- Create additional databases if needed
-- CREATE DATABASE IF NOT EXISTS wordpress_test;
-- CREATE DATABASE IF NOT EXISTS wordpress_staging;

-- Set up additional users if needed
-- CREATE USER IF NOT EXISTS 'wp_readonly'@'%' IDENTIFIED BY 'readonly_password';
-- GRANT SELECT ON wordpress.* TO 'wp_readonly'@'%';

-- Optimize MySQL settings for WordPress
SET GLOBAL innodb_buffer_pool_size = 256M;
SET GLOBAL max_connections = 200;
SET GLOBAL query_cache_size = 32M;
SET GLOBAL query_cache_type = 1;

-- Flush privileges
FLUSH PRIVILEGES;
