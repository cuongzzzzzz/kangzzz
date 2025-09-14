from flask import Flask, request, jsonify, render_template
from flask_cors import CORS
from flask_jwt_extended import JWTManager, jwt_required, get_jwt_identity, create_access_token
import psycopg2
import redis
import bcrypt
import os
import logging
from datetime import datetime, timedelta
import json

app = Flask(__name__)
app.config['JWT_SECRET_KEY'] = os.getenv('JWT_SECRET_KEY', 'your-secret-key')
app.config['JWT_ACCESS_TOKEN_EXPIRES'] = timedelta(hours=24)

# Initialize extensions
CORS(app)
jwt = JWTManager(app)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Database configuration
DB_CONFIG = {
    'host': os.getenv('POSTGRES_HOST', 'postgres-primary'),
    'port': os.getenv('POSTGRES_PORT', 5432),
    'database': os.getenv('POSTGRES_DB', 'enterprise'),
    'user': os.getenv('POSTGRES_USER', 'postgres'),
    'password': os.getenv('POSTGRES_PASSWORD', 'password')
}

# Redis configuration
REDIS_CONFIG = {
    'host': os.getenv('REDIS_HOST', 'redis-master'),
    'port': int(os.getenv('REDIS_PORT', 6379)),
    'password': os.getenv('REDIS_PASSWORD', 'password'),
    'decode_responses': True
}

