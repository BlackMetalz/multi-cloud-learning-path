# Azure Storage Account — The Entry Point to All Storage Services

## What is a Storage Account?

A Storage Account is a unique namespace in Azure that contains all your storage services. Think of it as a "storage umbrella" — you create one account, and inside it you get access to multiple storage types.

```
Storage Account (mystorageaccount.blob.core.windows.net)
  ├── Blob Storage (Containers)         Object storage (files, images, backups...)
  │     ├── container: images/
  │     ├── container: backups/
  │     └── container: logs/
  ├── File Storage (File Shares)        Network drive (SMB/NFS)
  │     └── share: team-docs/
  ├── Queue Storage                     Simple message queue
  │     └── queue: task-queue
  └── Table Storage                     Simple NoSQL key-value store
        └── table: user-sessions
```

**This is unique to Azure.** AWS and GCP don't have this wrapper — you create S3 buckets or Cloud Storage buckets directly. In Azure, you must create a Storage Account first, then create blobs/files/queues inside it.

## The 4 Storage Types Inside

### 1. Blob Storage — the one you'll use most

"Blob" = Binary Large Object. Store any file: images, videos, PDFs, logs, backups, static websites.

```
Storage Account
  └── Container (like a folder/bucket)
        └── Blob (the actual file)
```

**3 access tiers** — based on how often you read the data:

| Tier | Use case | Storage cost | Access cost |
|---|---|---|---|
| **Hot** | Frequently accessed data | Highest | Lowest |
| **Cool** | Infrequently accessed (>30 days) | Lower | Higher |
| **Archive** | Rarely accessed (>180 days) | Cheapest | Highest (hours to retrieve) |

```bash
# Create a container
az storage container create \
  --account-name mystorageaccount \
  --name images

# Upload a file
az storage blob upload \
  --account-name mystorageaccount \
  --container-name images \
  --file ./photo.jpg \
  --name photo.jpg

# List blobs
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

# Set blob tier
az storage blob set-tier \
  --account-name mystorageaccount \
  --container-name images \
  --name photo.jpg \
  --tier Cool
```

### 2. File Storage — network drive in the cloud

Azure Files provides SMB and NFS file shares. Mount it on VMs or even your local machine like a network drive.

```bash
# Create a file share
az storage share create \
  --account-name mystorageaccount \
  --name team-docs \
  --quota 10   # 10 GB

# Upload a file
az storage file upload \
  --account-name mystorageaccount \
  --share-name team-docs \
  --source ./report.pdf

# Mount on Linux VM
sudo mount -t cifs \
  //mystorageaccount.file.core.windows.net/team-docs \
  /mnt/team-docs \
  -o username=mystorageaccount,password=<storage-key>
```

### 3. Queue Storage — simple async messaging

Lightweight message queue. Each message up to 64KB. Good for decoupling services.

```bash
# Create a queue
az storage queue create \
  --account-name mystorageaccount \
  --name task-queue

# Send a message
az storage message put \
  --account-name mystorageaccount \
  --queue-name task-queue \
  --content "process-image:photo.jpg"

# Read messages (peek, don't delete)
az storage message peek \
  --account-name mystorageaccount \
  --queue-name task-queue
```

For complex messaging (topics, subscriptions, dead-letter), use **Azure Service Bus** instead.

### 4. Table Storage — simple NoSQL

Key-value store for structured data. Cheap, fast, no schema required. Good for logs, user sessions, simple metadata.

For complex queries, relationships, or global distribution, use **Cosmos DB** instead.

## Storage Account Settings

When creating a Storage Account, you choose:

### Performance Tier

| Tier | Backed by | Use case |
|---|---|---|
| **Standard** | HDD | General purpose, cost-effective |
| **Premium** | SSD | Low latency, high throughput (databases, analytics) |

### Redundancy (how many copies of your data)

| Option | Copies | Where | Durability |
|---|---|---|---|
| **LRS** (Locally Redundant) | 3 | Same datacenter | 11 nines |
| **ZRS** (Zone Redundant) | 3 | 3 availability zones in same region | 12 nines |
| **GRS** (Geo Redundant) | 6 | 3 local + 3 in paired region | 16 nines |
| **GZRS** (Geo-Zone Redundant) | 6 | 3 zones + 3 in paired region | 16 nines |

**Rule of thumb:**
- Learning/dev → **LRS** (cheapest)
- Production → **ZRS** minimum
- Critical data → **GRS** or **GZRS**

### Account Kind

| Kind | What it supports |
|---|---|
| **StorageV2** (General Purpose v2) | Everything. Always use this. |
| BlobStorage | Blob only. Legacy, don't use. |
| StorageV1 | Old version. Don't use. |

Just use **StorageV2**. Always.

## Creating a Storage Account

```bash
# Create storage account (Standard, LRS, StorageV2)
az storage account create \
  --resource-group rg-myapp \
  --name mystorageaccount \
  --sku Standard_LRS \
  --kind StorageV2 \
  --location southeastasia

# List storage accounts
az storage account list --resource-group rg-myapp --output table

# Show details
az storage account show --resource-group rg-myapp --name mystorageaccount

# Get access keys
az storage account keys list --resource-group rg-myapp --name mystorageaccount

# Get connection string (for apps)
az storage account show-connection-string --resource-group rg-myapp --name mystorageaccount
```

## Access Control

Multiple ways to control who can access your storage:

| Method | How | When to use |
|---|---|---|
| **Access Keys** | 2 keys per account, full access | Quick scripts, NOT production |
| **SAS Token** | Scoped token (time-limited, specific permissions) | Sharing files with external users |
| **Entra ID (RBAC)** | Role-based access via Azure AD | Production, team access |
| **Container access level** | Public read for blobs/container | Static websites, public assets |

```bash
# Generate SAS token (read-only, expires in 1 day)
az storage container generate-sas \
  --account-name mystorageaccount \
  --name images \
  --permissions r \
  --expiry 2026-12-31 \
  --output tsv
```

## Static Website Hosting

Blob Storage can serve static websites directly — no web server needed.

```bash
# Enable static website
az storage blob service-properties update \
  --account-name mystorageaccount \
  --static-website \
  --index-document index.html \
  --404-document 404.html

# Upload website files to $web container (auto-created)
az storage blob upload-batch \
  --account-name mystorageaccount \
  --destination '$web' \
  --source ./build/

# Your site is live at:
# https://mystorageaccount.z23.web.core.windows.net
```

## Multi-Cloud Comparison

| Concept | Azure | AWS | GCP |
|---|---|---|---|
| Account/wrapper | Storage Account | — (none) | — (none) |
| Object storage | Blob Container | S3 Bucket | Cloud Storage Bucket |
| Access tiers | Hot / Cool / Archive | Standard / IA / Glacier | Standard / Nearline / Coldline / Archive |
| File share | Azure Files | EFS | Filestore |
| Simple queue | Queue Storage | SQS | Pub/Sub |
| Static website | Blob static website | S3 static website | Cloud Storage static website |
| Redundancy options | LRS / ZRS / GRS / GZRS | Same region / Cross-region replication | Single / Dual / Multi-region |

Key difference: Azure groups all storage types under one account. AWS/GCP treat each as independent services.

## When to Use What

```
Need to store files (images, backups, logs)?
  → Blob Storage

Need a shared drive for VMs or teams?
  → Azure Files

Need simple async messaging between services?
  → Queue Storage (simple) or Service Bus (advanced)

Need cheap NoSQL for simple data?
  → Table Storage (simple) or Cosmos DB (advanced)

Need to host a static website?
  → Blob Storage (static website feature)
```
