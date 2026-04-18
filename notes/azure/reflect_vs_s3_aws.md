# Azure Storage Account vs AWS S3 — Mental Model

## Quick Mapping

```
AWS                              Azure
───────────────────────────────────────────────────
(không có)                   →   Storage Account (layer bọc ngoài)
S3 Bucket                    →   Blob Container
S3 Object                    →   Blob
S3 Bucket Policy             →   Container Access Policy / RBAC
S3 Lifecycle Rules           →   Lifecycle Management
S3 Versioning                →   Blob Versioning
S3 Storage Classes           →   Access Tiers (Hot/Cool/Archive)
S3 Presigned URL             →   SAS Token
S3 Static Website            →   Static Website (trong Blob)
───────────────────────────────────────────────────
EFS                          →   Azure Files
SQS                          →   Queue Storage
DynamoDB (simple use)        →   Table Storage
```

## Key Difference

| AWS | Azure |
|-----|-------|
| Tạo S3 bucket trực tiếp | Phải tạo Storage Account trước, rồi mới tạo container |
| Mỗi bucket có settings riêng | Storage Account chứa settings chung cho tất cả services bên trong |
| Bucket name globally unique | Storage Account name globally unique |
| Bucket policy per bucket | RBAC có thể set ở account hoặc container level |

## Simple Mental Model

```
Storage Account = "Folder chứa nhiều S3 buckets + EFS + SQS + DynamoDB"
                   (1 account, 4 loại storage)

AWS: Mỗi service độc lập, tạo riêng
Azure: Gom vào 1 account, share settings (network, encryption, redundancy)
```

## Real-World Example

```
AWS:
  - s3://my-images-bucket        (tạo riêng)
  - s3://my-backup-bucket        (tạo riêng)  
  - EFS: my-team-share           (service khác)

Azure:
  - mystorageaccount
      ├── container: images      (như S3 bucket)
      ├── container: backups     (như S3 bucket)
      └── fileshare: team-share  (như EFS)
```

## Immutable vs Mutable Settings

**Không thể đổi sau khi tạo:**
- Storage Account name
- Location/Region
- Performance tier (Standard ↔ Premium)
- Hierarchical namespace (Data Lake Gen2)

**Có thể đổi sau:**
- Redundancy (LRS/ZRS/GRS) — có giới hạn
- Access tier (Hot/Cool)
- Network/Firewall rules
- Data protection (soft delete, versioning)
- Encryption settings

Tóm lại: **Name, Region, Performance tier** — chọn đúng từ đầu.
