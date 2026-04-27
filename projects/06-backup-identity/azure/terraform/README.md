### Pre-flight

```bash
# 1. SKU check (lesson learned từ project 02)
az vm list-skus -l southeastasia --size Standard_D2alds_v7 \
  --query "[?length(restrictions)==\`0\`].name" -o tsv

# 2. UPN của bro để add vào group
az ad signed-in-user show --query userPrincipalName -o tsv
# Copy output này vào operator_group_members trong tfvars
```

### Tutorial

```bash
cd projects/06-backup-identity/azure/terraform
az login --use-device-code
cp terraform.tfvars.example terraform.tfvars
# edit: subscription_id + operator_group_members (UPN của bro)

terraform init
terraform plan -out=tfplan
# Plan: 13 to add, 0 to change, 0 to destroy.
terraform apply "tfplan"
# 
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



### Verify

1. VM running
```bash
# 
az vm list -g rg-backup-lab -o table
```

Expected output:
```
Name           ResourceGroup    Location
-------------  ---------------  -------------
vm-backup-lab  rg-backup-lab    southeastasia
```


2. Vault có protected item
```bash
az backup item list \
  --vault-name $(terraform output -raw vault_name) \
  --resource-group rg-backup-lab \
  --backup-management-type AzureIaasVM \
  -o table
# Status sẽ là "IRPending" cho đến khi backup đầu tiên xong
```

Expected output:
```
# Before
Name                                              Friendly Name    Container name                                 Resource Group    Type    Last Backup Status    Protection Status    Health Status
------------------------------------------------  ---------------  ---------------------------------------------  ----------------  ------  --------------------  -------------------  ---------------
VM;iaasvmcontainerv2;rg-backup-lab;vm-backup-lab  vm-backup-lab    iaasvmcontainerv2;rg-backup-lab;vm-backup-lab  rg-backup-lab     VM                            Healthy              Passed
# After
Name                                              Friendly Name    Container name                                 Resource Group    Type    Last Backup Status    Last Recovery Point               Protection Status    Health Status    Recommendations
------------------------------------------------  ---------------  ---------------------------------------------  ----------------  ------  --------------------  --------------------------------  -------------------  ---------------  -----------------
VM;iaasvmcontainerv2;rg-backup-lab;vm-backup-lab  vm-backup-lab    iaasvmcontainerv2;rg-backup-lab;vm-backup-lab  rg-backup-lab     VM      Completed             2026-04-27T15:08:58.207564+00:00  Healthy              Passed
```

3. Group có member
```bash
az ad group member list -g $(terraform output -raw operator_group_name) -o table
```

Expected output:
```

@odata.type            DisplayName    GivenName    PreferredLanguage    Surname    UserPrincipalName
---------------------  -------------  -----------  -------------------  ---------  ----------------------------------------------------------------
#microsoft.graph.user  Lương Kiên     Lương        en                   Kiên       my-email#EXT#@my-email.onmicrosoft.com
```

4. Custom role tồn tại
```bash
az role definition list --custom-role-only --query "[?contains(roleName, 'VM Operator')]" -o table
```

5. Role assignment hợp lệ
```bash
az role assignment list \
  --assignee $(terraform output -raw operator_group_id) \
  --scope /subscriptions/$(az account show --query id -o tsv)/resourceGroups/rg-backup-lab \
  -o table
```

### Verify custom role + assignment (Step 3)

> Bro đang là **Owner subscription** → RBAC hợp nhất → Owner override mọi custom role. Tự test bằng tài khoản chính sẽ KHÔNG thấy denial. Test denial thật cần Service Principal hoặc user phụ — phức tạp, skip cho lab này. Chỉ verify role + assignment tồn tại đúng là đủ cho exam objective.

```bash
# 1. Custom role tồn tại với đúng actions
az role definition list --custom-role-only \
  --query "[?contains(roleName, 'VM Operator')].{name:roleName, actions:permissions[0].actions}" \
  -o jsonc
# Expect: actions list bao gồm start/restart/powerOff/deallocate/read,
# KHÔNG có 'Microsoft.Compute/virtualMachines/write' hoặc '/delete'

# 2. Group có role assignment
az role assignment list \
  --assignee $(terraform output -raw operator_group_id) \
  --scope /subscriptions/$(az account show --query id -o tsv)/resourceGroups/rg-backup-lab \
  --query "[].{role:roleDefinitionName, principal:principalName, scope:scope}" \
  -o table

