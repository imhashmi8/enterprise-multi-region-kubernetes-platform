# Shared backend config for all stacks in eu-west-1.
# State is stored in the PRIMARY region bucket (us-east-1) with an eu-west-1 key prefix.
# Pass the stack-specific key at init time:
#
#   terraform init \
#     -backend-config=../../environments/eu-west-1/backend.tfvars \
#     -backend-config="key=eu-west-1/01-foundation/terraform.tfstate"
#
# Replace 528956693660 with your 12-digit AWS account ID.

bucket         = "eks-platform-terraform-state-528956693660"
region         = "us-east-1"
dynamodb_table = "eks-platform-terraform-locks"
encrypt        = true
