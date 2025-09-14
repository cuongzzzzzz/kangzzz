# Project 5: Cloud Native Architecture - AWS/Azure/GCP

## 📋 Tổng quan dự án
- **Level**: Enterprise Cloud
- **Stack**: Cloud Native + Serverless + Container Orchestration
- **Kiến trúc**: Multi-cloud với cloud-native services
- **Mục đích**: Scalable cloud-native application với auto-scaling
- **Thời gian deploy**: 120-180 phút

## 🏗️ Kiến trúc hệ thống
```
Internet → CDN (CloudFlare) → API Gateway (AWS API Gateway) → Lambda Functions
                                                              ↓
    ┌─────────────────────────────────────────────────────────────┐
    │                    Serverless Layer                        │
    ├─────────────────┬─────────────────┬─────────────────────────┤
    │   User Service  │  Product Service│   Order Service         │
    │   (Lambda)      │   (Lambda)      │   (Lambda)              │
    ├─────────────────┼─────────────────┼─────────────────────────┤
    │  Payment Service│  Notification   │   Analytics Service     │
    │   (Lambda)      │   Service (SNS) │   (Kinesis)             │
    └─────────────────┴─────────────────┴─────────────────────────┘
                                                              ↓
    ┌─────────────────────────────────────────────────────────────┐
    │                    Cloud Data Layer                        │
    ├─────────────────┬─────────────────┬─────────────────────────┤
    │   RDS Aurora    │   DynamoDB      │   ElastiCache           │
    │   (PostgreSQL)  │   (NoSQL)       │   (Redis)               │
    ├─────────────────┼─────────────────┼─────────────────────────┤
    │   S3 Storage    │   CloudSearch   │   SQS/SNS               │
    │   (Files)       │   (Search)      │   (Messaging)           │
    └─────────────────┴─────────────────┴─────────────────────────┘
```

## 📁 Cấu trúc dự án
```
project-05-cloud-native/
├── README.md
├── infrastructure/
│   ├── aws/
│   │   ├── terraform/
│   │   ├── cloudformation/
│   │   └── cdk/
│   ├── azure/
│   │   ├── terraform/
│   │   ├── arm-templates/
│   │   └── bicep/
│   └── gcp/
│       ├── terraform/
│       ├── deployment-manager/
│       └── cloud-functions/
├── applications/
│   ├── frontend/
│   │   ├── react-app/
│   │   └── nextjs-app/
│   ├── backend/
│   │   ├── lambda-functions/
│   │   ├── container-apps/
│   │   └── serverless-functions/
│   └── mobile/
│       ├── react-native/
│       └── flutter/
├── data/
│   ├── databases/
│   ├── storage/
│   └── analytics/
├── monitoring/
│   ├── cloudwatch/
│   ├── azure-monitor/
│   └── stackdriver/
├── security/
│   ├── iam/
│   ├── secrets/
│   └── compliance/
└── deploy/
    ├── deploy-aws.sh
    ├── deploy-azure.sh
    ├── deploy-gcp.sh
    └── deploy-multi-cloud.sh
```

## 🚀 Hướng dẫn Deploy

### Bước 1: Chuẩn bị Cloud Environment
```bash
# Cài đặt AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Cài đặt Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Cài đặt Google Cloud CLI
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Cài đặt Terraform
wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
unzip terraform_1.5.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Cài đặt Pulumi
curl -fsSL https://get.pulumi.com | sh
```

### Bước 2: Deploy AWS Infrastructure
```bash
# Configure AWS credentials
aws configure

# Deploy with Terraform
cd infrastructure/aws/terraform
terraform init
terraform plan
terraform apply

# Deploy with CDK
cd infrastructure/aws/cdk
npm install
cdk bootstrap
cdk deploy --all
```

