## Summary

<!-- Required: 2-4 sentences on what this PR does and why. Link to the issue or ADR it implements. -->

Closes #<!-- issue number -->

---

## Type of Change

<!-- Check all that apply -->

- [ ] `feat` — New feature or capability
- [ ] `fix` — Bug fix
- [ ] `chore` — Tooling, dependencies, or non-functional change
- [ ] `docs` — Documentation only
- [ ] `refactor` — Refactor without behaviour change
- [ ] `ci` — CI/CD pipeline change
- [ ] `BREAKING CHANGE` — Requires coordination with application teams

---

## Changes Made

<!-- Bullet list of specific changes. Be precise enough that a reviewer can follow along without the diff. -->

-
-

---

## Infrastructure Impact

<!-- Complete this section for any Terraform or Kubernetes changes -->

| Question | Answer |
|---|---|
| Resources created | |
| Resources modified | |
| Resources destroyed | |
| AWS regions affected | |
| Estimated cost delta | |
| Downtime expected? | Yes / No |
| Rollback procedure | |

---

## Testing

<!-- What did you do to test this change? -->

- [ ] `make validate` passes locally
- [ ] `make pre-commit` passes locally
- [ ] `terraform plan` reviewed and attached (for Terraform changes)
- [ ] `helm lint` + `helm template` rendered and reviewed
- [ ] Tested in non-production environment: `__________`
- [ ] Load/chaos tested (if applicable)

**Test evidence:**

<!-- Paste relevant command output, screenshots, or link to test run -->

---

## Checklist

- [ ] I have read [CONTRIBUTING.md](../CONTRIBUTING.md)
- [ ] No secrets, credentials, or PII are included in this PR
- [ ] All hardcoded values have been replaced with variables
- [ ] New resources are tagged with the standard tag set
- [ ] New components have appropriate alerts and runbooks
- [ ] An ADR has been created for significant architectural decisions
- [ ] CHANGELOG.md has been updated

---

## Reviewer Notes

<!-- Optional: anything specific you want reviewers to focus on, or context that isn't obvious from the diff -->
