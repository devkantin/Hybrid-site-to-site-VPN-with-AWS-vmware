variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC to attach the Virtual Private Gateway to"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC (used for tagging context)"
  type        = string
}

variable "private_route_table_ids" {
  description = "List of private route table IDs for VPN route propagation"
  type        = list(string)
}

variable "customer_gateway_ip" {
  description = "Public IP of the on-premises gateway (home router / strongSwan host)"
  type        = string
}

variable "on_prem_cidr" {
  description = "CIDR block of the on-premises network"
  type        = string
}

variable "tunnel1_psk" {
  description = "Pre-shared key for VPN tunnel 1. Null lets AWS auto-generate"
  type        = string
  sensitive   = true
  default     = null
}

variable "tunnel2_psk" {
  description = "Pre-shared key for VPN tunnel 2. Null lets AWS auto-generate"
  type        = string
  sensitive   = true
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
