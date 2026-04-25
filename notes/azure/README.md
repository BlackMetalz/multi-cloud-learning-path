# Review khóa học https://www.udemy.com/course/70533-azure/
- Học khá là chán. Giờ mình đã quá lười, ko phù hợp ngồi xem video số lượng lớn. Học được 2-3 ngày liên tục xong bỏ gần 2 tuần mới mò lại tiếp.
- Video thì toàn tua nhanh

# Một vài note nhớ được trong quá trình tâm sự với AI, méo biết đúng hay sai nhưng cứ note tạm

### Azure Storage Account
Lý do Azure thêm Storage Account là vì nó gom nhiều dịch vụ vào 1 (Blob + File + Queue + Table), nên cần 1 cấp "tài khoản" chung. AWS/GCP thì tách hẳn ra (S3, EFS, SQS riêng từng service).

Subscription Owner ≠ Data plane access. Bro tạo được storage account (control plane via Microsoft.Storage/* permission từ Owner role), nhưng đọc/ghi blob (data plane) cần role riêng kiểu Storage Blob Data *.
Đây là pattern separation of management/data plane — câu hỏi quen thuộc trong AZ-104. Account key thì bypass RBAC nhưng dùng --auth-mode login (Azure AD) là best practice, audit được, revoke được. 