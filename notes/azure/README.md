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

### Concept for AZ-104 unlocked in Phase 4 - fullstack app
- "Subscription Owner có đọc được KV secret không?" → Không (Owner = control plane only). Phải có role data plane (Key Vault Secrets User/Officer/Administrator).
- Khi nào UAMI vs SAMI?" → Reuse identity giữa nhiều resources = UAMI. Throwaway 1-1 = SAMI.
- "Legacy access policy vs RBAC trên KV?" → RBAC mới hơn, AAD-based, granular hơn, Microsoft khuyên dùng. Bro đang dùng RBAC (rbac_authorization_enabled = true).

### Concept for AZ-104 unlocked in Phase 5 - fullstack app
- Where do you query App Service logs centrally across multiple apps?" → Log Analytics workspace + diagnostic setting
- "Difference between Activity Log and Diagnostic Logs?" → Activity = control plane (who created what), Diagnostic = resource-level (HTTP requests, blob reads). Cả 2 đều ship vào Log Analytics được
- "Cost driver chính của Log Analytics?" → GB ingested per day + retention days. Production hay dùng daily_quota_gb để cap

### Concept for AZ-104 unlocked in Phase 6 - psql

- "How to give an Azure VM/App Service access to Postgres without IP whitelisting?" → Private Endpoint + VNet integration
- "DBA cần đọc password Postgres để debug, không có quyền edit terraform — làm sao?" → KV access policy + role Key Vault Secrets User
- "Connection failure 'no pg_hba.conf entry'?" → Thường là firewall rule, không phải pg_hba (Azure managed file đó cho mình)
- "Single Server vs Flexible Server?" → Single deprecated 2025, Flexible mới hơn — luôn chọn Flexible

### Hub-spoke

hub-spoke là kiểu “một trung tâm, nhiều vệ tinh” để mạng Azure dễ quản lý, an toàn, và scale tốt hơn.

Ví dụ:
- Web app ở 1 spoke.
- Database ở 1 spoke khác.
- Firewall, VPN, DNS nằm ở hub.

Khi web app muốn nói chuyện với database:
- Nó không “quẹo” qua hết các mạng khác.
- Nó đi qua hub, rồi hub kiểm soát xem có cho phép không.

Vì sao người ta thích kiểu này
- Dễ quản lý: mọi thứ quan trọng gom về một chỗ.
- An toàn hơn: hub đứng giữa để chặn/lọc traffic.
- Dễ mở rộng: có thêm app mới thì thêm 1 spoke mới, không làm rối toàn mạng.
- Hợp cho công ty lớn: nhiều team, nhiều môi trường, nhiều app.

Túm cái váy lại: Hub-spoke = 1 trung tâm quản lý + nhiều mạng con tách biệt. Giống như một thành phố có đường vành đai và các khu dân cư nối vào trung tâm, chứ không cần mọi khu nối trực tiếp với nhau.

