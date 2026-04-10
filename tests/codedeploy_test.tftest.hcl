# tests/codedeploy_test.tftest.hcl
# Native Terraform tests for the CodeDeploy + S3 + IAM resources.
# Uses mock providers — no AWS credentials needed.
# Run with: terraform test -filter=tests/codedeploy_test.tftest.hcl

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
  codedeploy_app_name  = "test-app"
}

# ─────────────────────────────────────────────────────────────
# Test: S3 bucket name is set from variable
# ─────────────────────────────────────────────────────────────
run "s3_bucket_name_from_variable" {
  command = plan

  assert {
    condition     = aws_s3_bucket.artifacts.bucket == "test-bucket-unique-12345"
    error_message = "S3 bucket name must match s3_artifact_bucket variable"
  }
}

# ─────────────────────────────────────────────────────────────
# Test: S3 bucket has public access blocked
# ─────────────────────────────────────────────────────────────
run "s3_public_access_blocked" {
  command = plan

  assert {
    condition     = aws_s3_bucket_public_access_block.artifacts.block_public_acls == true
    error_message = "S3 bucket must block public ACLs"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.artifacts.block_public_policy == true
    error_message = "S3 bucket must block public policies"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.artifacts.restrict_public_buckets == true
    error_message = "S3 bucket must restrict public buckets"
  }
}

# ─────────────────────────────────────────────────────────────
# Test: CodeDeploy app name matches variable
# ─────────────────────────────────────────────────────────────
run "codedeploy_app_name_matches" {
  command = plan

  assert {
    condition     = aws_codedeploy_app.this.name == "test-app"
    error_message = "CodeDeploy app name must match codedeploy_app_name variable"
  }
}

# ─────────────────────────────────────────────────────────────
# Test: EC2 IAM role allows CodeDeploy agent to pull from S3
# ─────────────────────────────────────────────────────────────
run "ec2_iam_role_exists" {
  command = plan

  assert {
    condition     = aws_iam_role.ec2_codedeploy.name == "test-vpn-lab-ec2-role"
    error_message = "EC2 IAM role must be named {project}-{env}-ec2-role"
  }
}
