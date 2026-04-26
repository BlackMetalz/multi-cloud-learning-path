### Tutorial

```bash
cd projects/08-networking-advanced/azure/terraform
az login --use-device-code
cp terraform.tfvars.example terraform.tfvars
# edit subscription_id, có thể đổi dns_zone_name

terraform init && terraform apply
```

### File layout

```
azure/terraform/
├── providers.tf            # azurerm 4.x, key=networking-advanced.tfstate
├── variables.tf, locals.tf, main.tf
├── apps.tf                 # 2 App Service F1 (SEA + EAS)
├── traffic_manager.tf      # TM Priority routing, 2 external endpoints
├── dns.tf                  # Public DNS zone + CNAME (www, tm) + TXT (asuid.www)
├── frontdoor.tf            # toggle: profile + endpoint + origin group + origin + route
├── vpn.tf                  # toggle: VNet + GatewaySubnet + VPN Gateway P2S (AAD auth)
├── outputs.tf
└── terraform.tfvars.example
```

### Step 2 — Test Traffic Manager priority failover

```bash
TM_FQDN=$(terraform output -raw tm_fqdn)

# 1. Resolve TM (sẽ ra CNAME → App Service primary)
nslookup $TM_FQDN
# Expect: ... canonical name = app-net-lab-sea-XXX.azurewebsites.net.

# 2. Curl qua TM
curl -sI https://$TM_FQDN | head -3

# 3. Stop primary App Service → TM healthcheck fail → routing chuyển sang secondary
az webapp stop -g rg-net-lab -n $(terraform output -raw app_primary_url | sed 's|https://||;s|.azurewebsites.net||')

# Đợi ~2-3 phút (TM monitor interval 30s × 3 fails = ~90s)
nslookup $TM_FQDN
# Expect: bây giờ resolve sang App Service secondary

# Restart primary
az webapp start -g rg-net-lab -n $(terraform output -raw app_primary_url | sed 's|https://||;s|.azurewebsites.net||')
```

### Step 3 — Front Door

```bash
# Bật toggle, apply
# (edit tfvars: enable_front_door = true)
terraform apply

FD=$(terraform output -raw frontdoor_endpoint_hostname)

# Curl qua Front Door — first request là cache miss, request 2+ cache hit
curl -sI https://$FD | grep -i x-cache
# Expect lần 2: x-cache: TCP_HIT (or similar from edge POP)

# Tắt khi xong học
# (edit tfvars: enable_front_door = false)
terraform apply
```

### Step 4 — VPN Point-to-Site

```bash
# Bật toggle, apply (mất ~30 phút!)
# (edit tfvars: enable_vpn_gateway = true)
terraform apply

# Sau khi tạo xong:
# 1. Portal → Virtual network gateway → Point-to-site configuration → Download VPN client
# 2. Chọn "Azure VPN Client" (vì AAD auth)
# 3. Mac: cài app "Azure VPN Client" từ App Store → import file XML download → connect (sẽ prompt AAD login)
# 4. Connected → bro có IP từ pool 172.16.0.0/24
# 5. Test: spawn 1 VM nhỏ trong vnet-vpn-net-lab.snet-workload → ping private IP của VM từ Mac

# Tắt khi xong (cứu credit)
# (edit tfvars: enable_vpn_gateway = false)
terraform apply  # destroy gateway mất ~10 phút
```

### Step 5 — Test DNS records (qua Azure DNS NS)

DNS zone không "thật" trừ khi bro update NS records ở registrar. Test resolution qua Azure DNS NS trực tiếp:

```bash
NS=$(terraform output -json dns_zone_nameservers | jq -r '.[0]')
echo "Azure NS: $NS"

# Query trực tiếp NS Azure
dig @$NS www.lab.kien.dev CNAME +short
# Expect: app-net-lab-sea-XXX.azurewebsites.net.

dig @$NS tm.lab.kien.dev CNAME +short
# Expect: tm-net-lab-XXX.trafficmanager.net.

dig @$NS asuid.www.lab.kien.dev TXT +short
# Expect: TXT verification ID
```

### Pre-flight notes

- **F1 App Service limit**: 10 free instances per subscription. Project 01, 04, 08 cộng dồn = 4. Còn dư.
- **Region pair**: SEA ↔ EAS là Azure paired region (cho disaster recovery automatic). Tốt cho Traffic Manager priority demo.
- **DNS zone $0.50/mo** kể cả không có record. Destroy nếu xong project.

### Cleanup

```bash
# Tắt toggle trước (gỡ Front Door + VPN ~$3.6/day)
# Edit tfvars: enable_front_door = false, enable_vpn_gateway = false
terraform apply

# Destroy hoàn toàn
terraform destroy
```
