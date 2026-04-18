# VM Disk Encryption

| Type | Là gì | Khi nào dùng |
|------|-------|--------------|
| **SSE** (Server-Side Encryption) | Azure tự encrypt ở storage layer | Mặc định, không cần làm gì |
| **ADE** (Azure Disk Encryption) | Encrypt trong OS (BitLocker/DM-Crypt), key ở Key Vault | Compliance yêu cầu OS-level encryption |

**Verdict:** SSE đủ cho hầu hết. ADE chỉ khi compliance bắt buộc.
