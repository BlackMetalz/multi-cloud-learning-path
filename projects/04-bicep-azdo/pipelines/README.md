### Setup Azure DevOps from scratch (one-time, ~15 phút)

Phần lớn setup ADO là portal-based, không có Bicep cho ADO entities. Đi theo thứ tự dưới.

#### 1. Tạo organization + project

1. Mở https://dev.azure.com → **New organization** (free, không cần credit card riêng)
2. Trong org → **New project**
   - Name: `multi-cloud-learning`
   - Visibility: Private
   - Version control: **Git** (mặc định)
   - Work item process: Basic
3. Free tier giới hạn:
   - 1 Microsoft-hosted parallel job (1800 min/month) — đủ cho lab
   - 5 user free

#### 2. Connect GitHub repo (không phải clone vào ADO Repos)

1. Project Settings (góc trái dưới) → **Service connections** → **New service connection**
2. Chọn **GitHub** → **OAuth** → authorize → chọn repo `multi-cloud-learning-path`
3. Save → connection name auto = `<your-github-username>` hoặc tự đặt

#### 3. Tạo Azure Service Connection (Workload Identity Federation)

1. Service connections → **New** → **Azure Resource Manager**
2. Authentication method: **Workload Identity Federation (automatic)** ← **đây là cái mới, không cần secret**
3. Scope: Subscription → chọn sub Azure của bro
4. Service connection name: `azure-bicep-lab` (ghi nhớ tên này, sẽ dùng trong variable group)
5. **Grant access permission to all pipelines**: ✓
6. Save

→ ADO tự tạo App Registration + Federated Credential trong Entra ID, và cấp Contributor trên subscription.

Verify: vào Azure Portal → Entra ID → App registrations → tìm app `<org>-<project>-<sc-name>` → Federated credentials → thấy 1 entry với issuer `https://vstoken.dev.azure.com/...`.

#### 4. Variable Group `bicep-lab-vars`

1. Pipelines → **Library** → **+ Variable group**
2. Name: `bicep-lab-vars`
3. Variables:
   | Name | Value | Secret? |
   |---|---|---|
   | `AZURE_SC_NAME` | `azure-bicep-lab` (tên SC vừa tạo) | no |
   | `AZURE_SUBSCRIPTION_ID` | `6ffa294f-bae0-416c-b9d0-df60a129f559` | no |
   | `LOCATION` | `southeastasia` | no |
4. Save

(Optional) **Link to Key Vault** ở step nâng cao: variable group có thể pull secrets từ KV thay vì hardcode. Phải gán role *Key Vault Secrets User* cho Service Principal của ADO trên KV trước.

#### 5. Environment với approval gate

1. Pipelines → **Environments** → **New environment**
2. Name: `bicep-lab-dev`
3. Resource: None
4. Create → vào environment vừa tạo → **Approvals and checks** → **+** → **Approvals**
5. Approvers: thêm chính bro
6. Save → giờ mọi deployment job target environment này sẽ bị gate.

#### 6. Tạo Pipeline trỏ vào file YAML

1. Pipelines → **Pipelines** → **New pipeline**
2. Where is your code? → **GitHub** → chọn repo
3. Configure your pipeline → **Existing Azure Pipelines YAML file**
4. Branch: `main`
5. Path: `/projects/04-bicep-azdo/pipelines/azure-pipelines.yaml`
6. Continue → Run

Lần đầu chạy ADO sẽ ask permission cho:
- Variable group `bicep-lab-vars` → Permit
- Service Connection `azure-bicep-lab` → Permit
- Environment `bicep-lab-dev` → Permit

Sau đó stage Validate chạy → if green, stage Deploy_dev pause → bro vào pipeline run → click **Review** → **Approve** → deploy chạy.

### Pipeline behavior cheatsheet

| Trigger | Stage chạy |
|---|---|
| Push to `main` (touching bicep/) | Validate → Deploy_dev (with approval) |
| PR vào `main` | Validate only (không deploy) |
| Manual run | Tất cả stage theo `condition` |

### Verify what-if output trong stage 1

ADO Job log → `az deployment sub what-if` task → expect output kiểu:
```
Resource and property changes are indicated with these symbols:
  + Create
  ~ Modify
  - Delete
  = Nochange
...
+ /subscriptions/.../resourceGroups/rg-bicep-lab-dev
+ /subscriptions/.../resourceGroups/rg-bicep-lab-dev/providers/Microsoft.Storage/storageAccounts/...
...
```

Nếu Deploy_dev sau đó tạo ra 0 modifications khi rerun → drift detection working.

### Common gotchas

- **"User does not have access to subscription"** lúc what-if: SC chưa được grant Contributor → check Step 3.6 đã tick *Grant access permission to all pipelines*.
- **"Variable group not found"**: chưa permit lần đầu run. Click vào pipeline run, chấp nhận permission prompt.
- **Approval timeout (default 30 days)**: nếu bro quên approve, deployment fail. Có thể chỉnh trong environment config.
- **`bicepparam` parser error**: cần Bicep CLI ≥ 0.21. ADO image `ubuntu-latest` đã có sẵn nhưng có thể cũ — pipeline đã `az bicep upgrade` ngầm via `az bicep build`.

### Cleanup ADO

- Delete pipeline: Pipelines → Pipelines → ... → Delete
- Delete project: Organization Settings → Projects → ... → Delete
- Delete org: Organization Settings → Overview → Delete
