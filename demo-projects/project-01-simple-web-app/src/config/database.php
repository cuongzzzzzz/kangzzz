<?php
// Database configuration
$host = 'mysql';
$dbname = 'simple_webapp';
$username = 'webapp_user';
$password = 'webapp_password123';

// PDO options
$options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES   => false,
    PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci"
];

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password, $options);
} catch (PDOException $e) {
    // Log error for debugging
    error_log("Database connection failed: " . $e->getMessage());
    
    // Show user-friendly error
    die("Database connection failed. Please try again later.");
}

// Function to execute prepared statements safely
function executeQuery($pdo, $sql, $params = []) {
    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        return $stmt;
    } catch (PDOException $e) {
        error_log("Query execution failed: " . $e->getMessage());
        throw new Exception("Database query failed");
    }
}

// Function to get all products
function getAllProducts($pdo) {
    $sql = "SELECT * FROM products ORDER BY created_at DESC";
    return executeQuery($pdo, $sql)->fetchAll();
}

// Function to get product by ID
function getProductById($pdo, $id) {
    $sql = "SELECT * FROM products WHERE id = ?";
    $stmt = executeQuery($pdo, $sql, [$id]);
    return $stmt->fetch();
}

// Function to add new product
function addProduct($pdo, $name, $description, $price, $category) {
    $sql = "INSERT INTO products (name, description, price, category) VALUES (?, ?, ?, ?)";
    executeQuery($pdo, $sql, [$name, $description, $price, $category]);
    return $pdo->lastInsertId();
}

// Function to update product
function updateProduct($pdo, $id, $name, $description, $price, $category) {
    $sql = "UPDATE products SET name = ?, description = ?, price = ?, category = ? WHERE id = ?";
    return executeQuery($pdo, $sql, [$name, $description, $price, $category, $id])->rowCount();
}

// Function to delete product
function deleteProduct($pdo, $id) {
    $sql = "DELETE FROM products WHERE id = ?";
    return executeQuery($pdo, $sql, [$id])->rowCount();
}

// Function to search products
function searchProducts($pdo, $searchTerm) {
    $sql = "SELECT * FROM products WHERE name LIKE ? OR description LIKE ? OR category LIKE ? ORDER BY created_at DESC";
    $searchPattern = "%$searchTerm%";
    return executeQuery($pdo, $sql, [$searchPattern, $searchPattern, $searchPattern])->fetchAll();
}
?>
