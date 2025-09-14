// MongoDB initialization script for Modern Web App
// This script sets up the database with collections, indexes, and sample data

// Switch to the application database
db = db.getSiblingDB('modernwebapp');

print('Initializing Modern Web App database...');

// Create collections
db.createCollection('users');
db.createCollection('products');
db.createCollection('orders');
db.createCollection('categories');
db.createCollection('reviews');
db.createCollection('cart');
db.createCollection('wishlist');
db.createCollection('notifications');

print('Collections created successfully');

// Create indexes for better performance
print('Creating indexes...');

// Users collection indexes
db.users.createIndex({ "email": 1 }, { unique: true });
db.users.createIndex({ "username": 1 }, { unique: true });
db.users.createIndex({ "createdAt": -1 });
db.users.createIndex({ "isActive": 1 });

// Products collection indexes
db.products.createIndex({ "name": "text", "description": "text", "tags": "text" });
db.products.createIndex({ "category": 1 });
db.products.createIndex({ "price": 1 });
db.products.createIndex({ "stock": 1 });
db.products.createIndex({ "isActive": 1 });
db.products.createIndex({ "createdAt": -1 });
db.products.createIndex({ "rating": -1 });

// Orders collection indexes
db.orders.createIndex({ "userId": 1 });
db.orders.createIndex({ "orderNumber": 1 }, { unique: true });
db.orders.createIndex({ "status": 1 });
db.orders.createIndex({ "createdAt": -1 });
db.orders.createIndex({ "totalAmount": 1 });

// Categories collection indexes
db.categories.createIndex({ "name": 1 }, { unique: true });
db.categories.createIndex({ "slug": 1 }, { unique: true });
db.categories.createIndex({ "isActive": 1 });
db.categories.createIndex({ "parentId": 1 });

// Reviews collection indexes
db.reviews.createIndex({ "productId": 1 });
db.reviews.createIndex({ "userId": 1 });
db.reviews.createIndex({ "rating": 1 });
db.reviews.createIndex({ "createdAt": -1 });

print('Indexes created successfully');

// Insert sample categories
print('Inserting sample categories...');
db.categories.insertMany([
  {
    name: 'Electronics',
    slug: 'electronics',
    description: 'Electronic devices and accessories',
    image: 'https://images.unsplash.com/photo-1498049794561-7780e7231661?w=400',
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    name: 'Clothing',
    slug: 'clothing',
    description: 'Fashion and apparel for men, women, and children',
    image: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400',
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    name: 'Home & Garden',
    slug: 'home-garden',
    description: 'Home improvement and garden supplies',
    image: 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=400',
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    name: 'Sports',
    slug: 'sports',
    description: 'Sports equipment and accessories',
    image: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400',
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    name: 'Books',
    slug: 'books',
    description: 'Books and educational materials',
    image: 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=400',
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    name: 'Toys',
    slug: 'toys',
    description: 'Toys and games for all ages',
    image: 'https://images.unsplash.com/photo-1558060370-9b8c421e4a6a?w=400',
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date()
  }
]);

print('Sample categories inserted');

// Insert sample products
print('Inserting sample products...');
db.products.insertMany([
  {
    name: 'MacBook Pro 16"',
    description: 'High-performance laptop for professionals with M2 Pro chip, 16GB RAM, and 512GB SSD',
    price: 2499.99,
    originalPrice: 2799.99,
    category: 'Electronics',
    categoryId: ObjectId(),
    sku: 'MBP16-001',
    stock: 25,
    images: [
      'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800',
      'https://images.unsplash.com/photo-1541807084-5c52b6b3adef?w=800'
    ],
    tags: ['laptop', 'macbook', 'apple', 'professional', 'm2'],
    specifications: {
      processor: 'Apple M2 Pro',
      memory: '16GB',
      storage: '512GB SSD',
      display: '16.2-inch Liquid Retina XDR',
      graphics: '19-core GPU'
    },
    rating: 4.8,
    reviewCount: 156,
    isActive: true,
    isFeatured: true,
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    name: 'iPhone 15 Pro',
    description: 'Latest iPhone with A17 Pro chip, Pro camera system, and titanium design',
    price: 999.99,
    originalPrice: 1099.99,
    category: 'Electronics',
    categoryId: ObjectId(),
    sku: 'IP15P-001',
    stock: 100,
    images: [
      'https://images.unsplash.com/photo-1592899677977-9c10b588e209?w=800',
      'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=800'
    ],
    tags: ['iphone', 'smartphone', 'apple', 'pro', 'camera'],
    specifications: {
      processor: 'A17 Pro',
      memory: '8GB',
      storage: '128GB',
      display: '6.1-inch Super Retina XDR',
      camera: '48MP Main, 12MP Ultra Wide, 12MP Telephoto'
    },
    rating: 4.7,
    reviewCount: 89,
    isActive: true,
    isFeatured: true,
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    name: 'Nike Air Max 270',
    description: 'Comfortable running shoes with Max Air cushioning and breathable mesh upper',
    price: 150.00,
    originalPrice: 180.00,
    category: 'Sports',
    categoryId: ObjectId(),
    sku: 'NAM270-001',
    stock: 75,
    images: [
      'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800',
      'https://images.unsplash.com/photo-1606107557195-0e29a4b5b4aa?w=800'
    ],
    tags: ['nike', 'shoes', 'running', 'sports', 'air max'],
    specifications: {
      brand: 'Nike',
      type: 'Running Shoes',
      size: 'US 7-12',
      color: 'Black/White',
      material: 'Mesh and Synthetic'
    },
    rating: 4.5,
    reviewCount: 234,
    isActive: true,
    isFeatured: false,
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    name: 'Coffee Maker Deluxe',
    description: 'Automatic coffee maker with programmable timer, 12-cup capacity, and built-in grinder',
    price: 89.99,
    originalPrice: 120.00,
    category: 'Home & Garden',
    categoryId: ObjectId(),
    sku: 'CMD-001',
    stock: 30,
    images: [
      'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=800',
      'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=800'
    ],
    tags: ['coffee', 'maker', 'kitchen', 'appliance', 'programmable'],
    specifications: {
      capacity: '12 cups',
      features: ['Programmable Timer', 'Built-in Grinder', 'Auto Shut-off'],
      material: 'Stainless Steel',
      power: '120V'
    },
    rating: 4.3,
    reviewCount: 67,
    isActive: true,
    isFeatured: false,
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    name: 'Wireless Bluetooth Headphones',
    description: 'Noise-cancelling wireless headphones with 30-hour battery life and premium sound quality',
    price: 199.99,
    originalPrice: 249.99,
    category: 'Electronics',
    categoryId: ObjectId(),
    sku: 'WBH-001',
    stock: 50,
    images: [
      'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800',
      'https://images.unsplash.com/photo-1484704849700-f032a568e944?w=800'
    ],
    tags: ['headphones', 'wireless', 'bluetooth', 'noise-cancelling', 'audio'],
    specifications: {
      connectivity: 'Bluetooth 5.0',
      battery: '30 hours',
      noiseCancelling: 'Active',
      driver: '40mm',
      frequency: '20Hz - 20kHz'
    },
    rating: 4.6,
    reviewCount: 123,
    isActive: true,
    isFeatured: true,
    createdAt: new Date(),
    updatedAt: new Date()
  }
]);

