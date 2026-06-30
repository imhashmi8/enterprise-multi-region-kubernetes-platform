# Platform Architecture Overview

## Design Principles

| Principle | Application |
|---|---|
| **Everything as Code** | All infrastructure, configuration, and policy is version-controlled and applied via automation — no manual console changes |
| **GitOps** | Kubernetes state is driven entirely by Git. ArgoCD reconciles cluster state continuously |
| **Immutable Infrastructure** | Nodes and AMIs are replaced, not patched in-place. All mutable state lives in managed data services |
| **Defence in Depth** | Security controls at every layer: IAM, network policies, pod security, image scanning, runtime detection |
| **Observability by Default** | Every workload exposes metrics, structured logs, and distributed traces. No observability opt-in required |
| **Progressive Delivery** | Argo Rollouts enforces canary / blue-green promotion with automated analysis before full rollout |
| **Multi-Region Active-Active** | Traffic is split across two AWS regions. Either region can absorb 100% of load during DR events |

---

## Region Strategy

| Region | Role | Failover Priority |
|---|---|---|
| `us-east-1` | Primary | 1 |
| `eu-west-1` | Secondary | 2 |

Route53 latency-based routing directs users to the lowest-latency region. AWS Global Accelerator provides static anycast IPs with automatic regional failover.

---

## Network Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│  Internet                                                          │
└──────────────────────────────┬─────────────────────────────────────┘
                               │
                    ┌──────────▼──────────┐
                    │  AWS Global         │
                    │  Accelerator        │
                    │  Route53 Latency    │
                    └──────┬──────┬───────┘
                           │      │
           ┌───────────────▼─┐  ┌─▼───────────────┐
           │  us-east-1      │  │  eu-west-1       │
           │  VPC            │  │  VPC             │
           │  ┌───────────┐  │  │  ┌───────────┐  │
           │  │ Public    │  │  │  │ Public    │  │
           │  │ Subnets   │  │  │  │ Subnets   │  │
           │  │ (ALB/NLB) │  │  │  │ (ALB/NLB) │  │
           │  └─────┬─────┘  │  │  └─────┬─────┘  │
           │        │        │  │        │         │
           │  ┌─────▼─────┐  │  │  ┌─────▼─────┐  │
           │  │ Private   │  │  │  │ Private   │  │
           │  │ Subnets   │  │  │  │ Subnets   │  │
           │  │ (EKS      │  │  │  │ (EKS      │  │
           │  │  Nodes)   │  │  │  │  Nodes)   │  │
           │  └─────┬─────┘  │  │  └─────┬─────┘  │
           │        │        │  │        │         │
           │  ┌─────▼─────┐  │  │  ┌─────▼─────┐  │
           │  │ Data      │  │  │  │ Data      │  │
           │  │ Subnets   │  │  │  │ Subnets   │  │
           │  │ (RDS,     │  │  │  │ (RDS,     │  │
           │  │  Redis)   │  │  │  │  Redis)   │  │
           └──│───────────│──┘  └──│───────────│──┘
              │           │        │           │
              └───────────┴────────┴───────────┘
                           VPC Peering /
                        Transit Gateway
```

Each region uses a `/16` VPC divided into three subnet tiers (public, private, data) across 3 availability zones — 9 subnets per VPC.

---

## EKS Cluster Architecture

```
EKS Control Plane (AWS Managed)
│
├── System Node Group (on-demand, t3.medium)
│   └── kube-system, monitoring, argocd, cert-manager, external-secrets
│
├── Application Node Group (on-demand, m6i.xlarge)
│   └── Baseline capacity for production workloads
│
└── Spot Node Pool (via Karpenter)
    └── Burst capacity, batch, and non-critical workloads
```

---

## GitOps Flow

```
Developer                  Git                     ArgoCD              Kubernetes
    │                       │                          │                    │
    │──── git push ────────►│                          │                    │
    │                       │──── webhook ────────────►│                    │
    │                       │                          │── git clone ──────►│
    │                       │                          │                    │
    │                       │                          │── apply/sync ─────►│
    │                       │                          │◄─ reconciled ──────│
    │◄─── PR status ────────│◄─── sync status ─────────│                    │
```

ArgoCD runs in the primary region and manages both clusters. A DR scenario promotes the secondary ArgoCD instance to active.

---

## Secret Management Flow

```
AWS Secrets Manager / Parameter Store
        │
External Secrets Operator (ESO)
        │  (polls on schedule, creates/rotates)
        ▼
Kubernetes Secret (namespaced)
        │
Pod (mounts as env var or volume)
```

No secrets are stored in Git. All secrets are injected at runtime by ESO from AWS Secrets Manager.
