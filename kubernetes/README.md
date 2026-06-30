# Kubernetes

Raw Kubernetes manifests managed via Kustomize.

## Structure (target — populated across phases)

```
kubernetes/
├── base/                  # Base configurations (cluster-agnostic)
│   ├── namespaces/
│   ├── rbac/
│   ├── network-policies/
│   └── resource-quotas/
└── overlays/              # Environment / region-specific patches
    ├── production-us-east-1/
    ├── production-eu-west-1/
    └── staging/
```

## Conventions

- All workloads set `resources.requests` and `resources.limits`
- All workloads define `readinessProbe` and `livenessProbe`
- PodDisruptionBudgets are required for `replicas > 1`
- `latest` image tags are prohibited
- `hostPath` volumes are prohibited
- Validated with `kubeconform` in CI
