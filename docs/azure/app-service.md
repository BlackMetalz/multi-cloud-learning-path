# Azure App Service — For AWS Elastic Beanstalk Users

PaaS for web apps. Push code or container, Azure handles the rest.

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

## Key Concepts

```
App Service Plan (compute/pricing)
  └── Web App 1
  └── Web App 2
  └── Function App
```

**App Service Plan** = compute layer (CPU, RAM, pricing tier). Multiple apps can share one plan.

| Tier | What you get |
|------|--------------|
| **Free/Shared** | Dev/test, no custom domain, limited |
| **Basic** | Custom domain, manual scale |
| **Standard** | Auto-scale, deployment slots, daily backup |
| **Premium** | VNet integration, more slots, more scale |

## Create & Deploy

```bash
# Create App Service Plan
az appservice plan create \
  --resource-group rg-myapp \
  --name myPlan \
  --sku B1 \
  --is-linux

# Create Web App (container)
az webapp create \
  --resource-group rg-myapp \
  --plan myPlan \
  --name mywebapp123 \
  --deployment-container-image-name nginx:alpine

# Create Web App (code - Node.js)
az webapp create \
  --resource-group rg-myapp \
  --plan myPlan \
  --name mywebapp123 \
  --runtime "NODE:18-lts"

# Deploy from Git
az webapp deployment source config \
  --resource-group rg-myapp \
  --name mywebapp123 \
  --repo-url https://github.com/user/repo \
  --branch main \
  --manual-integration

# Deploy ZIP file
az webapp deploy \
  --resource-group rg-myapp \
  --name mywebapp123 \
  --src-path app.zip
```

## Deployment Options

| Method | When to use |
|--------|-------------|
| **Git push** | Simple, auto-deploy on push |
| **ZIP deploy** | CI/CD pipelines |
| **Container** | Dockerfile, full control |
| **GitHub Actions** | CI/CD with testing |

## Scaling

```bash
# Scale UP (bigger instance)
az appservice plan update \
  --resource-group rg-myapp \
  --name myPlan \
  --sku P1V2

# Scale OUT (more instances) - manual
az appservice plan update \
  --resource-group rg-myapp \
  --name myPlan \
  --number-of-workers 3

# Auto-scale (Standard tier+)
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

Like Beanstalk environment swap. Zero-downtime deployments.

```bash
# Create staging slot
az webapp deployment slot create \
  --resource-group rg-myapp \
  --name mywebapp123 \
  --slot staging

# Deploy to staging
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

| Option | What it does |
|--------|--------------|
| **Public** | Default, accessible from internet |
| **Access Restrictions** | Whitelist IPs/VNets |
| **VNet Integration** | App can access resources in VNet (outbound) |
| **Private Endpoint** | App only accessible from VNet (inbound) |

```bash
# VNet integration (outbound)
az webapp vnet-integration add \
  --resource-group rg-myapp \
  --name mywebapp123 \
  --vnet myVnet \
  --subnet app-subnet

# Access restriction (allow specific IP)
az webapp config access-restriction add \
  --resource-group rg-myapp \
  --name mywebapp123 \
  --priority 100 \
  --ip-address 203.0.113.0/24
```

## Custom Domain + TLS

```bash
# Add custom domain
az webapp config hostname add \
  --resource-group rg-myapp \
  --webapp-name mywebapp123 \
  --hostname www.example.com

# Free managed certificate (easy)
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

Like Beanstalk environment variables.

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

## Multi-Cloud Comparison

| Concept | Azure | AWS | GCP |
|---------|-------|-----|-----|
| PaaS | App Service | Elastic Beanstalk | App Engine |
| Container PaaS | App Service | App Runner | Cloud Run |
| Compute layer | App Service Plan | EB Environment | App Engine Instance |
| Blue/Green | Deployment Slots | Environment Swap | Traffic Splitting |
| Serverless | Azure Functions | Lambda | Cloud Functions |
