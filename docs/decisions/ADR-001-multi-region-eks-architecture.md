# ADR-001: Multi-Region EKS Architecture

| Field | Value |
|---|---|
| **Status** | Accepted |
| **Date** | 2024-01-15 |
| **Deciders** | Platform Engineering, Engineering Leadership |
| **Supersedes** | — |
| **Superseded by** | — |

---

## Context

The platform must support enterprise workloads with the following requirements:

- **99.99% availability SLA** — single-region failures must not result in customer-facing downtime
- **GDPR and data residency** — EU customer data must remain within EU AWS regions
- **Sub-100ms latency** for users in North America and Europe
- **RPO < 15 minutes, RTO < 30 minutes** for disaster recovery scenarios
- **Regulatory compliance** — SOC 2 Type II, ISO 27001

The current single-region architecture cannot satisfy the HA and data residency requirements simultaneously.

---

## Decision

Deploy two active Amazon EKS clusters: one in `us-east-1` (primary) and one in `eu-west-1` (secondary). Both clusters serve live traffic, sized to absorb 100% of load from either region independently.

Traffic routing is handled by Route53 latency-based routing with health checks and AWS Global Accelerator for static anycast IPs and automatic failover.

ArgoCD in the primary region manages both clusters. In a DR event, the secondary cluster's ArgoCD instance is promoted to active using a runbook-driven procedure.

---

## Options Considered

### Option A: Single-region with Multi-AZ (Rejected)

Deploy one EKS cluster across 3 AZs in `us-east-1`.

**Pros:** Simpler operations, lower cost, less operational surface.

**Cons:** Cannot satisfy GDPR data residency requirements for EU users. A regional AWS outage (e.g., us-east-1 degradation in Dec 2021) would cause full platform unavailability. Does not meet 99.99% SLA.

### Option B: Active-Passive Multi-Region (Rejected)

Primary cluster in `us-east-1`. Passive standby in `eu-west-1` receiving no live traffic, warmed up on failover.

**Pros:** Lower cost than active-active. Simpler traffic management.

**Cons:** Failover warming adds 5–15 minutes to RTO, missing the 30-minute target at scale. Passive cluster represents wasted capacity and adds operational complexity (keeping it in sync without real traffic exercising it).

### Option C: Active-Active Multi-Region (Accepted)

Two live clusters. Traffic split via Route53 latency routing. Each cluster independently capable of handling full load.

**Pros:** Meets 99.99% SLA. Natural EU data residency via regional routing. Both clusters are continuously exercised by real traffic (eliminates cold-start risk). Achieves RTO < 5 minutes via DNS failover — well within the 30-minute target.

**Cons:** Higher cost (~1.8× vs. single-region). More complex GitOps topology. Requires cross-region data synchronisation strategy for stateful services.

---

## Consequences

### Positive
- Platform meets all HA, data residency, and DR requirements
- Both regions serve real traffic → no cold-start risk on failover
- Regional isolation for compliance (EU data stays in eu-west-1)

### Negative / Mitigations
- **Cost increase**: ~1.8× infrastructure cost vs. single-region. Mitigated by Karpenter spot usage and right-sizing.
- **Operational complexity**: Two clusters to maintain, patch, and monitor. Mitigated by unified ArgoCD management, shared Helm charts, and automated Karpenter drift remediation.
- **Data synchronisation**: Stateful services (RDS Aurora Global, ElastiCache Global Datastore) must replicate cross-region. Write latency increases by ~80ms for synchronous replication to eu-west-1.
- **GitOps topology**: ArgoCD ApplicationSets target both clusters. Requires careful sync-wave ordering and health check tuning. Documented in runbook `runbooks/argocd-multi-cluster.md`.

---

## Implementation Notes

- VPC CIDR ranges must not overlap: `us-east-1` uses `10.0.0.0/16`, `eu-west-1` uses `10.1.0.0/16`
- Transit Gateway connects the two VPCs for control-plane traffic
- Terraform workspaces are used per region (`us-east-1`, `eu-west-1`) with a shared remote state backend in `us-east-1`
- EKS version is pinned and updated via the platform upgrade runbook. Both clusters must run the same minor version at all times.
