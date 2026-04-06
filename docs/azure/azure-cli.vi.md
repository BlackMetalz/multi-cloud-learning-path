# Azure CLI — Học Pattern, Không Cần Nhớ Từng Command

## Cài đặt

### macOS

```bash
# Homebrew (khuyên dùng)
brew install azure-cli

# Kiểm tra
az version
```

### Ubuntu / Debian

```bash
# Script cài đặt từ Microsoft
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Kiểm tra
az version
```

### Tab Autocomplete

```bash
# Zsh — thêm vào ~/.zshrc
autoload -U +X bashcompinit && bashcompinit
source /opt/homebrew/etc/bash_completion.d/az    # macOS (Homebrew)
source /etc/bash_completion.d/azure-cli           # Ubuntu

# Bash — thêm vào ~/.bashrc
source /opt/homebrew/etc/bash_completion.d/az    # macOS (Homebrew)
source /etc/bash_completion.d/azure-cli           # Ubuntu
```

Restart shell hoặc `source ~/.zshrc`, sau đó:

```
az vm <TAB><TAB>     → create  delete  list  show  start  stop  restart ...
az vm create --<TAB> → --name  --resource-group  --image  --size ...
```
```

## Login & Thiết lập môi trường

```bash
# Đăng nhập qua browser
az login

# Đăng nhập bằng device code (SSH / remote / không có browser)
az login --use-device-code

# Đăng nhập bằng service principal (CI/CD)
az login --service-principal -u <app-id> -p <password> --tenant <tenant-id>
```

```bash
# Xem đang đăng nhập tài khoản nào
az account show

# Liệt kê tất cả subscriptions
az account list --output table

# Chuyển subscription
az account set --subscription "my-subscription-name-or-id"
```

```bash
# Set default resource group & location (khỏi lặp lại mỗi command)
az configure --defaults group=rg-myapp location=southeastasia

# Giờ 2 dòng này tương đương:
az vm create --resource-group rg-myapp --location southeastasia --name my-vm ...
az vm create --name my-vm ...   # dùng defaults

# Xem defaults hiện tại
az configure --list-defaults

# Xoá defaults
az configure --defaults group="" location=""
```

```bash
# Environment variables (cách khác thay cho az configure)
export AZURE_DEFAULTS_GROUP=rg-myapp
export AZURE_DEFAULTS_LOCATION=southeastasia
```

## Mental Model

Azure CLI tuân theo 1 pattern duy nhất:

```
az <resource> <action> --<parameters>
```

Hiểu pattern này, bạn đoán được gần như mọi command.

## Pattern

```
az group   create   --name mygroup --location eastasia
az vm      create   --name myvm    --resource-group mygroup
az webapp  create   --name myapp   --resource-group mygroup
│          │        │
│          │        └── Parameters (cấu hình gì)
│          └── Action (muốn làm gì)
└── Resource (làm việc với cái gì)
```

**Actions dùng lại được cho mọi resource:**

| Action | Ý nghĩa |
|---|---|
| `create` | Tạo mới resource |
| `delete` | Xoá resource |
| `list` | Liệt kê tất cả resources |
| `show` | Xem chi tiết 1 resource |
| `update` | Cập nhật resource |
| `start` / `stop` / `restart` | Điều khiển trạng thái chạy |

Biết `az vm create` thì tự suy ra được `az webapp create`, `az postgres server create`...

## Cheat Sheet theo Category

### 0. Account & Auth

```bash
# Đăng nhập
az login                                    # Đăng nhập qua browser
az login --use-device-code                  # Dùng device code (SSH/remote)

# Subscription
az account show                             # Subscription hiện tại
az account list --output table              # Tất cả subscriptions
az account set --subscription "my-sub"      # Chuyển subscription
```

### 1. Resource Group — container chứa mọi thứ

```bash
az group create --name rg-myapp --location southeastasia
az group list --output table
az group delete --name rg-myapp --yes       # Xoá group + TẤT CẢ resources bên trong
```

> **Mấu chốt**: Xoá resource group = xoá hết mọi thứ bên trong. Rất tiện khi học — tạo, thử nghiệm, xoá group, không tốn tiền.

### 2. Virtual Machine

```bash
# Tạo VM
az vm create \
  --resource-group rg-myapp \
  --name my-vm \
  --image Ubuntu2204 \
  --size Standard_B1s \
  --admin-username azureuser \
  --generate-ssh-keys

