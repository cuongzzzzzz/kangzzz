from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import psycopg2
import redis
import os
import logging
from datetime import datetime, timedelta
from typing import List, Optional
from pydantic import BaseModel
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
import time
import json

app = FastAPI(
    title="Analytics Service",
    description="Analytics microservice for microservices demo",
    version="1.0.0"
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('/var/log/analytics-service.log')
    ]
)
logger = logging.getLogger(__name__)

# Prometheus metrics
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
REQUEST_DURATION = Histogram('http_request_duration_seconds', 'HTTP request duration', ['method', 'endpoint'])

# Database connection
def get_db_connection():
    try:
        conn = psycopg2.connect(
            host=os.getenv('POSTGRES_HOST', 'postgres-service'),
            port=os.getenv('POSTGRES_PORT', 5432),
            database=os.getenv('POSTGRES_DB', 'analytics'),
            user=os.getenv('POSTGRES_USER', 'postgres'),
            password=os.getenv('POSTGRES_PASSWORD', 'password')
        )
        return conn
    except Exception as e:
        logger.error(f"Failed to connect to database: {e}")
        return None

# Redis connection
def get_redis_connection():
    try:
        r = redis.Redis(
            host=os.getenv('REDIS_HOST', 'redis-service'),
            port=int(os.getenv('REDIS_PORT', 6379)),
            decode_responses=True,
            socket_connect_timeout=5,
            socket_timeout=5,
            retry_on_timeout=True
        )
        r.ping()
        return r
    except Exception as e:
        logger.error(f"Failed to connect to Redis: {e}")
        return None

# Pydantic models
class AnalyticsData(BaseModel):
    id: Optional[int] = None
    event_type: str
    user_id: int
    data: dict
    timestamp: Optional[datetime] = None

class AnalyticsQuery(BaseModel):
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    event_type: Optional[str] = None
    user_id: Optional[int] = None

class AnalyticsResponse(BaseModel):
    total_events: int
    events_by_type: dict
    events_by_user: dict
    events_by_date: dict
    top_users: List[dict]
    top_events: List[dict]

# Middleware
@app.middleware("http")
async def metrics_middleware(request, call_next):
    start_time = time.time()
    
    response = await call_next(request)
    
    duration = time.time() - start_time
    REQUEST_DURATION.labels(method=request.method, endpoint=request.url.path).observe(duration)
    REQUEST_COUNT.labels(method=request.method, endpoint=request.url.path, status=response.status_code).inc()
    
    return response

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health_check():
    try:
        # Check database connection
        conn = get_db_connection()
        if not conn:
            raise Exception("Database not available")
        
        with conn.cursor() as cursor:
            cursor.execute("SELECT 1")
        
        conn.close()
        
        # Check Redis connection
        redis_conn = get_redis_connection()
        if not redis_conn:
            raise Exception("Redis not available")
        
        return {
            "status": "healthy",
            "service": "analytics-service",
            "timestamp": datetime.utcnow().isoformat(),
            "version": "1.0.0"
        }
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        return JSONResponse(
            status_code=503,
            content={
                "status": "unhealthy",
                "service": "analytics-service",
                "error": str(e),
                "timestamp": datetime.utcnow().isoformat()
            }
        )

@app.get("/metrics")
async def metrics():
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}

