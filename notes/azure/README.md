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

### Resource project 02 - hub and spoke
Hub-Spoke project — sẽ tạo những gì
Sơ đồ tổng thể

┌─────────────────────── Resource Group: rg-<project> ───────────────────────┐
│                                                                            │
│   ┌─────── VNet HUB (vnet-hub) ───────┐    ┌── VNet SPOKE (vnet-spoke) ──┐ │
│   │                                   │    │                             │ │
│   │  AzureBastionSubnet ─── Bastion   │◄──►│  snet-vm  ─── VM (Ubuntu)   │ │
│   │       (+ Public IP)               │peer│              + NIC + NSG    │ │
│   │                                   │    │                             │ │
│   │  snet-appgw ─── App Gateway v2    │    │  snet-pe  ─── PrivateEndpoint─→ Storage Account
│   │              (+ Public IP)        │    │              + Private DNS  │ │   (public access OFF)
│   └───────────────────────────────────┘    └─────────────────────────────┘ │
│                                                                            │
│   Log Analytics Workspace ◄── Diagnostic settings (NSG, AppGW)             │
└────────────────────────────────────────────────────────────────────────────┘


Liệt kê resource theo file:

`main.tf` — foundation
- random_string.suffix — 6 ký tự random, để tên storage account globally unique.
- data.azurerm_client_config — đọc tenant/subscription hiện tại.
- data.http.myip — gọi api.ipify.org lấy public IP của bro → nhét vào NSG cho phép SSH.
- azurerm_resource_group.main — RG chứa tất cả.

`network.tf` — xương sống
- 2 VNet: vnet-hub, vnet-spoke.
- 4 Subnet: AzureBastionSubnet, snet-appgw (trong hub) | snet-vm, snet-pe (trong spoke; PE subnet tắt network policies).
- 2 VNet Peering (hub↔spoke, 2 chiều).
- 1 NSG trên snet-vm với 3 rule: SSH từ IP của bro, HTTP từ VirtualNetwork, HTTP từ GatewayManager (cho AppGW probe).
- 1 association NSG ↔ subnet vm.

`vm.tf` — workload
- tls_private_key — sinh SSH key 4096-bit (không dùng ~/.ssh của máy).
- azurerm_network_interface — NIC private-only, không public IP.
- azurerm_linux_virtual_machine — Ubuntu 24.04, var.vm_size, cloud-init cài nginx + landing page, SystemAssigned identity.

`bastion.tf` — toggle enable_bastion
- azurerm_public_ip (Standard, Static).
- azurerm_bastion_host SKU Basic — SSH/RDP qua portal, không cần public IP trên VM.

`appgw.tf` — toggle enable_app_gateway
- azurerm_public_ip cho AppGW.
- azurerm_application_gateway Standard_v2 (capacity 1) — listener HTTP:80 → backend pool là private IP của VM.

`storage.tf` + `private_endpoint.tf` — private storage
- azurerm_storage_account Standard_LRS, public_network_access_enabled = false → chỉ vào được qua PE.
- azurerm_private_dns_zone privatelink.blob.core.windows.net.
- azurerm_private_dns_zone_virtual_network_link — gắn DNS zone vào spoke VNet.
- azurerm_private_endpoint — PE cho subresource blob, auto register vào private DNS zone.


`monitor.tf` — observability
- azurerm_log_analytics_workspace (PerGB2018).
- azurerm_monitor_diagnostic_setting cho NSG (luôn bật) và AppGW (chỉ khi enable_app_gateway).

Tổng số resource (khi bật full toggles)
|Nhóm  |Sốresource|
| -- | -- |
|RG + random + data sources | 1 RG|
| Networking  | 2 VNet + 4 subnet + 2 peering + 1 NSG + 1 NSG-assoc = 10|
|VM  |1 NIC + 1 VM + 1 TLS key = 3|
|Bastion (toggle)  |1 PIP + 1 Bastion = 2 |
|AppGW (toggle)|  1 PIP + 1 AppGW = 2|
|Storage + PE  | 1 SA + 1 DNS zone + 1 link + 1 PE = 4|
|Monitoring  |1 LAW + 1 diag NSG + 1 diag AppGW = 3|
|Tổng  |~25 resource (full bật)|


Điểm thiết kế đáng chú ý
1. VM không có public IP — access bắt buộc qua Bastion (admin) hoặc AppGW (HTTP traffic).
2. Storage tắt public access hoàn toàn — VM truy cập blob qua Private Endpoint + Private DNS, FQDN *.blob.core.windows.net resolve về private IP trong spoke.
3. Toggle enable_bastion / enable_app_gateway — tiết kiệm tiền khi không học (Bastion ~$0.19/h, AppGW v2 ~$10/ngày).
4. NSG rule "AllowSSHFromMyIP" — tự lấy IP của bro qua data.http, dev-only; production thật phải tắt và chỉ dùng Bastion.
5. Hub-spoke peering 2 chiều nhưng allow_gateway_transit = false → đây là pattern peering đơn giản, không phải topology có VPN/ER gateway ở hub.
