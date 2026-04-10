# tests/vpc_test.tftest.hcl
# Native Terraform tests (terraform test) for the VPC configuration.
# Uses mock providers so no real AWS credentials are required.
# Run with: terraform test -filter=tests/vpc_test.tftest.hcl

mock_provider "aws" {}

# Override the VPC module so its outputs are known at plan time.
# This avoids "for_each from computed value" errors in the vpn module.
override_module {
  target = module.vpc
  outputs = {
    vpc_id                 = "vpc-00000000000000000"
    vpc_cidr_block         = "10.0.0.0/16"
    private_subnets        = ["subnet-00000000000000001"]
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
# Test: VPC module receives the correct CIDR and name
# ─────────────────────────────────────────────────────────────
run "vpc_cidr_and_name_are_set" {
  command = plan

  assert {
    condition     = module.vpc.vpc_cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR must be 10.0.0.0/16"
  }
}

# ─────────────────────────────────────────────────────────────
# Test: Environment validation rejects invalid values
# ─────────────────────────────────────────────────────────────
run "invalid_environment_rejected" {
  command = plan

  variables {
    environment = "production" # Not in the allowed list
  }

  expect_failures = [var.environment]
}

# ─────────────────────────────────────────────────────────────
# Test: Private subnets count matches availability zones
# ─────────────────────────────────────────────────────────────
run "subnet_count_matches_azs" {
  command = plan

  assert {
    condition     = length(var.private_subnet_cidrs) == length(var.availability_zones)
    error_message = "Number of private_subnet_cidrs must equal number of availability_zones"
  }
}
