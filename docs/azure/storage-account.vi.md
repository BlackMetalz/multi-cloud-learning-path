# Azure Storage Account — Điểm vào cho mọi Storage Service

## Storage Account là gì?

Storage Account là 1 namespace duy nhất trên Azure chứa tất cả storage services. Hiểu đơn giản là "ô dù storage" — tạo 1 account, bên trong có nhiều loại storage.

```
Storage Account (mystorageaccount.blob.core.windows.net)
  ├── Blob Storage (Containers)         Object storage (file, ảnh, backup...)
  │     ├── container: images/
  │     ├── container: backups/
  │     └── container: logs/
  ├── File Storage (File Shares)        Network drive (SMB/NFS)
  │     └── share: team-docs/
  ├── Queue Storage                     Message queue đơn giản
  │     └── queue: task-queue
  └── Table Storage                     NoSQL key-value đơn giản
        └── table: user-sessions
```

**Đây là điểm riêng của Azure.** AWS và GCP không có layer bọc ngoài này — tạo S3 bucket hay Cloud Storage bucket trực tiếp. Ở Azure, phải tạo Storage Account trước, rồi mới tạo blob/file/queue bên trong.

## 4 loại Storage bên trong

### 1. Blob Storage — dùng nhiều nhất

"Blob" = Binary Large Object. Lưu file bất kỳ: ảnh, video, PDF, log, backup, static website.

```
Storage Account
  └── Container (giống folder/bucket)
        └── Blob (file thực tế)
```

**3 access tier** — dựa theo tần suất truy cập:

| Tier | Use case | Chi phí lưu trữ | Chi phí truy cập |
|---|---|---|---|
| **Hot** | Data truy cập thường xuyên | Cao nhất | Thấp nhất |
| **Cool** | Ít truy cập (>30 ngày) | Thấp hơn | Cao hơn |
| **Archive** | Hiếm khi truy cập (>180 ngày) | Rẻ nhất | Đắt nhất (mất hàng giờ để lấy ra) |

```bash
# Tạo container
az storage container create \
  --account-name mystorageaccount \
  --name images

# Upload file
az storage blob upload \
  --account-name mystorageaccount \
  --container-name images \
  --file ./photo.jpg \
  --name photo.jpg

# Liệt kê blobs
az storage blob list \
  --account-name mystorageaccount \
  --container-name images \
  --output table

# Download
az storage blob download \
  --account-name mystorageaccount \
  --container-name images \
  --name photo.jpg \
  --file ./downloaded.jpg

# Đổi tier
az storage blob set-tier \
  --account-name mystorageaccount \
  --container-name images \
  --name photo.jpg \
  --tier Cool
```

### 2. File Storage — ổ mạng trên cloud

Azure Files cung cấp file share qua SMB và NFS. Mount được trên VM hoặc máy local như ổ mạng.

```bash
# Tạo file share
az storage share create \
  --account-name mystorageaccount \
  --name team-docs \
  --quota 10   # 10 GB

# Upload file
az storage file upload \
  --account-name mystorageaccount \
  --share-name team-docs \
  --source ./report.pdf

# Mount trên Linux VM
sudo mount -t cifs \
  //mystorageaccount.file.core.windows.net/team-docs \
  /mnt/team-docs \
  -o username=mystorageaccount,password=<storage-key>
```

### 3. Queue Storage — messaging async đơn giản

Message queue nhẹ. Mỗi message tối đa 64KB. Tốt cho việc tách rời services.

```bash
# Tạo queue
az storage queue create \
  --account-name mystorageaccount \
  --name task-queue

# Gửi message
az storage message put \
  --account-name mystorageaccount \
  --queue-name task-queue \
  --content "process-image:photo.jpg"

# Đọc message (peek, không xoá)
az storage message peek \
  --account-name mystorageaccount \
  --queue-name task-queue
```

Nếu cần messaging phức tạp hơn (topics, subscriptions, dead-letter), dùng **Azure Service Bus**.

### 4. Table Storage — NoSQL đơn giản

Key-value store cho structured data. Rẻ, nhanh, không cần schema. Tốt cho logs, user sessions, metadata đơn giản.

Nếu cần query phức tạp, relationships, hay global distribution, dùng **Cosmos DB**.

## Cấu hình Storage Account

Khi tạo Storage Account, bạn chọn:

### Performance Tier

| Tier | Sử dụng | Use case |
|---|---|---|
| **Standard** | HDD | Đa dụng, tiết kiệm |
| **Premium** | SSD | Latency thấp, throughput cao (databases, analytics) |

### Redundancy (bao nhiêu bản sao data)

