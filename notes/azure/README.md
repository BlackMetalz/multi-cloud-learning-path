# Review khóa học https://www.udemy.com/course/70533-azure/
- Học khá là chán. Giờ mình đã quá lười, ko phù hợp ngồi xem video số lượng lớn. Học được 2-3 ngày liên tục xong bỏ gần 2 tuần mới mò lại tiếp.
- Video thì toàn tua nhanh

# Một vài note nhớ được trong quá trình tâm sự với AI, méo biết đúng hay sai nhưng cứ note tạm

### Azure Storage Account
Lý do Azure thêm Storage Account là vì nó gom nhiều dịch vụ vào 1 (Blob + File + Queue + Table), nên cần 1 cấp "tài khoản" chung. AWS/GCP thì tách hẳn ra (S3, EFS, SQS riêng từng service).

Subscription Owner ≠ Data plane access. Bro tạo được storage account (control plane via Microsoft.Storage/* permission từ Owner role), nhưng đọc/ghi blob (data plane) cần role riêng kiểu Storage Blob Data *.
Đây là pattern separation of management/data plane — câu hỏi quen thuộc trong AZ-104. Account key thì bypass RBAC nhưng dùng --auth-mode login (Azure AD) là best practice, audit được, revoke được. 

### Concept for AZ-104 unlocked in Phase 3 - fullstack app

- "How does an Azure App Service access Key Vault secrets without storing credentials?" → MI (Managed Identity) + Key Vault reference.
- "Difference between Owner role and Key Vault Administrator?" → Control plane (Owner = manage vault) vs data plane (KV Admin = manage secrets/keys/certs)
- "Subscription Owner có đọc được KV secret không?" → Không (Owner = control plane only). Phải có role data plane (Key Vault Secrets User/Officer/Administrator).
- Khi nào UAMI vs SAMI?" → Reuse identity giữa nhiều resources = UAMI. Throwaway 1-1 = SAMI.
- "Legacy access policy vs RBAC trên KV?" → RBAC mới hơn, AAD-based, granular hơn, Microsoft khuyên dùng. Bro đang dùng RBAC (rbac_authorization_enabled = true).