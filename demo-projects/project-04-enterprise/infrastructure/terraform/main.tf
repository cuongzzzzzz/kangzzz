# Enterprise Infrastructure - Terraform Configuration
# This configuration creates a complete enterprise infrastructure on AWS

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-lts-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# VPC
resource "aws_vpc" "enterprise_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "enterprise-vpc"
    Environment = var.environment
  }
}

# Internet Gateway
resource "aws_internet_gateway" "enterprise_igw" {
  vpc_id = aws_vpc.enterprise_vpc.id

  tags = {
    Name        = "enterprise-igw"
    Environment = var.environment
  }
}

# Public Subnets
resource "aws_subnet" "public_subnets" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.enterprise_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "enterprise-public-subnet-${count.index + 1}"
    Environment = var.environment
    Type        = "Public"
  }
}

# Private Subnets
resource "aws_subnet" "private_subnets" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.enterprise_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "enterprise-private-subnet-${count.index + 1}"
    Environment = var.environment
    Type        = "Private"
  }
}

# Database Subnets
resource "aws_subnet" "database_subnets" {
  count = length(var.database_subnet_cidrs)

  vpc_id            = aws_vpc.enterprise_vpc.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "enterprise-database-subnet-${count.index + 1}"
    Environment = var.environment
    Type        = "Database"
  }
}

# Route Tables
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.enterprise_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.enterprise_igw.id
  }

  tags = {
    Name        = "enterprise-public-rt"
    Environment = var.environment
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.enterprise_vpc.id

  tags = {
    Name        = "enterprise-private-rt"
    Environment = var.environment
  }
}

# Route Table Associations
resource "aws_route_table_association" "public_rta" {
  count = length(aws_subnet.public_subnets)

  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_rta" {
  count = length(aws_subnet.private_subnets)

  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

# Security Groups
resource "aws_security_group" "web_sg" {
  name_prefix = "enterprise-web-sg"
  vpc_id      = aws_vpc.enterprise_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "enterprise-web-sg"
    Environment = var.environment
  }
}

resource "aws_security_group" "app_sg" {
  name_prefix = "enterprise-app-sg"
  vpc_id      = aws_vpc.enterprise_vpc.id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "enterprise-app-sg"
    Environment = var.environment
  }
}

resource "aws_security_group" "db_sg" {
  name_prefix = "enterprise-db-sg"
  vpc_id      = aws_vpc.enterprise_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "enterprise-db-sg"
    Environment = var.environment
  }
}

# Application Load Balancer
resource "aws_lb" "enterprise_alb" {
  name               = "enterprise-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = aws_subnet.public_subnets[*].id

  enable_deletion_protection = false

  tags = {
    Name        = "enterprise-alb"
    Environment = var.environment
  }
}

# ALB Target Group
resource "aws_lb_target_group" "enterprise_tg" {
  name     = "enterprise-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.enterprise_vpc.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = {
    Name        = "enterprise-tg"
    Environment = var.environment
  }
}

# ALB Listener
resource "aws_lb_listener" "enterprise_listener" {
  load_balancer_arn = aws_lb.enterprise_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.enterprise_tg.arn
  }
}

# Launch Template
resource "aws_launch_template" "enterprise_lt" {
  name_prefix   = "enterprise-lt"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    environment = var.environment
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "enterprise-instance"
      Environment = var.environment
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "enterprise_asg" {
  name                = "enterprise-asg"
  vpc_zone_identifier = aws_subnet.private_subnets[*].id
  target_group_arns   = [aws_lb_target_group.enterprise_tg.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  launch_template {
    id      = aws_launch_template.enterprise_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "enterprise-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "enterprise_db_subnet_group" {
  name       = "enterprise-db-subnet-group"
  subnet_ids = aws_subnet.database_subnets[*].id

  tags = {
    Name        = "enterprise-db-subnet-group"
    Environment = var.environment
  }
}

# RDS Instance
resource "aws_db_instance" "enterprise_db" {
  identifier = "enterprise-db"

  engine         = "postgres"
  engine_version = "15.4"
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "enterprise"
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.enterprise_db_subnet_group.name

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name        = "enterprise-db"
    Environment = var.environment
  }
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "enterprise_cache_subnet_group" {
  name       = "enterprise-cache-subnet-group"
  subnet_ids = aws_subnet.private_subnets[*].id
}

# ElastiCache Cluster
resource "aws_elasticache_replication_group" "enterprise_redis" {
  replication_group_id       = "enterprise-redis"
  description                = "Enterprise Redis cluster"

  node_type            = var.redis_node_type
  port                 = 6379
  parameter_group_name = "default.redis7"

  num_cache_clusters = var.redis_num_cache_nodes

  subnet_group_name  = aws_elasticache_subnet_group.enterprise_cache_subnet_group.name
  security_group_ids = [aws_security_group.db_sg.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  tags = {
    Name        = "enterprise-redis"
    Environment = var.environment
  }
}

# S3 Bucket for backups
resource "aws_s3_bucket" "enterprise_backups" {
  bucket = "${var.project_name}-backups-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "enterprise-backups"
    Environment = var.environment
  }
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "enterprise_backups_versioning" {
  bucket = aws_s3_bucket.enterprise_backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "enterprise_backups_encryption" {
  bucket = aws_s3_bucket.enterprise_backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "enterprise_logs" {
  name              = "/aws/ec2/enterprise"
  retention_in_days = 30

  tags = {
    Name        = "enterprise-logs"
    Environment = var.environment
  }
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "enterprise-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_sns_topic.enterprise_alerts.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.enterprise_asg.name
  }
}

resource "aws_cloudwatch_metric_alarm" "high_memory" {
  alarm_name          = "enterprise-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 memory utilization"
  alarm_actions       = [aws_sns_topic.enterprise_alerts.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.enterprise_asg.name
  }
}

# SNS Topic for alerts
resource "aws_sns_topic" "enterprise_alerts" {
  name = "enterprise-alerts"

  tags = {
    Name        = "enterprise-alerts"
    Environment = var.environment
  }
}

# Route 53 Hosted Zone (if domain is provided)
resource "aws_route53_zone" "enterprise_zone" {
  count = var.domain_name != "" ? 1 : 0
  name  = var.domain_name

  tags = {
    Name        = "enterprise-zone"
    Environment = var.environment
  }
}

# Route 53 Record
resource "aws_route53_record" "enterprise_record" {
  count   = var.domain_name != "" ? 1 : 0
  zone_id = aws_route53_zone.enterprise_zone[0].zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.enterprise_alb.dns_name
    zone_id                = aws_lb.enterprise_alb.zone_id
    evaluate_target_health = true
  }
}