@app.post("/api/analytics")
async def create_analytics_data(data: AnalyticsData):
    try:
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=503, detail="Database not available")
        
        with conn.cursor() as cursor:
            cursor.execute("""
                INSERT INTO analytics_data (event_type, user_id, data, timestamp)
                VALUES (%s, %s, %s, %s)
                RETURNING id
            """, (data.event_type, data.user_id, json.dumps(data.data), data.timestamp or datetime.utcnow()))
            
            analytics_id = cursor.fetchone()[0]
            conn.commit()
        
        conn.close()
        
        # Invalidate cache
        redis_conn = get_redis_connection()
        if redis_conn:
            redis_conn.delete("analytics:*")
        
        logger.info(f"Analytics data created with ID: {analytics_id}")
        return {"id": analytics_id, "message": "Analytics data created successfully"}
        
    except Exception as e:
        logger.error(f"Error creating analytics data: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.get("/api/analytics")
async def get_analytics_data(query: AnalyticsQuery = Depends()):
    try:
        # Check cache first
        redis_conn = get_redis_connection()
        cache_key = f"analytics:query:{hash(str(query.dict()))}"
        
        if redis_conn:
            cached = redis_conn.get(cache_key)
            if cached:
                logger.info("Analytics data retrieved from cache")
                return json.loads(cached)
        
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=503, detail="Database not available")
        
        # Build query
        where_conditions = []
        params = []
        
        if query.start_date:
            where_conditions.append("timestamp >= %s")
            params.append(query.start_date)
        
        if query.end_date:
            where_conditions.append("timestamp <= %s")
            params.append(query.end_date)
        
        if query.event_type:
            where_conditions.append("event_type = %s")
            params.append(query.event_type)
        
        if query.user_id:
            where_conditions.append("user_id = %s")
            params.append(query.user_id)
        
        where_clause = " AND ".join(where_conditions) if where_conditions else "1=1"
        
        with conn.cursor() as cursor:
            # Get total events
            cursor.execute(f"SELECT COUNT(*) FROM analytics_data WHERE {where_clause}", params)
            total_events = cursor.fetchone()[0]
            
            # Get events by type
            cursor.execute(f"""
                SELECT event_type, COUNT(*) as count
                FROM analytics_data
                WHERE {where_clause}
                GROUP BY event_type
                ORDER BY count DESC
            """, params)
            events_by_type = {row[0]: row[1] for row in cursor.fetchall()}
            
            # Get events by user
            cursor.execute(f"""
                SELECT user_id, COUNT(*) as count
                FROM analytics_data
                WHERE {where_clause}
                GROUP BY user_id
                ORDER BY count DESC
                LIMIT 10
            """, params)
            events_by_user = {str(row[0]): row[1] for row in cursor.fetchall()}
            
            # Get events by date
            cursor.execute(f"""
                SELECT DATE(timestamp) as date, COUNT(*) as count
                FROM analytics_data
                WHERE {where_clause}
                GROUP BY DATE(timestamp)
                ORDER BY date DESC
                LIMIT 30
            """, params)
            events_by_date = {str(row[0]): row[1] for row in cursor.fetchall()}
            
            # Get top users
            cursor.execute(f"""
                SELECT user_id, COUNT(*) as count
                FROM analytics_data
                WHERE {where_clause}
                GROUP BY user_id
                ORDER BY count DESC
                LIMIT 5
            """, params)
            top_users = [{"user_id": row[0], "count": row[1]} for row in cursor.fetchall()]
            
            # Get top events
            cursor.execute(f"""
                SELECT event_type, COUNT(*) as count
                FROM analytics_data
                WHERE {where_clause}
                GROUP BY event_type
                ORDER BY count DESC
                LIMIT 5
            """, params)
            top_events = [{"event_type": row[0], "count": row[1]} for row in cursor.fetchall()]
        
        conn.close()
        
        result = AnalyticsResponse(
            total_events=total_events,
            events_by_type=events_by_type,
            events_by_user=events_by_user,
            events_by_date=events_by_date,
            top_users=top_users,
            top_events=top_events
        )
        
        # Cache for 5 minutes
        if redis_conn:
            redis_conn.setex(cache_key, 300, json.dumps(result.dict()))
        
        logger.info(f"Retrieved analytics data: {total_events} total events")
        return result
        
    except Exception as e:
        logger.error(f"Error getting analytics data: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.get("/api/analytics/summary")
async def get_analytics_summary():
    try:
        # Check cache first
        redis_conn = get_redis_connection()
        if redis_conn:
            cached = redis_conn.get("analytics:summary")
            if cached:
                logger.info("Analytics summary retrieved from cache")
                return json.loads(cached)
        
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=503, detail="Database not available")
        
        with conn.cursor() as cursor:
            # Get summary statistics
            cursor.execute("""
                SELECT 
                    COUNT(*) as total_events,
                    COUNT(DISTINCT user_id) as unique_users,
                    COUNT(DISTINCT event_type) as unique_event_types,
                    MIN(timestamp) as first_event,
                    MAX(timestamp) as last_event
                FROM analytics_data
            """)
            
            summary = cursor.fetchone()
            
            # Get recent activity (last 24 hours)
            cursor.execute("""
                SELECT COUNT(*) as recent_events
                FROM analytics_data
                WHERE timestamp >= NOW() - INTERVAL '24 hours'
            """)
            
            recent_events = cursor.fetchone()[0]
        
        conn.close()
        
        result = {
            "total_events": summary[0],
            "unique_users": summary[1],
            "unique_event_types": summary[2],
            "first_event": summary[3].isoformat() if summary[3] else None,
            "last_event": summary[4].isoformat() if summary[4] else None,
            "recent_events_24h": recent_events
        }
        
        # Cache for 1 minute
        if redis_conn:
            redis_conn.setex("analytics:summary", 60, json.dumps(result))
        
        logger.info("Retrieved analytics summary")
        return result
        
    except Exception as e:
        logger.error(f"Error getting analytics summary: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.get("/api/analytics/events/{event_type}")
async def get_events_by_type(event_type: str, limit: int = 100):
    try:
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=503, detail="Database not available")
        
        with conn.cursor() as cursor:
            cursor.execute("""
                SELECT id, user_id, data, timestamp
                FROM analytics_data
                WHERE event_type = %s
                ORDER BY timestamp DESC
                LIMIT %s
            """, (event_type, limit))
            
            events = []
            for row in cursor.fetchall():
                events.append({
                    "id": row[0],
                    "user_id": row[1],
                    "data": json.loads(row[2]),
                    "timestamp": row[3].isoformat()
                })
        
        conn.close()
        
        logger.info(f"Retrieved {len(events)} events of type {event_type}")
        return {"events": events, "count": len(events)}
        
    except Exception as e:
        logger.error(f"Error getting events by type {event_type}: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.delete("/api/analytics/{analytics_id}")
async def delete_analytics_data(analytics_id: int):
    try:
        conn = get_db_connection()
        if not conn:
            raise HTTPException(status_code=503, detail="Database not available")
        
        with conn.cursor() as cursor:
            cursor.execute("DELETE FROM analytics_data WHERE id = %s", (analytics_id,))
            
            if cursor.rowcount == 0:
                raise HTTPException(status_code=404, detail="Analytics data not found")
            
            conn.commit()
        
        conn.close()
        
        # Invalidate cache
        redis_conn = get_redis_connection()
        if redis_conn:
            redis_conn.delete("analytics:*")
        
        logger.info(f"Analytics data {analytics_id} deleted")
        return {"message": "Analytics data deleted successfully"}
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting analytics data {analytics_id}: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
