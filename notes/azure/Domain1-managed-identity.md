# Domain 1 — Managed Identity

## System-Assigned (SAMI) vs User-Assigned (UAMI)

| | SAMI | UAMI |
|---|---|---|
| Lifecycle | Gắn với resource, xóa resource thì xóa MI | Độc lập, tồn tại sau khi resource bị xóa |
| Reuse | 1 resource → 1 identity | 1 identity → nhiều resource |
| Khi nào dùng | Throwaway, 1-1 với VM/App Service | Reuse identity giữa nhiều resource |

**Rule nhớ nhanh:** UAMI khi cần share identity. SAMI khi đơn giản 1-1.

## Control Plane vs Data Plane (hay xuất hiện trong đề)

```
Subscription Owner
├── Control plane: tạo/xóa/manage resource (Microsoft.Storage/*, Microsoft.KeyVault/*)
└── Data plane: KHÔNG có — phải assign role riêng

Ví dụ:
- Owner tạo được Storage Account ✓
- Owner đọc blob → cần role "Storage Blob Data Reader" ✓
- Owner tạo được Key Vault ✓
- Owner đọc secret → cần role "Key Vault Secrets User" ✓
```

## Managed Identity + Key Vault (pattern hay thi)

```
App Service → [System-Assigned MI] → Key Vault Reference → Secret
```

Setup:
1. Enable SAMI trên App Service
2. Assign role `Key Vault Secrets User` cho MI trên KV
3. App setting dùng `@Microsoft.KeyVault(SecretUri=...)`

Không cần store credentials anywhere — MI tự lấy token từ Azure AD.

## Key Vault Access Models

| Model | Đặc điểm |
|---|---|
| Legacy Access Policy | Flat list, per-object permission, không audit tốt |
| RBAC (mới) | Azure AD-based, granular, Microsoft khuyên dùng |

**Exam:** Nếu đề hỏi "best practice" → chọn RBAC.

## Exam Gotchas

- `Subscription Owner ≠ đọc được KV secret` → Owner chỉ có control plane
- `Key Vault Administrator` = quản lý vault cấu hình (control plane), không phải đọc secret (data plane)
- Xóa SAMI → mất access ngay. Xóa UAMI → mất access nhưng identity vẫn tồn tại nếu có resource khác dùng
