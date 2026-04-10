locals {
  name = "${var.project_name}-${var.environment}"

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )

  ami_id = var.ec2_ami_id != "" ? var.ec2_ami_id : data.aws_ami.amazon_linux_2023.id
}

# ─────────────────────────────────────────────────────────────
# Data: Latest Amazon Linux 2023 AMI
# ─────────────────────────────────────────────────────────────
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# ─────────────────────────────────────────────────────────────
# VPC — terraform-aws-modules/vpc/aws (Anton Babenko)
# ─────────────────────────────────────────────────────────────
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.name}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnet_cidrs

  # NAT not needed — on-prem traffic routes via VGW
  enable_nat_gateway = false
  # VGW is created in the vpn module for full control
  enable_vpn_gateway = false

  tags = local.common_tags
}

# ─────────────────────────────────────────────────────────────
# Security Group — terraform-aws-modules/security-group/aws
# ─────────────────────────────────────────────────────────────
module "ec2_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.name}-ec2-sg"
  description = "Allow ICMP and SSH from on-premises network via VPN"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = -1
      to_port     = -1
      protocol    = "icmp"
      description = "ICMP ping from on-premises (strongSwan)"
      cidr_blocks = var.on_prem_cidr
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH from on-premises (strongSwan)"
      cidr_blocks = var.on_prem_cidr
    },
  ]

  egress_rules = ["all-all"]

  tags = local.common_tags
}

# ─────────────────────────────────────────────────────────────
# EC2 — terraform-aws-modules/ec2-instance/aws (Anton Babenko)
# ─────────────────────────────────────────────────────────────
module "ec2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.0"

  name = "${local.name}-server"

  ami                    = local.ami_id
  instance_type          = var.ec2_instance_type
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [module.ec2_sg.security_group_id]

  iam_instance_profile = aws_iam_instance_profile.ec2_codedeploy.name

  associate_public_ip_address = false

  tags = local.common_tags
}

# ─────────────────────────────────────────────────────────────
# VPN — local module (Customer GW + Virtual Private GW + Connection)
# ─────────────────────────────────────────────────────────────
module "vpn" {
  source = "./modules/vpn"

  name                    = local.name
  vpc_id                  = module.vpc.vpc_id
  vpc_cidr                = var.vpc_cidr
  private_route_table_ids = module.vpc.private_route_table_ids
  customer_gateway_ip     = var.customer_gateway_ip
  on_prem_cidr            = var.on_prem_cidr
  tunnel1_psk             = var.vpn_tunnel1_psk
  tunnel2_psk             = var.vpn_tunnel2_psk

  tags = local.common_tags
}

# ─────────────────────────────────────────────────────────────
# S3 — CodeDeploy artifact bucket
# ─────────────────────────────────────────────────────────────
resource "aws_s3_bucket" "artifacts" {
  bucket = var.s3_artifact_bucket

  tags = local.common_tags
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ─────────────────────────────────────────────────────────────
# IAM — EC2 instance profile for CodeDeploy agent + S3 access
# ─────────────────────────────────────────────────────────────
resource "aws_iam_role" "ec2_codedeploy" {
  name = "${local.name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_codedeploy.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "ec2_s3_artifacts" {
  name = "${local.name}-s3-artifacts"
  role = aws_iam_role.ec2_codedeploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket",
        ]
        Resource = [
          aws_s3_bucket.artifacts.arn,
          "${aws_s3_bucket.artifacts.arn}/*",
        ]
      },
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_codedeploy" {
  name = "${local.name}-ec2-profile"
  role = aws_iam_role.ec2_codedeploy.name

  tags = local.common_tags
}

# ─────────────────────────────────────────────────────────────
# IAM — CodeDeploy service role
# ─────────────────────────────────────────────────────────────
resource "aws_iam_role" "codedeploy" {
  name = "${local.name}-codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "codedeploy.amazonaws.com" }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "codedeploy" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

# ─────────────────────────────────────────────────────────────
# CodeDeploy — Application + Deployment Group
# ─────────────────────────────────────────────────────────────
resource "aws_codedeploy_app" "this" {
  name             = var.codedeploy_app_name
  compute_platform = "Server"

  tags = local.common_tags
}

resource "aws_codedeploy_deployment_group" "this" {
  app_name              = aws_codedeploy_app.this.name
  deployment_group_name = "${var.codedeploy_app_name}-dg"
  service_role_arn      = aws_iam_role.codedeploy.arn

  deployment_config_name = "CodeDeployDefault.AllAtOnce"

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "${local.name}-server"
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}
