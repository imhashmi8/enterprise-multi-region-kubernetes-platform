# Enterprise Multi-Region Kubernetes Platform

[![CI](https://github.com/your-org/enterprise-multi-region-kubernetes-platform/actions/workflows/validate.yml/badge.svg)](https://github.com/your-org/enterprise-multi-region-kubernetes-platform/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![Terraform](https://img.shields.io/badge/Terraform-1.7+-623CE4?logo=terraform)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.29+-326CE5?logo=kubernetes)](https://kubernetes.io/)
[![ArgoCD](https://img.shields.io/badge/ArgoCD-2.10+-EF7B4D?logo=argo)](https://argoproj.github.io/cd/)

A production-grade, multi-region Kubernetes platform built on Amazon EKS. Designed for enterprise workloads requiring high availability, disaster recovery, GitOps-driven delivery, and full-stack observability across multiple AWS regions.

---

## Platform Overview

This repository is the single source of truth for the platform engineering layer that powers application teams. It covers infrastructure provisioning, cluster configuration, GitOps, progressive delivery, observability, and security — from first `terraform apply` to production traffic.

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Global Traffic Layer                         │
│              Route53 Latency Routing + AWS Global Accelerator       │
└───────────────────────────┬─────────────────────┬───────────────────┘
                            │                     │
            ┌───────────────▼──────┐  ┌───────────▼──────────────┐
            │   us-east-1 (Primary)│  │  eu-west-1 (Secondary)   │
            │   EKS Cluster        │  │   EKS Cluster            │
            │   ┌───────────────┐  │  │   ┌───────────────┐      │
            │   │  App Workloads│  │  │   │  App Workloads│      │
            │   │  ArgoCD       │  │  │   │  ArgoCD Agent │      │
            │   │  Observability│  │  │   │  Observability│      │
            │   └───────────────┘  │  │   └───────────────┘      │
            └──────────────────────┘  └──────────────────────────┘
                            │                     │
            ┌───────────────▼─────────────────────▼───────────────┐
            │              Shared Services Layer                   │
            │   RDS Aurora Global │ ElastiCache │ S3 Cross-Region │
            └──────────────────────────────────────────────────────┘
```

---

## Technology Stack

| Layer | Technology |
|---|---|
| Cloud Provider | AWS |
| Container Orchestration | Amazon EKS 1.29+ |
| Infrastructure as Code | Terraform 1.7+ |
| GitOps | ArgoCD 2.10+ |
| Progressive Delivery | Argo Rollouts |
| Package Management | Helm 3.14+ |
| CI/CD | GitHub Actions |
| Service Mesh | (Phase 5) |
| Secret Management | External Secrets Operator + AWS Secrets Manager |
| Metrics | Prometheus + Thanos |
| Logging | Fluent Bit + Loki |
| Tracing | Tempo + OpenTelemetry |
| Dashboards | Grafana |
| Alerting | Alertmanager + PagerDuty |
| Node Autoscaling | Karpenter |
| Chaos Engineering | LitmusChaos |
| DNS | Route53 |
| Ingress | AWS Load Balancer Controller |
| Policy | OPA Gatekeeper |
| Container Security | Trivy + Falco |

---

## Repository Structure

```
enterprise-multi-region-kubernetes-platform/
├── .github/                    # GitHub repository governance
│   ├── CODEOWNERS              # Code ownership and review routing
│   ├── ISSUE_TEMPLATE/         # Standardised issue templates
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── workflows/              # GitHub Actions CI/CD pipelines
│
├── docs/                       # Platform documentation
│   ├── architecture/           # Architecture diagrams and decisions
│   ├── decisions/              # Architecture Decision Records (ADRs)
│   └── runbooks/               # Operational runbooks
│
├── terraform/                  # Infrastructure as Code
│   ├── environments/           # Per-environment variable files
│   ├── modules/                # Reusable Terraform modules
│   └── stacks/                 # Root modules per logical stack
│
├── kubernetes/                 # Raw Kubernetes manifests
│   ├── base/                   # Base Kustomize configurations
│   └── overlays/               # Environment-specific overlays
│
├── helm/                       # Custom Helm charts
│   └── charts/                 # Internal platform charts
│
├── argocd/                     # ArgoCD configuration
│   ├── applications/           # ArgoCD Application manifests
│   ├── applicationsets/        # ArgoCD ApplicationSet manifests
│   └── projects/               # ArgoCD Project definitions
│
├── monitoring/                 # Observability stack configuration
│   ├── dashboards/             # Grafana dashboard JSON
│   ├── alerts/                 # PrometheusRule manifests
│   └── runbooks/               # Alert runbook links
│
└── scripts/                    # Platform automation scripts
    ├── bootstrap/              # Cluster bootstrap scripts
    └── tools/                  # Developer tooling helpers
```

---

## Prerequisites

| Tool | Version | Install |
|---|---|---|
| `terraform` | >= 1.7.0 | [hashicorp.com](https://developer.hashicorp.com/terraform/install) |
| `kubectl` | >= 1.29 | [kubernetes.io](https://kubernetes.io/docs/tasks/tools/) |
| `helm` | >= 3.14.0 | [helm.sh](https://helm.sh/docs/intro/install/) |
| `argocd` CLI | >= 2.10 | [argo-cd.readthedocs.io](https://argo-cd.readthedocs.io/en/stable/cli_installation/) |
| `aws` CLI | >= 2.15 | [aws.amazon.com](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) |
| `pre-commit` | >= 3.6 | [pre-commit.com](https://pre-commit.com/#install) |
| `make` | >= 3.8 | OS package manager |

---

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/your-org/enterprise-multi-region-kubernetes-platform.git
cd enterprise-multi-region-kubernetes-platform

# 2. Install developer tooling
make install-tools

# 3. Set up pre-commit hooks
make hooks

# 4. Validate your environment
make validate

# 5. See all available targets
make help
```

---

## Platform Roadmap

| Phase | Scope | Status |
|---|---|---|
| 1 | Repository Foundation & Project Structure | In Progress |
| 2 | Terraform AWS Foundation (VPC, IAM, S3 state backend) | Planned |
| 3 | EKS Cluster Provisioning (Primary Region) | Planned |
| 4 | GitOps Bootstrap with ArgoCD | Planned |
| 5 | Core Platform Add-ons (LBC, External Secrets, Cert-Manager) | Planned |
| 6 | Full Observability Stack (Prometheus, Grafana, Loki, Tempo) | Planned |
| 7 | Progressive Delivery with Argo Rollouts | Planned |
| 8 | Multi-Region Expansion (Secondary EKS Cluster) | Planned |
| 9 | Global Traffic Routing (Route53, Global Accelerator) | Planned |
| 10 | Disaster Recovery & Chaos Engineering | Planned |

---

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for development workflow, branch conventions, commit message standards, and PR requirements.

---

## Architecture Decisions

All significant technical decisions are documented as Architecture Decision Records in [docs/decisions/](./docs/decisions/).

---

## License

MIT — see [LICENSE](./LICENSE).
