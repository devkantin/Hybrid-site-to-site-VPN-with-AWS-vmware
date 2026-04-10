output "vpc_id" {
  description = "ID of the AWS VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the AWS VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "ec2_instance_id" {
  description = "ID of the EC2 instance in the private subnet"
  value       = module.ec2.id
}

output "ec2_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = module.ec2.private_ip
}

output "customer_gateway_id" {
  description = "ID of the Customer Gateway (on-premises device)"
  value       = module.vpn.customer_gateway_id
}

output "vpn_gateway_id" {
  description = "ID of the Virtual Private Gateway"
  value       = module.vpn.vpn_gateway_id
}

output "vpn_connection_id" {
  description = "ID of the Site-to-Site VPN connection"
  value       = module.vpn.vpn_connection_id
}

output "vpn_tunnel1_address" {
  description = "AWS endpoint IP for VPN tunnel 1"
  value       = module.vpn.tunnel1_address
}

output "vpn_tunnel2_address" {
  description = "AWS endpoint IP for VPN tunnel 2"
  value       = module.vpn.tunnel2_address
}

output "vpn_tunnel1_cgw_inside_address" {
  description = "On-premises inside IP for VPN tunnel 1"
  value       = module.vpn.tunnel1_cgw_inside_address
}

output "vpn_tunnel2_cgw_inside_address" {
  description = "On-premises inside IP for VPN tunnel 2"
  value       = module.vpn.tunnel2_cgw_inside_address
}

output "s3_artifact_bucket" {
  description = "Name of the CodeDeploy artifact S3 bucket"
  value       = aws_s3_bucket.artifacts.id
}

output "codedeploy_app_name" {
  description = "Name of the CodeDeploy application"
  value       = aws_codedeploy_app.this.name
}

output "codedeploy_deployment_group" {
  description = "Name of the CodeDeploy deployment group"
  value       = aws_codedeploy_deployment_group.this.deployment_group_name
}