### Bước 3: Deploy Azure Infrastructure
```bash
# Login to Azure
az login

# Deploy with Terraform
cd infrastructure/azure/terraform
terraform init
terraform plan
terraform apply

# Deploy with Bicep
cd infrastructure/azure/bicep
az deployment group create --resource-group myResourceGroup --template-file main.bicep
```

### Bước 4: Deploy GCP Infrastructure
```bash
# Login to GCP
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

# Deploy with Terraform
cd infrastructure/gcp/terraform
terraform init
terraform plan
terraform apply

# Deploy with Deployment Manager
cd infrastructure/gcp/deployment-manager
gcloud deployment-manager deployments create my-deployment --config config.yaml
```

### Bước 5: Deploy Applications
```bash
# Deploy to AWS
./deploy/deploy-aws.sh

# Deploy to Azure
./deploy/deploy-azure.sh

# Deploy to GCP
./deploy/deploy-gcp.sh

# Deploy to multi-cloud
./deploy/deploy-multi-cloud.sh
```

## 🔧 Cấu hình chi tiết

### AWS Lambda Functions
```python
# applications/backend/lambda-functions/user-service/handler.py
import json
import boto3
import os
from decimal import Decimal
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS services
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['USERS_TABLE_NAME'])

def lambda_handler(event, context):
    """
    Lambda function to handle user operations
    """
    try:
        # Parse the event
        http_method = event['httpMethod']
        path_parameters = event.get('pathParameters', {})
        body = json.loads(event.get('body', '{}'))
        
        if http_method == 'GET':
            if 'userId' in path_parameters:
                return get_user(path_parameters['userId'])
            else:
                return list_users()
        elif http_method == 'POST':
            return create_user(body)
        elif http_method == 'PUT':
            return update_user(path_parameters['userId'], body)
        elif http_method == 'DELETE':
            return delete_user(path_parameters['userId'])
        else:
            return {
                'statusCode': 405,
                'body': json.dumps({'error': 'Method not allowed'})
            }
    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error'})
        }

def get_user(user_id):
    """Get a single user by ID"""
    try:
        response = table.get_item(Key={'userId': user_id})
        if 'Item' in response:
            return {
                'statusCode': 200,
                'body': json.dumps(response['Item'], default=decimal_default)
            }
        else:
            return {
                'statusCode': 404,
                'body': json.dumps({'error': 'User not found'})
            }
    except Exception as e:
        logger.error(f"Error getting user: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Failed to get user'})
        }

def list_users():
    """List all users"""
    try:
        response = table.scan()
        return {
            'statusCode': 200,
            'body': json.dumps(response['Items'], default=decimal_default)
        }
    except Exception as e:
        logger.error(f"Error listing users: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Failed to list users'})
        }

def create_user(user_data):
    """Create a new user"""
    try:
        user_id = user_data.get('userId')
        if not user_id:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'userId is required'})
            }
        
        # Add timestamp
        user_data['createdAt'] = int(time.time())
        user_data['updatedAt'] = int(time.time())
        
        table.put_item(Item=user_data)
        
        return {
            'statusCode': 201,
            'body': json.dumps(user_data, default=decimal_default)
        }
    except Exception as e:
        logger.error(f"Error creating user: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Failed to create user'})
        }

def update_user(user_id, user_data):
    """Update an existing user"""
    try:
        # Add updated timestamp
        user_data['updatedAt'] = int(time.time())
        
        # Update the item
        response = table.update_item(
            Key={'userId': user_id},
            UpdateExpression='SET #name = :name, #email = :email, #updatedAt = :updatedAt',
            ExpressionAttributeNames={
                '#name': 'name',
                '#email': 'email',
                '#updatedAt': 'updatedAt'
            },
            ExpressionAttributeValues={
                ':name': user_data.get('name'),
                ':email': user_data.get('email'),
                ':updatedAt': user_data['updatedAt']
            },
            ReturnValues='ALL_NEW'
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps(response['Attributes'], default=decimal_default)
        }
    except Exception as e:
        logger.error(f"Error updating user: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Failed to update user'})
        }

def delete_user(user_id):
    """Delete a user"""
    try:
        table.delete_item(Key={'userId': user_id})
        return {
            'statusCode': 204,
            'body': json.dumps({'message': 'User deleted successfully'})
        }
    except Exception as e:
        logger.error(f"Error deleting user: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Failed to delete user'})
        }

def decimal_default(obj):
    """Convert Decimal to float for JSON serialization"""
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError
```

