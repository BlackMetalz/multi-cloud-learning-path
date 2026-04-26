# Project 06: Backup + Identity

Cuối path. Touch những topic AZ-104 còn lại: Recovery Services Vault, Azure Backup, Entra ID groups, custom RBAC role, role assignments. PIM + Conditional Access cần Entra ID Premium nên chỉ document portal steps.

## Architecture

```
┌──────────── Entra ID (tenant scope) ─────────────┐
│  Group: g-vm-operators                            │
│    members: kien                                  │
│  Custom Role: VM Operator (start/stop/restart)    │
│    scope: rg-backup-lab                           │
└────────────────┬──────────────────────────────────┘
                 │ role assignment (group → role → RG)
                 ▼
┌──────────── rg-backup-lab ────────────────────────┐
│  VNet (10.30.0.0/16)                              │
│    └── Subnet (10.30.1.0/24)                      │
│  Linux VM B1s (Ubuntu)                            │
│    NIC, no public IP, no SSH from Internet        │
│  Recovery Services Vault                          │
│    └── Backup Policy (daily, 7-day retention)     │
│        └── Protected VM ────────────────┐         │
└────────────────────────────────────────┴─────────┘
                  Azure Backup encrypts + stores in vault
```

## Learning Goals (AZ-104)

- **Recovery Services Vault** — central backup store, GRS replication
- **Backup Policy** — schedule + retention rules
- **`azurerm_backup_protected_vm`** — wire VM ↔ vault ↔ policy
- **Entra ID Group** (via `azuread_group`) — security group, members
- **Custom RBAC Role** (`azurerm_role_definition`) — least-privilege actions
- **Role Assignment** — group as principal, custom role at RG scope
- (Documented only) **PIM** — Just-in-Time elevation, requires Entra ID P2
- (Documented only) **Conditional Access** — sign-in policies, requires Entra ID P1

## Steps

### Step 1 — Bootstrap
- [ ] `cp terraform.tfvars.example terraform.tfvars`, fill subscription_id
- [ ] `terraform init && apply`
- [ ] VM B1s up, vault created, backup policy attached, group + custom role exist

### Step 2 — Trigger first backup
- [ ] Portal → Recovery Services Vault → Backup items → Azure Virtual Machine → click VM → **Backup now**
- [ ] Wait ~30 min — first snapshot xong, status = Completed

### Step 3 — Verify custom role works
- [ ] Add yourself to `g-vm-operators` group (already done if email matches)
- [ ] Open new shell with reduced perms: `az login --service-principal` (or test in Cloud Shell as the group user)
- [ ] Try `az vm start -g rg-backup-lab -n vm-backup-lab` → ✓ allowed
- [ ] Try `az vm delete ...` → ✗ forbidden (custom role không có delete)

### Step 4 — Restore test (optional, 30+ phút)
- [ ] Portal → Vault → Backup items → VM → **Restore VM** → restore as new VM
- [ ] Verify new VM bootable

### Step 5 — PIM walkthrough (Entra ID P2 required)
**Free trial Entra ID P2 1 tháng nếu muốn**: Portal → Entra ID → Licenses → Try / Buy.
- [ ] Portal → Entra ID → Roles and administrators → User Administrator → Add assignments
- [ ] Assignment type: **Eligible** (not Active) → user: bro → save
- [ ] Test: bro logout/login lại → portal → "My roles" → Activate → enter justification → role active 1h
- [ ] Audit: Entra ID → Audit logs → filter by activity "Add member to role completed"

### Step 6 — Conditional Access walkthrough (Entra ID P1)
- [ ] Portal → Entra ID → Security → Conditional Access → New policy
- [ ] Name: `cap-require-mfa-from-untrusted-locations`
- [ ] Users: All users (or test group)
- [ ] Cloud apps: All
- [ ] Conditions → Locations → Exclude → "Trusted locations" (cần named locations trước)
- [ ] Grant → Require multi-factor authentication
- [ ] Report-only mode trước khi enforce
- [ ] Verify trong Sign-in logs sau 1-2 lần login

### Step 7 — Cleanup
- [ ] `terraform destroy`
- [ ] **Lưu ý**: vault có **soft delete 14 ngày** mặc định — nếu apply lại bị conflict tên, đợi hoặc đổi suffix

## Cloud Services Used

| Concept | Azure | AWS | GCP |
|---|---|---|---|
| Backup vault | Recovery Services Vault | AWS Backup Vault | Backup and DR Service |
| Backup policy | Backup Policy | Backup Plan | Backup Plan |
| Identity directory | Entra ID | IAM Identity Center / Cognito | Cloud Identity |
| Group | Entra ID Group | IAM Group | Google Group |
| Custom role | RBAC Role Definition | IAM Customer Managed Policy | IAM Custom Role |
| JIT elevation | PIM (Privileged Identity Mgmt) | IAM Roles + Session Mgr | IAM Conditional Access |
| Sign-in policy | Conditional Access | IAM Identity Center policies | Context-aware Access |

## Cost Notes

| Resource | Cost (approx) |
|---|---|
| VM B1s | ~$8/mo (~$0.27/day) |
| Recovery Services Vault (GRS) | $5/mo + storage GB |
| Backup snapshots (~50GB) | ~$0.10/day |
| Entra ID groups, custom roles | Free |
| **Total** | **~$0.40/day** if leave running |

`az vm deallocate` để pause VM, vault stays. Destroy nếu xong hẳn.
