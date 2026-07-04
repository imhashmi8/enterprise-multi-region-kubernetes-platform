#!/usr/bin/env bash
set -euo pipefail

# Bootstrap ArgoCD in the primary EKS cluster (us-east-1).
# Run this after the EKS cluster is provisioned and kubeconfig is configured.
#
# Usage:
#   ./scripts/bootstrap/01-argocd.sh [--region us-east-1]

# ── Variables ─────────────────────────────────────────────────────────────────
REGION="${REGION:-us-east-1}"
CLUSTER_NAME="${CLUSTER_NAME:-eks-platform-production-${REGION}}"
ARGOCD_NAMESPACE="argocd"
ARGOCD_CHART_VERSION="${ARGOCD_CHART_VERSION:-7.3.11}"
REPO_ROOT="$(git rev-parse --show-toplevel)"

# ── Helpers ───────────────────────────────────────────────────────────────────
log()  { echo "[$(date -u +%H:%M:%S)] $*"; }
die()  { echo "[ERROR] $*" >&2; exit 1; }
wait_for_rollout() {
  local ns="$1" deploy="$2"
  log "Waiting for $deploy to be ready..."
  kubectl rollout status deployment/"$deploy" -n "$ns" --timeout=300s
}

# ── Pre-flight checks ─────────────────────────────────────────────────────────
command -v kubectl >/dev/null || die "kubectl not found"
command -v helm    >/dev/null || die "helm not found"
command -v aws     >/dev/null || die "aws CLI not found"

log "Updating kubeconfig for cluster: $CLUSTER_NAME in $REGION"
aws eks update-kubeconfig \
  --region "$REGION" \
  --name   "$CLUSTER_NAME"

kubectl cluster-info --request-timeout=10s || die "Cannot reach cluster — check kubeconfig and VPN"

# ── Namespaces ────────────────────────────────────────────────────────────────
log "Applying platform namespaces..."
kubectl apply -f "$REPO_ROOT/kubernetes/base/namespaces/namespaces.yaml"

# ── Install ArgoCD via Helm ───────────────────────────────────────────────────
log "Adding ArgoCD Helm repository..."
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

log "Installing ArgoCD $ARGOCD_CHART_VERSION..."
helm upgrade --install argocd argo/argo-cd \
  --namespace "$ARGOCD_NAMESPACE" \
  --version   "$ARGOCD_CHART_VERSION" \
  --values    "$REPO_ROOT/argocd/install/argocd-values.yaml" \
  --wait \
  --timeout 10m

wait_for_rollout "$ARGOCD_NAMESPACE" argocd-server
wait_for_rollout "$ARGOCD_NAMESPACE" argocd-repo-server

# ── Apply ArgoCD Projects ─────────────────────────────────────────────────────
log "Applying ArgoCD Projects..."
kubectl apply -f "$REPO_ROOT/argocd/projects/platform.yaml"
kubectl apply -f "$REPO_ROOT/argocd/projects/workloads.yaml"

# ── Bootstrap App of Apps ─────────────────────────────────────────────────────
log "Applying argocd-config App of Apps..."
kubectl apply -f "$REPO_ROOT/argocd/applications/argocd-config.yaml"
kubectl apply -f "$REPO_ROOT/argocd/applications/namespaces.yaml"

# ── Retrieve initial admin password ──────────────────────────────────────────
log "Retrieving initial ArgoCD admin password..."
INITIAL_PASSWORD=$(kubectl get secret argocd-initial-admin-secret \
  -n "$ARGOCD_NAMESPACE" \
  -o jsonpath='{.data.password}' | base64 -d)

log "ArgoCD is ready."
echo ""
echo "  Access ArgoCD:"
echo "    kubectl port-forward svc/argocd-server -n argocd 8080:80"
echo "    URL:      http://localhost:8080"
echo "    Username: admin"
echo "    Password: $INITIAL_PASSWORD"
echo ""
echo "  Rotate the password immediately after first login."
echo ""
log "Bootstrap complete."
