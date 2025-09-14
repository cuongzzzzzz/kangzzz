from flask import Flask, jsonify, request
from flask_cors import CORS
import pymongo
import redis
import os
import logging
from datetime import datetime
from marshmallow import Schema, fields, ValidationError
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
import time

app = Flask(__name__)
CORS(app)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('/var/log/product-service.log')
    ]
)
logger = logging.getLogger(__name__)

# Prometheus metrics
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
REQUEST_DURATION = Histogram('http_request_duration_seconds', 'HTTP request duration', ['method', 'endpoint'])

# MongoDB connection
try:
    mongo_client = pymongo.MongoClient(
        host=os.getenv('MONGODB_HOST', 'mongodb-service'),
        port=int(os.getenv('MONGODB_PORT', 27017)),
        username=os.getenv('MONGODB_USER', 'root'),
        password=os.getenv('MONGODB_PASSWORD', 'password'),
        serverSelectionTimeoutMS=5000,
        connectTimeoutMS=5000,
        socketTimeoutMS=5000
    )
    db = mongo_client[os.getenv('MONGODB_DB', 'products')]
    products_collection = db.products
    logger.info("Connected to MongoDB")
except Exception as e:
    logger.error(f"Failed to connect to MongoDB: {e}")
    mongo_client = None
    db = None
    products_collection = None

# Redis connection
try:
    redis_client = redis.Redis(
        host=os.getenv('REDIS_HOST', 'redis-service'),
        port=int(os.getenv('REDIS_PORT', 6379)),
        decode_responses=True,
        socket_connect_timeout=5,
        socket_timeout=5,
        retry_on_timeout=True
    )
    redis_client.ping()
    logger.info("Connected to Redis")
except Exception as e:
    logger.error(f"Failed to connect to Redis: {e}")
    redis_client = None

# Validation schemas
class ProductSchema(Schema):
    name = fields.Str(required=True, validate=lambda x: len(x) >= 2 and len(x) <= 100)
    description = fields.Str(required=True, validate=lambda x: len(x) >= 10 and len(x) <= 1000)
    price = fields.Float(required=True, validate=lambda x: x > 0)
    category = fields.Str(required=True, validate=lambda x: len(x) >= 2 and len(x) <= 50)
    stock = fields.Int(required=True, validate=lambda x: x >= 0)
    sku = fields.Str(required=True, validate=lambda x: len(x) >= 3 and len(x) <= 50)

product_schema = ProductSchema()

# Middleware for metrics
@app.before_request
def before_request():
    request.start_time = time.time()

@app.after_request
def after_request(response):
    if hasattr(request, 'start_time'):
        duration = time.time() - request.start_time
        REQUEST_DURATION.labels(method=request.method, endpoint=request.endpoint).observe(duration)
    
    REQUEST_COUNT.labels(
        method=request.method, 
        endpoint=request.endpoint or 'unknown',
        status=response.status_code
    ).inc()
    
    return response

@app.route('/health')
def health_check():
    try:
        # Check MongoDB connection
        if mongo_client:
            mongo_client.admin.command('ping')
        else:
            raise Exception("MongoDB not connected")
        
        # Check Redis connection
        if redis_client:
            redis_client.ping()
        else:
            raise Exception("Redis not connected")
        
        return jsonify({
            'status': 'healthy',
            'service': 'product-service',
            'timestamp': datetime.utcnow().isoformat(),
            'version': '1.0.0'
        }), 200
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        return jsonify({
            'status': 'unhealthy',
            'service': 'product-service',
            'error': str(e),
            'timestamp': datetime.utcnow().isoformat()
        }), 503

@app.route('/metrics')
def metrics():
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

