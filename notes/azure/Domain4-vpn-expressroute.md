# Domain 4 — VPN Gateway & ExpressRoute

## VPN Gateway

Kết nối on-premises → Azure qua **internet** (encrypted IPSec tunnel).

### Types

| Type | Mô tả | Dùng khi |
|---|---|---|
| Route-based | Dynamic routing, hỗ trợ IKEv2, Point-to-Site | **Mặc định, nên dùng** |
| Policy-based | Static routing, legacy, chỉ IKEv1, không hỗ trợ P2S | Legacy device buộc phải dùng |

### SKUs (VPN Gateway)

| SKU | Throughput | BGP | Zone-redundant |
|---|---|---|---|
| Basic | 100 Mbps | ✗ | ✗ |
| VpnGw1 | 650 Mbps | ✓ | ✗ |
| VpnGw1AZ | 650 Mbps | ✓ | ✓ |
| VpnGw5AZ | 10 Gbps | ✓ | ✓ |

### Connection Types
- **Site-to-Site (S2S):** on-premises network ↔ Azure VNet
- **Point-to-Site (P2S):** individual device → Azure VNet (remote work)
- **VNet-to-VNet:** 2 Azure VNet khác region kết nối qua gateway

## ExpressRoute

Kết nối on-premises → Azure qua **đường truyền riêng** (không qua internet), cung cấp bởi connectivity provider.

### Key Points
- **Private, dedicated bandwidth** → latency thấp, ổn định
- Không bị ảnh hưởng bởi internet congestion
- SLA cao hơn VPN
- **Không mã hóa mặc định** (đường đã private) — nếu cần encrypt → VPN over ExpressRoute

### Circuit SKUs

| SKU | Bandwidth | Routing |
|---|---|---|
| Local | Up to 10 Gbps | Chỉ region gần nhất |
| Standard | 50 Mbps → 10 Gbps | Tất cả regions cùng geo |
| Premium | 50 Mbps → 100 Gbps | Global + Microsoft 365 |

## So sánh VPN vs ExpressRoute

| | VPN Gateway | ExpressRoute |
|---|---|---|
| Đường truyền | Internet (encrypted) | Private (provider) |
| Băng thông | Đến 10 Gbps | Đến 100 Gbps |
| Latency | Cao hơn, biến động | Thấp, ổn định |
| Mã hóa | IPSec mặc định | Không mặc định |
| Setup time | Nhanh (vài phút) | Chậm (vài tuần, cần provider) |
| Chi phí | Thấp hơn | Cao hơn |
| SLA | 99.9% | 99.95% |

## Coexistence (VPN + ExpressRoute cùng lúc)

Dùng cả hai để:
- ExpressRoute = primary path
- VPN = failover nếu ExpressRoute down

Cần **UltraPerformance VPN Gateway SKU** để coexistence.

## Exam Gotchas

- ExpressRoute **không đi qua internet** → câu hỏi "secure private connection" = ExpressRoute
- VPN Policy-based **không hỗ trợ** Point-to-Site
- **Active-Active** VPN Gateway = 2 tunnel, high availability
- ExpressRoute **Global Reach:** kết nối 2 on-prem sites thông qua Azure backbone (không cần hairpin qua internet)
- Câu hỏi "consistent latency, high bandwidth" = ExpressRoute
- Câu hỏi "quick setup, cost-effective" = VPN Gateway
