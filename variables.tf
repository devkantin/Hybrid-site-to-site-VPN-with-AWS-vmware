variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "hybrid-vpn-lab"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "lab"

  validation {
    condition     = contains(["lab", "dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: lab, dev, staging, prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the AWS VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-1a"]
}

variable "customer_gateway_ip" {
  description = "Public IP address of the on-premises VMware/strongSwan gateway"
  type        = string
  default     = "172.220.62.45"
}

variable "on_prem_cidr" {
  description = "CIDR block of the on-premises (VMware) network"
  type        = string
  default     = "192.168.91.0/24"
}

variable "ec2_instance_type" {
  description = "EC2 instance type for the private test server"
  type        = string
  default     = "t3.micro"
}

variable "ec2_ami_id" {
  description = "AMI ID for EC2 instance. Leave empty to auto-select latest Amazon Linux 2023"
  type        = string
  default     = ""
}

variable "vpn_tunnel1_psk" {
  description = "Pre-shared key for VPN tunnel 1. If null, AWS auto-generates"
  type        = string
  sensitive   = true
  default     = null
}

variable "vpn_tunnel2_psk" {
  description = "Pre-shared key for VPN tunnel 2. If null, AWS auto-generates"
  type        = string
  sensitive   = true
  default     = null
}

variable "s3_artifact_bucket" {
  description = "Name of the S3 bucket used for CodeDeploy build artifacts"
  type        = string
  default     = "hybrid-vpn-lab-codedeploy-artifacts"
}

variable "codedeploy_app_name" {
  description = "Name of the CodeDeploy application"
  type        = string
  default     = "hybrid-vpn-app"
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