# 3. Group có member (UPN bro)
az ad group member list \
  -g $(terraform output -raw operator_group_name) \
  --query "[].userPrincipalName" -o tsv
```

3 cái xác nhận RBAC chain hoàn chỉnh: **custom role → group assignment → user member**. AZ-104 hỏi nguyên cái chain này, không hỏi denial test.

> Muốn xem denial thật: tạo Service Principal scoped chỉ vào role này (`az ad sp create-for-rbac --role "VM Operator (backup-lab)" --scopes <rg>`), login bằng SP với `--allow-no-subscriptions` flag, rồi run các az command. Phức tạp ở chỗ SP không có quyền list subscription nên `az login` thường behave lạ. Skip an toàn.

### Restore test (Step 4 — optional, ~30 min)

- List recovery points:
```bash
# Heads-up: --container-name là FRIENDLY NAME (chỉ tên VM), không phải full ARM resource ID.
VAULT=$(terraform output -raw vault_name)
VM=$(terraform output -raw vm_name)

az backup recoverypoint list \
  --vault-name $VAULT \
  --resource-group rg-backup-lab \
  --container-name $VM \
  --item-name $VM \
  --backup-management-type AzureIaasVM \
  -o table
```

Expected output
```
Name                 Time                              Consistency
-------------------  --------------------------------  --------------------
2252108548792055062  2026-04-27T15:08:58.207564+00:00  FileSystemConsistent
```

- Nếu empty → check backup đã chạy chưa:
```bash
az backup item list \
  --vault-name $VAULT \
  --resource-group rg-backup-lab \
  --backup-management-type AzureIaasVM \
  --query "[].{vm:properties.friendlyName, lastBackup:properties.lastBackupTime, status:properties.lastBackupStatus}" \
  -o table

# lastBackupTime null → chưa có backup → trigger backup-now (ở verify step trước),
# rồi đợi 30-60 phút cho full snapshot đầu tiên xong.
```

#### Disaster simulation: xoá VM + restore

```bash
# 1. Note recovery point ID hiện có (sẽ dùng để restore)
RP_ID=$(az backup recoverypoint list \
  --vault-name $VAULT --resource-group rg-backup-lab \
  --container-name $VM --item-name $VM \
  --backup-management-type AzureIaasVM \
  --query "[0].name" -o tsv)
echo "Recovery point to restore from: $RP_ID"

# 2. Xoá VM (protection vẫn giữ trong vault — backup data còn nguyên)
az vm delete -g rg-backup-lab -n $VM --yes

# 3. (Optional) xoá luôn OS disk để full disaster
DISK_ID=$(az disk list -g rg-backup-lab \
  --query "[?contains(name, '$VM')].id" -o tsv)
[ -n "$DISK_ID" ] && az disk delete --ids $DISK_ID --yes

# 4. Verify VM gone
az vm show -g rg-backup-lab -n $VM 2>&1 | grep -i "not found" && echo "VM deleted ✓"

# 5. Verify recovery point STILL accessible
az backup recoverypoint list \
  --vault-name $VAULT --resource-group rg-backup-lab \
  --container-name $VM --item-name $VM \
  --backup-management-type AzureIaasVM -o table

# Recovery point vẫn còn nguyên ✓
```

#### Restore via Portal (recommend, ~5 phút)

CLI restore phức tạp (`az backup restore restore-disks` → tạo lại VM từ disk → wire NIC). Portal đơn giản hơn nhiều:

1. **Portal** → `rsv-backup-lab-xxx` (vault) → **Backup items** → **Azure Virtual Machine** → click `vm-backup-lab`
2. Click **Restore VM** trên top
3. Chọn recovery point (cái có trong `$RP_ID`)
4. **Restore type**: chọn 1 trong 3:
   - **Create new** → tạo VM mới với tên khác (an toàn nhất)
   - **Replace existing** → ghi đè lên VM cũ (cần VM tồn tại)
   - **Restore disks** → chỉ tạo disks, attach manually
5. Resource group: `rg-backup-lab`. Tên VM mới: `vm-backup-lab-restored`
6. Storage account staging: tạo mới hoặc dùng có sẵn
7. **Restore** → đợi ~10-15 phút (job chạy background)

Track progress:
```bash
az backup job list -v $VAULT -g rg-backup-lab \
  --query "[].{operation:properties.operation, status:properties.status, target:properties.entityFriendlyName, start:properties.startTime}" \
  -o table | head -5
