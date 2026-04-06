# Cloud Scope & Hierarchy — The Organizational Model Behind Every Cloud

## Why This Matters

Every cloud has a hierarchy that controls:
- **Who can access what** (IAM/RBAC)
- **Who pays for what** (Billing)
- **What rules apply where** (Policy)
- **What limits exist** (Quota)

Learn this once, and IAM, billing, and policy all make sense.

## Azure Scope Hierarchy

```
Tenant (Entra ID)                    Identity & org boundary
  └── Management Group               Group subscriptions, apply policy (optional)
        └── Subscription             Billing boundary, quota limits
              └── Resource Group     Logical container for resources
                    └── Resource     VM, DB, Storage, VNet...
```

### Each Layer Explained

| Scope | What it is | Real-world analogy |
|---|---|---|
| **Tenant** | Your organization in Azure. Contains all users, groups, app registrations. 1 company = 1 tenant. | The company |
| **Management Group** | Optional grouping of subscriptions. Apply policies/RBAC across multiple subs at once. Mainly for enterprises. | Departments |
| **Subscription** | Billing unit. Each sub has its own quota, payment method, and resource limits. | A credit card / budget |
| **Resource Group** | Logical container. Group related resources together. Delete group = delete everything inside. | A project folder |
| **Resource** | The actual thing — a VM, a database, a storage account. | The files in the folder |

### RBAC Inheritance

Roles assigned at a higher scope inherit downward:

```
Owner at Tenant              → owns everything
Contributor at Subscription  → can manage all resource groups & resources in that sub
Reader at Resource Group     → can view all resources in that group only
```

You CANNOT override inherited permissions at a lower scope. A Contributor at Subscription level will always have Contributor access to every Resource Group in that Subscription.

### Common Patterns

**Small team / learning:**
```
Tenant
  └── 1 Subscription (Pay-As-You-Go)
        ├── rg-project-a
        ├── rg-project-b
        └── rg-sandbox        ← experiment here, delete when done
```

**Production setup:**
```
Tenant
  └── Management Group: Root
        ├── Management Group: Production
        │     └── Subscription: Prod
        │           ├── rg-app-prod
        │           └── rg-shared-prod
        └── Management Group: Non-Production
              ├── Subscription: Dev
              │     └── rg-app-dev
              └── Subscription: Staging
                    └── rg-app-staging
```

## Multi-Cloud Comparison

```
Azure                    AWS                       GCP                      OpenStack
─────                    ───                       ───                      ─────────
Tenant (Entra ID)   ≈   Organization         ≈   Organization         ≈   Domain
Management Group    ≈   OU (Org Unit)        ≈   Folder               ≈   — (none)
Subscription        ≈   Account              ≈   Project              ≈   Project
Resource Group      ≈   — (tags/stacks)      ≈   — (labels)           ≈   — (none)
Resource            ≈   Resource             ≈   Resource             ≈   Resource
```

### Key Differences

| Aspect | Azure | AWS | GCP | OpenStack |
|---|---|---|---|---|
| **Billing boundary** | Subscription | Account | Project (Billing Account) | No built-in billing |
| **Resource grouping** | Resource Group (first-class) | Tags / CloudFormation stacks (loose) | Labels (loose) | Not available |
| **Identity boundary** | Tenant (Entra ID) | Organization + IAM | Organization + Workspace | Domain (Keystone) |
| **Network isolation** | VNet (manual, within subscription) | VPC (default per region) | VPC (global, per project) | Network (auto per project) |
| **Policy enforcement** | Azure Policy (any scope) | SCP (org/OU/account) | Org Policy (org/folder/project) | Oslo.policy (per service) |
| **Hierarchy depth** | 6 levels of Management Groups | 5 levels of OUs | 10 levels of Folders | Flat (domain → project) |

### The Pattern

Despite different names, every cloud solves the same organizational problems:

1. **Who are you?** → Identity boundary (Tenant / Organization / Domain)
2. **What can you group?** → Organizational units (Management Group / OU / Folder)
3. **Who pays?** → Billing boundary (Subscription / Account / Project)
4. **How to organize resources?** → Grouping (Resource Group / Tags / Labels)
5. **What rules apply?** → Policy (Azure Policy / SCP / Org Policy)
6. **What are the limits?** → Quota per billing boundary

## Practical Tips

1. **Start simple** — 1 subscription, a few resource groups. Add management groups when you actually need them.
2. **Resource Group = your sandbox** — Create `rg-sandbox`, experiment, `az group delete --name rg-sandbox --yes`, pay nothing.
3. **Name consistently** — `rg-{app}-{env}` (e.g., `rg-myapp-prod`, `rg-myapp-dev`).
4. **Separate environments by subscription** when the team grows — easier billing, cleaner RBAC, harder to accidentally break prod.
5. **RBAC at the right scope** — Don't give Subscription-level Contributor to everyone. Start narrow (Resource Group), expand when needed.
