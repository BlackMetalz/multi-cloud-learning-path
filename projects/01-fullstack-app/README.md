# Project 01: Deploy a Full-Stack App

Deploy a full-stack web application from scratch. One app, multiple clouds.

## Architecture

```
User → CDN → Load Balancer → App Service (API) → Database
                                    ↓
                              Blob Storage (static assets)
```

## Learning Goals

By completing this project, you will learn:
- Compute: deploy a web app / container
- Database: provision and connect a managed database
- Storage: upload and serve static files
- Networking: configure DNS, load balancer, CDN
- Security: manage secrets, configure IAM
- CI/CD: automate deployment with GitHub Actions
- IaC: define all infrastructure as code with Terraform

## Steps

### Step 1 — Bootstrap the App
- [x] Nginx with custom `index.html` and `/health` endpoint
- [x] Dockerize the app

### Step 2 — Deploy to Azure
- [x] Write Terraform to provision: Resource Group, App Service Plan, Web App
- [ ] `cp terraform.tfvars.example terraform.tfvars` and fill in your subscription ID
- [ ] Run `terraform init && terraform plan && terraform apply`
- [ ] Verify `GET /health` works via public URL from `terraform output`

### Step 3 — Add Database
- [ ] Provision Azure Database for PostgreSQL via Terraform
- [ ] Add a simple CRUD endpoint (e.g. `/notes`)
- [ ] Store DB credentials in Azure Key Vault

### Step 4 — Add Storage
- [ ] Provision Azure Blob Storage via Terraform
- [ ] Add file upload endpoint (e.g. `POST /files`)
- [ ] Serve uploaded files via Blob Storage URL

### Step 5 — Monitoring & Logging
- [ ] Enable Azure Monitor + Log Analytics
- [ ] Set up alerts (e.g. high error rate, high latency)
- [ ] Add structured logging to the app

### Step 6 — CI/CD
- [ ] Create GitHub Actions workflow: test → build → push image → deploy
- [ ] Auto-deploy on push to `main`

### Step 7 — Production Hardening
- [ ] Add custom domain + TLS certificate
- [ ] Configure Azure CDN / Front Door
- [ ] Set up auto-scaling rules

### Step 8 — Replicate on AWS (later)
- [ ] Same app, deploy to ECS / App Runner + RDS + S3

### Step 9 — Replicate on GCP (later)
- [ ] Same app, deploy to Cloud Run + Cloud SQL + Cloud Storage

## Cloud Services Used

| Step | Azure | AWS (later) | GCP (later) |
|---|---|---|---|
| Compute | App Service | ECS / App Runner | Cloud Run |
| Database | PostgreSQL Flexible Server | RDS PostgreSQL | Cloud SQL |
| Storage | Blob Storage | S3 | Cloud Storage |
| Secrets | Key Vault | Secrets Manager | Secret Manager |
| Monitoring | Azure Monitor | CloudWatch | Cloud Monitoring |
| CI/CD | GitHub Actions | GitHub Actions | GitHub Actions |
| CDN | Front Door | CloudFront | Cloud CDN |
| IaC | Terraform | Terraform | Terraform |