| Option | Bản sao | Ở đâu | Durability |
|---|---|---|---|
| **LRS** (Locally Redundant) | 3 | Cùng datacenter | 11 nines |
| **ZRS** (Zone Redundant) | 3 | 3 availability zones cùng region | 12 nines |
| **GRS** (Geo Redundant) | 6 | 3 local + 3 ở paired region | 16 nines |
| **GZRS** (Geo-Zone Redundant) | 6 | 3 zones + 3 ở paired region | 16 nines |

**Nguyên tắc chọn:**
- Học/dev → **LRS** (rẻ nhất)
- Production → **ZRS** tối thiểu
- Data quan trọng → **GRS** hoặc **GZRS**

### Account Kind

| Kind | Hỗ trợ gì |
|---|---|
| **StorageV2** (General Purpose v2) | Mọi thứ. Luôn dùng cái này. |
| BlobStorage | Chỉ Blob. Legacy, đừng dùng. |
| StorageV1 | Phiên bản cũ. Đừng dùng. |

Luôn dùng **StorageV2**. Không cần nghĩ.

## Tạo Storage Account

```bash
# Tạo storage account (Standard, LRS, StorageV2)
az storage account create \
  --resource-group rg-myapp \
  --name mystorageaccount \
  --sku Standard_LRS \
  --kind StorageV2 \
  --location southeastasia

# Liệt kê storage accounts
az storage account list --resource-group rg-myapp --output table

# Xem chi tiết
az storage account show --resource-group rg-myapp --name mystorageaccount

# Lấy access keys
az storage account keys list --resource-group rg-myapp --name mystorageaccount

# Lấy connection string (cho app)
az storage account show-connection-string --resource-group rg-myapp --name mystorageaccount
```

## Quản lý truy cập

Nhiều cách kiểm soát ai được truy cập storage:

| Phương thức | Cách hoạt động | Khi nào dùng |
|---|---|---|
| **Access Keys** | 2 keys mỗi account, full quyền | Script nhanh, KHÔNG dùng production |
| **SAS Token** | Token có phạm vi (giới hạn thời gian, quyền cụ thể) | Chia sẻ file cho người ngoài |
| **Entra ID (RBAC)** | Phân quyền qua Azure AD | Production, team access |
| **Container access level** | Public read cho blobs/container | Static website, public assets |

```bash
# Tạo SAS token (chỉ đọc, hết hạn trong 1 ngày)
az storage container generate-sas \
  --account-name mystorageaccount \
  --name images \
  --permissions r \
  --expiry 2026-12-31 \
  --output tsv
```

## Network Security

Kiểm soát truy cập storage ở tầng network.

| Option | Mô tả |
|---|---|
| **Public endpoint** | Mặc định. Truy cập được từ internet. |
| **Service Endpoint** | Traffic đi qua Azure backbone, vẫn dùng public IP |
| **Private Endpoint** | Có private IP trong VNet. Không expose ra ngoài. |
| **Firewall** | Whitelist IP hoặc VNet cụ thể |

```bash
# Chặn public access mặc định
az storage account update \
  --resource-group rg-myapp \
  --name mystorageaccount \
  --default-action Deny

# Cho phép VNet cụ thể
az storage account network-rule add \
  --resource-group rg-myapp \
  --account-name mystorageaccount \
  --vnet-name myVnet \
  --subnet default

# Cho phép IP cụ thể
az storage account network-rule add \
  --resource-group rg-myapp \
  --account-name mystorageaccount \
  --ip-address 203.0.113.0/24
```

**Production:** Dùng Private Endpoint + Firewall. Đừng để public access mở.

## Data Protection

Bảo vệ khỏi xóa nhầm và hỏng data.

| Feature | Mô tả |
|---|---|
| **Soft delete** | Khôi phục blob/container đã xóa (1-365 ngày) |
| **Versioning** | Giữ mọi phiên bản của blob tự động |
| **Point-in-time restore** | Rollback container về thời điểm cụ thể |
| **Immutable storage** | WORM — data không thể sửa/xóa (compliance) |

```bash
# Bật soft delete cho blobs (7 ngày)
az storage account blob-service-properties update \
  --resource-group rg-myapp \
  --account-name mystorageaccount \
  --enable-delete-retention true \
  --delete-retention-days 7

# Bật versioning
az storage account blob-service-properties update \
  --resource-group rg-myapp \
  --account-name mystorageaccount \
  --enable-versioning true

# Bật soft delete cho containers
az storage account blob-service-properties update \
  --resource-group rg-myapp \
  --account-name mystorageaccount \
  --enable-container-delete-retention true \
  --container-delete-retention-days 7
```

## Encryption

Mọi data đều được mã hóa. Bạn chọn ai quản lý key.

| Option | Key do ai quản lý | Khi nào dùng |
|---|---|---|
| **Microsoft-managed keys** | Azure (mặc định) | Đa số workloads |
| **Customer-managed keys (CMK)** | Bạn (qua Key Vault) | Compliance, cần toàn quyền |
| **Infrastructure encryption** | Mã hóa 2 lớp | Bảo mật cao hơn |

