# Helm

Internal Helm charts for the platform.

## Structure (target — populated across phases)

```
helm/
└── charts/
    ├── platform-base/     # Common labels, network policies, PSA config
    ├── observability/     # Grafana dashboard provisioning
    └── app-template/      # Opinionated chart for application teams
```

## Usage

```bash
# Lint a chart
helm lint helm/charts/<chart-name>

# Render locally
helm template <release-name> helm/charts/<chart-name> \
  --values helm/charts/<chart-name>/values.yaml

# Package
helm package helm/charts/<chart-name> -d /tmp/charts
```

Charts are published to an internal OCI registry (AWS ECR) via the CI pipeline.
