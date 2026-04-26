# Project 03: AKS + GitOps with GitHub Actions OIDC

Containerize an app, push to ACR, deploy to AKS — all through GitHub Actions with **zero secrets** (federated OIDC). Touch every AZ-400 muscle: containers, registries, Kubernetes, CI/CD with secret-less auth, workload identity.

## Architecture

```
┌─ GitHub repo (push to main) ─┐
│                              │
└──────────┬───────────────────┘
           │ OIDC token (no PAT/secret)
           ▼
┌─ GitHub Actions runner ──────┐
│  - azure/login@v2 (OIDC)     │
│  - az acr build              │
│  - az aks get-credentials    │
│  - kubectl apply             │
└──────────┬───────────────────┘
           │
           ▼
┌──────────────── Azure ───────────────────────┐
│  ACR (Basic) ◄── image push                  │
│       ▲                                      │
│       │ AcrPull (kubelet MI)                 │
│       │                                      │
│  AKS (oidc_issuer, workload_identity)        │
│   ↳ Pod with ServiceAccount                  │
│     └─ federated → UAMI → Azure resource     │
│                                              │
│  Log Analytics ◄── Container Insights        │
└──────────────────────────────────────────────┘
```

## Learning Goals (AZ-400 + AZ-104 mix)

- **Containers**: Dockerfile, multi-stage builds (basic), `az acr build`
- **ACR**: registry, AcrPull/AcrPush RBAC, no admin creds
- **AKS**: managed cluster, system pool, Azure CNI Overlay, autoscaler
- **Workload Identity**: pod → UAMI → Azure resource, no secrets in pod
- **GitHub Actions OIDC**: federated credential, `id-token: write`, `azure/login@v2`
- **kubectl basics**: deployment, service, ingress, namespace, contexts
- **Container Insights**: oms agent → Log Analytics for cluster + pod logs

## Steps

### Step 1 — Foundation
- [ ] `cp terraform.tfvars.example terraform.tfvars`, fill `subscription_id` + `github_repo`
- [ ] `terraform init && terraform apply`
- [ ] AKS up with 1 node + ACR + 2 UAMIs (deploy + workload)

### Step 2 — Build & deploy manually (no GHA yet)
- [ ] `az acr build --registry <acr> --image hello:v1 ./app`
- [ ] `az aks get-credentials -g rg-gitops -n aks-gitops --admin`
- [ ] `kubectl apply -f k8s/`
- [ ] `kubectl port-forward svc/hello 8080:80` → `curl localhost:8080`

### Step 3 — GitHub Actions OIDC
- [ ] Copy `cicd/deploy.yaml` → `.github/workflows/aks-deploy.yaml` (repo root)
- [ ] Add GH secrets from `terraform output`:
      `AZURE_CLIENT_ID` (deploy UAMI), `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`
- [ ] Push commit → workflow runs → image pushed → AKS rollout

### Step 4 — Workload Identity demo
- [ ] Pod uses ServiceAccount annotated with workload UAMI's client_id
- [ ] `kubectl exec` into pod, `curl` Azure metadata endpoint → MI token
- [ ] (optional) Add KV + secret read

### Step 5 — Stop nodes to save credit
- [ ] `az aks stop -g rg-gitops -n aks-gitops` — pauses node billing
- [ ] `az aks start` to resume (cluster state preserved)

### Step 6 — Cleanup
- [ ] `terraform destroy`

### Step 7 — Replicate on AWS (later): EKS + ECR + GHA OIDC + IRSA
### Step 8 — Replicate on GCP (later): GKE Autopilot + Artifact Registry + Workload Identity Federation

## Cloud Services Used

| Concept | Azure | AWS (later) | GCP (later) |
|---|---|---|---|
| Container registry | ACR | ECR | Artifact Registry |
| K8s | AKS | EKS | GKE / GKE Autopilot |
| Pod identity | Workload Identity (OIDC) | IRSA | Workload Identity |
| CI/CD federation | GHA → Azure (federated cred) | GHA → AWS (AssumeRoleWithWebIdentity) | GHA → GCP (WIF) |
| Cluster monitoring | Container Insights → Log Analytics | CloudWatch Container Insights | Cloud Logging + GKE metrics |
| IaC | Terraform | Terraform | Terraform |

## Cost Notes

| Resource | Cost (approx) | How to throttle |
|---|---|---|
| AKS control plane (Free tier) | $0 | always free |
| AKS node x1 D2s_v3 | ~$2-3/day | `aks_node_count`, or `az aks stop` |
| ACR Basic | ~$0.17/day | always on |
| Log Analytics | pay per GB ingested | reduce via daily cap |
| UAMI + federated creds | free | free |

`az aks stop -g rg-gitops -n aks-gitops` mỗi tối → pause node billing; control plane free anyway.
