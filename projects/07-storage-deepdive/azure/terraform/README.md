### Tutorial

```bash
cd projects/07-storage-deepdive/azure/terraform
az login --use-device-code
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
```

### File layout

```
azure/terraform/
├── providers.tf            # azurerm 4.x, key=storage-deepdive.tfstate
├── variables.tf, locals.tf
├── main.tf                 # RG + suffix
├── storage.tf              # SA với versioning + soft delete + role assign
├── containers.tf           # 3 containers (private, blob, compliance)
├── lifecycle.tf            # 2 rules: logs/ tier-down, public/ keep hot
├── sas.tf                  # Read-only SAS data source cho container logs
├── outputs.tf
└── terraform.tfvars.example
```

### Verify

```bash
SA=$(terraform output -raw storage_account_name)

# 1. Versioning + soft delete
az storage account blob-service-properties show \
  --account-name $SA --query "{ver:isVersioningEnabled, sd:deleteRetentionPolicy.enabled, csd:containerDeleteRetentionPolicy.enabled}" -o jsonc
# Expect: {"ver": true, "sd": true, "csd": true}

# 2. Lifecycle policy
az storage account management-policy show --account-name $SA -g rg-storage-lab --query policy.rules -o jsonc

# 3. SAS URL works
curl "$(terraform output -raw logs_sas_url)&restype=container&comp=list" | head -c 400
```

### Step 2 — Soft delete recovery

```bash
# Upload + delete + recover
echo "hello v1" > /tmp/file.txt
az storage blob upload \
  --account-name $SA \
  --container-name logs \
  --name test/file.txt \
  --file /tmp/file.txt \
  --auth-mode login

az storage blob delete \
  --account-name $SA \
  --container-name logs \
  --name test/file.txt \
  --auth-mode login

# List including deleted
az storage blob list \
  --account-name $SA \
  --container-name logs \
  --include d \
  --auth-mode login \
  --query "[].{name:name, deleted:deleted}" -o table

# Undelete
az storage blob undelete \
  --account-name $SA \
  --container-name logs \
  --name test/file.txt \
  --auth-mode login
```

### Step 3 — Versioning

```bash
# Upload v1
echo "version 1" > /tmp/v.txt
az storage blob upload --account-name $SA -c logs -n test/v.txt -f /tmp/v.txt --auth-mode login --overwrite

# Upload v2 (same name)
echo "version 2" > /tmp/v.txt
az storage blob upload --account-name $SA -c logs -n test/v.txt -f /tmp/v.txt --auth-mode login --overwrite

# List all versions
az storage blob list --account-name $SA -c logs --include v --auth-mode login \
  --prefix test/v.txt --query "[].{name:name, ver:versionId, current:isCurrentVersion}" -o table
```

### Step 4 — Test SAS

```bash
SAS_URL=$(terraform output -raw logs_sas_url)

# ✓ List should work
curl "${SAS_URL}&restype=container&comp=list" | head -c 400

# ✗ Write should fail (403)
curl -X PUT "${SAS_URL%\?*}/test-write.txt?${SAS_URL#*\?}" \
  -H "x-ms-blob-type: BlockBlob" \
  -d "should fail" -v 2>&1 | grep "HTTP/"
# Expect: 403 (read-only token)
```

### Step 6 — Immutability (portal)

> Cảnh báo: nếu chọn **Locked**, policy không bao giờ có thể giảm thời gian — container không thể xoá đến hết retention. Test nên dùng **Unlocked** với 1 day retention.

1. Portal → Storage account → Containers → `compliance` → ... → **Access policy**
2. **+ Add policy** → Type: **Time-based retention** → Days: 1 → Save (state: **Unlocked**)
3. Upload 1 file vào container
4. Try delete blob → ✗ blocked với error "Blob has immutability policy"
5. Đợi 1 ngày sau → blob sẽ delete được

### Step 7 — AzCopy

```bash
# Install on macOS
brew install azcopy

# Login với Entra ID
azcopy login

# Sync local dir → blob (resumable, parallelized)
mkdir -p /tmp/many-files && for i in {1..50}; do
  echo "file $i" > /tmp/many-files/file-$i.txt
done

azcopy sync /tmp/many-files \
  "https://$SA.blob.core.windows.net/logs/many-files" \
  --recursive

# So sánh: az CLI batch upload (chậm hơn nhiều file nhỏ)
time az storage blob upload-batch \
  --account-name $SA \
  --destination logs/batch-test \
  --source /tmp/many-files \
  --auth-mode login
```

### Cleanup

```bash
terraform destroy
# Nếu container `compliance` có locked immutability → unlock manually trước
```
