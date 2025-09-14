#!/bin/bash

# Enterprise Deployment Test Script
# This script tests the deployment and verifies all services are working

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BASE_URL="http://localhost"
TIMEOUT=30

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

test_endpoint() {
    local url=$1
    local expected_status=$2
    local service_name=$3
    
    log_info "Testing $service_name at $url"
    
    if response=$(curl -s -o /dev/null -w "%{http_code}" --max-time $TIMEOUT "$url" 2>/dev/null); then
        if [ "$response" = "$expected_status" ]; then
            log_success "$service_name is responding correctly (HTTP $response)"
            return 0
        else
            log_error "$service_name returned HTTP $response, expected $expected_status"
            return 1
        fi
    else
        log_error "$service_name is not responding"
        return 1
    fi
}

test_json_endpoint() {
    local url=$1
    local service_name=$2
    
    log_info "Testing $service_name JSON response at $url"
    
    if response=$(curl -s --max-time $TIMEOUT "$url" 2>/dev/null); then
        if echo "$response" | jq . >/dev/null 2>&1; then
            log_success "$service_name JSON response is valid"
            return 0
        else
            log_error "$service_name JSON response is invalid"
            return 1
        fi
    else
        log_error "$service_name is not responding"
        return 1
    fi
}

test_docker_services() {
    log_info "Testing Docker services..."
    
    # Check if docker-compose is running
    if ! docker-compose ps | grep -q "Up"; then
        log_error "Docker Compose services are not running"
        return 1
    fi
    
    # Count running services
    running_services=$(docker-compose ps | grep "Up" | wc -l)
    log_success "Docker services running: $running_services"
    
    # Check specific services
    services=("enterprise-haproxy" "enterprise-web1" "enterprise-api1" "enterprise-admin1" "enterprise-postgres-primary" "enterprise-redis-master")
    
    for service in "${services[@]}"; do
        if docker ps | grep -q "$service"; then
            log_success "Service $service is running"
        else
            log_error "Service $service is not running"
        fi
    done
}

test_web_services() {
    log_info "Testing web services..."
    
    # Test load balancer
    test_endpoint "$BASE_URL/health" "200" "Load Balancer"
    
    # Test web frontend
    test_endpoint "$BASE_URL" "200" "Web Frontend"
    
    # Test API health
    test_json_endpoint "$BASE_URL/api/health" "API Health"
    
    # Test admin panel
    test_endpoint "$BASE_URL/admin/health" "200" "Admin Panel"
}

test_monitoring_services() {
    log_info "Testing monitoring services..."
    
    # Test Prometheus
    test_endpoint "http://localhost:9090/-/healthy" "200" "Prometheus"
    
    # Test Grafana
    test_endpoint "http://localhost:3000/api/health" "200" "Grafana"
    
    # Test AlertManager
    test_endpoint "http://localhost:9093/-/healthy" "200" "AlertManager"
    
    # Test Kibana
    test_endpoint "http://localhost:5601/api/status" "200" "Kibana"
    
    # Test RabbitMQ
    test_endpoint "http://localhost:15672" "200" "RabbitMQ"
    
    # Test HAProxy Stats
    test_endpoint "http://localhost:8404" "200" "HAProxy Stats"
}

test_database_connections() {
    log_info "Testing database connections..."
    
    # Test PostgreSQL
    if docker exec enterprise-postgres-primary pg_isready -U postgres >/dev/null 2>&1; then
        log_success "PostgreSQL is ready"
    else
        log_error "PostgreSQL is not ready"
    fi
    
    # Test Redis
    if docker exec enterprise-redis-master redis-cli -a password ping >/dev/null 2>&1; then
        log_success "Redis is ready"
    else
        log_error "Redis is not ready"
    fi
}

test_api_functionality() {
    log_info "Testing API functionality..."
    
    # Test user registration
    log_info "Testing user registration..."
    if response=$(curl -s -X POST -H "Content-Type: application/json" \
        -d '{"name":"Test User","email":"test@example.com","password":"password123"}' \
        "$BASE_URL/api/auth/register" 2>/dev/null); then
        if echo "$response" | jq .token >/dev/null 2>&1; then
            log_success "User registration is working"
        else
            log_warning "User registration may have issues: $response"
        fi
    else
        log_warning "User registration test failed"
    fi
    
    # Test API metrics
    test_json_endpoint "$BASE_URL/api/metrics" "API Metrics"
}

test_load_balancing() {
    log_info "Testing load balancing..."
    
    # Test multiple requests to see if they're distributed
    log_info "Making multiple requests to test load balancing..."
    
    for i in {1..5}; do
        if curl -s --max-time 5 "$BASE_URL/health" >/dev/null 2>&1; then
            log_success "Request $i successful"
        else
            log_error "Request $i failed"
        fi
    done
}

generate_test_report() {
    local total_tests=$1
    local passed_tests=$2
    local failed_tests=$3
    
    echo ""
    echo "=========================================="
    echo "           TEST REPORT SUMMARY"
    echo "=========================================="
    echo "Total Tests: $total_tests"
    echo "Passed: $passed_tests"
    echo "Failed: $failed_tests"
    echo "Success Rate: $(( (passed_tests * 100) / total_tests ))%"
    echo "=========================================="
    
    if [ $failed_tests -eq 0 ]; then
        log_success "All tests passed! Deployment is successful."
    else
        log_warning "Some tests failed. Please check the logs and configuration."
    fi
}

# Main test function
main() {
    log_info "Starting Enterprise Deployment Test"
    echo ""
    
    local total_tests=0
    local passed_tests=0
    local failed_tests=0
    
    # Test Docker services
    if test_docker_services; then
        ((passed_tests++))
    else
        ((failed_tests++))
    fi
    ((total_tests++))
    
    # Test web services
    if test_web_services; then
        ((passed_tests++))
    else
        ((failed_tests++))
    fi
    ((total_tests++))
    
    # Test monitoring services
    if test_monitoring_services; then
        ((passed_tests++))
    else
        ((failed_tests++))
    fi
    ((total_tests++))
    
    # Test database connections
    if test_database_connections; then
        ((passed_tests++))
    else
        ((failed_tests++))
    fi
    ((total_tests++))
    
    # Test API functionality
    if test_api_functionality; then
        ((passed_tests++))
    else
        ((failed_tests++))
    fi
    ((total_tests++))
    
    # Test load balancing
    if test_load_balancing; then
        ((passed_tests++))
    else
        ((failed_tests++))
    fi
    ((total_tests++))
    
    # Generate report
    generate_test_report $total_tests $passed_tests $failed_tests
    
    echo ""
    log_info "Service URLs for manual testing:"
    echo "🌐 Web Application:     $BASE_URL"
    echo "🔧 API Endpoints:       $BASE_URL/api"
    echo "⚙️  Admin Panel:        $BASE_URL/admin"
    echo "📊 Prometheus:          http://localhost:9090"
    echo "📈 Grafana:             http://localhost:3000"
    echo "🚨 AlertManager:        http://localhost:9093"
    echo "🔍 Kibana:              http://localhost:5601"
    echo "🐰 RabbitMQ:            http://localhost:15672"
    echo "📈 HAProxy Stats:       http://localhost:8404"
}

# Check dependencies
if ! command -v curl &> /dev/null; then
    log_error "curl is required but not installed"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    log_warning "jq is not installed. JSON validation will be limited"
fi

# Run main function
main "$@"
