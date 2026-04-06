# Cloud Scope & Hierarchy — Mô hình tổ chức đằng sau mọi Cloud

## Tại sao cần biết?

Mọi cloud đều có hierarchy để kiểm soát:
- **Ai được truy cập gì** (IAM/RBAC)
- **Ai trả tiền cho gì** (Billing)
- **Luật gì áp dụng ở đâu** (Policy)
- **Giới hạn bao nhiêu** (Quota)

Hiểu 1 lần, IAM, billing, policy đều dễ hiểu.

## Azure Scope Hierarchy

```
Tenant (Entra ID)                    Ranh giới tổ chức & identity
  └── Management Group               Nhóm subscriptions, áp policy (optional)
        └── Subscription             Ranh giới billing, giới hạn quota
              └── Resource Group     Container logic cho resources
                    └── Resource     VM, DB, Storage, VNet...
```

### Giải thích từng layer

| Scope | Là gì | Ví dụ thực tế |
|---|---|---|
| **Tenant** | Tổ chức của bạn trên Azure. Chứa tất cả users, groups, app registrations. 1 công ty = 1 tenant. | Công ty |
| **Management Group** | Nhóm nhiều subscriptions lại. Áp policy/RBAC chung. Chủ yếu cho enterprise. | Phòng ban |
| **Subscription** | Đơn vị billing. Mỗi sub có quota, payment method, resource limits riêng. | Thẻ tín dụng / ngân sách |
| **Resource Group** | Container logic. Nhóm các resources liên quan. Xoá group = xoá hết bên trong. | Folder dự án |
| **Resource** | Thứ thực tế — VM, database, storage account. | Files trong folder |

### RBAC kế thừa từ trên xuống

Role assign ở scope cao sẽ kế thừa xuống dưới:

```
Owner ở Tenant              → sở hữu mọi thứ
Contributor ở Subscription  → quản lý tất cả resource groups & resources trong sub đó
Reader ở Resource Group     → chỉ xem được resources trong group đó
```

KHÔNG THỂ ghi đè permission kế thừa ở scope thấp hơn. Contributor ở Subscription sẽ luôn có quyền Contributor ở mọi Resource Group trong Subscription đó.

### Các pattern phổ biến

**Team nhỏ / đang học:**
```
Tenant
  └── 1 Subscription (Pay-As-You-Go)
        ├── rg-project-a
        ├── rg-project-b
        └── rg-sandbox        ← thử nghiệm ở đây, xoá khi xong
```

**Production setup:**
```
Tenant
  └── Management Group: Root
        ├── Management Group: Production
        │     └── Subscription: Prod
        │           ├── rg-app-prod
        │           └── rg-shared-prod
        └── Management Group: Non-Production
              ├── Subscription: Dev
              │     └── rg-app-dev
              └── Subscription: Staging
                    └── rg-app-staging
```

## So sánh Multi-Cloud

```
Azure                    AWS                       GCP                      OpenStack
─────                    ───                       ───                      ─────────
Tenant (Entra ID)   ≈   Organization         ≈   Organization         ≈   Domain
Management Group    ≈   OU (Org Unit)        ≈   Folder               ≈   — (không có)
Subscription        ≈   Account              ≈   Project              ≈   Project
Resource Group      ≈   — (tags/stacks)      ≈   — (labels)           ≈   — (không có)
Resource            ≈   Resource             ≈   Resource             ≈   Resource
```

### Điểm khác biệt chính

| Khía cạnh | Azure | AWS | GCP | OpenStack |
|---|---|---|---|---|
| **Ranh giới billing** | Subscription | Account | Project (Billing Account) | Không có billing built-in |
| **Nhóm resources** | Resource Group (first-class) | Tags / CloudFormation stacks (lỏng) | Labels (lỏng) | Không có |
| **Ranh giới identity** | Tenant (Entra ID) | Organization + IAM | Organization + Workspace | Domain (Keystone) |
| **Network isolation** | VNet (tạo thủ công, trong subscription) | VPC (mặc định theo region) | VPC (global, theo project) | Network (tự động theo project) |
| **Policy enforcement** | Azure Policy (mọi scope) | SCP (org/OU/account) | Org Policy (org/folder/project) | Oslo.policy (theo service) |
| **Độ sâu hierarchy** | 6 levels Management Groups | 5 levels OUs | 10 levels Folders | Phẳng (domain → project) |

### Pattern chung

Dù tên khác nhau, mọi cloud đều giải quyết cùng các bài toán tổ chức:

1. **Bạn là ai?** → Ranh giới identity (Tenant / Organization / Domain)
2. **Nhóm gì lại?** → Đơn vị tổ chức (Management Group / OU / Folder)
3. **Ai trả tiền?** → Ranh giới billing (Subscription / Account / Project)
4. **Tổ chức resources thế nào?** → Nhóm (Resource Group / Tags / Labels)
5. **Luật gì áp dụng?** → Policy (Azure Policy / SCP / Org Policy)
6. **Giới hạn bao nhiêu?** → Quota theo ranh giới billing

## Mẹo thực tế

1. **Bắt đầu đơn giản** — 1 subscription, vài resource groups. Thêm management groups khi thực sự cần.
2. **Resource Group = sandbox** — Tạo `rg-sandbox`, thử nghiệm, `az group delete --name rg-sandbox --yes`, không tốn tiền.
3. **Đặt tên nhất quán** — `rg-{app}-{env}` (ví dụ: `rg-myapp-prod`, `rg-myapp-dev`).
4. **Tách environment theo subscription** khi team lớn — billing rõ ràng, RBAC sạch hơn, khó phá prod hơn.
5. **RBAC đúng scope** — Đừng cho Contributor ở Subscription cho mọi người. Bắt đầu hẹp (Resource Group), mở rộng khi cần.
