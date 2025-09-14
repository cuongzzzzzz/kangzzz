// MongoDB initialization script for microservices demo
// This script creates collections and inserts sample data

// Switch to products database
db = db.getSiblingDB('products');

// Create products collection
db.createCollection('products');

// Insert sample products
db.products.insertMany([
  {
    id: "1",
    name: "MacBook Pro 16-inch",
    description: "Apple MacBook Pro with M2 Pro chip, 16GB RAM, 512GB SSD",
    price: 2499.99,
    category: "Laptops",
    stock: 50,
    sku: "MBP16-M2-512",
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    id: "2",
    name: "iPhone 15 Pro",
    description: "Apple iPhone 15 Pro with A17 Pro chip, 128GB storage",
    price: 999.99,
    category: "Phones",
    stock: 100,
    sku: "IP15P-128",
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    id: "3",
    name: "iPad Air 5th Gen",
    description: "Apple iPad Air with M1 chip, 64GB storage, Wi-Fi",
    price: 599.99,
    category: "Tablets",
    stock: 75,
    sku: "IPA5-64-WIFI",
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    id: "4",
    name: "AirPods Pro 2nd Gen",
    description: "Apple AirPods Pro with Active Noise Cancellation",
    price: 249.99,
    category: "Audio",
    stock: 200,
    sku: "APP2-ANC",
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    id: "5",
    name: "Apple Watch Series 9",
    description: "Apple Watch Series 9 with GPS, 45mm case",
    price: 429.99,
    category: "Wearables",
    stock: 150,
    sku: "AWS9-GPS-45",
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    id: "6",
    name: "Dell XPS 13",
    description: "Dell XPS 13 with Intel i7, 16GB RAM, 512GB SSD",
    price: 1299.99,
    category: "Laptops",
    stock: 30,
    sku: "DXPS13-I7-512",
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    id: "7",
    name: "Samsung Galaxy S24",
    description: "Samsung Galaxy S24 with 128GB storage, 5G",
    price: 799.99,
    category: "Phones",
    stock: 80,
    sku: "SGS24-128-5G",
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    id: "8",
    name: "Sony WH-1000XM5",
    description: "Sony WH-1000XM5 Wireless Noise Canceling Headphones",
    price: 399.99,
    category: "Audio",
    stock: 60,
    sku: "SWH1000XM5",
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    id: "9",
    name: "Microsoft Surface Pro 9",
    description: "Microsoft Surface Pro 9 with Intel i5, 8GB RAM, 256GB SSD",
    price: 1099.99,
    category: "Tablets",
    stock: 40,
    sku: "MSP9-I5-256",
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    id: "10",
    name: "Google Pixel 8",
    description: "Google Pixel 8 with 128GB storage, 5G",
    price: 699.99,
    category: "Phones",
    stock: 90,
    sku: "GP8-128-5G",
    created_at: new Date(),
    updated_at: new Date()
  }
]);

// Create indexes for better performance
db.products.createIndex({ "id": 1 }, { unique: true });
db.products.createIndex({ "sku": 1 }, { unique: true });
db.products.createIndex({ "category": 1 });
db.products.createIndex({ "price": 1 });
db.products.createIndex({ "stock": 1 });
db.products.createIndex({ "created_at": -1 });

// Create categories collection
db.createCollection('categories');

// Insert sample categories
db.categories.insertMany([
  {
    id: "1",
    name: "Laptops",
    description: "Portable computers for work and personal use",
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    id: "2",
    name: "Phones",
    description: "Mobile phones and smartphones",
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    id: "3",
    name: "Tablets",
    description: "Tablet computers and iPads",
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    id: "4",
    name: "Audio",
    description: "Headphones, speakers, and audio accessories",
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    id: "5",
    name: "Wearables",
    description: "Smartwatches and fitness trackers",
    created_at: new Date(),
    updated_at: new Date()
  }
]);

// Create indexes for categories
db.categories.createIndex({ "id": 1 }, { unique: true });
db.categories.createIndex({ "name": 1 }, { unique: true });

// Create product reviews collection
db.createCollection('product_reviews');

// Insert sample reviews
db.product_reviews.insertMany([
  {
    id: "1",
    product_id: "1",
    user_id: 1,
    rating: 5,
    title: "Excellent laptop!",
    comment: "The MacBook Pro is amazing. Great performance and build quality.",
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    id: "2",
    product_id: "1",
    user_id: 2,
    rating: 4,
    title: "Great but expensive",
    comment: "Love the laptop but it's quite expensive for what you get.",
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    id: "3",
    product_id: "2",
    user_id: 3,
    rating: 5,
    title: "Best phone ever!",
    comment: "The iPhone 15 Pro is incredible. Camera quality is outstanding.",
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    id: "4",
    product_id: "3",
    user_id: 4,
    rating: 4,
    title: "Good tablet",
    comment: "The iPad Air is great for work and entertainment.",
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    id: "5",
    product_id: "4",
    user_id: 5,
    rating: 5,
    title: "Amazing sound quality",
    comment: "The AirPods Pro have excellent noise cancellation and sound quality.",
    created_at: new Date(),
    updated_at: new Date()
  }
]);

// Create indexes for reviews
db.product_reviews.createIndex({ "id": 1 }, { unique: true });
db.product_reviews.createIndex({ "product_id": 1 });
db.product_reviews.createIndex({ "user_id": 1 });
db.product_reviews.createIndex({ "rating": 1 });
db.product_reviews.createIndex({ "created_at": -1 });

// Create product inventory collection
db.createCollection('product_inventory');

// Insert sample inventory data
db.product_inventory.insertMany([
  {
    product_id: "1",
    warehouse: "US-WEST-1",
    stock: 25,
    reserved: 5,
    available: 20,
    last_updated: new Date()
  },
  {
    product_id: "1",
    warehouse: "US-EAST-1",
    stock: 25,
    reserved: 3,
    available: 22,
    last_updated: new Date()
  },
  {
    product_id: "2",
    warehouse: "US-WEST-1",
    stock: 50,
    reserved: 10,
    available: 40,
    last_updated: new Date()
  },
  {
    product_id: "2",
    warehouse: "US-EAST-1",
    stock: 50,
    reserved: 8,
    available: 42,
    last_updated: new Date()
  },
  {
    product_id: "3",
    warehouse: "US-WEST-1",
    stock: 40,
    reserved: 5,
    available: 35,
    last_updated: new Date()
  },
  {
    product_id: "3",
    warehouse: "US-EAST-1",
    stock: 35,
    reserved: 3,
    available: 32,
    last_updated: new Date()
  }
]);

// Create indexes for inventory
db.product_inventory.createIndex({ "product_id": 1 });
db.product_inventory.createIndex({ "warehouse": 1 });
db.product_inventory.createIndex({ "available": 1 });

// Display summary
print("=== MongoDB Products Database Initialized ===");
print("Products collection:");
print("Total products: " + db.products.countDocuments());
print("Total categories: " + db.categories.countDocuments());
print("Total reviews: " + db.product_reviews.countDocuments());
print("Total inventory records: " + db.product_inventory.countDocuments());

// Show sample data
print("\nSample products:");
db.products.find({}, {name: 1, price: 1, category: 1, stock: 1}).limit(5).forEach(printjson);

print("\nSample categories:");
db.categories.find({}, {name: 1, description: 1}).forEach(printjson);

print("\nSample reviews:");
db.product_reviews.find({}, {product_id: 1, user_id: 1, rating: 1, title: 1}).limit(3).forEach(printjson);
