# Azure App Service — Dành cho người biết AWS Elastic Beanstalk

PaaS cho web apps. Push code hoặc container, Azure lo phần còn lại.

## Quick Mapping

```
AWS                              Azure
───────────────────────────────────────────────────
Elastic Beanstalk            →   App Service
EB Environment               →   App Service Plan (compute layer)
EB Application Version       →   Deployment Slot
App Runner                   →   App Service (container mode)
Lambda                       →   Azure Functions
```

## Các khái niệm chính

```
App Service Plan (compute/pricing)
  └── Web App 1
  └── Web App 2
  └── Function App
```

**App Service Plan** = compute layer (CPU, RAM, pricing tier). Nhiều apps có thể share 1 plan.

| Tier | Có gì |
|------|-------|
| **Free/Shared** | Dev/test, không custom domain, giới hạn |
| **Basic** | Custom domain, scale thủ công |
| **Standard** | Auto-scale, deployment slots, backup hàng ngày |
| **Premium** | VNet integration, nhiều slots hơn, scale nhiều hơn |

## Tạo & Deploy

```bash
# Tạo App Service Plan
az appservice plan create \
  --resource-group rg-myapp \
  --name myPlan \
  --sku B1 \
  --is-linux

# Tạo Web App (container)
az webapp create \
  --resource-group rg-myapp \
  --plan myPlan \
  --name mywebapp123 \
  --deployment-container-image-name nginx:alpine

# Tạo Web App (code - Node.js)
az webapp create \
  --resource-group rg-myapp \
  --plan myPlan \
  --name mywebapp123 \
  --runtime "NODE:18-lts"

# Deploy từ Git
az webapp deployment source config \
  --resource-group rg-myapp \
  --name mywebapp123 \
  --repo-url https://github.com/user/repo \
  --branch main \
  --manual-integration

# Deploy file ZIP
az webapp deploy \
  --resource-group rg-myapp \
  --name mywebapp123 \
  --src-path app.zip
```

## Các cách Deploy

| Method | Khi nào dùng |
|--------|--------------|
| **Git push** | Đơn giản, auto-deploy khi push |
| **ZIP deploy** | CI/CD pipelines |
| **Container** | Dockerfile, toàn quyền kiểm soát |
| **GitHub Actions** | CI/CD có testing |

## Scaling

```bash
# Scale UP (instance lớn hơn)
az appservice plan update \
  --resource-group rg-myapp \
  --name myPlan \
  --sku P1V2

# Scale OUT (nhiều instances hơn) - thủ công
az appservice plan update \
  --resource-group rg-myapp \
  --name myPlan \
  --number-of-workers 3

# Auto-scale (Standard tier trở lên)
az monitor autoscale create \
  --resource-group rg-myapp \
  --resource myPlan \
  --resource-type Microsoft.Web/serverfarms \
  --min-count 1 \
  --max-count 5 \
  --count 1

az monitor autoscale rule create \
  --resource-group rg-myapp \
  --autoscale-name myPlan \
  --condition "CpuPercentage > 70 avg 5m" \
  --scale out 1
```

## Deployment Slots (Blue/Green)

Giống Beanstalk environment swap. Deploy không downtime.

```bash
# Tạo slot staging
az webapp deployment slot create \
  --resource-group rg-myapp \
  --name mywebapp123 \
  --slot staging

# Deploy lên staging
az webapp deploy \
  --resource-group rg-myapp \
  --name mywebapp123 \
  --slot staging \
  --src-path app.zip

# Swap staging → production
az webapp deployment slot swap \
  --resource-group rg-myapp \
  --name mywebapp123 \
  --slot staging \
  --target-slot production
```

## Networking

| Option | Mô tả |
|--------|-------|
| **Public** | Mặc định, truy cập được từ internet |
| **Access Restrictions** | Whitelist IPs/VNets |
| **VNet Integration** | App có thể truy cập resources trong VNet (outbound) |
| **Private Endpoint** | App chỉ truy cập được từ VNet (inbound) |

```bash
# VNet integration (outbound)
az webapp vnet-integration add \
  --resource-group rg-myapp \
  --name mywebapp123 \
  --vnet myVnet \
  --subnet app-subnet

# Access restriction (cho phép IP cụ thể)
az webapp config access-restriction add \
  --resource-group rg-myapp \
  --name mywebapp123 \
  --priority 100 \
  --ip-address 203.0.113.0/24
```

## Custom Domain + TLS

```bash
# Thêm custom domain
az webapp config hostname add \
  --resource-group rg-myapp \
  --webapp-name mywebapp123 \
  --hostname www.example.com

# Free managed certificate (dễ)
az webapp config ssl create \
  --resource-group rg-myapp \
  --name mywebapp123 \
  --hostname www.example.com

# Bind certificate
az webapp config ssl bind \
  --resource-group rg-myapp \
  --name mywebapp123 \
  --certificate-thumbprint <thumbprint> \
  --ssl-type SNI
```

## App Settings & Connection Strings

Giống Beanstalk environment variables.

```bash
# Set app settings (env vars)
az webapp config appsettings set \
  --resource-group rg-myapp \
  --name mywebapp123 \
  --settings DB_HOST=mydb.postgres.database.azure.com API_KEY=@Microsoft.KeyVault(SecretUri=https://...)

# Set connection string
az webapp config connection-string set \
  --resource-group rg-myapp \
  --name mywebapp123 \
  --connection-string-type PostgreSQL \
  --settings DB="Host=mydb;Database=app;..."
```

## So sánh Multi-Cloud

| Concept | Azure | AWS | GCP |
|---------|-------|-----|-----|
| PaaS | App Service | Elastic Beanstalk | App Engine |
| Container PaaS | App Service | App Runner | Cloud Run |
| Compute layer | App Service Plan | EB Environment | App Engine Instance |
| Blue/Green | Deployment Slots | Environment Swap | Traffic Splitting |
| Serverless | Azure Functions | Lambda | Cloud Functions |