# Quản lý
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
# Tạo plan + app
az appservice plan create \
  --resource-group rg-myapp \
  --name plan-myapp \
  --sku F1 --is-linux

az webapp create \
  --resource-group rg-myapp \
  --plan plan-myapp \
  --name my-webapp \
  --runtime "NODE:20-lts"

# Deploy từ Docker
az webapp create \
  --resource-group rg-myapp \
  --plan plan-myapp \
  --name my-webapp \
  --deployment-container-image-name nginx:alpine

# Quản lý
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
# Tạo storage account
az storage account create \
  --resource-group rg-myapp \
  --name mystorageaccount \
  --sku Standard_LRS

# Tạo container (giống folder/bucket)
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
# Tạo server
az postgres flexible-server create \
  --resource-group rg-myapp \
  --name my-postgres \
  --location southeastasia \
  --admin-user myadmin \
  --admin-password 'SecureP@ss123' \
  --sku-name Standard_B1ms \
  --tier Burstable

# Firewall — cho phép IP của bạn
az postgres flexible-server firewall-rule create \
  --resource-group rg-myapp \
  --name my-postgres \
  --rule-name allow-myip \
  --start-ip-address <your-ip> \
  --end-ip-address <your-ip>

# Tạo database
az postgres flexible-server db create \
  --resource-group rg-myapp \
  --server-name my-postgres \
  --database-name mydb

# Kết nối
psql "host=my-postgres.postgres.database.azure.com dbname=mydb user=myadmin"
```

### 6. Key Vault (Secrets)

```bash
# Tạo vault
az keyvault create \
  --resource-group rg-myapp \
  --name my-keyvault

# Quản lý secrets
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

# NSG (Network Security Group) — giống firewall
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

## Azure CLI vs PowerShell — Thi AZ-104 / AZ-400

Cả hai đều xuất hiện trong đề thi. Cùng thao tác, khác cú pháp:

| Tác vụ | Azure CLI (`az`) | PowerShell (`Az` module) |
|---|---|---|
| Đăng nhập | `az login` | `Connect-AzAccount` |
| Tạo RG | `az group create --name rg --location eastasia` | `New-AzResourceGroup -Name rg -Location eastasia` |
| List RGs | `az group list` | `Get-AzResourceGroup` |
| Xoá RG | `az group delete --name rg` | `Remove-AzResourceGroup -Name rg` |
| Tạo VM | `az vm create --name vm ...` | `New-AzVM -Name vm ...` |
| List VMs | `az vm list` | `Get-AzVM` |
| Start VM | `az vm start --name vm ...` | `Start-AzVM -Name vm ...` |
| Stop VM | `az vm stop --name vm ...` | `Stop-AzVM -Name vm ...` |
| Tạo Web App | `az webapp create --name app ...` | `New-AzWebApp -Name app ...` |
| Tạo Storage | `az storage account create ...` | `New-AzStorageAccount ...` |
| Lấy Secret | `az keyvault secret show ...` | `Get-AzKeyVaultSecret ...` |
| Tạo VNet | `az network vnet create ...` | `New-AzVirtualNetwork ...` |
| Tạo NSG Rule | `az network nsg rule create ...` | `Add-AzNetworkSecurityRuleConfig ...` |

**Pattern của PowerShell:**

```
Verb-AzResource -ParameterName value
```

| Verb | Ý nghĩa | CLI tương đương |
|---|---|---|
| `New-` | Tạo mới | `create` |
| `Get-` | Đọc / Liệt kê | `show` / `list` |
| `Set-` | Cập nhật | `update` |
| `Remove-` | Xoá | `delete` |
| `Start-` / `Stop-` | Điều khiển trạng thái | `start` / `stop` |

**Mẹo thi:** Không cần thuộc lòng từng command. Đề thi kiểm tra khả năng **đọc hiểu** command. Thấy `New-AzResourceGroup` thì biết tạo resource group. Thấy `Get-AzVM` thì biết lấy danh sách VM.

## Mẹo

1. **`--output table`** — thêm vào mọi `list` command cho dễ đọc
2. **`az find "keyword"`** — tìm command theo keyword khi không nhớ
3. **`--query`** — filter output bằng JMESPath: `az vm list --query "[].{Name:name, State:powerState}"`
4. **Resource Group = sandbox** — tạo 1 group riêng để thử, xong `az group delete` là sạch