def get_db_connection():
    """Get database connection"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        return conn
    except Exception as e:
        logger.error(f"Database connection error: {e}")
        return None

def get_redis_connection():
    """Get Redis connection"""
    try:
        r = redis.Redis(**REDIS_CONFIG)
        r.ping()
        return r
    except Exception as e:
        logger.error(f"Redis connection error: {e}")
        return None

@app.route('/health')
def health_check():
    """Health check endpoint"""
    try:
        db_conn = get_db_connection()
        redis_conn = get_redis_connection()
        
        health_status = {
            'status': 'healthy',
            'timestamp': datetime.utcnow().isoformat(),
            'services': {
                'database': 'healthy' if db_conn else 'unhealthy',
                'cache': 'healthy' if redis_conn else 'unhealthy'
            }
        }
        
        if db_conn:
            db_conn.close()
        
        status_code = 200 if db_conn and redis_conn else 503
        return jsonify(health_status), status_code
        
    except Exception as e:
        logger.error(f"Health check error: {e}")
        return jsonify({
            'status': 'unhealthy',
            'error': str(e),
            'timestamp': datetime.utcnow().isoformat()
        }), 503

@app.route('/metrics')
def metrics():
    """Metrics endpoint"""
    try:
        metrics_data = {
            'timestamp': datetime.utcnow().isoformat(),
            'uptime': 'N/A',  # Would need to track start time
            'memory_usage': 'N/A',  # Would need psutil
            'active_connections': 'N/A'
        }
        return jsonify(metrics_data)
    except Exception as e:
        logger.error(f"Metrics error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/')
def index():
    """Admin dashboard home page"""
    return render_template('index.html')

@app.route('/login', methods=['POST'])
def login():
    """Admin login endpoint"""
    try:
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')
        
        if not email or not password:
            return jsonify({'error': 'Email and password required'}), 400
        
        conn = get_db_connection()
        if not conn:
            return jsonify({'error': 'Database connection failed'}), 500
        
        cursor = conn.cursor()
        cursor.execute(
            "SELECT id, name, email, password, role FROM users WHERE email = %s",
            (email,)
        )
        user = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if user and bcrypt.checkpw(password.encode('utf-8'), user[3].encode('utf-8')):
            access_token = create_access_token(identity=user[0])
            return jsonify({
                'access_token': access_token,
                'user': {
                    'id': user[0],
                    'name': user[1],
                    'email': user[2],
                    'role': user[4]
                }
            })
        else:
            return jsonify({'error': 'Invalid credentials'}), 401
            
    except Exception as e:
        logger.error(f"Login error: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/dashboard')
@jwt_required()
def dashboard():
    """Admin dashboard data"""
    try:
        current_user_id = get_jwt_identity()
        
        conn = get_db_connection()
        if not conn:
            return jsonify({'error': 'Database connection failed'}), 500
        
        cursor = conn.cursor()
        
        # Get user statistics
        cursor.execute("SELECT COUNT(*) FROM users")
        user_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM products")
        product_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM orders")
        order_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT SUM(total) FROM orders WHERE status = 'completed'")
        revenue = cursor.fetchone()[0] or 0
        
        # Get recent activities
        cursor.execute("""
            SELECT 'user' as type, name, email, created_at 
            FROM users 
            ORDER BY created_at DESC 
            LIMIT 5
        """)
        recent_users = cursor.fetchall()
        
        cursor.execute("""
            SELECT 'order' as type, id, total, status, created_at 
            FROM orders 
            ORDER BY created_at DESC 
            LIMIT 5
        """)
        recent_orders = cursor.fetchall()
        
        cursor.close()
        conn.close()
        
        dashboard_data = {
            'stats': {
                'users': user_count,
                'products': product_count,
                'orders': order_count,
                'revenue': float(revenue)
            },
            'recent_activities': {
                'users': [{'type': row[0], 'name': row[1], 'email': row[2], 'created_at': row[3].isoformat()} for row in recent_users],
                'orders': [{'type': row[0], 'id': row[1], 'total': float(row[2]), 'status': row[3], 'created_at': row[4].isoformat()} for row in recent_orders]
            }
        }
        
        return jsonify(dashboard_data)
        
    except Exception as e:
        logger.error(f"Dashboard error: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/users')
@jwt_required()
def get_users():
    """Get all users"""
    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({'error': 'Database connection failed'}), 500
        
        cursor = conn.cursor()
        cursor.execute("""
            SELECT id, name, email, created_at, updated_at 
            FROM users 
            ORDER BY created_at DESC
        """)
        users = cursor.fetchall()
        cursor.close()
        conn.close()
        
        user_list = []
        for user in users:
            user_list.append({
                'id': user[0],
                'name': user[1],
                'email': user[2],
                'created_at': user[3].isoformat(),
                'updated_at': user[4].isoformat() if user[4] else None
            })
        
        return jsonify(user_list)
        
    except Exception as e:
        logger.error(f"Get users error: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/products')
@jwt_required()
def get_products():
    """Get all products"""
    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({'error': 'Database connection failed'}), 500
        
        cursor = conn.cursor()
        cursor.execute("""
            SELECT id, name, description, price, stock, created_at, updated_at 
            FROM products 
            ORDER BY created_at DESC
        """)
        products = cursor.fetchall()
        cursor.close()
        conn.close()
        
        product_list = []
        for product in products:
            product_list.append({
                'id': product[0],
                'name': product[1],
                'description': product[2],
                'price': float(product[3]),
                'stock': product[4],
                'created_at': product[5].isoformat(),
                'updated_at': product[6].isoformat() if product[6] else None
            })
        
        return jsonify(product_list)
        
    except Exception as e:
        logger.error(f"Get products error: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/orders')
@jwt_required()
def get_orders():
    """Get all orders"""
    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({'error': 'Database connection failed'}), 500
        
        cursor = conn.cursor()
        cursor.execute("""
            SELECT o.id, o.total, o.status, o.created_at, o.updated_at,
                   u.name as user_name, u.email as user_email
            FROM orders o
            JOIN users u ON o.user_id = u.id
            ORDER BY o.created_at DESC
        """)
        orders = cursor.fetchall()
        cursor.close()
        conn.close()
        
        order_list = []
        for order in orders:
            order_list.append({
                'id': order[0],
                'total': float(order[1]),
                'status': order[2],
                'created_at': order[3].isoformat(),
                'updated_at': order[4].isoformat() if order[4] else None,
                'user_name': order[5],
                'user_email': order[6]
            })
        
        return jsonify(order_list)
        
    except Exception as e:
        logger.error(f"Get orders error: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/cache/status')
@jwt_required()
def cache_status():
    """Get cache status"""
    try:
        redis_conn = get_redis_connection()
        if not redis_conn:
            return jsonify({'status': 'disconnected', 'error': 'Redis connection failed'}), 500
        
        info = redis_conn.info()
        db_size = redis_conn.dbsize()
        
        cache_data = {
            'status': 'connected',
            'db_size': db_size,
            'memory_usage': info.get('used_memory_human', 'N/A'),
            'connected_clients': info.get('connected_clients', 'N/A'),
            'uptime': info.get('uptime_in_seconds', 'N/A')
        }
        
        return jsonify(cache_data)
        
    except Exception as e:
        logger.error(f"Cache status error: {e}")
        return jsonify({'status': 'disconnected', 'error': str(e)}), 500

@app.route('/cache/clear', methods=['POST'])
@jwt_required()
def clear_cache():
    """Clear cache"""
    try:
        redis_conn = get_redis_connection()
        if not redis_conn:
            return jsonify({'error': 'Redis connection failed'}), 500
        
        redis_conn.flushall()
        return jsonify({'message': 'Cache cleared successfully'})
        
    except Exception as e:
        logger.error(f"Clear cache error: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=False)
