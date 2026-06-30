# Architecture Decision Records

This directory contains Architecture Decision Records (ADRs) for the platform.

ADRs document significant technical decisions: the context that motivated them, the options considered, and the rationale for the choice made. They are immutable historical records — superseded decisions are marked as such and linked to the replacement ADR.

## Index

| ADR | Title | Status |
|---|---|---|
| [ADR-001](./ADR-001-multi-region-eks-architecture.md) | Multi-Region EKS Architecture | Accepted |

## Creating a New ADR

```bash
# Copy the template
cp docs/decisions/ADR-001-multi-region-eks-architecture.md \
   docs/decisions/ADR-XXX-short-title.md

# Edit and fill in the sections
# Open a PR — ADRs require approval from @your-org/engineering-leads
```

## ADR Status Values

| Status | Meaning |
|---|---|
| `Draft` | Under discussion, not yet decided |
| `Accepted` | Decision made and being acted on |
| `Superseded` | Replaced by a later ADR (link provided) |
| `Deprecated` | No longer relevant |
| `Rejected` | Considered but not adopted |
