# ArgoCD

GitOps configuration for the Enterprise Kubernetes Platform.

## Structure (target — populated across phases)

```
argocd/
├── projects/              # ArgoCD Project definitions (RBAC boundaries)
│   ├── platform.yaml
│   └── applications.yaml
├── applications/          # ArgoCD Application manifests
│   ├── cert-manager.yaml
│   ├── external-secrets.yaml
│   ├── karpenter.yaml
│   └── monitoring.yaml
└── applicationsets/       # ApplicationSet for multi-cluster management
    ├── platform-addons.yaml
    └── workloads.yaml
```

## Architecture

ArgoCD is deployed in the primary region (`us-east-1`) and manages both clusters:

- `in-cluster` — the cluster ArgoCD runs in (us-east-1)
- `eks-eu-west-1` — the secondary cluster (registered as an external cluster)

ApplicationSets target both clusters using cluster labels, enabling a single App definition to deploy to all regions.

## Sync Waves

Sync waves ensure installation order for dependent components:

| Wave | Components |
|---|---|
| -5 | Namespaces, CRDs |
| 0 | cert-manager, External Secrets |
| 5 | Karpenter, AWS LBC |
| 10 | Monitoring stack |
| 20 | Application workloads |
