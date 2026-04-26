# Project 08: Networking Advanced

Beyond the hub-spoke + Bastion + AppGW from project 02. Touch global routing (Traffic Manager, Front Door), point-to-site VPN, custom DNS — những thứ AZ-104 hỏi nhưng không tiện cover trong project nhỏ.

## Architecture

```
                          ┌──────────────────────┐
Browser ─── DNS lookup ──►│ Traffic Manager      │
   │                      │ (DNS-based routing)  │
   │                      └─────────┬────────────┘
   │                                │ resolves to one
   │            ┌───────────────────┼───────────────────┐
   │            ▼                                       ▼
   │     App Service SEA                        App Service EAS
   │     (Southeast Asia)                       (East Asia)
   │
   │
   ▼ (toggle: enable_front_door)
┌─ Front Door ─────────────────────────────────────────┐
│  Global edge POP, L7, custom domains, WAF (paid)     │
│  → backend = TM endpoint or App Service direct        │
└──────────────────────────────────────────────────────┘

   (toggle: enable_vpn_gateway)
┌─ VPN Gateway P2S ────────────────────────────────────┐
│  GatewaySubnet (must be exact name)                   │
│  Basic SKU + AAD authentication (no certs)            │
│  Client gets address from 172.16.0.0/24               │
│  → routes into spoke VNet                             │
└──────────────────────────────────────────────────────┘

   ┌─ Custom Public DNS Zone ─────────────────────────┐
   │  lab.kien.dev (or any unowned name)              │
   │   ├── A     www → App Service IP                 │
   │   └── CNAME tm  → tm-storage.trafficmanager.net  │
   └──────────────────────────────────────────────────┘
```

## Learning Goals (AZ-104)

- **Traffic Manager** — DNS-based, 6 routing methods (Priority/Weighted/Performance/Geographic/MultiValue/Subnet)
- **Front Door** — L7 reverse proxy at Microsoft global POPs, WAF, custom domain TLS
- **TM vs Front Door** — when to use which (DNS speed vs HTTP-aware routing)
- **VPN Gateway P2S** — Point-to-Site, AAD auth (newer than cert-based)
- **Public DNS zones** — `azurerm_dns_zone`, A/CNAME/MX records
- **Custom domain on App Service** — TXT verify + A/CNAME pointing

## Steps

### Step 1 — Foundation
- [ ] `cp terraform.tfvars.example terraform.tfvars`, fill subscription_id
- [ ] `terraform init && apply` (toggles default OFF, only TM + 2 App Services + DNS zone created)
- [ ] Both apps respond: `curl https://app-net-sea-XXXX.azurewebsites.net`

### Step 2 — Test Traffic Manager
- [ ] `nslookup <tm_dns_name>.trafficmanager.net` → returns **CNAME** to one of the App Services
- [ ] `curl https://<tm_dns_name>.trafficmanager.net` → routes to priority 1 endpoint
- [ ] Stop priority 1 App Service: `az webapp stop -n app-net-sea-XXX -g rg-net-lab` → re-test → routes to priority 2

### Step 3 — Toggle Front Door (~$1.20/day base)
- [ ] Set `enable_front_door = true`, `apply`
- [ ] `curl <fd_endpoint_hostname>` → cache hit at edge

### Step 4 — Toggle VPN Gateway (~$0.10/h Basic = ~$2.4/day)
- [ ] Set `enable_vpn_gateway = true`, `apply` (mất ~30 phút tạo gateway)
- [ ] Portal → Gateway → Point-to-site config → Download VPN client (Mac: viscosity hoặc OpenVPN)
- [ ] Connect → ping VM IP private (cần spawn 1 VM trong VNet để test)

### Step 5 — DNS records
- [ ] Add A record manually trong Portal hoặc TF
- [ ] `dig +short <record>.<dns_zone>` (zone không "thật" nhưng vẫn resolve qua Azure DNS)

### Step 6 — Cleanup
- [ ] Set toggles = false, apply (gỡ Front Door + VPN trước, ~$$$ saved)
- [ ] `terraform destroy` cuối

## Cloud Services Used

| Concept | Azure | AWS | GCP |
|---|---|---|---|
| DNS-based GLB | Traffic Manager | Route 53 routing policies | Cloud DNS routing |
| HTTP-aware GLB | Front Door | CloudFront + ALB | Cloud Load Balancer (Global) |
| L7 LB regional | Application Gateway | ALB | Cloud Load Balancer (Regional) |
| WAF | AppGW WAF / Front Door WAF | AWS WAF | Cloud Armor |
| Point-to-Site VPN | VPN Gateway P2S | Client VPN | HA VPN |
| Public DNS | Azure DNS | Route 53 | Cloud DNS |

## Cost Notes

| Resource | Cost (approx) | Toggle |
|---|---|---|
| App Service F1 ×2 | $0 | always (~10 free per sub) |
| Traffic Manager | $0.54/million queries (cheap) | always |
| Public DNS zone | $0.50/zone/month | always |
| **Front Door Standard** | **~$35/mo base + $$/GB** | `enable_front_door` |
| **VPN Gateway Basic** | **~$0.10/h = $72/mo** | `enable_vpn_gateway` |
