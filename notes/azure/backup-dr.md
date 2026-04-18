# Azure Backup & DR — Quick Mapping từ AWS

## Quick Mapping

```
AWS                              Azure
───────────────────────────────────────────────────
AWS Backup                   →   Azure Backup
Backup Vault                 →   Recovery Services Vault
AWS DRS / CloudEndure        →   Azure Site Recovery (ASR)
EBS Snapshots                →   VM Backup (disk snapshots)
```

## 2 Services

| Service | Làm gì |
|---------|--------|
| **Azure Backup** | Backup VMs, databases, files (daily, point-in-time) |
| **ASR** (Site Recovery) | Replicate VMs sang region khác, failover khi DR |

**Verdict:** Azure Backup = AWS Backup, ASR = DRS.
