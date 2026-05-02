# AZ-104 Exam Tricks (mẹo đọc đề)

Tổng hợp các bẫy hay gặp. Không phải study guide — chỉ là **pattern** để loại đáp án sai nhanh.

## 1. "X replaces NSG/Firewall" → luôn SAI

Bastion, Private Endpoint, VPN Gateway, Front Door, App Gateway... **không** thay thế NSG. NSG là layer filter riêng, luôn áp dụng song song.

## 2. VNet Peering

| Bẫy | Đúng |
|-----|------|
| Peering là **transitive** | SAI — A↔B, B↔C **không** cho A↔C |
| Bật `Use Remote Gateway` 1 phía là đủ | SAI — phải cặp với `Allow Gateway Transit` ở phía có gateway |
| 1 spoke dùng nhiều remote gateway | SAI — chỉ 1 |

## 3. Subnet tên cố định (sai 1 ký tự là fail)

| Service | Subnet name BẮT BUỘC |
|---------|----------------------|
| Azure Bastion | `AzureBastionSubnet` (/26 trở lên) |
| VPN/ER Gateway | `GatewaySubnet` (/27 trở lên) |
| Azure Firewall | `AzureFirewallSubnet` (/26) |

## 4. Storage Replication

| Protect against | Choose |
|-----------------|--------|
| Disk / hardware failure | LRS |
| Datacenter / zone failure | ZRS |
| Region failure | GRS / RA-GRS |
| Zone + region failure | GZRS / RA-GZRS |

**Bẫy:** "highest availability within a region" → ZRS (không phải GRS). GRS là **cross-region**.

## 5. Backup vs Site Recovery

- **Azure Backup** = data recovery (file, VM disk, DB) — RPO tính bằng giờ/ngày
- **Site Recovery (ASR)** = disaster recovery (replicate VM sang region khác) — RPO/RTO ngắn

Đề hỏi "khôi phục file bị xóa" → Backup. "Region down, switch sang region khác" → ASR.

### 5a. Recovery Services vault vs Backup vault (BẪY NAMING)

| Vault | Workload |
|-------|----------|
| **Recovery Services vault** (cũ) | Azure VM, **MARS agent (files/folders/system state on-prem)**, SQL/SAP HANA in VM, Azure File Shares |
| **Azure Backup vault** (mới) | PostgreSQL, **Blob**, Managed Disks, AKS, MySQL |

Keyword **"files, folders, system state"** → luôn là **Recovery Services vault** (vì gắn với MARS agent). Đừng nhầm với "Azure Backup vault" — tên giống nhau cố tình.

## 6. RBAC vs Azure Policy

- **RBAC** = ai được làm gì (access)
- **Policy** = resource được phép tồn tại không (compliance, deny tag missing, deny SKU lạ...)

Đề hỏi "enforce tag", "block region" → Policy. Đề hỏi "grant read access" → RBAC.

### 6a. 4 built-in roles cốt lõi (BẪY HAY RA)

| Role | Manage resources | Assign roles |
|------|:----------------:|:------------:|
| **Owner** | ✅ | ✅ |
| **Contributor** | ✅ | ❌ |
| **Reader** | ❌ (read-only) | ❌ |
| **User Access Administrator** | ❌ | ✅ |

**Bẫy hay gặp:** đề hỏi "full manage resources **nhưng không** assign roles" → đáp án là **Contributor**, KHÔNG phải User Access Administrator (UAA). UAA là role ngược lại — chỉ phân quyền, không động được resource.

**Mẹo rút gọn:**
- Owner = Contributor + UAA
- Contributor = "làm mọi thứ trừ phân quyền"
- UAA = "chỉ phân quyền"

Tên "User Access Administrator" nghe oai nhưng quyền hẹp — đọc kỹ keyword "manage **resources**" để không chọn nhầm.

### 6b. RBAC scope — 4 levels (gán role ở đâu?)

```
Management Group  (top, chứa nhiều subscription)
    ↓ inherit
Subscription
    ↓ inherit
Resource Group
    ↓ inherit
Resource          ← VNet, VM, Storage, Key Vault... mỗi resource đơn lẻ
```

**Quy tắc:** bất kỳ thứ gì có Resource ID đều có thể là scope. Role assigned ở scope cao **inherit xuống** scope thấp.

**Bẫy đề:** list cụ thể như "Virtual Network", "Storage Account" làm distractor — vẫn là **scope hợp lệ** (level Resource). Đừng loại chỉ vì nó "specific quá".

**Least privilege pattern:** thay vì gán Contributor ở Subscription, gán role hẹp (vd Network Contributor) ở chính VNet đó.

## 7. Locks

| Lock | Chặn gì |
|------|---------|
| `ReadOnly` | Cả modify + delete |
| `CanNotDelete` | Chỉ delete, vẫn modify được |

