# Domain 2 — VM Availability & Scaling

## Ba cách đảm bảo HA cho VM

### 1. Availability Set
- Bảo vệ khỏi **hardware failure trong cùng datacenter**
- **Fault Domain (FD):** rack vật lý khác nhau (power, switch riêng) — tối đa 3
- **Update Domain (UD):** nhóm VM không restart cùng lúc khi Azure patch — tối đa 20
- SLA: **99.95%** (cần ≥2 VM)
- Không bảo vệ khỏi datacenter sập

### 2. Availability Zones
- Bảo vệ khỏi **toàn bộ datacenter sập** (mỗi zone = datacenter vật lý khác nhau trong region)
- SLA: **99.99%** (cần ≥2 VM ở zone khác nhau)
- Không phải region nào cũng có (check trước)
- **Không thể combine Availability Set + Zone** — chọn một trong hai

### 3. VM Scale Sets (VMSS)
- Auto-scale số lượng VM theo load
- Tất cả VM dùng cùng image → stateless workload
- Có thể deploy across zones
- Tích hợp Load Balancer / App Gateway

## So sánh nhanh

| | Availability Set | Availability Zones | VMSS |
|---|---|---|---|
| Bảo vệ | Hardware/rack failure | Datacenter failure | Scale + HA |
| SLA | 99.95% | 99.99% | Tùy config |
| Use case | Legacy app, lift-and-shift | Production critical | Web tier, stateless |
| Region support | Mọi region | Chỉ region có zones | Mọi region |

## Exam Gotchas

- **Availability Set** = FD + UD, cùng datacenter → không chống zone failure
- **Zones** = datacenter khác nhau → chống zone failure, nhưng không có FD/UD concept
- SLA 99.99% → phải dùng Zones, không phải Set
- VMSS không tự đảm bảo HA nếu tất cả instance ở cùng zone
- **Single VM + Premium SSD** có SLA 99.9% (không cần Set/Zone)
