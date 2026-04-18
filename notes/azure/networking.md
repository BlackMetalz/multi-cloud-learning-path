# Azure Networking — Quick Mapping từ AWS VPC

## Quick Mapping

```
AWS                              Azure
───────────────────────────────────────────────────
VPC                          →   VNet
Subnet                       →   Subnet
Security Group               →   NSG (Network Security Group)
Elastic IP                   →   Public IP (Static)
ENI                          →   NIC (Network Interface Card)
VPC Peering                  →   VNet Peering
Internet Gateway             →   (tự động, không cần tạo)
NAT Gateway                  →   NAT Gateway
Route Table                  →   Route Table
```

## Điểm khác

| Concept | AWS | Azure |
|---------|-----|-------|
| Internet access | Tạo IGW + attach | Tự động có |
| Security rules | SG → instance | NSG → NIC hoặc Subnet |
| Public IP | EIP tách riêng | Public IP tạo kèm VM hoặc sau |

## NSG & ASG

**NSG** (Network Security Group) = AWS Security Group.

**ASG** (Application Security Group) = Azure-specific, group VMs theo logic.

```
Không có ASG:  Allow 443 from 10.0.1.0/24
Có ASG:        Allow 443 from ASG "web-servers"
```

Lợi ích: Thêm/bớt VM vào ASG, không cần sửa NSG rules.

| Concept | AWS | Azure |
|---------|-----|-------|
| Firewall rules | Security Group | NSG |
| Group by logic | SG reference SG | ASG (cleaner) |

## VNet Peering & Gateway

```
AWS                              Azure
───────────────────────────────────────────────────
VPC Peering (same region)    →   VNet Peering
VPC Peering (cross-region)   →   Global VNet Peering
VPN Gateway                  →   Virtual Network Gateway
Transit Gateway              →   Virtual WAN / VNet Gateway
Site-to-Site VPN             →   VPN Gateway Connection
Direct Connect               →   ExpressRoute
```

| Cần gì | Dùng |
|--------|------|
| Kết nối 2 VNets cùng region | VNet Peering |
| Kết nối 2 VNets khác region | Global Peering |
| On-prem ↔ Azure (internet) | VPN Gateway |
| On-prem ↔ Azure (dedicated) | ExpressRoute |

## DNS

```
AWS                              Azure
───────────────────────────────────────────────────
Route53                      →   Azure DNS
Route53 Hosted Zone (public) →   Public DNS Zone
Route53 Private Hosted Zone  →   Private DNS Zone
Route53 Domain Registration  →   App Service Domain
Route53 Health Checks        →   Traffic Manager
Route53 Routing Policies     →   Traffic Manager
```

**Note:** Azure tách health checks + traffic routing ra **Traffic Manager**, không built-in như Route53.

## Load Balancing

```
AWS                              Azure
───────────────────────────────────────────────────
NLB (Layer 4)                →   Azure Load Balancer
ALB (Layer 7)                →   Application Gateway
CloudFront + ALB (global)    →   Azure Front Door
Route53 routing policies     →   Traffic Manager (DNS-based)
```

| Service | Layer | Use case |
|---------|-------|----------|
| **Load Balancer** | L4 | VM load balancing, non-HTTP |
| **Application Gateway** | L7 | Web apps, SSL termination, WAF |
| **Front Door** | L7 Global | Global apps, CDN + LB + WAF |
| **Traffic Manager** | DNS | Failover, geo routing |

## Network Watcher (Debug Tools)

```
AWS                              Azure
───────────────────────────────────────────────────
VPC Flow Logs                →   NSG Flow Logs
VPC Reachability Analyzer    →   IP Flow Verify / Connection Troubleshoot
VPC Traffic Mirroring        →   Packet Capture
```

**Verdict:** Gần như 1:1 với AWS VPC/Route53/ELB, chỉ khác tên.