Lock **inherit** xuống child resource. Lock ở subscription → áp cho mọi RG bên dưới.

## 8. Service Endpoint vs Private Endpoint

| | Service Endpoint | Private Endpoint |
|---|---|---|
| IP | Public IP của PaaS | Private IP trong VNet |
| Scope | Subnet → service | NIC riêng cho instance cụ thể |
| Cross-region | Không | Có |
| Giá | Free | Trả tiền |

Đề có chữ "private IP in my VNet" → Private Endpoint.

## 9. VM High Availability

| Mức bảo vệ | Dùng |
|-----------|------|
| Lỗi rack/host | Availability Set |
| Lỗi datacenter | Availability Zone |
| Auto scale | VMSS |
| Cả 3 | VMSS + zones |

**SLA:** Single VM SSD 99.9% • AS 99.95% • AZ 99.99%.

## 10. Azure AD / Entra ID

- **Conditional Access** cần license **P1**
- **PIM** (Privileged Identity Management) cần **P2**
- MFA free cho global admin, full MFA cần P1

## 11. Cost Management bẫy

- **Reserved Instance** = commit 1/3 năm, giảm tới 72%
- **Spot VM** = rẻ nhưng có thể bị evict
- **Hybrid Benefit** = mang license Windows/SQL on-prem lên Azure

Đề hỏi "predictable workload, lowest cost" → RI. "Batch job, có thể restart" → Spot.

## 12. Đáp án quá tuyệt đối → 90% là distractor

Các từ khóa **red flag** trong đáp án:

