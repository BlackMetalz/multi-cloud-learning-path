# Azure Storage — Quick Reference

## Storage Account Types

| Type | Use case | Supports |
|------|----------|----------|
| **Standard general-purpose v2** (GPv2) | Default, hầu hết mọi thứ | Blob, File, Queue, Table |
| **Premium block blobs** | Latency thấp, I/O cao (logs, analytics) | Block Blob only |
| **Premium file shares** | SMB/NFS high-perf | Azure Files only |
| **Premium page blobs** | VM unmanaged disk | Page Blob only |

> Đề hỏi "lowest latency" hoặc "high-throughput" → Premium. Hỏi "most services" → GPv2.

---

## Storage Services

| Service | Dùng cho | AWS tương đương |
|---------|----------|-----------------|
| **Blob Storage** | Object (images, video, backup) | S3 |
| **Azure Files** | SMB/NFS file share (mount được) | EFS |

> **Azure Files — port 445:** dùng SMB protocol (Server Message Block) qua **port 445**. Nếu mount từ máy tính cá nhân/home network thì ISP của user phải **mở port 445** — nhiều ISP block port này mặc định. Đây là lý do phổ biến khiến mount Azure File Share từ nhà thất bại dù config đúng.
| **Queue Storage** | Message queue (async decoupling) | SQS |
| **Table Storage** | NoSQL key-value (schema-less) | DynamoDB (basic) |
| **Disk Storage** | Managed disk cho VM | EBS |

---

## Replication Types

### Trong 1 region

| Type | Copies | Protect against |
|------|--------|-----------------|
| **LRS** (Locally Redundant) | 3 copies, 1 datacenter | Hardware failure |
| **ZRS** (Zone Redundant) | 3 copies, 3 zones | Datacenter / zone failure |

### Cross-region

| Type | Copies | Protect against | Read từ secondary? |
|------|--------|-----------------|---------------------|
| **GRS** (Geo-Redundant) | 6 copies (3+3), 2 regions | Region failure | Không (read-only khi failover) |
| **RA-GRS** (Read-Access GRS) | 6 copies, 2 regions | Region failure | **Có** (luôn luôn) |
| **GZRS** | ZRS primary + LRS secondary | Zone + region failure | Không |
| **RA-GZRS** | ZRS primary + LRS secondary | Zone + region failure | **Có** |

### Chọn replication theo keyword

| Keyword trong đề | Chọn |
|-----------------|------|
| Disk/hardware failure, cheapest | **LRS** |
| Zone failure, within region | **ZRS** |
| Region down, data still available | **GRS** (nếu không cần đọc liên tục) |
| Region down + đọc được secondary liên tục | **RA-GRS** |
| Zone + region, highest availability | **RA-GZRS** |
| "available even if a region goes down" + "cost-effective" | **GRS** |

> **Bẫy exam:** "highest availability **within** a region" → **ZRS**, không phải GRS. GRS là cross-region.

> **Câu trong hình:** data available nếu region down + cost-effective → **GRS** (không cần read secondary liên tục, RA-GRS đắt hơn).

---

## Blob Access Tiers

| Tier | Dùng cho | Storage cost | Access cost |
|------|----------|-------------|-------------|
| **Hot** | Data truy cập thường xuyên | Cao | Thấp |
| **Cool** | Ít truy cập (≥ 30 ngày) | Thấp | Cao hơn |
| **Cold** | Rất ít truy cập (≥ 90 ngày) | Rất thấp | Cao |
| **Archive** | Offline, restore mất giờ (≥ 180 ngày) | Rẻ nhất | Đắt nhất + rehydrate time |

> Archive blob phải **rehydrate** (chuyển sang Hot/Cool) trước khi đọc được — mất vài giờ.
>
> Lifecycle Management Policy tự động chuyển tier theo tuổi blob.

---

## Blob Types

| Type | Dùng cho |
|------|----------|
| **Block Blob** | Files, images, video (default) |
| **Append Blob** | Logging (append-only) |
| **Page Blob** | VHD, random read/write (VM disk) |

---

## Access Control

| Method | Mô tả |
|--------|-------|
| **Storage Account Key** | Full access, dùng cho admin/automation |
| **SAS (Shared Access Signature)** | Token giới hạn permission + thời gian |
| **Azure AD / RBAC** | Recommended, role-based |
| **Anonymous public access** | Blob-level, cần bật tường minh |

**SAS types:**
- **Account SAS** — access nhiều service
- **Service SAS** — access 1 service cụ thể
- **User delegation SAS** — backed by Azure AD, an toàn nhất

---

## Networking & Security

- **Firewall rules** — giới hạn IP/VNet được phép truy cập storage account
- **Private Endpoint** — storage account có private IP trong VNet, traffic không ra internet
- **Secure transfer required** — bắt buộc HTTPS (bật mặc định)
- **Soft delete** — giữ blob đã xóa N ngày trước khi xóa hẳn (chống xóa nhầm)
- **Versioning** — lưu mọi version của blob
- **Immutable storage (WORM)** — Write Once Read Many, không ai xóa/sửa được trong retention period

---

## Lifecycle Management

```
Rule: nếu blob không được access 30 ngày → move to Cool
      nếu 90 ngày → move to Archive
      nếu 180 ngày → delete
```

Áp dụng tự động, giảm chi phí mà không cần code.

---

## Exam Tricks tổng hợp

| Tình huống | Đáp án |
|-----------|--------|
| "Protect against datacenter failure, same region" | ZRS |
| "Protect against region failure, cost-effective" | GRS |
| "Read from secondary at all times" | RA-GRS hoặc RA-GZRS |
| "Data cannot be deleted/modified for compliance" | Immutable storage (WORM) |
| "Automatically move old data to cheaper tier" | Lifecycle Management Policy |
| "Share files between VMs (SMB)" | Azure Files |
| "Store VM disk" | Managed Disk (Premium SSD/Standard SSD/HDD) |
| "Cheapest storage for rarely accessed archived data" | Archive tier |
| "Restore accidentally deleted blob" | Soft Delete |
| "Grant temp access to a specific blob without sharing key" | SAS token |
