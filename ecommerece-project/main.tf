##############################################
# PROVIDER
##############################################

terraform {
  required_version = ">= 1.5.0"
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

# ACM certs for CloudFront MUST be in us-east-1. Since var.aws_region is already
# us-east-1 in this project, aws.us_east_1 = aws is fine, but the alias is kept
# so this still works if you ever move the rest of the stack to another region.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  tags = {
    Project = var.project_name
    ManagedBy = "terraform"
  }
}

##############################################
# VPC
##############################################

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.tags, { Name = "${var.project_name}-vpc" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.tags, { Name = "${var.project_name}-igw" })
}

##############################################
# SUBNETS
##############################################

resource "aws_subnet" "public" {
  count                   = var.az_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.tags, { Name = "${var.project_name}-public-${count.index + 1}" })
}

resource "aws_subnet" "frontend" {
  count             = var.az_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.frontend_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(local.tags, { Name = "${var.project_name}-frontend-${count.index + 1}" })
}

resource "aws_subnet" "backend" {
  count             = var.az_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.backend_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(local.tags, { Name = "${var.project_name}-backend-${count.index + 1}" })
}

resource "aws_subnet" "db" {
  count             = var.az_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(local.tags, { Name = "${var.project_name}-db-${count.index + 1}" })
}

##############################################
# NAT GATEWAYS (one per AZ, in public subnets)
##############################################

resource "aws_eip" "nat" {
  count  = var.az_count
  domain = "vpc"
  tags   = merge(local.tags, { Name = "${var.project_name}-nat-eip-${count.index + 1}" })
}

resource "aws_nat_gateway" "nat" {
  count         = var.az_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags          = merge(local.tags, { Name = "${var.project_name}-nat-${count.index + 1}" })

  depends_on = [aws_internet_gateway.igw]
}

##############################################
# ROUTE TABLES
##############################################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.tags, { Name = "${var.project_name}-public-rt" })

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public" {
  count          = var.az_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# One private route table per AZ, each routing out via that AZ's NAT gateway.
# Frontend, backend, and db subnets in the same AZ share that AZ's route table.
resource "aws_route_table" "private" {
  count  = var.az_count
  vpc_id = aws_vpc.main.id
  tags   = merge(local.tags, { Name = "${var.project_name}-private-rt-${count.index + 1}" })

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }
}

resource "aws_route_table_association" "frontend" {
  count          = var.az_count
  subnet_id      = aws_subnet.frontend[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "backend" {
  count          = var.az_count
  subnet_id      = aws_subnet.backend[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "db" {
  count          = var.az_count
  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

##############################################
# SECURITY GROUPS (matches the SG chain diagram)
##############################################

# 1. Bastion Host - SSH only
resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-bastion-sg"
  description = "SSH access to bastion host"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${var.project_name}-bastion-sg" })
}

# 2. Frontend Load Balancer - HTTP/HTTPS from internet
resource "aws_security_group" "frontend_lb" {
  name        = "${var.project_name}-frontend-lb-sg"
  description = "HTTP/HTTPS from internet to frontend ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
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

  tags = merge(local.tags, { Name = "${var.project_name}-frontend-lb-sg" })
}

# 3. Frontend Server - only from Frontend LB SG
resource "aws_security_group" "frontend" {
  name        = "${var.project_name}-frontend-sg"
  description = "App port only from frontend load balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "App traffic from frontend LB"
    from_port       = var.frontend_app_port
    to_port         = var.frontend_app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_lb.id]
  }

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${var.project_name}-frontend-sg" })
}

# 4. Backend Load Balancer (internal) - only from Frontend Server SG
resource "aws_security_group" "backend_lb" {
  name        = "${var.project_name}-backend-lb-sg"
  description = "Internal ALB, only reachable from frontend servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "App traffic from frontend servers"
    from_port       = var.backend_app_port
    to_port         = var.backend_app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${var.project_name}-backend-lb-sg" })
}

# 5. Backend Server - only from Backend LB SG
resource "aws_security_group" "backend" {
  name        = "${var.project_name}-backend-sg"
  description = "App port only from backend load balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "App traffic from backend LB"
    from_port       = var.backend_app_port
    to_port         = var.backend_app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_lb.id]
  }

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${var.project_name}-backend-sg" })
}

# 6. RDS - only from Backend Server SG
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "MySQL only from backend servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from backend servers"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${var.project_name}-rds-sg" })
}

##############################################
# BASTION HOST
##############################################

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.bastion_instance_type
  subnet_id                   = aws_subnet.public[0].id
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true

  tags = merge(local.tags, { Name = "${var.project_name}-bastion" })
}

##############################################
# FRONTEND TIER: Launch Template + ASG + ALB
##############################################

resource "aws_launch_template" "frontend" {
  name_prefix   = "${var.project_name}-frontend-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.frontend_instance_type
  key_name      = var.key_name

  network_interfaces {
    security_groups             = [aws_security_group.frontend.id]
    associate_public_ip_address = false
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    # Placeholder bootstrap - replace with your actual frontend deploy steps
    # (git clone, npm install, pm2 start, etc.)
    dnf update -y
    echo "frontend node placeholder listening on port ${var.frontend_app_port}" > /var/log/frontend-userdata.log
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.tags, { Name = "${var.project_name}-frontend" })
  }
}

resource "aws_lb" "frontend" {
  name               = "${var.project_name}-frontend-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.frontend_lb.id]
  subnets            = aws_subnet.public[*].id

  tags = merge(local.tags, { Name = "${var.project_name}-frontend-alb" })
}