| Từ | Vì sao đáng ngờ |
|----|-----------------|
| `automatically` | Azure ít khi tự làm thay user — license, scaling, backup... đều cần config |
| `all` / `every` | "All PaaS services", "every VM in subscription" — Azure không apply blanket |
| `only` | "Each user can have only one license", "only via portal" — Azure thường có nhiều cách |
| `never` / `cannot` | Azure linh hoạt, ít có cấm tuyệt đối |
| `replaces` | Service A "replaces" Service B → thường là layer riêng (xem #1) |

**Ví dụ đã gặp:**
- "Licenses are **automatically** provisioned when user created" → SAI, phải gán thủ công hoặc qua group
- "Bastion **replaces** NSG" → SAI, NSG vẫn áp dụng song song
- "Each user can have **only** one license" → SAI, nhiều license OK
- "Auto sets up private endpoints for **all** PaaS services" → SAI, phải config từng cái

**Ngoại lệ — khi tuyệt đối lại đúng:**
- Subnet name **bắt buộc** đúng tên (#3) — "must be exactly `AzureBastionSubnet`"
- Lock `ReadOnly` chặn **cả** modify + delete
- Locks **always** inherit xuống child resource

→ Tuyệt đối về **technical fact** thì OK. Tuyệt đối về **behavior/automation** thì nghi ngờ.

## 12b. Storage Account — restrict access có 2 hướng

Đề hỏi "valid methods to restrict access" với storage → có **2 hướng độc lập**, đếm cả 2:

```
WHO can authenticate          FROM WHERE they can connect
─────────────────────────     ────────────────────────────
- Storage account key          - IP firewall rules
- SAS token (time-limited)     - VNet Service Endpoint
- Entra ID (RBAC)              - Private Endpoint
- Entra ID Kerberos            - Disable public access
  (Azure Files SMB)
```

Bẫy: đề list cả method network + method identity, dễ bỏ sót 1 hướng.

### 12b.1 SAS (Shared Access Signature)

URL token có chữ ký → share access **giới hạn thời gian + quyền** mà KHÔNG cần share storage key.

```
https://...blob.core.../file?sv=...&sig=...&se=2026-05-01&sp=r
                                            ↑ expiry      ↑ perm
```

3 loại SAS:
- **User delegation SAS** — ký bằng Entra ID credential (recommended, có thể revoke)
- **Service SAS** — ký bằng storage key, scope 1 service (blob/file/queue/table)
- **Account SAS** — ký bằng storage key, scope cả account

Đề hỏi "delegated time-limited access" → SAS. "OAuth 2.0 / Entra ID auth" → KHÔNG phải SAS, là RBAC data plane.

## 13. PowerShell vs CLI vs ARM/Bicep

Đề hỏi "deploy declarative IaC, idempotent" → ARM/Bicep/Terraform. Hỏi "imperative script" → CLI/PowerShell. Đừng chọn CLI khi đề nói "infrastructure as code template".

## 14. Load Balancer troubleshoot order

VM behind LB không nhận traffic → check theo thứ tự:

1. **Health probe** status (Portal → LB → Backend pool health)
2. **NSG** allow `AzureLoadBalancer` service tag inbound
3. **OS firewall** (Windows Firewall / iptables) mở port app + probe
4. **App** listen đúng port

Bẫy: VM sau LB **không nên** có public IP riêng — đáp án "assign public IP" để fix LB issue luôn sai (traffic sẽ bypass LB).

## 15. Network Watcher — chọn đúng tool

| Cần làm | Tool |
|---------|------|
| Đo latency / packet loss VM↔VM liên tục | **Connection Monitor** |
| Test 1 lần "VM A có tới được VM B port X không" | **Connection Troubleshoot** |
| "Packet này có bị NSG drop không" | **IP Flow Verify** |
| Effective NSG rules đang áp lên NIC | **Effective Security Rules** |
| Log toàn bộ traffic qua NSG | **NSG Flow Logs** |
| Vẽ topology mạng | **Topology** |
| Capture gói tin để phân tích Wireshark | **Packet Capture** |

**Mẹo nhớ:** đề có "between two VMs" + "network" → reflex Network Watcher. Đề có "continuous/monitor over time" → Connection **Monitor**. Đề có "one-time test" → Connection **Troubleshoot**.

## 16. Azure Monitor — Metrics vs Logs vs Insights

| | Dùng khi |
|---|---|
| **Metrics** | Số liệu numeric, time-series, near real-time (CPU, RPS) — alert nhanh |
| **Logs (Log Analytics)** | Query KQL, event/diagnostic, retention dài |
| **Insights** | Pre-built dashboard cho VM/Container/App (overview, không phải diagnostic sâu) |

Bẫy: đề hỏi "diagnostic giữa 2 VM cụ thể" → **không** chọn Insights. Insights là overview, không deep-dive.

**Phân biệt Insights vs Log Analytics khi đề có "analyze":**

| Đề có | Chọn |
|-------|------|
| "view dashboard / performance overview / dependency map" | Insights |
| "analyze / query / compliance report" | Log Analytics |
| "across multiple VMs" + data tổng hợp | Log Analytics |
| "Update Management / patch compliance" | Log Analytics (data đẩy vào workspace) |
| "Change tracking" | Log Analytics |

## 17. Private DNS + Private Endpoint + Hybrid resolution (COMBO DÀY)

Cụm câu hỏi xoay quanh "VM/on-prem resolve được tên private không" — phải nhớ **scope** của từng thành phần.

### Scope từng thành phần

| Thành phần | Scope | Ghi chú |
|------------|-------|---------|
| **Private DNS Zone** | **Global** | 1 zone link nhiều VNet ở mọi region/sub |
| **VNet** | Region | Không cross-region |
| **VNet Peering** | Cross-region/cross-sub OK | **KHÔNG tự share DNS** |
| **DNS Private Resolver** (inbound/outbound endpoint) | **Region** | HA cần resolver mỗi region |
| **Private Endpoint NIC** | Region (trong subnet) | |

### Bẫy #1: Peering không share DNS

VNet-A có Private Endpoint + zone đã link → VM-A resolve OK. VM-B trong VNet-B (peered) **fail** vì zone chưa link tới VNet-B.

**Fix:** link zone tới **cả hai** VNet. Zone là global, link bao nhiêu cũng được.

### Bẫy #2: Hybrid DNS cần Private Resolver

On-prem cần resolve `mystorage.privatelink.blob...` →

```
On-prem DNS  ──conditional fwd──→  DNS Private Resolver
                                   (inbound endpoint, region X)
                                          ↓
                                   linked Private DNS Zones
                                          ↓
                                   trả IP private endpoint
```

- **Inbound endpoint** = on-prem hỏi vào Azure
- **Outbound endpoint** = Azure resolve tên on-prem
- HA cross-region → deploy resolver ở 2 region

### Scenario hay ra

| Triệu chứng | Nguyên nhân | Fix |
|-------------|-------------|-----|
| VM resolve private endpoint → public IP | Zone chưa link VNet | Link zone vào VNet |
| Spoke không resolve dù peered hub | Zone chỉ link hub | Link zone vào cả spoke |
| On-prem resolve → public IP | Chưa có hybrid DNS | Deploy **DNS Private Resolver** + conditional fwd |
| HA cross-region hybrid | Resolver region-bound | Resolver ở 2 region |
| Zone ở sub khác không link | Cross-sub permission | Cấp `Network Contributor` cho zone |

### Mental model

```
Zone     = global phone book   (1 zone, link bất kỳ đâu)
VNet     = building             (region + sub specific)
Peering  = cầu nối building     (KHÔNG copy phone book qua)
Resolver = lễ tân đa ngôn ngữ   (region specific, on-prem ↔ Azure)
```

**Mẹo nhớ:** đề có "private endpoint + can't resolve" → 90% là DNS zone link issue. "On-prem + private endpoint" → cần Private Resolver.
