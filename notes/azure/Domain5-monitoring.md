# Azure Monitor — Quick Mapping từ AWS CloudWatch

## Quick Mapping

```
AWS                              Azure
───────────────────────────────────────────────────
CloudWatch                   →   Azure Monitor
CloudWatch Metrics           →   Metrics
CloudWatch Logs              →   Log Analytics Workspace
CloudWatch Logs Insights     →   Kusto Query Language (KQL)
CloudWatch Alarms            →   Alerts
CloudWatch Agent             →   Azure Monitor Agent
X-Ray                        →   Application Insights
```

## KQL vs CloudWatch Logs Insights

```sql
-- CloudWatch Logs Insights
fields @timestamp, @message | filter @message like /error/

-- Kusto (KQL)
AzureDiagnostics | where Message contains "error"
```

**Verdict:** Giống CloudWatch, chỉ cần học KQL syntax.