### Azure Functions
```python
# applications/backend/azure-functions/product-service/__init__.py
import azure.functions as func
import json
import logging
import os
from azure.cosmos import CosmosClient
from azure.cosmos.exceptions import CosmosResourceNotFoundError

app = func.FunctionApp()

# Initialize Cosmos DB client
cosmos_client = CosmosClient(
    os.environ['COSMOS_ENDPOINT'], 
    os.environ['COSMOS_KEY']
)
database = cosmos_client.get_database_client(os.environ['COSMOS_DATABASE'])
container = database.get_container_client(os.environ['COSMOS_CONTAINER'])

@app.function_name(name="GetProducts")
@app.route(route="products", methods=["GET"])
def get_products(req: func.HttpRequest) -> func.HttpResponse:
    """Get all products"""
    try:
        # Query products from Cosmos DB
        items = list(container.read_all_items())
        
        return func.HttpResponse(
            json.dumps(items),
            status_code=200,
            mimetype="application/json"
        )
    except Exception as e:
        logging.error(f"Error getting products: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Failed to get products"}),
            status_code=500,
            mimetype="application/json"
        )

@app.function_name(name="GetProduct")
@app.route(route="products/{id}", methods=["GET"])
def get_product(req: func.HttpRequest) -> func.HttpResponse:
    """Get a single product by ID"""
    try:
        product_id = req.route_params.get('id')
        
        # Get product from Cosmos DB
        item = container.read_item(item=product_id, partition_key=product_id)
        
        return func.HttpResponse(
            json.dumps(item),
            status_code=200,
            mimetype="application/json"
        )
    except CosmosResourceNotFoundError:
        return func.HttpResponse(
            json.dumps({"error": "Product not found"}),
            status_code=404,
            mimetype="application/json"
        )
    except Exception as e:
        logging.error(f"Error getting product: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Failed to get product"}),
            status_code=500,
            mimetype="application/json"
        )

@app.function_name(name="CreateProduct")
@app.route(route="products", methods=["POST"])
def create_product(req: func.HttpRequest) -> func.HttpResponse:
    """Create a new product"""
    try:
        product_data = req.get_json()
        
        # Add timestamp
        product_data['createdAt'] = int(time.time())
        product_data['updatedAt'] = int(time.time())
        
        # Create product in Cosmos DB
        created_item = container.create_item(body=product_data)
        
        return func.HttpResponse(
            json.dumps(created_item),
            status_code=201,
            mimetype="application/json"
        )
    except Exception as e:
        logging.error(f"Error creating product: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Failed to create product"}),
            status_code=500,
            mimetype="application/json"
        )
```

