#!/bin/bash

# Cloud Native AWS Deployment Script
# This script automates the deployment of cloud-native applications to AWS

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="cloud-native"
AWS_REGION="us-east-1"
ENVIRONMENT="production"
LOG_FILE="/var/log/$PROJECT_NAME-aws-deploy.log"

# Functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a $LOG_FILE
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a $LOG_FILE
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a $LOG_FILE
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a $LOG_FILE
    exit 1
}

info() {
    echo -e "${PURPLE}[INFO]${NC} $1" | tee -a $LOG_FILE
}

highlight() {
    echo -e "${CYAN}[HIGHLIGHT]${NC} $1" | tee -a $LOG_FILE
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        error "AWS CLI is not installed. Please install AWS CLI first."
    fi
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        error "Terraform is not installed. Please install Terraform first."
    fi
    
    # Check if Node.js is installed
    if ! command -v node &> /dev/null; then
        error "Node.js is not installed. Please install Node.js first."
    fi
    
    # Check if Python is installed
    if ! command -v python3 &> /dev/null; then
        error "Python 3 is not installed. Please install Python 3 first."
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        error "AWS credentials not configured. Please run 'aws configure' first."
    fi
    
    # Check AWS region
    aws configure set region $AWS_REGION
    
    success "Prerequisites check completed"
}

# Deploy infrastructure with Terraform
deploy_infrastructure() {
    log "Deploying AWS infrastructure with Terraform..."
    
    cd infrastructure/aws/terraform
    
    # Initialize Terraform
    terraform init
    
    # Create terraform.tfvars if it doesn't exist
    if [ ! -f terraform.tfvars ]; then
        cat > terraform.tfvars << EOF
aws_region = "$AWS_REGION"
project_name = "$PROJECT_NAME"
environment = "$ENVIRONMENT"
vpc_cidr = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
database_subnet_cidrs = ["10.0.100.0/24", "10.0.200.0/24"]
instance_type = "t3.medium"
min_size = 1
max_size = 10
desired_capacity = 3
db_instance_class = "db.t3.micro"
db_allocated_storage = 20
db_max_allocated_storage = 100
db_username = "postgres"
db_password = "changeme123"
redis_node_type = "cache.t3.micro"
redis_num_cache_nodes = 2
EOF
    fi
    
    # Plan deployment
    terraform plan -out=tfplan
    
    # Apply deployment
    terraform apply tfplan
    
    # Get outputs
    terraform output -json > ../../terraform-outputs.json
    
    cd ../..
    
    success "AWS infrastructure deployed successfully"
}

# Deploy Lambda functions
deploy_lambda_functions() {
    log "Deploying Lambda functions..."
    
    # Install dependencies
    cd applications/backend/lambda-functions
    
    # Deploy user service
    cd user-service
    npm install
    zip -r user-service.zip .
    aws lambda create-function \
        --function-name user-service \
        --runtime nodejs18.x \
        --role arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/lambda-execution-role \
        --handler index.handler \
        --zip-file fileb://user-service.zip \
        --timeout 30 \
        --memory-size 256
    cd ..
    
    # Deploy product service
    cd product-service
    npm install
    zip -r product-service.zip .
    aws lambda create-function \
        --function-name product-service \
        --runtime nodejs18.x \
        --role arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/lambda-execution-role \
        --handler index.handler \
        --zip-file fileb://product-service.zip \
        --timeout 30 \
        --memory-size 256
    cd ..
    
    # Deploy order service
    cd order-service
    npm install
    zip -r order-service.zip .
    aws lambda create-function \
        --function-name order-service \
        --runtime nodejs18.x \
        --role arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/lambda-execution-role \
        --handler index.handler \
        --zip-file fileb://order-service.zip \
        --timeout 30 \
        --memory-size 256
    cd ..
    
    cd ../../..
    
    success "Lambda functions deployed successfully"
}

