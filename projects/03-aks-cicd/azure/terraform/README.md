### Tutorial when you working xDD

```bash
cd projects/03-aks-cicd/azure/terraform
az login --use-device-code
cp terraform.tfvars.example terraform.tfvars
# edit: subscription_id + github_repo (must be your real repo!)
terraform init
terraform plan -out=tfplan
terraform apply "tfplan"
# AKS tạo lâu nhất ~5-10 phút
```

Plan detail:
```
Plan: 14 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + acr_login_server            = (known after apply)
  + acr_name                    = (known after apply)
  + aks_name                    = "aks-gitops"
  + aks_oidc_issuer_url         = (known after apply)
  + gha_AZURE_CLIENT_ID         = (known after apply)
  + gha_AZURE_SUBSCRIPTION_ID   = "6ffa294f-bae0-416c-b9d0-df60a129f559"
  + gha_AZURE_TENANT_ID         = "83f9ba21-b4f3-4a3e-9428-eb67f75a1993"
  + log_workspace_name          = "log-gitops"
  + resource_group              = "rg-gitops"
  + workload_identity_client_id = (known after apply)
```

### File layout

```
azure/terraform/
├── providers.tf            # azurerm 4.x + remote backend (key=gitops.tfstate)
├── variables.tf            # subscription, github_repo, AKS knobs
├── locals.tf               # naming + tags
├── main.tf                 # RG + random suffix
├── network.tf              # VNet + 1 subnet for AKS
├── acr.tf                  # ACR Basic, admin disabled
├── aks.tf                  # AKS cluster (oidc + workload identity ON), AcrPull role
├── identity.tf             # 2 UAMIs: GHA deploy + Pod workload, both with federated creds
├── monitor.tf              # Log Analytics for Container Insights
├── outputs.tf              # GHA secrets + workload identity client_id
├── terraform.tfvars.example
└── terraform.tfvars        # gitignored
```

### Pre-flight SKU check (lesson learned từ project 02)

```bash
az vm list-skus -l southeastasia --size Standard_D2s_v3 \
  --query "[?length(restrictions)==\`0\`].name" -o tsv
# Expect: Standard_D2s_v3  (nếu trống → đổi region hoặc SKU khác như D2alds_v7)
```

### After apply — populate GitHub secrets

```bash
echo "AZURE_CLIENT_ID=$(terraform output -raw gha_AZURE_CLIENT_ID)"
echo "AZURE_TENANT_ID=$(terraform output -raw gha_AZURE_TENANT_ID)"
echo "AZURE_SUBSCRIPTION_ID=$(terraform output -raw gha_AZURE_SUBSCRIPTION_ID)"
```

GitHub repo → Settings → Secrets and variables → Actions → New repository secret. Paste 3 cái trên.

### Manual smoke test (Step 2 — before GHA)

```bash
ACR=$(terraform output -raw acr_name)
ACR_LOGIN=$(terraform output -raw acr_login_server)
RG=$(terraform output -raw resource_group)
AKS=$(terraform output -raw aks_name)

# Heads-up 1: Azure free-trial / credit subscriptions disable ACR Tasks,
#             so `az acr build` returns TasksOperationsNotAllowed. Build local + push instead.
# Heads-up 2: Apple Silicon Mac builds ARM64 by default; AKS nodes are AMD64.
#             Always pass --platform linux/amd64.
az acr login -n $ACR
docker buildx build --platform linux/amd64 -t $ACR_LOGIN/hello:v1 --push ../../app
# verify
az acr repository list -n $ACR -o table  
# expected output
# Result
# --------
# hello

# Lấy admin kubeconfig (vì local_account_disabled = false default)
az aks get-credentials -g $RG -n $AKS --admin --overwrite-existing

# Update image tag in k8s/deployment.yaml để trỏ đến ACR
sed -i.bak "s|REPLACE_ACR|$(terraform output -raw acr_login_server)|g" ../../k8s/deployment.yaml

kubectl apply -f ../../k8s/
kubectl wait --for=condition=ready pod -l app=hello --timeout=120s
kubectl port-forward svc/hello 8080:80
# new terminal: curl localhost:8080
```

### Workload Identity demo (Step 4)

#### Why annotate the ServiceAccount? — the federation triangle

3 thứ phải khớp nhau để pod gọi được Azure mà **không có secret nào** trong container:

```
┌───────────────────────────────────┐
│ 1. K8s ServiceAccount             │   ←  "Pod là ai" trong cluster
│    name: demo-sa                  │      (just an identity label)
│    namespace: default             │
│    annotation: client-id=<UAMI>   │   ←  trỏ tới Azure identity
└──────────────┬────────────────────┘
               │
               │  AKS OIDC issuer ký token cho SA này:
               │  sub = "system:serviceaccount:default:demo-sa"
               │
               ▼
┌───────────────────────────────────┐
│ 2. Federated Credential           │   ←  "Trust policy" của UAMI
│    on UAMI id-workload-gitops     │      (created in identity.tf)
│    issuer: AKS OIDC URL           │
│    subject: system:sa:default:    │
│             demo-sa               │
│    audience: AzureADTokenExchange │
└──────────────┬────────────────────┘
               │ Match → AAD cấp access token cho UAMI
               ▼
┌───────────────────────────────────┐
│ 3. Azure UAMI                     │   ←  Identity có role thật
│    id-workload-gitops             │      (gắn role lên đây để cấp quyền)
│    + role assignments             │
└───────────────────────────────────┘
```

**Annotation `azure.workload.identity/client-id` để làm gì?**