### Google Cloud Functions
```javascript
// applications/backend/gcp-functions/order-service/index.js
const { Firestore } = require('@google-cloud/firestore');
const { PubSub } = require('@google-cloud/pubsub');

// Initialize Firestore
const firestore = new Firestore();
const ordersCollection = firestore.collection('orders');

// Initialize Pub/Sub
const pubsub = new PubSub();
const orderTopic = pubsub.topic('order-events');

/**
 * HTTP Cloud Function to handle order operations
 */
exports.orderService = async (req, res) => {
  // Set CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const { method, path } = req;
    const pathParts = path.split('/').filter(part => part);

    if (method === 'GET') {
      if (pathParts.length === 1) {
        // GET /orders - List all orders
        await listOrders(req, res);
      } else if (pathParts.length === 2) {
        // GET /orders/{id} - Get specific order
        await getOrder(req, res, pathParts[1]);
      }
    } else if (method === 'POST') {
      // POST /orders - Create new order
      await createOrder(req, res);
    } else if (method === 'PUT') {
      // PUT /orders/{id} - Update order
      await updateOrder(req, res, pathParts[1]);
    } else if (method === 'DELETE') {
      // DELETE /orders/{id} - Delete order
      await deleteOrder(req, res, pathParts[1]);
    } else {
      res.status(405).json({ error: 'Method not allowed' });
    }
  } catch (error) {
    console.error('Error processing request:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

async function listOrders(req, res) {
  try {
    const snapshot = await ordersCollection.get();
    const orders = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    res.status(200).json(orders);
  } catch (error) {
    console.error('Error listing orders:', error);
    res.status(500).json({ error: 'Failed to list orders' });
  }
}

async function getOrder(req, res, orderId) {
  try {
    const orderDoc = await ordersCollection.doc(orderId).get();
    
    if (!orderDoc.exists) {
      res.status(404).json({ error: 'Order not found' });
      return;
    }

    res.status(200).json({
      id: orderDoc.id,
      ...orderDoc.data()
    });
  } catch (error) {
    console.error('Error getting order:', error);
    res.status(500).json({ error: 'Failed to get order' });
  }
}

async function createOrder(req, res) {
  try {
    const orderData = req.body;
    
    // Add timestamp
    orderData.createdAt = new Date().toISOString();
    orderData.updatedAt = new Date().toISOString();
    orderData.status = 'pending';

    // Create order in Firestore
    const orderRef = await ordersCollection.add(orderData);
    
    // Publish order created event
    await orderTopic.publishMessage({
      data: Buffer.from(JSON.stringify({
        type: 'order_created',
        orderId: orderRef.id,
        orderData: orderData
      }))
    });

    res.status(201).json({
      id: orderRef.id,
      ...orderData
    });
  } catch (error) {
    console.error('Error creating order:', error);
    res.status(500).json({ error: 'Failed to create order' });
  }
}

async function updateOrder(req, res, orderId) {
  try {
    const updateData = req.body;
    updateData.updatedAt = new Date().toISOString();

    // Update order in Firestore
    await ordersCollection.doc(orderId).update(updateData);
    
    // Publish order updated event
    await orderTopic.publishMessage({
      data: Buffer.from(JSON.stringify({
        type: 'order_updated',
        orderId: orderId,
        updateData: updateData
      }))
    });

    res.status(200).json({ message: 'Order updated successfully' });
  } catch (error) {
    console.error('Error updating order:', error);
    res.status(500).json({ error: 'Failed to update order' });
  }
}

async function deleteOrder(req, res, orderId) {
  try {
    // Delete order from Firestore
    await ordersCollection.doc(orderId).delete();
    
    // Publish order deleted event
    await orderTopic.publishMessage({
      data: Buffer.from(JSON.stringify({
        type: 'order_deleted',
        orderId: orderId
      }))
    });

    res.status(204).send('');
  } catch (error) {
    console.error('Error deleting order:', error);
    res.status(500).json({ error: 'Failed to delete order' });
  }
}
```

## 📊 Cloud Monitoring

### AWS CloudWatch
```yaml
# monitoring/aws/cloudwatch-dashboard.json
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          [ "AWS/Lambda", "Invocations", "FunctionName", "user-service" ],
          [ ".", "Errors", ".", "." ],
          [ ".", "Duration", ".", "." ]
        ],
        "period": 300,
        "stat": "Average",
        "region": "us-east-1",
        "title": "Lambda Functions"
      }
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          [ "AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", "users" ],
          [ ".", "ConsumedWriteCapacityUnits", ".", "." ]
        ],
        "period": 300,
        "stat": "Sum",
        "region": "us-east-1",
        "title": "DynamoDB Usage"
      }
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          [ "AWS/ElastiCache", "CurrConnections", "CacheClusterId", "redis-cluster" ],
          [ ".", "CacheHits", ".", "." ],
          [ ".", "CacheMisses", ".", "." ]
        ],
        "period": 300,
        "stat": "Average",
        "region": "us-east-1",
        "title": "ElastiCache Performance"
      }
    }
  ]
}
```

