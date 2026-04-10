#!/bin/bash
# CodeDeploy BeforeInstall hook
# Copies build artifact from S3 to /tmp on the EC2 instance.
# The bucket name is set via the Terraform variable s3_artifact_bucket.
set -euo pipefail

BUCKET="${S3_ARTIFACT_BUCKET:-hybrid-vpn-lab-codedeploy-artifacts}"
APP_KEY="demo-build-project/my-app"

echo "[runbuild] Pulling artifact: s3://${BUCKET}/${APP_KEY}"
aws s3 cp "s3://${BUCKET}/${APP_KEY}" /tmp/

echo "[runbuild] Done."
