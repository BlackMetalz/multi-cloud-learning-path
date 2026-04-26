# Project 04: Bicep + Azure DevOps Pipelines

Port một slice infra sang **Bicep** (Microsoft-native IaC, không state file) và deploy qua **Azure DevOps multi-stage pipeline** với what-if + manual approval. Đây là combo hay xuất hiện trong câu hỏi AZ-400.

## Why Bicep + Azure DevOps khi mình đã có Terraform + GitHub Actions?

| Aspect | Terraform | Bicep | Cần học cho AZ-400 |
|---|---|---|---|
| State | Terraform state file (remote backend) | ❌ Không có — ARM là source of truth | ✓ |
| Drift detection | `terraform plan` so với state | `az deployment ... what-if` so với ARM live state | ✓ |
| Module system | `module {}` block | `module xxx 'path.bicep'` | ✓ |
| Provider lock | `.terraform.lock.hcl` | Không cần (ARM API versioning trong template) | ✓ |
| What blocks vendor | Multi-cloud OK | Azure-only | – |
| Tooling | `terraform fmt`, `tflint` | `az bicep format`, `az bicep lint` | ✓ |

**Bicep "thắng" Terraform** ở: không cần backend, không state corruption, syntax gọn hơn HCL, type-safe parameter files (`.bicepparam`).
**Terraform "thắng" Bicep** ở: multi-cloud, ecosystem providers (Datadog, Cloudflare...).

Tương tự, Azure DevOps có **Variable Groups + KV-linked secrets + Environment approvals** built-in — GitHub Actions phải kéo từ Repository Secrets / Environments thủ công hơn.

## Architecture

```
┌─────────────────────── GitHub repo (single source) ───────────────────────┐
│                                                                            │
│  projects/04-bicep-azdo/bicep/                                             │
│    ├── main.bicep            (subscription-scope deployment)               │
│    ├── modules/{storage,keyvault,appservice}.bicep                         │
│    └── params/{dev,prod}.bicepparam                                        │
│                                                                            │
│  projects/04-bicep-azdo/pipelines/azure-pipelines.yaml                     │
└─────────────────────┬──────────────────────────────────────────────────────┘
                      │ ADO triggers on push to main (via GitHub SC)
                      ▼
┌─────────────── Azure DevOps Pipeline ──────────────┐
│  Stage 1: Validate    (bicep build, what-if)       │
│        ↓                                            │
│  Stage 2: Deploy-dev  (env = bicep-lab-dev)         │
│        └─ requires manual approval (env config)     │
│        ↓                                            │
│  Service Connection (Workload Identity Federation)  │
│        ↓ no client secret                           │
└────────┬────────────────────────────────────────────┘
         ▼
┌──── Azure subscription ────┐
│  rg-bicep-lab-dev          │
│    ├── Storage Account     │
│    ├── Key Vault           │
│    └── App Service (F1)    │
└────────────────────────────┘
```

## Learning Goals (AZ-400)

- **Bicep authoring**: subscription-scope deployment, modules, `.bicepparam`, `uniqueString`, conditional resources
- **`az deployment what-if`** — ARM-side drift preview (no state file involved)
- **Azure DevOps Pipelines YAML**: stages, jobs, deployment jobs, environments
- **Workload Identity Federation** for ADO Service Connection (no SP secret)
- **Variable Groups + KV-linked variables** — pipeline secrets without inlining
- **Environment approval gates** — manual gate between stages
- (Optional) **Self-hosted agent** — install agent on a VM, register pool, route a job

## Steps

### Step 1 — Local Bicep workflow (no pipeline yet)
- [ ] `az bicep upgrade`
- [ ] `cd projects/04-bicep-azdo/bicep`
- [ ] `az bicep build --file main.bicep` → check `main.json` produced (= ARM compiled)
- [ ] `az deployment sub what-if -l southeastasia --template-file main.bicep --parameters params/dev.bicepparam`
- [ ] `az deployment sub create -l southeastasia --template-file main.bicep --parameters params/dev.bicepparam`
- [ ] Verify resources in `rg-bicep-lab-dev`

### Step 2 — Setup Azure DevOps org + project (one-time)
Walk-through in `pipelines/README.md`. Summary:
- [ ] Create free org at https://dev.azure.com
- [ ] Create project `multi-cloud-learning`
- [ ] Connect to GitHub: Project Settings → Service connections → New → GitHub
- [ ] Create Azure Service Connection (Workload Identity Federation, automatic mode)

### Step 3 — Variable Groups + Environment
- [ ] Pipelines → Library → New Variable Group: `bicep-lab-vars`
      vars: `AZURE_SC_NAME` (your service connection name), `LOCATION` (southeastasia)
- [ ] Pipelines → Environments → New: `bicep-lab-dev`
      Approvals & checks → Add → Approvals → set yourself as required reviewer

### Step 4 — Run the pipeline
- [ ] Pipelines → New Pipeline → GitHub → select repo → Existing Azure Pipelines YAML file → `projects/04-bicep-azdo/pipelines/azure-pipelines.yaml`
- [ ] Run → watch Stage 1 (Validate) green → Stage 2 prompts approval → click approve → deploy runs
- [ ] What-if output should match what Stage 2 actually deploys

### Step 5 — Break + observe
- [ ] Edit `params/dev.bicepparam`: change a tag value, push to main
- [ ] `what-if` should show **Modify** on the resource (incremental drift)
- [ ] Approve → applied

### Step 6 — Cleanup
- [ ] `az group delete -n rg-bicep-lab-dev --yes`
- [ ] (Optional) Delete ADO project to free org

## Cloud Services Used

| Concept | Azure | AWS | GCP |
|---|---|---|---|
| Native IaC | Bicep / ARM | CloudFormation / CDK | Deployment Manager (deprecated) / Config Connector |
| Plan / drift | `az deployment what-if` | CloudFormation Change Sets | DM `preview` (legacy) |
| Pipeline service | Azure DevOps Pipelines | AWS CodePipeline / CodeBuild | Cloud Build |
| Pipeline OIDC to cloud | WIF Service Connection | GHA → AWS via OIDC | WIF |
| Approval gate | Environment approvals | CodePipeline manual approval | Cloud Build approval |
| Secret store linked to pipeline | Variable Group + KV link | SSM Parameter / Secrets Manager | Secret Manager |

## Cost Notes

| Resource | Cost |
|---|---|
| Azure DevOps free tier | $0 (1 free Microsoft-hosted parallel job, 1800 min/month) |
| App Service F1 | $0 |
| Storage LRS | ~$0.02/GB/month |
| Key Vault standard | $0.03/10k operations |
| **Total realistic** | **<$1/day** — can leave running |
