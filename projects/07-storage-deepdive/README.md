# Project 07: Storage Deep-Dive

Touch những feature của Azure Storage mà projects 01-06 không đụng tới: lifecycle, blob versioning, soft delete, SAS, immutability, AzCopy. Cheap (<$0.10/day).

## Architecture

```
┌─────────── Storage Account (StorageV2, LRS) ───────────┐
│                                                         │
│  Blob service settings:                                 │
│    versioning_enabled = true                            │
│    change_feed_enabled = true                           │
│    delete_retention (blob)      = 7 days                │
│    container_delete_retention   = 7 days                │
│                                                         │
│  Containers:                                            │
│    logs/      ──── Lifecycle policy ────┐               │
│      private  (cool >30d, archive >90d, │               │
│                delete >365d)             │               │
│    public/    blob (anonymous read)      │               │
│    compliance/ private + immutability   │               │
│      (legal hold + time-based retention)│               │
│                                          │               │
│  SAS tokens (data source outputs):                      │
│    logs/ → read-only listable, 1 year   │               │
└─────────────────────────────────────────┘               │
                                                          │
  AzCopy commands documented in terraform README          │
```

## Learning Goals (AZ-104)

- **Storage tiers** — Hot / Cool / Cold / Archive, transition costs, retrieval times
- **Lifecycle Management** — `azurerm_storage_management_policy` with rules per prefix
- **Blob versioning + Change feed** — undelete via version restore
- **Soft delete** — accidental delete recovery (blob & container level)
- **SAS tokens** — Service vs Account SAS, permissions, IP/time scope
- **Immutability policies** — WORM (Write Once Read Many), legal hold vs time-based
- **AzCopy** — bulk upload/sync, faster than az CLI for large blobs
- **Redundancy options** — LRS / ZRS / GRS / RA-GRS / GZRS — when to use what

## Steps

### Step 1 — Bootstrap
- [ ] `cp terraform.tfvars.example terraform.tfvars`, fill subscription_id
- [ ] `terraform init && apply`
- [ ] Verify storage account + 3 containers + lifecycle policy

### Step 2 — Test soft delete recovery
- [ ] Upload a file: `az storage blob upload ...`
- [ ] Delete it: `az storage blob delete ...`
- [ ] List deleted: `az storage blob list ... --include d`
- [ ] Undelete: `az storage blob undelete ...`

### Step 3 — Test versioning
- [ ] Upload v1 → upload v2 (same blob name)
- [ ] List versions: `az storage blob list ... --include v`
- [ ] Restore v1 by copying old version over current

### Step 4 — Test SAS
- [ ] `terraform output -raw logs_sas_url` → save URL
- [ ] `curl <SAS_URL>` to list, then try write → 403 (read-only token)

### Step 5 — Lifecycle observation (cần đợi)
- [ ] Lifecycle rules chạy 1 lần/24h, không trigger ngay
- [ ] Force run (preview feature) hoặc đợi 1 ngày, kiểm tra blob có chuyển tier

### Step 6 — Immutability (portal walkthrough)
- [ ] Container `compliance` → Access policy → Add policy
- [ ] Time-based retention: 1 day (test), policy state: Locked? **đừng lock** (irreversible)
- [ ] Try delete blob → ✗ blocked

### Step 7 — AzCopy bulk upload
- [ ] Generate ~100 small files locally
- [ ] `azcopy login` rồi `azcopy sync ./local-dir 'https://<sa>.blob.core.windows.net/logs/'`
- [ ] So sánh tốc độ với `az storage blob upload-batch`

### Step 8 — Cleanup
- [ ] **Quan trọng**: nếu đã lock immutability → container không xoá được trong N ngày
- [ ] `terraform destroy` (sẽ fail nếu có locked policy → unlock manually first)

## Cloud Services Used

| Concept | Azure | AWS | GCP |
|---|---|---|---|
| Object storage | Blob Storage | S3 | Cloud Storage |
| Tiers | Hot/Cool/Cold/Archive | Standard/IA/Glacier | Standard/Nearline/Coldline/Archive |
| Lifecycle | Management policy | S3 Lifecycle | Object Lifecycle Management |
| Versioning | Blob versioning | S3 Versioning | Object Versioning |
| Soft delete | Blob/Container delete retention | S3 Versioning + MFA Delete | Bucket retention policy |
| Pre-signed URL | SAS token | S3 Presigned URL | Signed URL |
| WORM | Immutability policies | S3 Object Lock | Bucket Lock |
| Bulk transfer | AzCopy | aws s3 sync / DataSync | gsutil / Storage Transfer |

## Cost Notes

| Resource | Cost |
|---|---|
| Storage account | Free (account itself) |
| Hot tier blob storage | ~$0.018/GB/month |
| Cool tier | ~$0.01/GB/month |
| Archive tier | ~$0.002/GB/month (but slow rehydrate) |
| Operations | $0.005/10k reads, $0.065/10k writes |
| **Total for lab (~1GB hot)** | **~$0.001/day** — basically free |
