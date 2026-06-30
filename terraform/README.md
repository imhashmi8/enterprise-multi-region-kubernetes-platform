# Terraform

Infrastructure as Code for the Enterprise Kubernetes Platform.

## Structure (target — populated across phases)

```
terraform/
├── environments/          # Per-environment .tfvars files
│   ├── us-east-1/
│   └── eu-west-1/
├── modules/               # Reusable internal modules
│   ├── eks/
│   ├── vpc/
│   ├── karpenter/
│   ├── iam/
│   └── tagging/
└── stacks/                # Root modules (deployable units)
    ├── 00-bootstrap/      # S3 state backend, DynamoDB lock table
    ├── 01-foundation/     # VPC, subnets, Transit Gateway
    ├── 02-eks/            # EKS cluster + managed node groups
    ├── 03-addons/         # EKS add-ons (CoreDNS, kube-proxy, VPC CNI)
    └── 04-platform/       # Platform-level resources (IAM roles for services)
```

## State Backend

Remote state is stored in S3 with DynamoDB locking. Bootstrap the backend before running any other stack:

```bash
cd terraform/stacks/00-bootstrap
terraform init
terraform apply
```

## Usage

```bash
# Initialize a stack (example: foundation in us-east-1)
cd terraform/stacks/01-foundation
terraform init \
  -backend-config=../../environments/us-east-1/backend.tfvars

# Plan
terraform plan \
  -var-file=../../environments/us-east-1/terraform.tfvars \
  -out=tfplan

# Apply
terraform apply tfplan
```

## Conventions

- All modules have `variables.tf`, `outputs.tf`, `versions.tf`, and `README.md`
- All taggable resources use the `tagging` module
- No hardcoded account IDs, AMI IDs, or region strings — use data sources or variables
- `terraform fmt -recursive` is enforced by pre-commit