# Deploy API Gateway
deploy_api_gateway() {
    log "Deploying API Gateway..."
    
    # Create API Gateway
    API_ID=$(aws apigateway create-rest-api \
        --name "$PROJECT_NAME-api" \
        --description "Cloud Native API Gateway" \
        --query 'id' --output text)
    
    # Get root resource ID
    ROOT_RESOURCE_ID=$(aws apigateway get-resources \
        --rest-api-id $API_ID \
        --query 'items[0].id' --output text)
    
    # Create /users resource
    USERS_RESOURCE_ID=$(aws apigateway create-resource \
        --rest-api-id $API_ID \
        --parent-id $ROOT_RESOURCE_ID \
        --path-part users \
        --query 'id' --output text)
    
    # Create /products resource
    PRODUCTS_RESOURCE_ID=$(aws apigateway create-resource \
        --rest-api-id $API_ID \
        --parent-id $ROOT_RESOURCE_ID \
        --path-part products \
        --query 'id' --output text)
    
    # Create /orders resource
    ORDERS_RESOURCE_ID=$(aws apigateway create-resource \
        --rest-api-id $API_ID \
        --parent-id $ROOT_RESOURCE_ID \
        --path-part orders \
        --query 'id' --output text)
    
    # Create methods for each resource
    aws apigateway put-method \
        --rest-api-id $API_ID \
        --resource-id $USERS_RESOURCE_ID \
        --http-method GET \
        --authorization-type NONE
    
    aws apigateway put-method \
        --rest-api-id $API_ID \
        --resource-id $PRODUCTS_RESOURCE_ID \
        --http-method GET \
        --authorization-type NONE
    
    aws apigateway put-method \
        --rest-api-id $API_ID \
        --resource-id $ORDERS_RESOURCE_ID \
        --http-method GET \
        --authorization-type NONE
    
    # Deploy API
    aws apigateway create-deployment \
        --rest-api-id $API_ID \
        --stage-name $ENVIRONMENT
    
    success "API Gateway deployed successfully"
}

# Deploy DynamoDB tables
deploy_dynamodb_tables() {
    log "Deploying DynamoDB tables..."
    
    # Create users table
    aws dynamodb create-table \
        --table-name users \
        --attribute-definitions \
            AttributeName=userId,AttributeType=S \
        --key-schema \
            AttributeName=userId,KeyType=HASH \
        --provisioned-throughput \
            ReadCapacityUnits=5,WriteCapacityUnits=5
    
    # Create products table
    aws dynamodb create-table \
        --table-name products \
        --attribute-definitions \
            AttributeName=productId,AttributeType=S \
        --key-schema \
            AttributeName=productId,KeyType=HASH \
        --provisioned-throughput \
            ReadCapacityUnits=5,WriteCapacityUnits=5
    
    # Create orders table
    aws dynamodb create-table \
        --table-name orders \
        --attribute-definitions \
            AttributeName=orderId,AttributeType=S \
        --key-schema \
            AttributeName=orderId,KeyType=HASH \
        --provisioned-throughput \
            ReadCapacityUnits=5,WriteCapacityUnits=5
    
    # Wait for tables to be created
    aws dynamodb wait table-exists --table-name users
    aws dynamodb wait table-exists --table-name products
    aws dynamodb wait table-exists --table-name orders
    
    success "DynamoDB tables created successfully"
}

# Deploy S3 buckets
deploy_s3_buckets() {
    log "Deploying S3 buckets..."
    
    # Create main bucket
    BUCKET_NAME="$PROJECT_NAME-$ENVIRONMENT-$(date +%s)"
    aws s3 mb s3://$BUCKET_NAME --region $AWS_REGION
    
    # Create static assets bucket
    STATIC_BUCKET_NAME="$PROJECT_NAME-static-$ENVIRONMENT-$(date +%s)"
    aws s3 mb s3://$STATIC_BUCKET_NAME --region $AWS_REGION
    
    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket $BUCKET_NAME \
        --versioning-configuration Status=Enabled
    
    aws s3api put-bucket-versioning \
        --bucket $STATIC_BUCKET_NAME \
        --versioning-configuration Status=Enabled
    
    # Enable encryption
    aws s3api put-bucket-encryption \
        --bucket $BUCKET_NAME \
        --server-side-encryption-configuration '{
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }
            ]
        }'
    
    success "S3 buckets created successfully"
}

