# Project structure

```
  projects/03-aks-cicd/
  ├── README.md                     # architecture, AZ-400 mapping, multi-cloud table, cost notes
  ├── app/
  │   ├── Dockerfile                # nginx:alpine (mirrored from project 01)
  │   ├── nginx.conf                # /health endpoint
  │   └── index.html
  ├── k8s/
  │   ├── deployment.yaml           # 2 replicas, workload identity label, REPLACE_ACR placeholder
  │   ├── service.yaml              # ClusterIP
  │   └── sa.yaml                   # demo-sa with REPLACE_WL_CLIENT_ID annotation
  ├── cicd/
  │   └── deploy.yaml               # GHA workflow — copy to .github/workflows/aks-deploy.yaml
  ├── azure/terraform/
  │   ├── providers.tf              # azurerm 4.x, "core" registration, key=gitops.tfstate
  │   ├── variables.tf              # github_repo required, aks_node_size default D2s_v3
  │   ├── locals.tf, main.tf        # RG + suffix
  │   ├── network.tf                # VNet + 1 subnet (Azure CNI Overlay → /24 đủ)
  │   ├── acr.tf                    # Basic, admin_enabled=false
  │   ├── aks.tf                    # Free tier, oidc_issuer + workload_identity ON, AcrPull on kubelet MI
  │   ├── identity.tf               # 2 UAMI: gha_deploy + workload, federated creds for both
  │   ├── monitor.tf                # Log Analytics
  │   ├── outputs.tf                # gha_AZURE_*, workload_identity_client_id, oidc_issuer_url
  │   ├── terraform.tfvars.example
  │   └── README.md                 # pre-flight SKU check, manual smoke test, WI demo, az aks stop tip
```