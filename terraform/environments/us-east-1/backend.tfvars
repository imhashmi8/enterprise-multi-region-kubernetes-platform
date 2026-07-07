# Shared backend config for all stacks in us-east-1.
# Pass the stack-specific key at init time:
#
#   terraform init \
#     -backend-config=../../environments/us-east-1/backend.tfvars \
#     -backend-config="key=us-east-1/01-foundation/terraform.tfstate"
#
# Replace 528956693660 with your 12-digit AWS account ID.

bucket         = "eks-platform-terraform-state-528956693660"
region         = "us-east-1"
dynamodb_table = "eks-platform-terraform-locks"
encrypt        = true