# Deploy CloudFront distribution
deploy_cloudfront() {
    log "Deploying CloudFront distribution..."
    
    # Create CloudFront distribution
    DISTRIBUTION_ID=$(aws cloudfront create-distribution \
        --distribution-config '{
            "CallerReference": "'$(date +%s)'",
            "Comment": "Cloud Native CDN",
            "DefaultCacheBehavior": {
                "TargetOriginId": "S3-'$STATIC_BUCKET_NAME'",
                "ViewerProtocolPolicy": "redirect-to-https",
                "TrustedSigners": {
                    "Enabled": false,
                    "Quantity": 0
                },
                "ForwardedValues": {
                    "QueryString": false,
                    "Cookies": {
                        "Forward": "none"
                    }
                },
                "MinTTL": 0,
                "DefaultTTL": 86400,
                "MaxTTL": 31536000
            },
            "Origins": {
                "Quantity": 1,
                "Items": [
                    {
                        "Id": "S3-'$STATIC_BUCKET_NAME'",
                        "DomainName": "'$STATIC_BUCKET_NAME'.s3.amazonaws.com",
                        "S3OriginConfig": {
                            "OriginAccessIdentity": ""
                        }
                    }
                ]
            },
            "Enabled": true,
            "PriceClass": "PriceClass_100"
        }' \
        --query 'Distribution.Id' --output text)
    
    success "CloudFront distribution created successfully"
}

# Deploy monitoring
deploy_monitoring() {
    log "Deploying monitoring stack..."
    
    # Create CloudWatch log groups
    aws logs create-log-group --log-group-name /aws/lambda/user-service
    aws logs create-log-group --log-group-name /aws/lambda/product-service
    aws logs create-log-group --log-group-name /aws/lambda/order-service
    
    # Create CloudWatch alarms
    aws cloudwatch put-metric-alarm \
        --alarm-name "Lambda-Error-Rate" \
        --alarm-description "Lambda function error rate" \
        --metric-name Errors \
        --namespace AWS/Lambda \
        --statistic Sum \
        --period 300 \
        --threshold 5 \
        --comparison-operator GreaterThanThreshold \
        --evaluation-periods 2
    
    # Create SNS topic for alerts
    SNS_TOPIC_ARN=$(aws sns create-topic \
        --name "$PROJECT_NAME-alerts" \
        --query 'TopicArn' --output text)
    
    # Subscribe to SNS topic
    aws sns subscribe \
        --topic-arn $SNS_TOPIC_ARN \
        --protocol email \
        --notification-endpoint admin@example.com
    
    success "Monitoring stack deployed successfully"
}

# Deploy frontend to S3
deploy_frontend() {
    log "Deploying frontend to S3..."
    
    cd applications/frontend
    
    # Install dependencies
    npm install
    
    # Build application
    npm run build
    
    # Upload to S3
    aws s3 sync build/ s3://$STATIC_BUCKET_NAME --delete
    
    # Invalidate CloudFront cache
    aws cloudfront create-invalidation \
        --distribution-id $DISTRIBUTION_ID \
        --paths "/*"
    
    cd ../..
    
    success "Frontend deployed successfully"
}

# Verify deployment
verify_deployment() {
    log "Verifying deployment..."
    
    # Check Lambda functions
    aws lambda list-functions --query 'Functions[].FunctionName' --output table
    
    # Check DynamoDB tables
    aws dynamodb list-tables --query 'TableNames' --output table
    
    # Check S3 buckets
    aws s3 ls --query 'Buckets[].Name' --output table
    
    # Check API Gateway
    aws apigateway get-rest-apis --query 'items[].name' --output table
    
    success "Deployment verification completed"
}