### Azure Monitor
```json
{
  "query": "requests | where timestamp > ago(1h) | summarize count() by bin(timestamp, 5m), resultCode",
  "visualization": "timechart",
  "title": "Request Rate by Status Code"
}
```

### Google Cloud Monitoring
```yaml
# monitoring/gcp/alerting-policy.yaml
displayName: "High Error Rate"
conditions:
  - displayName: "Error rate is high"
    conditionThreshold:
      filter: 'resource.type="cloud_function" AND metric.type="logging.googleapis.com/user/error_count"'
      comparison: COMPARISON_GREATER_THAN
      thresholdValue: 10
      duration: "300s"
alertStrategy:
  autoClose: "1800s"
notificationChannels:
  - "projects/my-project/notificationChannels/123456789"
```

## 🚨 Disaster Recovery

### Multi-Region Setup
```bash
# AWS Multi-Region
aws configure set region us-west-2
terraform apply -var="region=us-west-2"

# Azure Multi-Region
az deployment group create --resource-group myResourceGroup --template-file main.bicep --parameters region=westus2

# GCP Multi-Region
gcloud deployment-manager deployments create my-deployment --config config.yaml --properties=region=us-west2
```

### Backup Strategy
```bash
# AWS S3 Cross-Region Replication
aws s3api put-bucket-replication --bucket my-bucket --replication-configuration file://replication.json

# Azure Cross-Region Backup
az backup vault create --resource-group myResourceGroup --name myVault --location eastus

# GCP Cross-Region Backup
gsutil mb -l us-west2 gs://my-backup-bucket-west2
```

## 📈 Cost Optimization

### Auto-Scaling Configuration
```yaml
# AWS Auto Scaling
AutoScalingGroup:
  Type: AWS::AutoScaling::AutoScalingGroup
  Properties:
    MinSize: 1
    MaxSize: 10
    DesiredCapacity: 3
    TargetGroupARNs:
      - !Ref TargetGroup
    LaunchTemplate:
      LaunchTemplateId: !Ref LaunchTemplate
      Version: !GetAtt LaunchTemplate.LatestVersionNumber
    Policies:
      - PolicyName: ScaleUpPolicy
        ScalingAdjustment: 1
        AdjustmentType: ChangeInCapacity
      - PolicyName: ScaleDownPolicy
        ScalingAdjustment: -1
        AdjustmentType: ChangeInCapacity
```

### Cost Monitoring
```bash
# AWS Cost Explorer
aws ce get-cost-and-usage --time-period Start=2023-01-01,End=2023-01-31 --granularity MONTHLY --metrics BlendedCost

# Azure Cost Management
az consumption usage list --start-date 2023-01-01 --end-date 2023-01-31

# GCP Cost Management
gcloud billing budgets list --billing-account=123456-789ABC-DEF012
```

## 📝 Checklist khôi phục

- [ ] Cloud provider setup và configuration
- [ ] Infrastructure as Code deployment
- [ ] Serverless functions deployment
- [ ] Database setup và configuration
- [ ] Monitoring và alerting setup
- [ ] Security configuration
- [ ] Backup strategy implementation
- [ ] Multi-region setup
- [ ] Cost optimization
- [ ] Disaster recovery testing

## 🎯 Next Steps

1. **Multi-cloud strategy** cho vendor lock-in avoidance
2. **Advanced monitoring** với APM và distributed tracing
3. **Security hardening** với zero-trust architecture
4. **Compliance** với SOC2, ISO27001, GDPR
5. **Cost optimization** với FinOps practices

---

*Dự án này phù hợp cho enterprise cần cloud-native application với auto-scaling, high availability và cost optimization.*
