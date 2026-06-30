# Monitoring

Observability stack configuration for the Enterprise Kubernetes Platform.

## Stack

| Component | Purpose |
|---|---|
| Prometheus | Metrics collection and storage |
| Thanos | Long-term metrics retention + cross-region query |
| Grafana | Dashboards and visualisation |
| Loki | Log aggregation |
| Fluent Bit | Log shipping from nodes/pods |
| Tempo | Distributed tracing |
| OpenTelemetry Collector | Trace + metric pipeline |
| Alertmanager | Alert routing (PagerDuty, Slack) |

## Structure (target — populated in Phase 6)

```
monitoring/
├── dashboards/            # Grafana dashboard JSON (provisioned via ConfigMap)
│   ├── platform/
│   └── kubernetes/
├── alerts/                # PrometheusRule manifests
│   ├── kubernetes.yaml
│   ├── eks.yaml
│   └── platform.yaml
└── runbooks/              # Symlinks / references to docs/runbooks/
```

## Alerting Philosophy

- Every alert has a runbook link in its annotations
- Alerts fire at `warning` before they escalate to `critical`
- `critical` alerts page on-call immediately via PagerDuty
- `warning` alerts post to Slack `#platform-alerts` with no on-call page
- No alert fires without a clear actionable remediation path
