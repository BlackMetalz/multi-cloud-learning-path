# Phase 1

### Prepare
```bash
cd projects/01-fullstack-app/azure/terraform
cp terraform.tfvars.example terraform.tfvars
# Enter your sub scription id, which can be found in "Resource Manager | Subscriptions"
# Install az cli here (Ubuntu): https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux?view=azure-cli-latest&pivots=apt
az login --use-device-code

terraform init
az provider register --namespace Microsoft.Web --wait
az provider register --namespace Microsoft.Storage --wait
# Query to check
az provider show --namespace Microsoft.Web --query registrationState -o tsv
# For phase 3, need to register followings: Microsoft.DBforPostgreSQL, Microsoft.KeyVault, Microsoft.Insights (for monitor)
```

### Plan & Apply
```bash
# Expected: Registered
terraform plan -out=tfplan
# Verify tfplan
terraform show tfplan
# Apply it bro!
terraform apply tfplan
```

Expected output after apply:
```
azurerm_linux_web_app.main: Creating...
azurerm_linux_web_app.main: Still creating... [00m10s elapsed]
azurerm_linux_web_app.main: Still creating... [00m20s elapsed]
azurerm_linux_web_app.main: Still creating... [00m30s elapsed]
azurerm_linux_web_app.main: Still creating... [00m40s elapsed]
azurerm_linux_web_app.main: Still creating... [00m50s elapsed]
azurerm_linux_web_app.main: Creation complete after 54s [id=/subscriptions/your-subscription-id-here-bro/resourceGroups/rg-fullstack-app/providers/Microsoft.Web/sites/app-fullstack-app]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

app_url = "https://app-fullstack-app.azurewebsites.net"
```

### Verify
```bash
curl $(terraform output -raw app_url)
```

Example output
```
HTTP/1.1 200 OK
Content-Length: 896
Content-Type: text/html
Date: Sat, 25 Apr 2026 11:28:18 GMT
Server: nginx/1.29.8
Accept-Ranges: bytes
ETag: "69d4f411-380"
Last-Modified: Tue, 07 Apr 2026 12:09:53 GMT
```

# Phase 2 (Actually phase 3 xD)
### Phase 3 - Add Storage Account (need to do this earlier than phase 2)

New provider added. Need to upgrade
```
│ The following dependency selections recorded in the lock file are inconsistent with the current configuration:
│   - provider registry.terraform.io/hashicorp/random: required by this configuration but no version is selected
│ 
│ To update the locked dependency selections to match a changed configuration, run:
│   terraform init -upgrade
```

Plan it again and apply
```bash
terraform plan -out=tfplan
terraform apply "tfplan"
```

Expected output
```
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

app_url = "https://app-fullstack-app.azurewebsites.net"
static_url = "https://stfullstackappl5vqvo.z23.web.core.windows.net/"
storage_account_name = "stfullstackappl5vqvo"
```

### Upload index.html (storage account take from output)

Hmm, we need to create `Storage Blob Data Contributor` role first.
```bash
az role assignment create \
--assignee $(az ad signed-in-user show --query id -o tsv) \
--role "Storage Blob Data Contributor" \
--scope $(az storage account show -n $(terraform output -raw storage_account_name) --query id -o tsv)
```

If you not going to run that, you will not able to upload xD
```
You do not have the required permissions needed to perform this operation.
Depending on your operation, you may need to be assigned one of the following roles:
    "Storage Blob Data Owner"
    "Storage Blob Data Contributor"
    "Storage Blob Data Reader"
    "Storage Queue Data Contributor"
    "Storage Queue Data Reader"
    "Storage Table Data Contributor"
    "Storage Table Data Reader"
```

Run this from current terraform folder
```bash
az storage blob upload \
--account-name $(terraform output -raw storage_account_name) \
--container-name '$web' \ 
--name index.html \
--file ../../app/index.html \
--auth-mode login \
--overwrite
```

You may reliazed that '$web', it is special and predefined.

| Name | Purpose |
| -- | --|
| $web | Static web hosting|
| $logs| Storage analytics logs|
| $blobchangefeed| Blob change feed events|

Expected output
```json
Finished[#############################################################]  100.0000%
{
  "client_request_id": "client-request-id-here",
  "content_md5": "content_md5_here/Gofg==",
  "date": "2026-04-25T17:28:11+00:00",
  "encryption_key_sha256": null,
  "encryption_scope": null,
  "etag": "\"some-hex-xD\"",
  "lastModified": "2026-04-25T17:28:12+00:00",
  "request_id": "request_id_here",
  "request_server_encrypted": true,
  "structured_body": null,
  "version": "2026-02-06",
  "version_id": null
}
```

### Let's test

You can get by static url in scenario you forgot: `terraform output -raw static_url`.
Quick test: `curl -I $(terraform output -raw static_url)`

### Ok, it is not related to AZ-104 but it is needed
We need to create `remote backend`, because we did ignore terraform.tfstate already!
```bash
# We need a global unique name
SA_BACKEND="sttfstate$(openssl rand -hex 3)" # sttfstate139f04

# Create resource group named "rg-tfstate" in location southeastasia xD
# We need to create this manually, this is where we store remote tfstate, we will get fucked if we add this resourceGroup via terraform LOL
az group create -n rg-tfstate -l southeastasia

# Create storage account to contain Terraform StateState. This is step after we create resource Group above
az storage account create \
--name $SA_BACKEND \
--resource-group rg-tfstate \
--location southeastasia \
--sku Standard_LRS \
--allow-blob-public-access false \
--min-tls-version TLS1_2

# Create container "tfstate" inside storage account
# In case you don't know what the fuck is "container". It is fucking bucket in AWS/GCP
az storage container create \
--name tfstate \
--account-name $SA_BACKEND \
--auth-mode login
```

### Update remote backend in main.tf

```hcl
  # Remote backend
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstate139f04"   # ← thay bằng tên SA_BACKEND ở trên
    container_name       = "tfstate"
    key                  = "fullstack-app.tfstate"
  }
```

### Migrate state local --> Azure

```bash
terraform init -migrate-state
```

If will ask: "Do you want to copy existing state to the new backend?" → fucking yes

After that, your state will be saved as `fullstack-app.tfstate` in container(bucket) tfstate

### How does App Service access secrets without  storing credentials
Managed Identity + KV. Visible: `az keyvault secret show`


# Phase 3 - Key Vault

### Register new resource provider
```
az provider register --namespace Microsoft.KeyVault --wait
```

Apply it.
```bash
terraform init   # pull provider hashicorp/time
terraform plan -out=tfplan
terraform apply "tfplan"
```

Expected output:
```
Apply complete! Resources: 6 added, 1 changed, 0 destroyed.

Outputs:

app_url = "https://app-fullstack-app.azurewebsites.net"
key_vault_name = "kv-fullstackapp-l5vqvo"
static_url = "https://stfullstackappl5vqvo.z23.web.core.windows.net/"
storage_account_name = "stfullstackappl5vqvo"
webapp_name = "app-fullstack-app"
```

### Verify after create

Set variable
```bash
KV=$(terraform output -raw key_vault_name)
APP=$(terraform output -raw webapp_name)
RG="rg-fullstack-app"
```

- Show UAMI (user-assigned managed identity)
`az identity show -n id-fullstack-app -g $RG --query '{principalId:principalId, clientId:clientId}'`

- App Service phải đang dùng UAMI ("type": "UserAssigned) (không phải SystemAssigned)
`az webapp identity show -n $APP -g $RG`

### Summary
- We use service account (common) instead of hard code user/password.
- Rotate give no downtime and easy to rotate within 1 click.