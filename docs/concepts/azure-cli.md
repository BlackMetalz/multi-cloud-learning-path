# Azure CLI — Learn the Pattern, Not the Commands

## The Mental Model

Azure CLI follows one consistent pattern:

```
az <resource> <action> --<parameters>
```

Once you see this, you can guess almost any command.

## The Pattern

```
az group   create   --name mygroup --location eastasia
az vm      create   --name myvm    --resource-group mygroup
az webapp  create   --name myapp   --resource-group mygroup
│          │        │
│          │        └── Parameters (what you want to configure)
│          └── Action (what you want to do)
└── Resource (what you're working with)
```

**Actions are reusable across resources:**

| Action | Meaning |
|---|---|
| `create` | Create a new resource |
| `delete` | Delete a resource |
| `list` | List all resources |
| `show` | Show details of one resource |
| `update` | Update an existing resource |
| `start` / `stop` / `restart` | Control running state |

So if you know `az vm create`, you already know the shape of `az webapp create`, `az postgres server create`, etc.

## Cheat Sheet by Category

### 0. Account & Auth

```bash
# Login
az login                                    # Browser login
az login --use-device-code                  # Device code (for SSH/remote)

# Account
az account show                             # Current subscription
az account list --output table              # All subscriptions
az account set --subscription "my-sub"      # Switch subscription
```

### 1. Resource Group — the container for everything

```bash
az group create --name rg-myapp --location southeastasia
az group list --output table
az group delete --name rg-myapp --yes       # Delete group + ALL resources inside
```

> **Key insight**: Delete the resource group = delete everything in it. Useful for learning — spin up, experiment, delete group, pay nothing.

### 2. Virtual Machine

```bash
# Create
az vm create \
  --resource-group rg-myapp \
  --name my-vm \
  --image Ubuntu2204 \
  --size Standard_B1s \
  --admin-username azureuser \
  --generate-ssh-keys

# Manage
az vm list --resource-group rg-myapp --output table
az vm show --resource-group rg-myapp --name my-vm
az vm start --resource-group rg-myapp --name my-vm
az vm stop --resource-group rg-myapp --name my-vm
az vm delete --resource-group rg-myapp --name my-vm --yes

# SSH
az vm open-port --resource-group rg-myapp --name my-vm --port 80
ssh azureuser@<public-ip>
```

### 3. App Service (Web App)

```bash
# Create plan + app
az appservice plan create \
  --resource-group rg-myapp \
  --name plan-myapp \
  --sku F1 --is-linux

az webapp create \
  --resource-group rg-myapp \
  --plan plan-myapp \
  --name my-webapp \
  --runtime "NODE:20-lts"

# Deploy from Docker
az webapp create \
  --resource-group rg-myapp \
  --plan plan-myapp \
  --name my-webapp \
  --deployment-container-image-name nginx:alpine

# Manage
az webapp list --resource-group rg-myapp --output table
az webapp show --resource-group rg-myapp --name my-webapp
az webapp restart --resource-group rg-myapp --name my-webapp
az webapp log tail --resource-group rg-myapp --name my-webapp

# Config
az webapp config appsettings set \
  --resource-group rg-myapp \
  --name my-webapp \
  --settings DB_HOST=mydb.postgres.database.azure.com
```

### 4. Storage

```bash
# Create account
az storage account create \
  --resource-group rg-myapp \
  --name mystorageaccount \
  --sku Standard_LRS

# Create container (like a folder/bucket)
az storage container create \
  --account-name mystorageaccount \
  --name uploads

# Upload / Download
az storage blob upload \
  --account-name mystorageaccount \
  --container-name uploads \
  --file ./myfile.txt \
  --name myfile.txt

az storage blob list --account-name mystorageaccount --container-name uploads --output table
az storage blob download --account-name mystorageaccount --container-name uploads --name myfile.txt --file ./downloaded.txt
```

### 5. Database (PostgreSQL)

```bash
# Create server
az postgres flexible-server create \
  --resource-group rg-myapp \
  --name my-postgres \
  --location southeastasia \
  --admin-user myadmin \
  --admin-password 'SecureP@ss123' \
  --sku-name Standard_B1ms \
  --tier Burstable

# Firewall — allow your IP
az postgres flexible-server firewall-rule create \
  --resource-group rg-myapp \
  --name my-postgres \
  --rule-name allow-myip \
  --start-ip-address <your-ip> \
  --end-ip-address <your-ip>

# Create database
az postgres flexible-server db create \
  --resource-group rg-myapp \
  --server-name my-postgres \
  --database-name mydb

# Connect
psql "host=my-postgres.postgres.database.azure.com dbname=mydb user=myadmin"
```

