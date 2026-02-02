locals {
  name_prefix = "${var.project_slug}-${var.environment}"
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# --- Networking ---
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.name_prefix}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  database_subnets = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false
  
  create_database_subnet_group = true

  tags = local.common_tags
}

resource "aws_security_group" "lb_sg" {
  name        = "${local.name_prefix}-lb-sg"
  description = "Load Balancer Security Group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Beanstalk might add 443 later, or we allow it now.
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_security_group" "app_sg" {
  name        = "${local.name_prefix}-app-sg"
  description = "Application Security Group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
    description     = "Allow HTTP from LB"
  }
  
  ingress {
      from_port = 5000
      to_port = 5000
      protocol = "tcp"
      security_groups = [aws_security_group.lb_sg.id]
      description = "Allow traffic to Beanstalk default port"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_security_group" "db_sg" {
  name        = "${local.name_prefix}-db-sg"
  description = "Database Security Group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  tags = local.common_tags
}

# --- Database ---
resource "random_password" "db_password" {
  length           = 16
  special          = false
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db_creds" {
  name_prefix = "${local.name_prefix}-db-creds-"
  description = "Database credentials for ${var.environment}"
  tags        = local.common_tags
}

resource "aws_secretsmanager_secret_version" "db_creds_val" {
  secret_id     = aws_secretsmanager_secret.db_creds.id
  secret_string = jsonencode({
    username = "dbadmin"
    password = var.db_password != null ? var.db_password : random_password.db_password.result
    engine   = "postgres"
    host     = aws_db_instance.postgres.address
    port     = aws_db_instance.postgres.port
    dbname   = "appdb"
  })
}

resource "aws_db_instance" "postgres" {
  identifier           = "${local.name_prefix}-db"
  engine               = "postgres"
  engine_version       = "16.3" # Check latest available in region, usually safe
  instance_class       = var.db_instance_class
  allocated_storage    = 20
  storage_type         = "gp3"
  username             = "dbadmin"
  password             = var.db_password != null ? var.db_password : random_password.db_password.result
  db_name              = "appdb" # Initial DB name
  
  multi_az             = var.db_multi_az
  db_subnet_group_name = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  
  backup_retention_period = var.db_backup_retention
  deletion_protection     = var.db_deletion_protection
  skip_final_snapshot     = !var.db_deletion_protection # Skip if not protected (dev), else snapshot
  
  tags = local.common_tags
}

# --- Backend (Elastic Beanstalk) ---
# S3 Bucket for Beanstalk Application Versions
resource "aws_s3_bucket" "beanstalk_app_versions" {
  bucket = "${local.name_prefix}-beanstalk-artifacts"
  force_destroy = true # Allow destroy for dev stacks 
  tags = local.common_tags
}

resource "aws_iam_role" "beanstalk_ec2" {
  name = "${local.name_prefix}-beanstalk-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "beanstalk_web_tier" {
  role       = aws_iam_role.beanstalk_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

# Allow reading secrets/parameters
resource "aws_iam_policy" "app_secrets_policy" {
  name        = "${local.name_prefix}-secrets-policy"
  description = "Allow application to read config and secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:ssm:${var.aws_region}:*:parameter/gergen-stack/${var.environment}/*"
      },
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect   = "Allow"
        Resource = aws_secretsmanager_secret.db_creds.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_secrets" {
  role       = aws_iam_role.beanstalk_ec2.name
  policy_arn = aws_iam_policy.app_secrets_policy.arn
}

resource "aws_iam_instance_profile" "beanstalk_ec2" {
  name = "${local.name_prefix}-beanstalk-ec2-profile"
  role = aws_iam_role.beanstalk_ec2.name
}

resource "aws_elastic_beanstalk_application" "app" {
  name        = "${local.name_prefix}-app"
  description = "Spring Boot API"
  tags        = local.common_tags
}

resource "aws_elastic_beanstalk_environment" "env" {
  name                = "${local.name_prefix}-env"
  application         = aws_elastic_beanstalk_application.app.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.4.2 running Corretto 21" 
  # Note: solution stacks update frequently, referencing a regex or data source is better but specific string is required here.
  # 4.4.2 is recent as of early 2025. 
  
  tier = "WebServer"

  # Network
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = module.vpc.vpc_id
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", module.vpc.public_subnets) # Public subnets for cheap compute (no NAT)
  }
  setting {
    namespace = "aws:ec2:instances"
    name      = "InstanceTypes"
    value     = "t3.small"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.beanstalk_ec2.name
  }
  
  # Security
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.app_sg.id
  }

  # Environment Variables
  setting {
      namespace = "aws:elasticbeanstalk:application:environment"
      name = "SPRING_PROFILES_ACTIVE"
      value = var.environment
  }
  setting {
      namespace = "aws:elasticbeanstalk:application:environment"
      name = "SERVER_PORT"
      value = "5000"
  }
  
  # Health
  setting {
      namespace = "aws:elasticbeanstalk:environment:process:default"
      name = "HealthCheckPath"
      value = "/actuator/health"
  }

  tags = local.common_tags
}

# --- Frontend (S3 + CloudFront) ---
resource "aws_s3_bucket" "web_bucket" {
  bucket = "${local.name_prefix}-web"
  force_destroy = true 
  tags = local.common_tags
}

resource "aws_s3_bucket_website_configuration" "web_hosting" {
  bucket = aws_s3_bucket.web_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "web_public" {
  bucket = aws_s3_bucket.web_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "web_policy" {
  depends_on = [aws_s3_bucket_public_access_block.web_public]
  bucket = aws_s3_bucket.web_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.web_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_cloudfront_distribution" "web_cf" {
  origin {
    domain_name = aws_s3_bucket.web_bucket.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.web_bucket.id}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.web_bucket.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # SPA Routing support: Redirect 403/404 to index.html
  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
  }
  
  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
  }

  price_class = "PriceClass_100" # US/Europe only (cheaper)

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
  
  tags = local.common_tags
}

# --- SSM Parameters (Application Config) ---
resource "aws_ssm_parameter" "db_url" {
  name  = "/gergen-stack/${var.environment}/database/url"
  type  = "String"
  value = "jdbc:postgresql://${aws_db_instance.postgres.endpoint}/${aws_db_instance.postgres.db_name}"
  tags  = local.common_tags
}

resource "aws_ssm_parameter" "jwt_issuer" {
  name  = "/gergen-stack/${var.environment}/auth/issuer"
  type  = "String"
  value = var.auth_issuer_uri
  tags  = local.common_tags
}
