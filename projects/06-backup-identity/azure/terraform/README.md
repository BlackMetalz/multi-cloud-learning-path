### Tutorial

```bash
cd projects/06-backup-identity/azure/terraform
az login --use-device-code
cp terraform.tfvars.example terraform.tfvars
# edit: subscription_id + operator_group_members (UPN của bro)

terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### File layout

```
azure/terraform/
├── providers.tf              # azurerm 4.x + azuread 3.x, key=backup-identity.tfstate
├── variables.tf              # vm_size, retention, operator_group_members
├── locals.tf, main.tf        # tags + RG + suffix
├── network.tf                # tiny VNet for VM (no public IP)
├── vm.tf                     # B1s Ubuntu, no public IP
├── backup.tf                 # Recovery Vault + daily policy + protected VM
├── identity.tf               # Entra group + custom role + role assignment
├── outputs.tf
└── terraform.tfvars.example
```

### Pre-flight

```bash
# 1. SKU check (lesson learned từ project 02)
az vm list-skus -l southeastasia --size Standard_B1s \
  --query "[?length(restrictions)==\`0\`].name" -o tsv

# 2. UPN của bro để add vào group
az ad signed-in-user show --query userPrincipalName -o tsv
# Copy output này vào operator_group_members trong tfvars
```

### Verify

```bash
# 1. VM running
az vm list -g rg-backup-lab -o table

# 2. Vault có protected item
az backup item list \
  --vault-name $(terraform output -raw vault_name) \
  --resource-group rg-backup-lab \
  --backup-management-type AzureIaasVM \
  -o table
# Status sẽ là "IRPending" cho đến khi backup đầu tiên xong

# 3. Trigger backup ngay (thay vì đợi 23:00)
az backup protection backup-now \
  --vault-name $(terraform output -raw vault_name) \
  --resource-group rg-backup-lab \
  --container-name $(az vm show -g rg-backup-lab -n $(terraform output -raw vm_name) --query id -o tsv) \
  --item-name $(terraform output -raw vm_name) \
  --backup-management-type AzureIaasVM \
  --workload-type VM \
  --retain-until $(date -v +30d +%d-%m-%Y 2>/dev/null || date -d "+30 days" +%d-%m-%Y)

# 4. Group có member
az ad group member list -g $(terraform output -raw operator_group_name) -o table

# 5. Custom role tồn tại
az role definition list --custom-role-only --query "[?contains(roleName, 'VM Operator')]" -o table

# 6. Role assignment hợp lệ
az role assignment list \
  --assignee $(terraform output -raw operator_group_id) \
  --scope /subscriptions/$(az account show --query id -o tsv)/resourceGroups/rg-backup-lab \
  -o table
```

### Test custom role least-privilege (Step 3)

Mở Cloud Shell hoặc terminal khác, login as group user (cùng UPN bro vừa add):

```bash
# ✓ Allowed
az vm start -g rg-backup-lab -n vm-backup-lab
az vm deallocate -g rg-backup-lab -n vm-backup-lab

# ✗ Forbidden (không có quyền create)
az vm create -g rg-backup-lab -n vm-test --image Ubuntu2404 --admin-username u --generate-ssh-keys
# Expect: AuthorizationFailed

# ✗ Forbidden (không có quyền delete)
az vm delete -g rg-backup-lab -n vm-backup-lab --yes
# Expect: AuthorizationFailed
```

### Restore test (Step 4 — optional, ~30 min)

```bash
# List recovery points
az backup recoverypoint list \
  --vault-name $(terraform output -raw vault_name) \
  --resource-group rg-backup-lab \
  --container-name $(az vm show -g rg-backup-lab -n $(terraform output -raw vm_name) --query id -o tsv) \
  --item-name $(terraform output -raw vm_name) \
  --backup-management-type AzureIaasVM \
  -o table

# Easier: portal-based restore (Vault → Backup items → ... → Restore VM)
```

### Cleanup

```bash
terraform destroy
# Vault có soft-delete 14 ngày — provider config đã set soft_delete_enabled=false
# nhưng nếu bị stuck, manual: Portal → Vault → Soft-deleted items → Undelete → Stop backup → Delete
```

### PIM walkthrough (Entra ID P2 needed — manual portal)

Không tự động hoá được trong free tier. 3 bước nếu bro activate trial P2:

1. **Tạo eligible assignment**:
   - Portal → Entra ID → Roles → "User Administrator" → Add assignments
   - Type: **Eligible**, target: bro, duration: 1 year
2. **Activate khi cần**:
   - Portal → "My roles" → User Administrator → Activate
   - Lý do: "Lab testing PIM activation"
   - Duration: 1h
3. **Audit**:
   - Entra ID → Audit logs → filter activity = "Add member to role completed (PIM activation)"

### Conditional Access walkthrough (Entra ID P1)

1. Portal → Entra ID → Security → Named locations → New → "Trusted office"
   - Country: Vietnam (or specific IP range)
2. Conditional Access → New policy: `cap-require-mfa-untrusted`
   - Users: All users (exclude break-glass account!)
   - Cloud apps: All
   - Conditions → Locations → Exclude → "Trusted office"
   - Grant → Require MFA
   - **Report-only** trước khi enforce
3. Sign in từ mobile/coffee shop → trigger MFA prompt
4. Audit: Entra ID → Sign-in logs → filter "Conditional Access" column