### 6. Key Vault (Secrets)

```bash
# Create vault
az keyvault create \
  --resource-group rg-myapp \
  --name my-keyvault

# Secrets
az keyvault secret set --vault-name my-keyvault --name db-password --value 'SecureP@ss123'
az keyvault secret show --vault-name my-keyvault --name db-password
az keyvault secret list --vault-name my-keyvault --output table
```

### 7. Networking

```bash
# VNet + Subnet
az network vnet create \
  --resource-group rg-myapp \
  --name my-vnet \
  --address-prefix 10.0.0.0/16 \
  --subnet-name default \
  --subnet-prefix 10.0.1.0/24

# NSG (Network Security Group) — like a firewall
az network nsg create --resource-group rg-myapp --name my-nsg
az network nsg rule create \
  --resource-group rg-myapp \
  --nsg-name my-nsg \
  --name allow-http \
  --priority 100 \
  --destination-port-ranges 80 443 \
  --access Allow \
  --protocol Tcp
```

### 8. Monitor & Logs

```bash
# Activity log
az monitor activity-log list --resource-group rg-myapp --output table

# Metrics
az monitor metrics list \
  --resource <resource-id> \
  --metric "Percentage CPU" \
  --output table

# Alerts
az monitor metrics alert create \
  --resource-group rg-myapp \
  --name high-cpu \
  --scopes <resource-id> \
  --condition "avg Percentage CPU > 80" \
  --description "CPU over 80%"
```

## Azure CLI vs PowerShell — AZ-104 / AZ-400 Exam

Both appear in exams. Same operations, different syntax:

| Task | Azure CLI (`az`) | PowerShell (`Az` module) |
|---|---|---|
| Login | `az login` | `Connect-AzAccount` |
| Create RG | `az group create --name rg --location eastasia` | `New-AzResourceGroup -Name rg -Location eastasia` |
| List RGs | `az group list` | `Get-AzResourceGroup` |
| Delete RG | `az group delete --name rg` | `Remove-AzResourceGroup -Name rg` |
| Create VM | `az vm create --name vm ...` | `New-AzVM -Name vm ...` |
| List VMs | `az vm list` | `Get-AzVM` |
| Start VM | `az vm start --name vm ...` | `Start-AzVM -Name vm ...` |
| Stop VM | `az vm stop --name vm ...` | `Stop-AzVM -Name vm ...` |
| Create Web App | `az webapp create --name app ...` | `New-AzWebApp -Name app ...` |
| Create Storage | `az storage account create ...` | `New-AzStorageAccount ...` |
| Get Secret | `az keyvault secret show ...` | `Get-AzKeyVaultSecret ...` |
| Create VNet | `az network vnet create ...` | `New-AzVirtualNetwork ...` |
| Create NSG Rule | `az network nsg rule create ...` | `Add-AzNetworkSecurityRuleConfig ...` |

**PowerShell pattern:**

```
Verb-AzResource -ParameterName value
```

| Verb | Meaning | CLI equivalent |
|---|---|---|
| `New-` | Create | `create` |
| `Get-` | Read / List | `show` / `list` |
| `Set-` | Update | `update` |
| `Remove-` | Delete | `delete` |
| `Start-` / `Stop-` | Control state | `start` / `stop` |

**Exam tip:** You don't need to memorize every command. The exam tests whether you can **read and understand** the commands. If you see `New-AzResourceGroup`, you know it creates a resource group. If you see `Get-AzVM`, you know it lists/gets VMs.

## Tips

1. **`--output table`** — mọi `list` command thêm flag này để dễ đọc
2. **`az interactive`** — chế độ autocomplete, gợi ý command khi gõ
3. **`az find "keyword"`** — tìm command theo keyword khi không nhớ
4. **`--query`** — filter output bằng JMESPath: `az vm list --query "[].{Name:name, State:powerState}"`
5. **Resource Group = sandbox** — tạo 1 group riêng để thử, xong `az group delete` là sạch
