# Azure Identity & Governance — Quick Mapping từ AWS

## Quick Mapping

```
AWS                              Azure
───────────────────────────────────────────────────
IAM Users                    →   Entra ID Users
IAM Groups                   →   Entra ID Groups
IAM Roles                    →   RBAC Roles
IAM Policies (permissions)   →   RBAC Role Assignments
AWS Organizations            →   Management Groups
SCPs                         →   Azure Policies
AWS Account                  →   Subscription
Resource Tags                →   Resource Tags
(không có)                   →   Resource Locks
```

## Hierarchy

```
AWS:
  Organization
    └── Account 1
    └── Account 2

Azure:
  Tenant (Entra ID)
    └── Management Group
          └── Subscription 1
                └── Resource Group
                      └── Resources
          └── Subscription 2
```

## RBAC (Role-Based Access Control)

Giống IAM Roles nhưng assign ở nhiều levels:

```
Management Group  →  inherit xuống tất cả
  └── Subscription  →  inherit xuống tất cả RGs
        └── Resource Group  →  inherit xuống resources
              └── Resource  →  chỉ resource đó
```

Built-in roles phổ biến:

| Role | Quyền |
|------|-------|
| **Owner** | Full access + assign roles |
| **Contributor** | Full access, không assign roles |
| **Reader** | View only |
| **User Access Administrator** | Manage access only |

```bash
# Assign role
az role assignment create \
  --assignee user@example.com \
  --role "Contributor" \
  --scope /subscriptions/<sub-id>/resourceGroups/rg-myapp
```

## Azure Policy (≠ IAM Policy!)

**Khác hoàn toàn với AWS IAM Policy.** Azure Policy enforce rules trên resources, không phải permissions.

| AWS | Azure |
|-----|-------|
| IAM Policy = ai được làm gì | RBAC = ai được làm gì |
| SCP = restrict accounts | Azure Policy = enforce rules trên resources |

Ví dụ Azure Policy:
- "VM chỉ được tạo ở Southeast Asia"
- "Storage account phải bật encryption"
- "Tất cả resources phải có tag 'Environment'"

```bash
# List built-in policies
az policy definition list --query "[].displayName" -o tsv | head -20

# Assign policy (require tag)
az policy assignment create \
  --name "require-env-tag" \
  --policy "/providers/Microsoft.Authorization/policyDefinitions/require-tag" \
  --scope /subscriptions/<sub-id> \
  --params '{"tagName": {"value": "Environment"}}'
```

## Resource Locks

**AWS không có.** Chống xóa/sửa nhầm.

| Lock type | Cho phép |
|-----------|----------|
| **CanNotDelete** | Read + Update, không Delete |
| **ReadOnly** | Read only, không Update/Delete |

```bash
# Add delete lock
az lock create \
  --name no-delete \
  --lock-type CanNotDelete \
  --resource-group rg-myapp

# Must remove lock before delete
az lock delete --name no-delete --resource-group rg-myapp
```

## Management Groups

Giống AWS Organizations, group Subscriptions để apply policies/RBAC.

```
Root Management Group
  ├── Production
  │     ├── Subscription: prod-app1
  │     └── Subscription: prod-app2
  └── Development
        └── Subscription: dev-sandbox
```

Policy/RBAC assign ở Management Group → inherit xuống tất cả Subscriptions.

## So sánh tổng hợp

| Concept | AWS | Azure |
|---------|-----|-------|
| Identity provider | IAM | Entra ID (Azure AD) |
| Permissions | IAM Policies | RBAC Role Assignments |
| Resource rules | SCPs | Azure Policies |
| Account grouping | Organizations + OUs | Management Groups |
| Billing boundary | Account | Subscription |
| Resource grouping | Tags only | Resource Groups + Tags |
| Delete protection | Termination protection (EC2) | Resource Locks (any resource) |

## Entra ID (Azure AD) vs AWS IAM

| Feature | AWS IAM | Entra ID |
|---------|---------|----------|
| Built-in MFA | IAM MFA | Conditional Access (mạnh hơn) |
| SSO to apps | IAM Identity Center | Enterprise Apps |
| B2B access | Cross-account roles | Guest Users |
| B2C access | Cognito | Azure AD B2C |

**Verdict:** RBAC ≈ IAM Roles. Azure Policy ≈ SCPs (nhưng flexible hơn). Resource Locks là bonus.