```

Expected output:
```
Operation        Status      Target         Start
---------------  ----------  -------------  --------------------------------
Restore          InProgress  vm-backup-lab  2026-04-27T17:19:23.879160+00:00
Backup           Completed   vm-backup-lab  2026-04-27T15:08:49.701154+00:00
ConfigureBackup  Completed   vm-backup-lab  2026-04-27T11:46:01.960140+00:00
# After 5 minutes.
Operation        Status     Target         Start
---------------  ---------  -------------  --------------------------------
Restore          Completed  vm-backup-lab  2026-04-27T17:19:23.879160+00:00
Backup           Completed  vm-backup-lab  2026-04-27T15:08:49.701154+00:00
ConfigureBackup  Completed  vm-backup-lab  2026-04-27T11:46:01.960140+00:00
```

Khi `Status = Completed`:
```bash
# Verify VM mới boot OK
az vm list -g rg-backup-lab -o table
# Có vm-backup-lab-restored với PowerState = VM running
Name         ResourceGroup    Location
-----------  ---------------  -------------
vm-backup-lab-restored  rg-backup-lab    southeastasia
```

> **Warning về Terraform state**: bro vừa xoá VM ngoài Terraform (qua CLI/portal). State còn trỏ tới VM cũ → `terraform plan` sẽ thấy "missing resource, will recreate". Nếu muốn cleanup an toàn:
> ```bash
> terraform state rm azurerm_linux_virtual_machine.main azurerm_network_interface.vm tls_private_key.vm
> # Sau đó terraform destroy chỉ destroy phần còn lại (vault, network, identity)
> ```
> Hoặc skip — `terraform destroy` cuối project sẽ tự handle missing resources với warning.

### Cleanup

#### Happy path (không làm disaster sim ở Step 4)

```bash
terraform destroy
# Provider features đã set purge_protected_items_from_vault_on_destroy = true
# → destroy sẽ stop protection, purge backup data, rồi xoá vault.
```

#### Sau disaster sim (đã xoá VM thủ công ở Step 4) — cần manual cleanup

`terraform destroy` sẽ fail vì 3 thứ orphan ngoài state TF. Tốt nhất là vào xoá thủ công resource group ở trên portal / qua CLI. Kiểu gì cũng còn 1 resource `Recovery Services vault`. Không xoá được do đã enable soft-delete.

1. Custom role + role assignments (subscription scope)
```bash
ROLE_NAME=$(az role definition list --custom-role-only \
  --query "[?contains(roleName, 'VM Operator')].name" -o tsv)

if [ -n "$ROLE_NAME" ]; then
  az role assignment list --role $ROLE_NAME --query "[].id" -o tsv \
    | xargs -I{} az role assignment delete --ids {}
  az role definition delete --name "$ROLE_NAME"
fi
```

2. Entra ID group (tenant scope)
```bash
az ad group delete --group g-vm-operators
```

> **Lesson cho lab có disaster sim**: luôn cleanup theo layer order — Backup protection → Compute (VM/NIC/Disk) → Network (subnet/VNet) → Identity (role assignments → definitions) → RG. `terraform destroy` lo phần TF biết, phần đụng tay ngoài phải clean tay.

### PIM + Conditional Access — SKIP cho AZ-104

> **Không cần cho AZ-104.** Cả 2 thuộc về **AZ-500 (Azure Security Engineer)** và SC-300 (Identity Administrator). AZ-104 chỉ hỏi đến RBAC + custom roles + group assignment, đã verify ở Step 3.
>
> Lý do skip:
> - Cần Entra ID P1 (CA) hoặc P2 (PIM) license — không có trong free trial subscription
> - Hands-on giá trị thấp cho AZ-104 exam scope
> - Để dành học khi prep AZ-500 sau

Concept ngắn để bro có context (đủ trả lời câu multiple-choice nếu xuất hiện):

| Feature | Mục đích | Tier required |
|---|---|---|
| **PIM** (Privileged Identity Management) | Just-in-Time elevation: user là *eligible* cho role, phải activate khi cần (kèm MFA, justification, time-bound 1-8h) | Entra ID **P2** |
| **Conditional Access** | Sign-in policy: "if user X from location Y on device Z → require MFA / block / require compliant device" | Entra ID **P1** |
| **Identity Protection** | Risk-based: Microsoft phát hiện sign-in bất thường → tự động force MFA / password reset | Entra ID **P2** |

Khi prep AZ-500: bro có thể activate Entra ID P2 trial 30 ngày + thực hành. Lúc đó quay lại lab này cũng được.