resource "aws_lb_target_group" "frontend" {
  name     = "${var.project_name}-frontend-tg"
  port     = var.frontend_app_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }

  tags = local.tags
}

resource "aws_lb_listener" "frontend_http" {
  load_balancer_arn = aws_lb.frontend.arn
  port              = 80
  protocol          = "HTTP"

  # Redirect plain HTTP to HTTPS
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "frontend_https" {
  load_balancer_arn = aws_lb.frontend.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_autoscaling_group" "frontend" {
  name                = "${var.project_name}-frontend-asg"
  vpc_zone_identifier = aws_subnet.frontend[*].id
  min_size            = var.frontend_asg_min
  max_size            = var.frontend_asg_max
  desired_capacity    = var.frontend_asg_desired
  target_group_arns   = [aws_lb_target_group.frontend.arn]
  health_check_type   = "ELB"

  launch_template {
    id      = aws_launch_template.frontend.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-frontend-asg"
    propagate_at_launch = true
  }
}

##############################################
# BACKEND TIER: Launch Template + ASG + Internal ALB
##############################################

resource "aws_launch_template" "backend" {
  name_prefix   = "${var.project_name}-backend-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.backend_instance_type
  key_name      = var.key_name

  network_interfaces {
    security_groups             = [aws_security_group.backend.id]
    associate_public_ip_address = false
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    # Placeholder bootstrap - replace with your actual backend deploy steps
    dnf update -y
    echo "backend node placeholder listening on port ${var.backend_app_port}" > /var/log/backend-userdata.log
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.tags, { Name = "${var.project_name}-backend" })
  }
}

resource "aws_lb" "backend" {
  name               = "${var.project_name}-backend-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.backend_lb.id]
  subnets            = aws_subnet.backend[*].id

  tags = merge(local.tags, { Name = "${var.project_name}-backend-alb" })
}

resource "aws_lb_target_group" "backend" {
  name     = "${var.project_name}-backend-tg"
  port     = var.backend_app_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }

  tags = local.tags
}

resource "aws_lb_listener" "backend_http" {
  load_balancer_arn = aws_lb.backend.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

resource "aws_autoscaling_group" "backend" {
  name                = "${var.project_name}-backend-asg"
  vpc_zone_identifier = aws_subnet.backend[*].id
  min_size            = var.backend_asg_min
  max_size            = var.backend_asg_max
  desired_capacity    = var.backend_asg_desired
  target_group_arns   = [aws_lb_target_group.backend.arn]
  health_check_type   = "ELB"

  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-backend-asg"
    propagate_at_launch = true
  }
}

##############################################
# RDS: Primary + Read Replica
##############################################

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.db[*].id
  tags       = local.tags
}

resource "aws_db_instance" "primary" {
  identifier             = "${var.project_name}-db-primary"
  engine                 = "mysql"
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  multi_az               = false
  skip_final_snapshot    = true
  backup_retention_period = 7 # required (>0) for read replicas to work

  tags = merge(local.tags, { Name = "${var.project_name}-db-primary" })
}

resource "aws_db_instance" "replica" {
  identifier             = "${var.project_name}-db-replica"
  replicate_source_db    = aws_db_instance.primary.identifier
  instance_class         = var.db_replica_instance_class
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = true

  tags = merge(local.tags, { Name = "${var.project_name}-db-replica" })
}

##############################################
# ACM CERTIFICATE (used by both ALB and CloudFront - us-east-1)
##############################################

#resource "aws_acm_certificate" "main" {
 # provider                  = aws.us_east_1
  #domain_name               = var.domain_name
  #subject_alternative_names = ["www.${var.domain_name}"]
 # validation_method         = "DNS"

 # lifecycle {
  ##  create_before_destroy = true
  #}

  #tags = local.tags
#}

#data "aws_route53_zone" "main" {
 # name         = var.domain_name
 # private_zone = false
#}

#resource "aws_route53_record" "cert_validation" {
  #for_each = {
    #for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
     # name   = dvo.resource_record_name
     # record = dvo.resource_record_value
      #type   = dvo.resource_record_type
    #}
  #}

 # zone_id = data.aws_route53_zone.main.zone_id
 ## name    = each.value.name
 ## type    = each.value.type
 # records = [each.value.record]
 # ttl     = 60
#}

#resource "aws_acm_certificate_validation" "main" {
 ## provider                = aws.us_east_1
 # certificate_arn         = aws_acm_certificate.main.arn
 # validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
#}

##############################################
# WAF (for CloudFront - must be scope CLOUDFRONT, in us-east-1)
##############################################

resource "aws_wafv2_web_acl" "main" {
  provider    = aws.us_east_1
  name        = "${var.project_name}-waf"
  description = "WAF for CloudFront in front of the frontend ALB"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-waf"
    sampled_requests_enabled   = true
  }

  tags = local.tags
}

##############################################
# CLOUDFRONT (edge, in front of frontend ALB) + Shield Standard is automatic
##############################################

resource "aws_cloudfront_distribution" "main" {
  enabled         = true
  is_ipv6_enabled = true
  aliases         = [var.domain_name, "www.${var.domain_name}"]
  web_acl_id      = aws_wafv2_web_acl.main.arn
  price_class     = "PriceClass_All"

  origin {
    domain_name = aws_lb.frontend.dns_name
    origin_id   = "frontend-alb"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "frontend-alb"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies {
        forward = "all"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.main.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = local.tags
}

##############################################
# ROUTE 53 - point domain at CloudFront
##############################################

resource "aws_route53_record" "root" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  ##alias {
   # name                   = aws_cloudfront_distribution.main.domain_name
   # zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
  ##  evaluate_target_health = false
 # }
#}