Đây là cờ hiệu cho **AKS Workload Identity webhook**. Webhook quan sát mọi pod được tạo ra; nếu pod:
- Dùng SA có annotation này, **VÀ**
- Có label `azure.workload.identity/use: "true"` (đã set sẵn trong `deployment.yaml`)

→ webhook **mutate spec của pod** trước khi nó chạy, tự động:
- Mount file token tại `/var/run/secrets/azure/tokens/azure-identity-token` (token này do AKS OIDC issuer ký, có claim `sub=system:serviceaccount:default:demo-sa`)
- Inject env vars: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_FEDERATED_TOKEN_FILE`, `AZURE_AUTHORITY_HOST`

Azure SDK trong pod (Python/Go/.NET/Node...) tự động đọc 4 env này → exchange token với AAD → nhận access token cho UAMI → gọi Azure API. Cả flow zero config trong code app.

**Luồng khi pod gọi Azure** (ví dụ đọc Key Vault):
```
Pod code (Azure SDK)
  → đọc token từ AZURE_FEDERATED_TOKEN_FILE (do K8s project vào volume)
  → POST đến https://login.microsoftonline.com với token này làm "client_assertion"
  → AAD verify: issuer + subject + audience có khớp federated cred của UAMI không?
  → Match → AAD trả về access_token cho UAMI
  → Pod dùng access_token gọi Key Vault / Storage / Postgres / ...
```

**Sao tách SA và Pod identity ra?**
- 1 SA = 1 Azure identity. Nhiều pod share cùng SA → share UAMI → share role.
- Workload khác nhau → SA khác → UAMI khác → least-privilege từng workload.
- Rotate quyền = sửa role assignment trên UAMI, **không cần restart pod**.

**Sao phải `rollout restart` deployment sau khi apply SA?**
- Webhook chỉ mutate pod **lúc tạo mới**. Pod đang chạy không có token mount đâu.
- `kubectl rollout restart` huỷ pod cũ, tạo pod mới → webhook intercept → inject.

#### Commands

```bash
# 1. Patch the SA with workload identity client_id
WL_CLIENT_ID=$(terraform output -raw workload_identity_client_id)
sed -i.bak "s|REPLACE_WL_CLIENT_ID|$WL_CLIENT_ID|g" ../../k8s/sa.yaml
kubectl apply -f ../../k8s/sa.yaml

# 2. Re-roll the deployment so pods pick up the SA token mount
kubectl rollout restart deploy/hello

# 3. Verify the pod has federated token + correct env
POD=$(kubectl get pod -l app=hello -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD -- env | grep AZURE
# Expect 4 vars: AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_FEDERATED_TOKEN_FILE, AZURE_AUTHORITY_HOST
# Cũng nên có file token:
kubectl exec $POD -- ls -la /var/run/secrets/azure/tokens/

# 4. Decode JWT để xem claims.
# JWT dùng base64url KHÔNG padding → macOS `base64 -d` strict sẽ truncate group cuối.
# Cần pad `=` cho đủ multiple of 4 trước khi decode.

# Cách 1 — Python (gọn, có sẵn trên Mac/Linux):
kubectl exec $POD -- sh -c 'cat $AZURE_FEDERATED_TOKEN_FILE' \
  | python3 -c "import sys,base64,json; p=sys.stdin.read().split('.')[1]; print(json.dumps(json.loads(base64.urlsafe_b64decode(p+'='*(-len(p)%4))), indent=2))"

# Cách 2 — POSIX shell (awk pad + tr base64url → base64 + base64 -d):
kubectl exec $POD -- sh -c 'cat $AZURE_FEDERATED_TOKEN_FILE' \
  | awk -F. '{p=$2; pad=(4-length(p)%4)%4; for(i=0;i<pad;i++) p=p"="; print p}' \
  | tr '_-' '/+' \
  | base64 -d \
  | jq .
```

**3 claims cần soi** — phải khớp y chang `azurerm_federated_identity_credential.workload_sa` trong `identity.tf`:

| Claim trong JWT | Khớp với field nào của federated cred | Ý nghĩa |
|---|---|---|
| `"iss": "https://southeastasia.oic.prod-aks.azure.com/<tenant>/<cluster>/"` | `issuer = aks.oidc_issuer_url` | AKS OIDC issuer ký token |
| `"sub": "system:serviceaccount:default:demo-sa"` | `subject = "system:serviceaccount:default:demo-sa"` | Pod đang dùng SA `demo-sa` ở namespace `default` |
| `"aud": ["api://AzureADTokenExchange"]` | `audience = ["api://AzureADTokenExchange"]` | Token có audience là AAD token exchange endpoint |

3 cái match → AAD chấp nhận token này → cấp access_token cho UAMI. Sai 1 trong 3 → AAD reject với `AADSTS70021: No matching federated identity record found`.

Bonus claims trong `kubernetes.io`:
- `pod.name`, `pod.uid` — chứng minh token gắn liền với pod cụ thể này
- `serviceaccount.name`, `serviceaccount.uid` — không thể giả mạo SA khác
- `exp` — token chỉ sống ~1h, K8s tự refresh

> **Note**: `curl http://169.254.169.254/metadata/...` (IMDS) trả về **kubelet identity** (cái có AcrPull role), KHÔNG phải workload identity. Để test workload identity thật, cần Azure SDK trong pod gọi resource cụ thể (Key Vault, Storage). Đó là step nâng cao — skeleton này chỉ verify plumbing đã đúng.

### Save credit between sessions

```bash
# Pause node billing (cluster state preserved, ~30s)
az aks stop -g rg-gitops -n aks-gitops

# Resume next day
az aks start -g rg-gitops -n aks-gitops
```

### Cleanup
```bash
terraform destroy
```