```bash
# Xem encryption hiện tại
az storage account show \
  --resource-group rg-myapp \
  --name mystorageaccount \
  --query encryption

# Bắt buộc HTTPS (mã hóa in transit)
az storage account update \
  --resource-group rg-myapp \
  --name mystorageaccount \
  --https-only true
```

In-transit: Luôn dùng HTTPS. Azure bật mặc định cho accounts mới.

## Stored Access Policies

Định nghĩa policy có thể tái sử dụng cho SAS tokens. Có thể thu hồi quyền mà không cần đổi key.

```bash
# Tạo policy trên container
az storage container policy create \
  --account-name mystorageaccount \
  --container-name images \
  --name readonly-policy \
  --permissions r \
  --expiry 2026-12-31

# Tạo SAS dùng policy
az storage container generate-sas \
  --account-name mystorageaccount \
  --name images \
  --policy-name readonly-policy \
  --output tsv

# Thu hồi quyền bằng cách xóa policy
az storage container policy delete \
  --account-name mystorageaccount \
  --container-name images \
  --name readonly-policy
```

**Tại sao dùng policy?**
- Thu hồi SAS token mà không cần xoay account key
- Quản lý tập trung permissions và expiry
- Tối đa 5 policies mỗi container

## Lifecycle Management

Tự động chuyển tier hoặc xóa blobs theo tuổi. Tiết kiệm chi phí.

```bash
# Tạo lifecycle policy (Cool sau 30 ngày, Archive sau 90, xóa sau 365)
az storage account management-policy create \
  --account-name mystorageaccount \
  --resource-group rg-myapp \
  --policy @policy.json
```

Ví dụ `policy.json`:
```json
{
  "rules": [{
    "name": "aging-rule",
    "type": "Lifecycle",
    "definition": {
      "filters": { "blobTypes": ["blockBlob"] },
      "actions": {
        "baseBlob": {
          "tierToCool": { "daysAfterModificationGreaterThan": 30 },
          "tierToArchive": { "daysAfterModificationGreaterThan": 90 },
          "delete": { "daysAfterModificationGreaterThan": 365 }
        }
      }
    }
  }]
}
```

## AzCopy

CLI tool copy data nhanh. Nhanh hơn `az storage blob upload` nhiều.

```bash
# Tải AzCopy
curl -L https://aka.ms/downloadazcopy-v10-linux | tar xz

# Login (mở browser)
azcopy login

# Upload folder
azcopy copy "./local-folder" "https://mystorageaccount.blob.core.windows.net/container" --recursive

# Download folder
azcopy copy "https://mystorageaccount.blob.core.windows.net/container" "./local" --recursive

# Sync (như rsync)
azcopy sync "./local-folder" "https://mystorageaccount.blob.core.windows.net/container"
```

## Static Website Hosting

Blob Storage có thể host static website trực tiếp — không cần web server.

```bash
# Bật static website
az storage blob service-properties update \
  --account-name mystorageaccount \
  --static-website \
  --index-document index.html \
  --404-document 404.html

# Upload website files vào container $web (tự động tạo)
az storage blob upload-batch \
  --account-name mystorageaccount \
  --destination '$web' \
  --source ./build/

# Website live tại:
# https://mystorageaccount.z23.web.core.windows.net
```

## So sánh Multi-Cloud

| Concept | Azure | AWS | GCP |
|---|---|---|---|
| Account/wrapper | Storage Account | — (không có) | — (không có) |
| Object storage | Blob Container | S3 Bucket | Cloud Storage Bucket |
| Access tiers | Hot / Cool / Archive | Standard / IA / Glacier | Standard / Nearline / Coldline / Archive |
| File share | Azure Files | EFS | Filestore |
| Simple queue | Queue Storage | SQS | Pub/Sub |
| Static website | Blob static website | S3 static website | Cloud Storage static website |
| Redundancy | LRS / ZRS / GRS / GZRS | Same region / Cross-region replication | Single / Dual / Multi-region |

Điểm khác biệt chính: Azure gom tất cả storage types vào 1 account. AWS/GCP coi mỗi loại là service độc lập.

## Khi nào dùng gì

```
Cần lưu file (ảnh, backup, log)?
  → Blob Storage

Cần ổ mạng chung cho VMs hoặc team?
  → Azure Files

Cần messaging async đơn giản giữa services?
  → Queue Storage (đơn giản) hoặc Service Bus (nâng cao)

Cần NoSQL rẻ cho data đơn giản?
  → Table Storage (đơn giản) hoặc Cosmos DB (nâng cao)

Cần host static website?
  → Blob Storage (tính năng static website)
```
