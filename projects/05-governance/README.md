# Project 05: Governance + Monitoring lab

Cheap-to-run nhưng dày AZ-104 exam points. Build a Management Group hierarchy, enforce policies, set budget alerts, route alerts to email.

## Architecture

```
                Tenant Root Group (managed by Microsoft)
                        │
                        ▼
                ┌─── mg-root ────┐
                │                │
          ┌─────┴─────┐    ┌─────┴─────┐
          │ mg-prod   │    │ mg-nonprod│
          └─────┬─────┘    └─────┬─────┘
                │                │
                ▼                ▼
        Subscription (yours, attached to mg-nonprod)
                │
        ┌───────┴───────┐
        │ Policy Init.  │   Allowed-locations + Require-tag + Deny-untagged-RG
        │ Budget        │   $50/mo, alerts 50% / 90% / 100%
        │ Action Group  │   email kien
        │ Activity Alrt │   when policy assignment deleted
        └───────────────┘
```

## Learning Goals (AZ-104)

- **Management Groups** — `azurerm_management_group`, sub assignment, hierarchy
- **Azure Policy** — built-in + custom definitions, initiatives, MG-scope assignment
- **Cost Management** — Budget at subscription scope, threshold alerts
- **Action Groups** — fanout target (email/webhook/SMS/...)
- **Activity Log Alerts** — fire on control-plane events (e.g. policy modified, role assignment created)

## Steps

### Step 0 — Pre-flight
- [ ] `az account show` — confirm bro là **Owner** trên subscription
- [ ] (Nếu fail Step 1) Elevate access: Entra ID → Properties → "Access management for Azure resources" → Yes (cấp tạm User Access Admin trên root MG, tắt sau khi tạo xong)

### Step 1 — MG hierarchy + policies
- [ ] `cp terraform.tfvars.example terraform.tfvars`, fill subscription_id + email
- [ ] `terraform init && apply`
- [ ] Verify: `az account management-group list -o table` → thấy mg-root, mg-prod, mg-nonprod
- [ ] Verify policy: thử tạo RG ở location ngoài allowlist → bị deny

### Step 2 — Test policy compliance
- [ ] Portal → Policy → Compliance → mg-nonprod → xem % compliance theo initiative
- [ ] Tạo 1 RG không có tag "Environment" → xem violation xuất hiện

### Step 3 — Trigger budget + activity alert
- [ ] Portal → Cost Management → Budgets → check budget của bro
- [ ] Manually delete an assignment trong portal → activity alert fire → email xuất hiện

### Step 4 — Cleanup
- [ ] `terraform destroy`

## Cloud Services Used

| Concept | Azure | AWS | GCP |
|---|---|---|---|
| Account hierarchy | Management Groups | AWS Organizations OUs | GCP Resource Hierarchy (folders) |
| Policy as code | Azure Policy + Initiative | AWS SCP + Config Rules | Organization Policy + Forseti |
| Cost alerts | Budgets + Cost Mgmt | AWS Budgets + Cost Anomaly | Billing budgets |
| Notification fanout | Action Groups | SNS Topic | Pub/Sub + Cloud Functions |
| Audit alerts | Activity Log Alerts | CloudTrail + EventBridge | Cloud Audit Logs + Alerting |

## Cost Notes

| Resource | Cost |
|---|---|
| Management Groups | Free |
| Azure Policy definitions/assignments | Free |
| Budgets | Free |
| Action Groups | Free (email channel) |
| Activity Log Alerts | Free for first 1000 alerts/month |
| **Total** | **~$0/day** — leave running |