# Show deployment information
show_info() {
    log "Cloud Native AWS deployment completed successfully!"
    echo
    echo "=========================================="
    echo "  Cloud Native AWS Deployment Information"
    echo "=========================================="
    echo
    echo "🌐 API Gateway:"
    echo "   URL: https://$API_ID.execute-api.$AWS_REGION.amazonaws.com/$ENVIRONMENT"
    echo "   Users: https://$API_ID.execute-api.$AWS_REGION.amazonaws.com/$ENVIRONMENT/users"
    echo "   Products: https://$API_ID.execute-api.$AWS_REGION.amazonaws.com/$ENVIRONMENT/products"
    echo "   Orders: https://$API_ID.execute-api.$AWS_REGION.amazonaws.com/$ENVIRONMENT/orders"
    echo
    echo "🔧 Lambda Functions:"
    echo "   User Service: user-service"
    echo "   Product Service: product-service"
    echo "   Order Service: order-service"
    echo
    echo "🗄️  Databases:"
    echo "   DynamoDB Tables: users, products, orders"
    echo "   RDS Aurora: $(terraform output -raw rds_endpoint 2>/dev/null || echo 'Not deployed')"
    echo "   ElastiCache: $(terraform output -raw redis_endpoint 2>/dev/null || echo 'Not deployed')"
    echo
    echo "📦 Storage:"
    echo "   S3 Bucket: $BUCKET_NAME"
    echo "   Static Assets: $STATIC_BUCKET_NAME"
    echo "   CloudFront: $DISTRIBUTION_ID"
    echo
    echo "📊 Monitoring:"
    echo "   CloudWatch: https://console.aws.amazon.com/cloudwatch/"
    echo "   SNS Alerts: $SNS_TOPIC_ARN"
    echo
    echo "📝 Useful Commands:"
    echo "   List functions: aws lambda list-functions"
    echo "   List tables: aws dynamodb list-tables"
    echo "   List buckets: aws s3 ls"
    echo "   View logs: aws logs tail /aws/lambda/user-service --follow"
    echo
    echo "=========================================="
}

# Cleanup function
cleanup() {
    log "Cleaning up AWS resources..."
    
    # Delete Lambda functions
    aws lambda delete-function --function-name user-service 2>/dev/null || true
    aws lambda delete-function --function-name product-service 2>/dev/null || true
    aws lambda delete-function --function-name order-service 2>/dev/null || true
    
    # Delete DynamoDB tables
    aws dynamodb delete-table --table-name users 2>/dev/null || true
    aws dynamodb delete-table --table-name products 2>/dev/null || true
    aws dynamodb delete-table --table-name orders 2>/dev/null || true
    
    # Delete S3 buckets
    aws s3 rb s3://$BUCKET_NAME --force 2>/dev/null || true
    aws s3 rb s3://$STATIC_BUCKET_NAME --force 2>/dev/null || true
    
    # Delete CloudFront distribution
    aws cloudfront delete-distribution --id $DISTRIBUTION_ID 2>/dev/null || true
    
    # Delete infrastructure with Terraform
    cd infrastructure/aws/terraform
    terraform destroy -auto-approve
    cd ../../..
    
    success "Cleanup completed"
}

# Main deployment function
main() {
    log "Starting Cloud Native AWS deployment..."
    
    check_prerequisites
    deploy_infrastructure
    deploy_lambda_functions
    deploy_api_gateway
    deploy_dynamodb_tables
    deploy_s3_buckets
    deploy_cloudfront
    deploy_monitoring
    deploy_frontend
    verify_deployment
    show_info
    
    success "Cloud Native AWS deployment completed successfully!"
}

# Handle script arguments
case "${1:-}" in
    "cleanup")
        cleanup
        ;;
    "status")
        aws lambda list-functions --query 'Functions[].FunctionName' --output table
        aws dynamodb list-tables --query 'TableNames' --output table
        aws s3 ls --query 'Buckets[].Name' --output table
        ;;
    "logs")
        aws logs tail /aws/lambda/${2:-user-service} --follow
        ;;
    "deploy-function")
        deploy_lambda_functions
        ;;
    "deploy-frontend")
        deploy_frontend
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo
        echo "Commands:"
        echo "  (no args)  Full deployment"
        echo "  cleanup     Remove all resources"
        echo "  status      Show deployment status"
        echo "  logs        Show logs for a function"
        echo "  deploy-function Deploy Lambda functions only"
        echo "  deploy-frontend Deploy frontend only"
        echo "  help        Show this help message"
        ;;
    *)
        main
        ;;
esac
