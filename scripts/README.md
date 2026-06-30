# Scripts

Platform automation and developer tooling scripts.

## Structure (target — populated across phases)

```
scripts/
├── bootstrap/             # One-time cluster bootstrapping
│   ├── 01-backend.sh      # Initialise Terraform state backend
│   ├── 02-eks.sh          # Bootstrap EKS + install ArgoCD
│   └── 03-argocd.sh       # Apply ArgoCD projects and initial apps
└── tools/                 # Developer helpers
    ├── kubeconfig.sh      # Fetch and merge kubeconfig for a region
    ├── port-forward.sh    # Quick port-forward helpers
    └── rotate-secrets.sh  # Trigger ESO secret rotation
```

## Standards

- All scripts are POSIX-compatible `bash`
- `set -euo pipefail` is set at the top of every script
- All scripts pass `shellcheck --severity=warning`
- Scripts accept environment variables for configuration, never hardcoded values
- Scripts are idempotent — safe to run multiple times
- Destructive operations prompt for confirmation unless `--force` is passed
