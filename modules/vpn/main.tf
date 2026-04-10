# ─────────────────────────────────────────────────────────────
# Customer Gateway — represents the on-premises strongSwan device
# ─────────────────────────────────────────────────────────────
resource "aws_customer_gateway" "this" {
  bgp_asn    = 65000
  ip_address = var.customer_gateway_ip
  type       = "ipsec.1"

  tags = merge(var.tags, {
    Name = "${var.name}-cgw"
  })
}

# ─────────────────────────────────────────────────────────────
# Virtual Private Gateway — AWS side of the IPSec tunnel
# ─────────────────────────────────────────────────────────────
resource "aws_vpn_gateway" "this" {
  vpc_id = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-vgw"
  })
}

# ─────────────────────────────────────────────────────────────
# Route propagation — push VPN routes into private route tables
# ─────────────────────────────────────────────────────────────
resource "aws_vpn_gateway_route_propagation" "this" {
  for_each = toset(var.private_route_table_ids)

  vpn_gateway_id = aws_vpn_gateway.this.id
  route_table_id = each.value
}

# ─────────────────────────────────────────────────────────────
# Site-to-Site VPN Connection (IKEv1 / IPSec, static routing)
# Matches the strongSwan configuration on the Ubuntu VMware VM
# ─────────────────────────────────────────────────────────────
resource "aws_vpn_connection" "this" {
  customer_gateway_id = aws_customer_gateway.this.id
  vpn_gateway_id      = aws_vpn_gateway.this.id
  type                = "ipsec.1"

  # Static routing — BGP not used in this lab
  static_routes_only = true

  # IKEv1 to match strongSwan ike=aes256-sha256-modp2048 config
  tunnel1_ike_versions                 = ["ikev1"]
  tunnel1_phase1_encryption_algorithms = ["AES256"]
  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase1_dh_group_numbers      = [14]
  tunnel1_phase2_encryption_algorithms = ["AES256"]
  tunnel1_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase2_dh_group_numbers      = [14]

  tunnel2_ike_versions                 = ["ikev1"]
  tunnel2_phase1_encryption_algorithms = ["AES256"]
  tunnel2_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase1_dh_group_numbers      = [14]
  tunnel2_phase2_encryption_algorithms = ["AES256"]
  tunnel2_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase2_dh_group_numbers      = [14]

  tunnel1_preshared_key = var.tunnel1_psk
  tunnel2_preshared_key = var.tunnel2_psk

  tags = merge(var.tags, {
    Name = "${var.name}-vpn"
  })
}

# ─────────────────────────────────────────────────────────────
# Static route for the on-premises network
# ─────────────────────────────────────────────────────────────
resource "aws_vpn_connection_route" "on_prem" {
  destination_cidr_block = var.on_prem_cidr
  vpn_connection_id      = aws_vpn_connection.this.id
}
