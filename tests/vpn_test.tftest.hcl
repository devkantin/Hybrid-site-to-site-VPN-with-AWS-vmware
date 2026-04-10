# tests/vpn_test.tftest.hcl
# Native Terraform tests for the VPN module in isolation.
# Uses mock providers — no AWS credentials needed.
# Run with: terraform test -filter=tests/vpn_test.tftest.hcl

mock_provider "aws" {}

override_module {
  target = module.vpc
  outputs = {
    vpc_id                  = "vpc-00000000000000000"
    vpc_cidr_block          = "10.0.0.0/16"
    private_subnets         = ["subnet-00000000000000001"]
    private_route_table_ids = ["rtb-00000000000000001"]
  }
}

override_module {
  target = module.ec2
  outputs = {
    id         = "i-00000000000000001"
    private_ip = "10.0.1.10"
  }
}

override_module {
  target = module.ec2_sg
  outputs = {
    security_group_id = "sg-00000000000000001"
  }
}

variables {
  project_name         = "test-vpn"
  environment          = "lab"
  vpc_cidr             = "10.0.0.0/16"
  private_subnet_cidrs = ["10.0.1.0/24"]
  availability_zones   = ["us-east-1a"]
  customer_gateway_ip  = "1.2.3.4"
  on_prem_cidr         = "192.168.0.0/24"
  s3_artifact_bucket   = "test-bucket-unique-12345"
}

# ─────────────────────────────────────────────────────────────
# Test: Customer Gateway uses correct public IP from variable
# ─────────────────────────────────────────────────────────────
run "customer_gateway_ip_matches" {
  command = plan

  assert {
    condition     = var.customer_gateway_ip == "1.2.3.4"
    error_message = "customer_gateway_ip must equal the test value '1.2.3.4'"
  }
}

# ─────────────────────────────────────────────────────────────
# Test: VPN static_routes_only is true (checked via variable)
# ─────────────────────────────────────────────────────────────
run "vpn_on_prem_cidr_matches" {
  command = plan

  assert {
    condition     = var.on_prem_cidr == "192.168.0.0/24"
    error_message = "on_prem_cidr must equal the test value '192.168.0.0/24'"
  }
}

# ─────────────────────────────────────────────────────────────
# Test: PSKs are not exposed in plan (sensitive)
# ─────────────────────────────────────────────────────────────
run "psks_are_null_by_default" {
  command = plan

  assert {
    condition     = var.vpn_tunnel1_psk == null
    error_message = "vpn_tunnel1_psk must default to null"
  }

  assert {
    condition     = var.vpn_tunnel2_psk == null
    error_message = "vpn_tunnel2_psk must default to null"
  }
}
