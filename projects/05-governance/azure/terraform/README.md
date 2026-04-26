### Tutorial

```bash
cd projects/05-governance/azure/terraform
az login --use-device-code
cp terraform.tfvars.example terraform.tfvars
# edit: subscription_id + alert_email

terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### File layout

```
azure/terraform/
├── providers.tf              # azurerm 4.x, key=governance.tfstate
├── variables.tf              # subscription, alert_email, allowed_locations, budget
├── locals.tf, main.tf        # tags + RG (chứa action group)
├── management_groups.tf      # mg-root → mg-prod, mg-nonprod (sub gán mg-nonprod)
├── policies.tf               # 2 built-in + 1 custom + initiative + assignment
├── budget.tf                 # subscription budget 50/90/100% thresholds
├── alerts.tf                 # action group + 2 activity log alerts
├── outputs.tf
├── terraform.tfvars.example
└── terraform.tfvars          # gitignored
```

### Pre-flight: permission to create Management Groups

```bash
# Check current user có quyền tạo MG không
az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv) \
  --scope "/" -o table 2>/dev/null
# Nếu trống → cần "Elevate access"
```

Nếu apply fail với `AuthorizationFailed` ở MG creation:
1. Portal → Microsoft Entra ID → Properties → **"Access management for Azure resources"** → Yes (gán tạm User Access Admin ở root scope cho bro)
2. Retry `terraform apply`
3. Tắt lại sau khi xong (Yes → No) để giảm blast radius

### Verify each piece

```bash
# 1. Management Groups
az account management-group list -o table

# 2. Policy assignment ở mg-nonprod
az policy assignment list --scope $(terraform output -raw mg_nonprod_id) -o table

# 3. Test policy compliance — thử tạo RG ở region không allowed
az group create -n rg-test-policy -l westus 2>&1 | grep -i "disallowed"
# Expect: RequestDisallowedByPolicy ✓

# 4. Test policy — thử tạo RG ở allowed region nhưng không có tag Environment
az group create -n rg-test-tag -l southeastasia 2>&1 | grep -i "disallowed"
# Expect: RequestDisallowedByPolicy ✓

# 5. Tạo RG hợp lệ → OK
az group create -n rg-test-ok -l southeastasia --tags Project=fullstack-app Environment=dev
# Cleanup
az group delete -n rg-test-ok --yes --no-wait
```

### Trigger alert manually (Step 3 dopamine)

```bash
# Xoá assignment → activity log alert fire trong ~5 phút
az policy assignment delete --name baseline-nonprod \
  --scope $(terraform output -raw mg_nonprod_id)

# Email arrived? Re-create:
terraform apply
```

### Cleanup

```bash
terraform destroy
```

> **Note**: Sub gán cho mg-nonprod sẽ rớt về Tenant Root khi mg-nonprod bị xoá. Không có hậu quả về billing, chỉ là hierarchy reset.