@app.route('/api/products')
def get_products():
    try:
        # Check cache first
        if redis_client:
            cached = redis_client.get('products:all')
            if cached:
                logger.info("Products retrieved from cache")
                return jsonify(eval(cached))
        
        # Get from database
        if not products_collection:
            return jsonify({'error': 'Database not available'}), 503
            
        products = list(products_collection.find({}, {'_id': 0}).sort('created_at', -1))
        
        # Cache for 5 minutes
        if redis_client:
            redis_client.setex('products:all', 300, str(products))
        
        logger.info(f"Retrieved {len(products)} products from database")
        return jsonify(products)
    except Exception as e:
        logger.error(f"Error getting products: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/api/products/<product_id>')
def get_product(product_id):
    try:
        # Check cache first
        if redis_client:
            cached = redis_client.get(f'product:{product_id}')
            if cached:
                logger.info(f"Product {product_id} retrieved from cache")
                return jsonify(eval(cached))
        
        # Get from database
        if not products_collection:
            return jsonify({'error': 'Database not available'}), 503
            
        product = products_collection.find_one({'id': product_id}, {'_id': 0})
        if not product:
            return jsonify({'error': 'Product not found'}), 404
        
        # Cache for 10 minutes
        if redis_client:
            redis_client.setex(f'product:{product_id}', 600, str(product))
        
        logger.info(f"Product {product_id} retrieved from database")
        return jsonify(product)
    except Exception as e:
        logger.error(f"Error getting product {product_id}: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/api/products', methods=['POST'])
def create_product():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        # Validate input
        try:
            validated_data = product_schema.load(data)
        except ValidationError as e:
            return jsonify({'error': 'Validation error', 'details': e.messages}), 400
        
        # Check if SKU already exists
        if products_collection and products_collection.find_one({'sku': validated_data['sku']}):
            return jsonify({'error': 'SKU already exists'}), 409
        
        # Add metadata
        validated_data['id'] = str(products_collection.count_documents({}) + 1)
        validated_data['created_at'] = datetime.utcnow().isoformat()
        validated_data['updated_at'] = datetime.utcnow().isoformat()
        
        if products_collection:
            result = products_collection.insert_one(validated_data)
            
            # Invalidate cache
            if redis_client:
                redis_client.delete('products:all')
            
            logger.info(f"Product created with ID: {validated_data['id']}")
            return jsonify({'id': validated_data['id'], 'message': 'Product created'}), 201
        else:
            return jsonify({'error': 'Database not available'}), 503
            
    except Exception as e:
        logger.error(f"Error creating product: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/api/products/<product_id>', methods=['PUT'])
def update_product(product_id):
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        # Validate input
        try:
            validated_data = product_schema.load(data)
        except ValidationError as e:
            return jsonify({'error': 'Validation error', 'details': e.messages}), 400
        
        if not products_collection:
            return jsonify({'error': 'Database not available'}), 503
        
        # Check if product exists
        existing_product = products_collection.find_one({'id': product_id})
        if not existing_product:
            return jsonify({'error': 'Product not found'}), 404
        
        # Update product
        validated_data['updated_at'] = datetime.utcnow().isoformat()
        result = products_collection.update_one(
            {'id': product_id},
            {'$set': validated_data}
        )
        
        if result.modified_count > 0:
            # Invalidate cache
            if redis_client:
                redis_client.delete(f'product:{product_id}')
                redis_client.delete('products:all')
            
            logger.info(f"Product {product_id} updated")
            return jsonify({'message': 'Product updated successfully'}), 200
        else:
            return jsonify({'error': 'Product not updated'}), 500
            
    except Exception as e:
        logger.error(f"Error updating product {product_id}: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/api/products/<product_id>', methods=['DELETE'])
def delete_product(product_id):
    try:
        if not products_collection:
            return jsonify({'error': 'Database not available'}), 503
        
        # Check if product exists
        existing_product = products_collection.find_one({'id': product_id})
        if not existing_product:
            return jsonify({'error': 'Product not found'}), 404
        
        # Delete product
        result = products_collection.delete_one({'id': product_id})
        
        if result.deleted_count > 0:
            # Invalidate cache
            if redis_client:
                redis_client.delete(f'product:{product_id}')
                redis_client.delete('products:all')
            
            logger.info(f"Product {product_id} deleted")
            return jsonify({'message': 'Product deleted successfully'}), 200
        else:
            return jsonify({'error': 'Product not deleted'}), 500
            
    except Exception as e:
        logger.error(f"Error deleting product {product_id}: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Route not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    logger.error(f"Internal server error: {error}")
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.getenv('PORT', 5000)), debug=False)
