# Enterprise Multi-Region Kubernetes Platform

[![CI](https://github.com/your-org/enterprise-multi-region-kubernetes-platform/actions/workflows/validate.yml/badge.svg)](https://github.com/your-org/enterprise-multi-region-kubernetes-platform/actions/workflows/validate.yml)
[![Terraform](https://img.shields.io/badge/Terraform-1.7+-623CE4?logo=terraform)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.29+-326CE5?logo=kubernetes)](https://kubernetes.io/)
[![ArgoCD](https://img.shields.io/badge/ArgoCD-2.10+-EF7B4D?logo=argo)](https://argoproj.github.io/cd/)

A production-grade, multi-region Kubernetes platform built on Amazon EKS. Covers infrastructure provisioning, GitOps, progressive delivery, full-stack observability, and disaster recovery — from first `terraform apply` to production traffic.

---

## Table of Contents

- [Platform Overview](#platform-overview)
- [Technology Stack](#technology-stack)
- [Repository Structure](#repository-structure)
- [Architecture](#architecture)
- [Terraform Design](#terraform-design)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Build Phases](#build-phases)

---

## Platform Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Global Traffic Layer                         │
│              Route53 Latency Routing + AWS Global Accelerator       │
└───────────────────────────┬─────────────────────┬───────────────────┘
                            │                     │
            ┌───────────────▼──────┐  ┌───────────▼──────────────┐
            │   us-east-1 (Primary)│  │  eu-west-1 (Secondary)   │
            │   EKS Cluster        │  │  EKS Cluster             │
            │   ┌───────────────┐  │  │  ┌───────────────┐       │
            │   │  App Workloads│  │  │  │  App Workloads│       │
            │   │  ArgoCD       │  │  │  │  ArgoCD Agent │       │
            │   │  Observability│  │  │  │  Observability│       │
            │   └───────────────┘  │  │  └───────────────┘       │
            └──────────────────────┘  └──────────────────────────┘
                            │                     │
            ┌───────────────▼─────────────────────▼───────────────┐
            │              Shared Services Layer                   │
            │   RDS Aurora Global │ ElastiCache │ S3 Cross-Region │
            └──────────────────────────────────────────────────────┘
```

Both regions serve live traffic simultaneously (active-active). Either region can absorb 100% of load independently, satisfying a 99.99% availability SLA without cold-start risk during failover.

---

## Technology Stack

| Layer | Technology |
|---|---|
| Cloud | AWS |
| Container Orchestration | Amazon EKS 1.29+ |
| Infrastructure as Code | Terraform 1.7+ |
| GitOps | ArgoCD 2.10+ |
| Progressive Delivery | Argo Rollouts |
| Package Management | Helm 3.14+ |
| CI/CD | GitHub Actions |
| Secret Management | External Secrets Operator + AWS Secrets Manager |
| Metrics | Prometheus + Thanos |
| Logging | Fluent Bit + Loki |
| Tracing | Tempo + OpenTelemetry |
| Dashboards | Grafana |
| Alerting | Alertmanager |
| Node Autoscaling | Karpenter |
| Chaos Engineering | LitmusChaos |
| DNS | Route53 |
| Ingress | AWS Load Balancer Controller |

---

## Repository Structure

```
enterprise-multi-region-kubernetes-platform/
├── .github/
│   ├── CODEOWNERS
│   ├── ISSUE_TEMPLATE/
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── workflows/
│
├── docs/
│   ├── architecture/
│   └── decisions/
│
├── terraform/
│   ├── environments/        # Per-region variable files
│   ├── modules/             # Reusable Terraform modules
│   └── stacks/              # Deployable units
│
├── kubernetes/              # Kustomize base + overlays
├── helm/                    # Internal Helm charts
├── argocd/                  # ArgoCD Applications, ApplicationSets, Projects
├── monitoring/              # Dashboards, PrometheusRules
└── scripts/                 # Bootstrap and tooling scripts
```

---

## Architecture

### Design Principles

| Principle | What it means in practice |
|---|---|
| Everything as Code | No manual console changes. All infrastructure, config, and policy lives in Git |
| GitOps | ArgoCD continuously reconciles cluster state from Git. Drift is auto-corrected |
| Immutable Infrastructure | Nodes are replaced not patched. AMIs are versioned and rotated |
| Defence in Depth | Security at every layer — IAM, network policies, pod security, image scanning, runtime detection |
| Observability by Default | Every workload emits metrics, structured logs, and traces without opt-in |
| Progressive Delivery | Canary and blue-green rollouts with automated analysis gates via Argo Rollouts |
| Active-Active Multi-Region | Both regions handle live traffic. Failover is DNS-level with no warm-up delay |

### Region Strategy

| Region | Role | VPC CIDR |
|---|---|---|
| `us-east-1` | Primary | `10.0.0.0/16` |
| `eu-west-1` | Secondary | `10.1.0.0/16` |

Route53 latency-based routing directs users to the nearest region. AWS Global Accelerator provides static anycast IPs with automatic regional health-check failover. CIDRs are non-overlapping to allow Transit Gateway peering.

### Network Layout

```
                          Internet
                             │
                  ┌──────────▼──────────┐
                  │   AWS Global        │
                  │   Accelerator /     │
                  │   Route53 Latency   │
                  └──────┬──────┬───────┘
                         │      │
         ┌───────────────▼─┐  ┌─▼───────────────┐
         │   us-east-1 VPC │  │  eu-west-1 VPC  │
         │                 │  │                 │
         │  Public  /20×3  │  │  Public  /20×3  │  ← ALBs, NAT Gateway EIPs
         │  Private /20×3  │  │  Private /20×3  │  ← EKS nodes and pods
         │  Data    /22×3  │  │  Data    /22×3  │  ← RDS, ElastiCache
         └────────┬────────┘  └────────┬────────┘
                  └─────────┬──────────┘
                     Transit Gateway
```

Each VPC spans 3 AZs with 3 subnet tiers = 9 subnets per VPC. NAT Gateways are deployed one per AZ (not shared) to eliminate cross-AZ traffic costs and AZ-level blast radius.

### EKS Cluster Layout

```
EKS Control Plane (AWS Managed)
│
├── System Node Group   — ON_DEMAND  t3.medium   (min 3, max 6)
│   ├── Taint: CriticalAddonsOnly=true:NoSchedule
│   └── Runs: kube-system, ArgoCD, cert-manager, external-secrets, monitoring
│
├── Application Node Group — ON_DEMAND  m6i.xlarge  (min 3, max 30)
│   └── Runs: general workloads
│
└── Spot Node Pool (via Karpenter — Phase 5)
    └── Burst capacity and batch workloads
```

The system node group taint prevents general workloads from crowding out platform components.

### GitOps Flow

```
Developer        GitHub          ArgoCD            Kubernetes
    │               │                │                  │
    ├─── PR ───────►│                │                  │
    │               ├─── CI checks ──┤                  │
    ├─── merge ─────►                │                  │
    │               ├─── webhook ───►│                  │
    │               │                ├─── git pull ─────►
    │               │                ├─── diff + apply ─►
    │               │                │◄── reconciled ───┤
    │◄── status ────┤◄── sync done ──┤                  │
```

ArgoCD in `us-east-1` manages both clusters via ApplicationSets. Sync waves control install ordering — CRDs and namespaces first, then platform add-ons, then workloads.

### Secret Management Flow

```
AWS Secrets Manager
        │
External Secrets Operator  ← polls on schedule, handles rotation
        │
Kubernetes Secret  (namespaced, never in Git)
        │
Pod  ← mounted as env var or volume
```

No secrets are stored in Git at any point.

---

## Terraform Design

The Terraform layer is split into three layers with distinct responsibilities.

```
terraform/
├── environments/    ← WHAT values to use (per region)
├── modules/         ← HOW to build each component (reusable logic)
└── stacks/          ← WHAT to deploy (the deployable units)
```

### Modules

Modules are reusable building blocks. They contain the logic for *how* to build something but have no backend, no provider, and no state of their own.

| Module | What it does |
|---|---|
| `modules/tagging` | Generates a standard tag map and name prefix used by every resource |
| `modules/vpc` | 3-tier VPC — public/private/data subnets, NAT GWs, flow logs, gateway VPC endpoints |
| `modules/eks` | EKS cluster — KMS encryption, node groups, OIDC provider, IRSA roles, managed add-ons |

### Stacks

Stacks are the actual deployable units. Each has its own remote state file, provider block, and backend configuration. They call modules and pass real values.

| Stack | What it deploys | Depends on |
|---|---|---|
| `00-bootstrap` | S3 state bucket + DynamoDB lock table | Nothing (run once) |
| `01-foundation` | VPC via the `vpc` module | `00-bootstrap` |
| `02-eks` | EKS cluster via the `eks` module | `01-foundation` remote state |

Stacks are numbered to communicate deploy order. Stack `02-eks` reads VPC outputs directly from `01-foundation`'s remote state — no manual copy-pasting of IDs.

```hcl
data "terraform_remote_state" "foundation" {
  backend = "s3"
  config  = {
    bucket = var.state_bucket_name
    key    = "${var.aws_region}/01-foundation/terraform.tfstate"
    region = "us-east-1"
  }
}
```

### Environments

Environment files contain the *values* for each region. The same stack code runs in both regions — only the values file changes.

```
environments/
├── us-east-1/
│   ├── backend.tfvars        # S3 bucket + DynamoDB table name
│   ├── 01-foundation.tfvars  # VPC CIDR 10.0.0.0/16, AZs, cluster name
│   └── 02-eks.tfvars         # Cluster version, node group sizes
└── eu-west-1/
    ├── backend.tfvars
    ├── 01-foundation.tfvars  # VPC CIDR 10.1.0.0/16
    └── 02-eks.tfvars
```

Adding a third region requires only a new folder under `environments/` — no Terraform code changes.

### Deploy Order

```bash
# 1. Bootstrap — run once per AWS account
cd terraform/stacks/00-bootstrap
terraform init
terraform apply -var="state_bucket_name=eks-platform-terraform-state-<ACCOUNT_ID>"

# 2. Foundation
cd ../01-foundation
terraform init \
  -backend-config=../../environments/us-east-1/backend.tfvars \
  -backend-config="key=us-east-1/01-foundation/terraform.tfstate"
terraform apply -var-file=../../environments/us-east-1/01-foundation.tfvars

# 3. EKS cluster
cd ../02-eks
terraform init \
  -backend-config=../../environments/us-east-1/backend.tfvars \
  -backend-config="key=us-east-1/02-eks/terraform.tfstate"
terraform apply -var-file=../../environments/us-east-1/02-eks.tfvars
```

Repeat steps 2 and 3 with `eu-west-1` paths for the secondary region.

---

## Prerequisites

| Tool | Version |
|---|---|
| `terraform` | >= 1.7.0 |
| `kubectl` | >= 1.29 |
| `helm` | >= 3.14.0 |
| `argocd` CLI | >= 2.10 |
| `aws` CLI | >= 2.15 |
| `pre-commit` | >= 3.6 |

---

## Quick Start

```bash
git clone https://github.com/your-org/enterprise-multi-region-kubernetes-platform.git
cd enterprise-multi-region-kubernetes-platform

make install-tools   # install CLI dependencies (macOS)
make hooks           # install pre-commit hooks
make validate        # run all validators
make help            # list all available targets
```

---

## Build Phases

### Phase 1 — Repository Foundation ✅

Set up the repository skeleton, developer tooling, and GitHub governance.

**Delivered:**
- Top-level directory structure for all future phases
- GitHub config — `CODEOWNERS`, PR template, issue templates (bug, feature, platform request)
- Pre-commit hooks — Terraform fmt, secret scanning (Gitleaks), YAML/JSON lint, Helm lint, kubeconform, shellcheck
- `Makefile` with validate, fmt, security-scan, docs, and clean targets
- GitHub Actions `validate.yml` — runs all checks on every PR to `main`

---

### Phase 2 — Terraform AWS Foundation ✅

Establish the Terraform state backend and VPC networking in both regions.

**Delivered:**
- `modules/tagging` — standard tag set and name prefix generation
- `modules/vpc` — 3-tier, 3-AZ VPC with per-AZ NAT Gateways, VPC Flow Logs, S3/DynamoDB gateway endpoints, locked default security group
- `stacks/00-bootstrap` — KMS-encrypted S3 state bucket with versioning and access logging, DynamoDB lock table with PITR
- `stacks/01-foundation` — wires tagging + vpc modules, outputs VPC IDs and subnet IDs to remote state

**Key decisions:**
- One NAT Gateway per AZ, not shared — eliminates cross-AZ data transfer costs and AZ blast radius
- Gateway VPC endpoints for S3 and DynamoDB are free and remove NAT costs for ECR image pulls
- State bucket uses `aws:kms` encryption with access logging to a separate bucket

---

### Phase 3 — EKS Cluster Provisioning ✅

Provision production-grade EKS clusters in both regions.

**Delivered:**
- `modules/eks` — full EKS module covering:
  - KMS envelope encryption for Kubernetes secrets
  - Private API endpoint (no public access in production)
  - Control plane logging to CloudWatch (api, audit, authenticator, controllerManager, scheduler)
  - IMDSv2 enforced on all nodes via launch templates (prevents SSRF-based credential theft)
  - Encrypted gp3 EBS root volumes on all nodes
  - System node group with `CriticalAddonsOnly` taint — isolates platform components from workloads
  - Application node group for general workloads
  - OIDC provider — enables IRSA (IAM Roles for Service Accounts) for all add-ons
  - IRSA roles pre-created for VPC CNI and EBS CSI Driver
  - Managed add-ons: `vpc-cni`, `coredns`, `kube-proxy`, `aws-ebs-csi-driver`
  - EKS Access Entries for cluster-admin IAM role binding (no manual `aws-auth` ConfigMap editing)
- `stacks/02-eks` — reads VPC outputs from `01-foundation` remote state, passes to the eks module

**Key decisions:**
- `authentication_mode = API_AND_CONFIG_MAP` — uses the newer Access Entries API instead of manually editing the `aws-auth` ConfigMap
- `lifecycle { ignore_changes = [scaling_config[0].desired_size] }` on node groups — allows Karpenter and the cluster autoscaler to manage desired count at runtime without Terraform drift

---

### Phase 4 — GitOps Bootstrap with ArgoCD 🔜

Install ArgoCD in the primary cluster and connect the secondary cluster. Define ArgoCD Projects, ApplicationSets, and the initial sync-wave ordering for platform add-ons.

---

### Phase 5 — Core Platform Add-ons 🔜

Deploy AWS Load Balancer Controller, External Secrets Operator, cert-manager, and Karpenter via ArgoCD ApplicationSets targeting both clusters.

---

### Phase 6 — Observability Stack 🔜

Deploy Prometheus, Grafana, Loki, Fluent Bit, Tempo, and Alertmanager. Wire dashboards, alert rules, and PagerDuty routing.

---

### Phase 7 — Progressive Delivery 🔜

Install Argo Rollouts and define canary and blue-green rollout strategies with automated metric analysis gates.

---

### Phase 8 — Multi-Region Expansion 🔜

Register the `eu-west-1` cluster with ArgoCD and extend all ApplicationSets to deploy platform add-ons and workloads to both regions.

---

### Phase 9 — Global Traffic Routing 🔜

Configure Route53 latency-based routing, health checks, and AWS Global Accelerator for static anycast IPs with automatic regional failover.

---

### Phase 10 — Disaster Recovery & Chaos Engineering 🔜

Define and test DR runbooks. Install LitmusChaos and run scheduled chaos experiments to validate platform resilience against node loss, AZ failure, and regional failover scenarios.
