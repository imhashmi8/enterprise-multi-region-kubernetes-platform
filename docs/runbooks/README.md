# Runbooks

Operational runbooks for the Enterprise Kubernetes Platform.

Runbooks are step-by-step procedures for recurring operational tasks and incident response. Every Alertmanager alert must link to a runbook. Every runbook must be tested during quarterly DR exercises.

---

## Index

| Runbook | Category | Last Tested |
|---|---|---|
| *(Phase 6: Observability — runbooks added with alert definitions)* | | |

---

## Runbook Standards

Each runbook must include:

1. **Alert / Trigger** — what condition triggers this runbook (alert name, PagerDuty policy)
2. **Severity** — P1 / P2 / P3
3. **Impact** — what breaks if this is not resolved
4. **Prerequisites** — tools and access required
5. **Diagnosis** — commands to understand the scope
6. **Remediation** — step-by-step fix with copy-pasteable commands
7. **Escalation** — who to page if the runbook doesn't resolve the issue
8. **Post-incident** — what to do after mitigation (file incident report, create follow-up issue)

## Runbook Template

```markdown
# RB-XXX: <Alert Name>

| Field        | Value              |
|---|---|
| Alert        | `<PrometheusRule name>` |
| Severity     | P1 / P2 / P3       |
| Team         | Platform / SRE     |
| Last Updated | YYYY-MM-DD         |

## Impact
...

## Prerequisites
...

## Diagnosis
\`\`\`bash
# commands
\`\`\`

## Remediation
\`\`\`bash
# commands
\`\`\`

## Escalation
...
```
