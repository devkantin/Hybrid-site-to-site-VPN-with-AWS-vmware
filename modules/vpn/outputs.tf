output "customer_gateway_id" {
  description = "ID of the Customer Gateway"
  value       = aws_customer_gateway.this.id
}

output "vpn_gateway_id" {
  description = "ID of the Virtual Private Gateway"
  value       = aws_vpn_gateway.this.id
}

output "vpn_connection_id" {
  description = "ID of the Site-to-Site VPN connection"
  value       = aws_vpn_connection.this.id
}

output "tunnel1_address" {
  description = "AWS public IP endpoint for VPN tunnel 1"
  value       = aws_vpn_connection.this.tunnel1_address
}

output "tunnel2_address" {
  description = "AWS public IP endpoint for VPN tunnel 2"
  value       = aws_vpn_connection.this.tunnel2_address
}

output "tunnel1_cgw_inside_address" {
  description = "On-premises (CGW) inside IP for tunnel 1"
  value       = aws_vpn_connection.this.tunnel1_cgw_inside_address
}

output "tunnel2_cgw_inside_address" {
  description = "On-premises (CGW) inside IP for tunnel 2"
  value       = aws_vpn_connection.this.tunnel2_cgw_inside_address
}

output "tunnel1_vgw_inside_address" {
  description = "AWS (VGW) inside IP for tunnel 1"
  value       = aws_vpn_connection.this.tunnel1_vgw_inside_address
}

output "tunnel2_vgw_inside_address" {
  description = "AWS (VGW) inside IP for tunnel 2"
  value       = aws_vpn_connection.this.tunnel2_vgw_inside_address
}
