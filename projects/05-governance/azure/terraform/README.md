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

Expected output:
```
Apply complete! Resources: 11 added, 0 changed, 0 destroyed.
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

Default tenant config cho phép **mọi AAD user** tạo MG (creator auto-Owner trên MG vừa tạo). Thường không cần check gì, cứ `apply` thử.

Nếu muốn check explicit:
```bash
TENANT_ID=$(az account show --query tenantId -o tsv)
az rest --method GET \
  --url "https://management.azure.com/providers/Microsoft.Management/managementGroups/$TENANT_ID/settings/default?api-version=2020-02-01"
# 3 outcomes:
#   404 ResourceNotFound  → settings chưa custom = default open ✓ (mặc định mọi tenant)
#   ... requireAuthorizationForGroupCreation: false → open ✓
#   ... requireAuthorizationForGroupCreation: true  → cần elevate access
```

> **Note**: `az role assignment list --scope "/"` trả về **trống là bình thường** — root scope rất hiếm khi có role assignment trực tiếp. Empty không có nghĩa là không tạo được MG.

Nếu apply fail với `AuthorizationFailed` ở MG creation:
1. Portal → Microsoft Entra ID → Properties → **"Access management for Azure resources"** → Yes (gán tạm User Access Admin ở root scope cho bro)
2. Retry `terraform apply`
3. Tắt lại sau khi xong (Yes → No) để giảm blast radius

### Verify each piece

1. Management Groups
```bash
az account management-group list -o table
```

Expected output:
```

DisplayName    Name        TenantId
-------------  ----------  ------------------------------------
mg-nonprod     mg-nonprod  tenant-id-here-bro
mg-prod        mg-prod     tenant-id-here-bro
mg-root        mg-root     tenant-id-here-bro
```

2. Policy assignment ở mg-nonprod
```bash
az policy assignment list --scope $(terraform output -raw mg_nonprod_id) -o table
```

Expected output:
```

DefinitionVersion    DisplayName                    EnforcementMode    Name              PolicyDefinitionId                                                                                                                   Scope
-------------------  -----------------------------  -----------------  ----------------  -----------------------------------------------------------------------------------------------------------------------------------  -----------------------------------------------------------
1.*.*                Baseline Governance — nonprod  Default            baseline-nonprod  /providers/Microsoft.Management/managementGroups/mg-root/providers/Microsoft.Authorization/policySetDefinitions/baseline-governance  /providers/Microsoft.Management/managementGroups/mg-nonprod
```


3. Test policy compliance — thử tạo RG ở region không allowed
```bash
az group create -n rg-test-policy -l westus 2>&1 | grep -i "disallowed"
# Expect: RequestDisallowedByPolicy ✓
```

4. Test policy — thử tạo RG ở allowed region nhưng không có tag Environment
```bash
az group create -n rg-test-tag -l southeastasia 2>&1 | grep -i "disallowed"
# Expect: RequestDisallowedByPolicy ✓
```

5. Tạo RG hợp lệ → OK
```bash
az group create -n rg-test-ok -l southeastasia --tags Project=fullstack-app Environment=dev
az group list|grep rg-test-ok

```
Expected output:
```json
# Create
{
  "id": "/subscriptions/sub-id/resourceGroups/rg-test-ok",
  "location": "southeastasia",
  "managedBy": null,
  "name": "rg-test-ok",
  "properties": {
    "provisioningState": "Succeeded"
  },
  "tags": {
    "Environment": "dev",
    "Project": "fullstack-app"
  },
  "type": "Microsoft.Resources/resourceGroups"
}
# List
    "id": "/subscriptions/sub-id/resourceGroups/rg-test-ok",
    "name": "rg-test-ok",
```

6. Cleanup
```bash
az group delete -n rg-test-ok --yes --no-wait
```

### Trigger alert manually (Step 3 dopamine)

> **Heads-up về scope**: `azurerm_monitor_activity_log_alert` chỉ listen ở subscription scope. Operations ở **MG scope** (như delete policy assignment ở mg-nonprod) **không bubble xuống** subscription log → alert sẽ không fire. Test bằng operation ở **subscription scope**:

```bash
SUB_ID=$(az account show --query id -o tsv)
MY_OID=$(az ad signed-in-user show --query id -o tsv)

# Create role assignment ở sub scope → activity log → role_assignment alert
az role assignment create \
  --role Reader \
  --assignee-object-id $MY_OID \
  --assignee-principal-type User \
  --scope /subscriptions/$SUB_ID

# Đợi 5-10 phút, check inbox + spam

# Cleanup
az role assignment delete \
  --assignee $MY_OID \
  --role Reader \
  --scope /subscriptions/$SUB_ID
```

Hoặc test direct action group (skip alert rule entirely):
```bash
# Portal → Monitor → Alerts → Action groups → ag-governance → "Test action group"
# Hoặc CLI (KHÔNG work trên free / credit subscription):
az monitor action-group test-notifications create \
  --action-group ag-governance \
  --resource-group rg-governance \
  -a email primary-email "$YOUR_EMAIL" true \
  --alert-type budget
# Free sub trả lỗi: "(Conflict) Free subscription not supported"
# Real activity log alerts vẫn work bình thường — restriction chỉ đánh API test-notifications.
```

> **Latency expected**: từ lúc trigger tới email tới ~5-10 phút.
> - Event → Activity log indexed: 1-3 phút
> - Alert engine evaluate: 1-2 phút
> - Action group → email gửi: 30s-1 phút
> - Email tới + spam filter: tuỳ provider

### Cleanup

```bash
terraform destroy
```

> **Note**: Sub gán cho mg-nonprod sẽ rớt về Tenant Root khi mg-nonprod bị xoá. Không có hậu quả về billing, chỉ là hierarchy reset.
