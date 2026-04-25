# Steps

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