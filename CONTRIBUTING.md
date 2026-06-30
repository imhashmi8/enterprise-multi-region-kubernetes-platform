# Contributing to the Enterprise Kubernetes Platform

This document defines the engineering standards and workflow for contributing to this platform repository. All contributors — including platform engineers, SREs, and application teams raising platform requests — are expected to follow these guidelines.

---

## Table of Contents

- [Development Setup](#development-setup)
- [Branch Strategy](#branch-strategy)
- [Commit Standards](#commit-standards)
- [Pull Request Process](#pull-request-process)
- [Code Review Standards](#code-review-standards)
- [Terraform Conventions](#terraform-conventions)
- [Kubernetes Manifest Conventions](#kubernetes-manifest-conventions)
- [Testing Requirements](#testing-requirements)

---

## Development Setup

```bash
# Install all required tools via Makefile
make install-tools

# Install and activate pre-commit hooks (mandatory)
make hooks

# Verify your setup passes all checks
make validate
```

Pre-commit hooks run on every commit and enforce: trailing whitespace, YAML/JSON lint, Terraform format, Helm lint, and secret scanning. **Do not bypass hooks with `--no-verify`.**

---

## Branch Strategy

This repository uses **trunk-based development** with short-lived feature branches.

| Branch | Purpose | Protection |
|---|---|---|
| `main` | Production-ready state | Required reviews, status checks |
| `feature/<scope>/<description>` | New features or changes | None |
| `fix/<scope>/<description>` | Bug fixes | None |
| `chore/<scope>/<description>` | Non-functional changes | None |

**Examples:**
```
feature/terraform/add-karpenter-node-pools
fix/argocd/sync-wave-ordering
chore/docs/update-adr-001
```

Branches should be **short-lived** (< 3 days). Long-running branches must be rebased onto `main` daily.

---

## Commit Standards

This repository follows the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification.

### Format

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Types

| Type | When to Use |
|---|---|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `chore` | Build, tooling, or dependency updates |
| `refactor` | Code change that is not a fix or feature |
| `test` | Adding or correcting tests |
| `perf` | Performance improvement |
| `ci` | Changes to CI/CD pipelines |
| `revert` | Reverting a prior commit |

### Scopes

Use the top-level directory that the change affects:

`terraform`, `kubernetes`, `helm`, `argocd`, `monitoring`, `scripts`, `docs`, `github`

### Examples

```
feat(terraform): add Karpenter NodePool for spot instances

fix(argocd): correct sync-wave annotations for cert-manager CRDs

docs(decisions): add ADR-003 for secret management strategy

ci(github): add Terraform plan to PR workflow
```

**Rules:**
- Description is lowercase, imperative mood, no period at end
- Body wraps at 72 characters
- Breaking changes include `BREAKING CHANGE:` in the footer

---

## Pull Request Process

1. **Open a draft PR** as soon as you push your first commit. Link the relevant issue.
2. **Self-review** your diff before requesting reviewers. Check for secrets, hardcoded values, and missing tests.
3. **Fill in the PR template** completely. Partial PRs will be returned without review.
4. **All CI checks must pass** before requesting review.
5. **Request review** from owners per `CODEOWNERS`. Do not merge without approvals.
6. **Squash-merge** is the default strategy. The squash commit message must follow Conventional Commits.
7. **Delete the branch** after merge.

### PR Size Guidelines

| PR Size | Lines Changed | Expectation |
|---|---|---|
| Small | < 200 | Preferred. Fast turnaround. |
| Medium | 200–500 | Acceptable. Clear description required. |
| Large | > 500 | Requires pre-approval. Split if possible. |

---

## Code Review Standards

Reviewers are expected to check:

- **Correctness** — does the change do what it claims?
- **Security** — no secrets, overly permissive IAM, or unvalidated inputs
- **Idempotency** — infrastructure changes must be safely re-applicable
- **Observability** — new components expose metrics, logs, and traces
- **Documentation** — ADRs for significant decisions, runbooks for new ops procedures
- **Tests** — `terraform validate`, `helm lint`, unit tests where applicable

Use GitHub suggestion blocks for minor fixes. For substantive concerns, request changes and explain the reasoning.

---

## Terraform Conventions

- All modules must have `variables.tf`, `outputs.tf`, and `versions.tf`
- Variables must have `description` and `type`; use `validation` blocks for constrained inputs
- Outputs must have `description`
- Tag all taggable resources with the standard tag set (see `terraform/modules/tagging/`)
- State is stored in S3 with DynamoDB locking — never commit `.tfstate` files
- Run `terraform fmt -recursive` before committing (enforced by pre-commit)
- Run `tflint` and `checkov` locally before opening a PR

---

## Kubernetes Manifest Conventions

- All workloads must define `resources.requests` and `resources.limits`
- All workloads must have `readinessProbe` and `livenessProbe`
- Pod disruption budgets are required for any Deployment with `replicas > 1`
- Use `RollingUpdate` strategy with `maxSurge: 1, maxUnavailable: 0` as default
- Never use `latest` image tags
- `hostPath` volumes are prohibited
- `privileged: true` containers require explicit platform team approval

---

## Testing Requirements

| Component | Required Tests |
|---|---|
| Terraform modules | `terraform validate`, `terraform plan` in CI |
| Helm charts | `helm lint`, `helm template` render check |
| Kubernetes manifests | `kubectl --dry-run=client`, `kubeconform` |
| Scripts | `shellcheck` |
| Python scripts | `pytest` unit tests |