print('Sample products inserted');

// Insert sample admin user
print('Inserting sample admin user...');
db.users.insertOne({
  username: 'admin',
  email: 'admin@modernwebapp.com',
  password: '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', // password
  firstName: 'Admin',
  lastName: 'User',
  role: 'admin',
  isActive: true,
  emailVerified: true,
  lastLogin: new Date(),
  createdAt: new Date(),
  updatedAt: new Date()
});

// Insert sample regular user
db.users.insertOne({
  username: 'demo',
  email: 'demo@modernwebapp.com',
  password: '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', // password
  firstName: 'Demo',
  lastName: 'User',
  role: 'user',
  isActive: true,
  emailVerified: true,
  lastLogin: new Date(),
  createdAt: new Date(),
  updatedAt: new Date()
});

print('Sample users inserted');

// Create views for common queries
print('Creating database views...');

// Product summary view
db.createView('product_summary', 'products', [
  {
    $match: { isActive: true }
  },
  {
    $project: {
      name: 1,
      price: 1,
      originalPrice: 1,
      category: 1,
      stock: 1,
      rating: 1,
      reviewCount: 1,
      isFeatured: 1,
      createdAt: 1,
      discount: {
        $cond: {
          if: { $gt: ['$originalPrice', '$price'] },
          then: {
            $round: [
              {
                $multiply: [
                  {
                    $divide: [
                      { $subtract: ['$originalPrice', '$price'] },
                      '$originalPrice'
                    ]
                  },
                  100
                ]
              },
              0
            ]
          },
          else: 0
        }
      }
    }
  }
]);

// Low stock products view
db.createView('low_stock_products', 'products', [
  {
    $match: {
      isActive: true,
      stock: { $lt: 10 }
    }
  },
  {
    $project: {
      name: 1,
      sku: 1,
      stock: 1,
      category: 1,
      price: 1
    }
  },
  {
    $sort: { stock: 1 }
  }
]);

print('Database views created');

// Create stored procedures (using MongoDB functions)
print('Creating stored procedures...');

// Function to get products by category
db.system.js.save({
  _id: 'getProductsByCategory',
  value: function(categoryName) {
    return db.products.find({
      category: categoryName,
      isActive: true
    }).sort({ createdAt: -1 }).toArray();
  }
});

// Function to search products
db.system.js.save({
  _id: 'searchProducts',
  value: function(searchTerm) {
    return db.products.find({
      $text: { $search: searchTerm },
      isActive: true
    }).sort({ score: { $meta: 'textScore' } }).toArray();
  }
});

// Function to get product statistics
db.system.js.save({
  _id: 'getProductStats',
  value: function() {
    return db.products.aggregate([
      {
        $group: {
          _id: null,
          totalProducts: { $sum: 1 },
          activeProducts: {
            $sum: { $cond: ['$isActive', 1, 0] }
          },
          lowStockProducts: {
            $sum: { $cond: [{ $lt: ['$stock', 10] }, 1, 0] }
          },
          averagePrice: { $avg: '$price' },
          highestPrice: { $max: '$price' },
          lowestPrice: { $min: '$price' },
          totalValue: {
            $sum: { $multiply: ['$price', '$stock'] }
          }
        }
      }
    ]).toArray();
  }
});

print('Stored procedures created');

// Create triggers (using MongoDB change streams)
print('Setting up change streams...');

// Create a change stream for product updates
const productChangeStream = db.products.watch([
  { $match: { operationType: { $in: ['insert', 'update', 'delete'] } } }
]);

// Log changes to a collection
productChangeStream.on('change', function(change) {
  db.audit_log.insertOne({
    collection: 'products',
    operation: change.operationType,
    documentId: change.documentKey._id,
    timestamp: new Date(),
    fullDocument: change.fullDocument,
    updatedFields: change.updateDescription?.updatedFields
  });
});

print('Change streams configured');

print('Modern Web App database initialization completed successfully!');
print('Database: ' + db.getName());
print('Collections: ' + db.getCollectionNames().join(', '));
print('Total products: ' + db.products.countDocuments());
print('Total categories: ' + db.categories.countDocuments());
print('Total users: ' + db.users.countDocuments());
