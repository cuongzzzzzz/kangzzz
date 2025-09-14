<?php
require_once 'config/database.php';
require_once 'includes/header.php';

// Get products from database
try {
    $stmt = $pdo->query("SELECT * FROM products ORDER BY created_at DESC LIMIT 10");
    $products = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    $products = [];
    $error = "Database connection failed: " . $e->getMessage();
}
?>

<div class="container">
    <div class="hero">
        <h1>Welcome to Simple Web App</h1>
        <p>A modern LAMP stack application for product management</p>
        <a href="pages/products.php" class="btn btn-primary">View Products</a>
    </div>

    <?php if (isset($error)): ?>
        <div class="alert alert-danger">
            <strong>Error:</strong> <?php echo htmlspecialchars($error); ?>
        </div>
    <?php endif; ?>

    <div class="features">
        <div class="feature-card">
            <h3>📦 Product Management</h3>
            <p>Add, edit, and manage your products with ease</p>
        </div>
        <div class="feature-card">
            <h3>🔍 Search & Filter</h3>
            <p>Find products quickly with our advanced search</p>
        </div>
        <div class="feature-card">
            <h3>📊 Analytics</h3>
            <p>Track your inventory and sales performance</p>
        </div>
    </div>

    <?php if (!empty($products)): ?>
        <div class="recent-products">
            <h2>Recent Products</h2>
            <div class="product-grid">
                <?php foreach ($products as $product): ?>
                    <div class="product-card">
                        <h4><?php echo htmlspecialchars($product['name']); ?></h4>
                        <p class="price">$<?php echo number_format($product['price'], 2); ?></p>
                        <p class="category"><?php echo htmlspecialchars($product['category']); ?></p>
                        <p class="description"><?php echo htmlspecialchars(substr($product['description'], 0, 100)) . '...'; ?></p>
                    </div>
                <?php endforeach; ?>
            </div>
        </div>
    <?php endif; ?>

    <div class="stats">
        <div class="stat-item">
            <h3><?php echo count($products); ?></h3>
            <p>Total Products</p>
        </div>
        <div class="stat-item">
            <h3>99.9%</h3>
            <p>Uptime</p>
        </div>
        <div class="stat-item">
            <h3>24/7</h3>
            <p>Support</p>
        </div>
    </div>
</div>

<?php require_once 'includes/footer.php'; ?>
