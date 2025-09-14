#!/bin/bash

# Test script for Microservices Demo
# This script tests all microservices endpoints

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to test HTTP endpoint
test_endpoint() {
    local url=$1
    local expected_status=$2
    local service_name=$3
    
    print_status "Testing $service_name at $url"
    
    if response=$(curl -s -w "%{http_code}" -o /dev/null "$url" 2>/dev/null); then
        if [ "$response" = "$expected_status" ]; then
            print_success "$service_name is responding correctly (HTTP $response)"
            return 0
        else
            print_warning "$service_name returned HTTP $response (expected $expected_status)"
            return 1
        fi
    else
        print_error "$service_name is not responding"
        return 1
    fi
}

# Function to test API endpoint with data
test_api_endpoint() {
    local method=$1
    local url=$2
    local data=$3
    local expected_status=$4
    local service_name=$5
    
    print_status "Testing $service_name $method $url"
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "%{http_code}" -o /dev/null "$url" 2>/dev/null)
    else
        response=$(curl -s -w "%{http_code}" -o /dev/null -X "$method" -H "Content-Type: application/json" -d "$data" "$url" 2>/dev/null)
    fi
    
    if [ "$response" = "$expected_status" ]; then
        print_success "$service_name $method endpoint is working (HTTP $response)"
        return 0
    else
        print_warning "$service_name $method endpoint returned HTTP $response (expected $expected_status)"
        return 1
    fi
}

# Main test function
main() {
    print_status "Starting Microservices Demo tests"
    echo ""
    
    local failed_tests=0
    
    # Test health endpoints
    print_status "Testing health endpoints..."
    echo ""
    
    test_endpoint "http://localhost:8000/health" "200" "API Gateway" || ((failed_tests++))
    test_endpoint "http://localhost:3001/health" "200" "User Service" || ((failed_tests++))
    test_endpoint "http://localhost:5001/health" "200" "Product Service" || ((failed_tests++))
    test_endpoint "http://localhost:5002/health" "200" "Order Service" || ((failed_tests++))
    test_endpoint "http://localhost:8081/actuator/health" "200" "Payment Service" || ((failed_tests++))
    test_endpoint "http://localhost:3002/health" "200" "Notification Service" || ((failed_tests++))
    test_endpoint "http://localhost:8001/health" "200" "Analytics Service" || ((failed_tests++))
    
    echo ""
    print_status "Testing API endpoints..."
    echo ""
    
    # Test User Service APIs
    test_api_endpoint "GET" "http://localhost:8000/api/users" "" "200" "User Service (via API Gateway)" || ((failed_tests++))
    test_api_endpoint "POST" "http://localhost:8000/api/users" '{"name":"Test User","email":"test@example.com","phone":"+1-555-0100"}' "201" "User Service (via API Gateway)" || ((failed_tests++))
    
    # Test Product Service APIs
    test_api_endpoint "GET" "http://localhost:8000/api/products" "" "200" "Product Service (via API Gateway)" || ((failed_tests++))
    test_api_endpoint "POST" "http://localhost:8000/api/products" '{"name":"Test Product","description":"Test Description","price":99.99,"category":"Test","stock":10,"sku":"TEST-001"}' "201" "Product Service (via API Gateway)" || ((failed_tests++))
    
    # Test Order Service APIs
    test_api_endpoint "GET" "http://localhost:8000/api/orders" "" "200" "Order Service (via API Gateway)" || ((failed_tests++))
    test_api_endpoint "POST" "http://localhost:8000/api/orders" '{"user_id":1,"product_id":1,"quantity":1,"total":99.99,"status":"pending"}' "201" "Order Service (via API Gateway)" || ((failed_tests++))
    
    # Test Payment Service APIs
    test_api_endpoint "GET" "http://localhost:8000/api/payments" "" "200" "Payment Service (via API Gateway)" || ((failed_tests++))
    test_api_endpoint "POST" "http://localhost:8000/api/payments" '{"order_id":1,"user_id":1,"amount":99.99,"currency":"USD","payment_method":"credit_card","status":"pending"}' "201" "Payment Service (via API Gateway)" || ((failed_tests++))
    
    # Test Notification Service APIs
    test_api_endpoint "GET" "http://localhost:8000/api/notifications" "" "200" "Notification Service (via API Gateway)" || ((failed_tests++))
    test_api_endpoint "POST" "http://localhost:8000/api/notifications" '{"user_id":1,"type":"test","title":"Test Notification","message":"This is a test notification","channel":"email","status":"pending"}' "201" "Notification Service (via API Gateway)" || ((failed_tests++))
    
    # Test Analytics Service APIs
    test_api_endpoint "GET" "http://localhost:8000/api/analytics" "" "200" "Analytics Service (via API Gateway)" || ((failed_tests++))
    test_api_endpoint "POST" "http://localhost:8000/api/analytics" '{"event_type":"test_event","user_id":1,"data":{"test":"data"}}' "201" "Analytics Service (via API Gateway)" || ((failed_tests++))
    
    echo ""
    print_status "Testing monitoring endpoints..."
    echo ""
    
    # Test monitoring endpoints
    test_endpoint "http://localhost:9090/-/healthy" "200" "Prometheus" || ((failed_tests++))
    test_endpoint "http://localhost:3000/api/health" "200" "Grafana" || ((failed_tests++))
    test_endpoint "http://localhost:16686/api/services" "200" "Jaeger" || ((failed_tests++))
    
    echo ""
    print_status "Testing database connectivity..."
    echo ""
    
    # Test database connectivity through services
    test_api_endpoint "GET" "http://localhost:3001/api/users" "" "200" "PostgreSQL (via User Service)" || ((failed_tests++))
    test_api_endpoint "GET" "http://localhost:5001/api/products" "" "200" "MongoDB (via Product Service)" || ((failed_tests++))
    
    echo ""
    print_status "Test Summary"
    echo "============="
    
    if [ $failed_tests -eq 0 ]; then
        print_success "All tests passed! 🎉"
        echo ""
        print_status "Service URLs:"
        echo "  API Gateway:     http://localhost:8000"
        echo "  User Service:    http://localhost:3001"
        echo "  Product Service: http://localhost:5001"
        echo "  Order Service:   http://localhost:5002"
        echo "  Payment Service: http://localhost:8081"
        echo "  Notification:    http://localhost:3002"
        echo "  Analytics:       http://localhost:8001"
        echo ""
        print_status "Monitoring URLs:"
        echo "  Prometheus:      http://localhost:9090"
        echo "  Grafana:         http://localhost:3000 (admin/admin123)"
        echo "  Jaeger:          http://localhost:16686"
        exit 0
    else
        print_error "$failed_tests test(s) failed! ❌"
        echo ""
        print_status "Troubleshooting:"
        echo "  1. Check if all services are running: docker-compose ps"
        echo "  2. Check service logs: docker-compose logs [service-name]"
        echo "  3. Check service health: curl http://localhost:[port]/health"
        echo "  4. Restart services: docker-compose restart"
        exit 1
    fi
}

# Run main function
main "$@"
