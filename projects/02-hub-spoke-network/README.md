# Project 02: Hub-Spoke Network + VM

Build an enterprise-style hub-spoke network on Azure. One topology, learn networking-heavy AZ-104 muscles.

## Architecture

```
Internet
   │
   ▼
[ Application Gateway ] (public IP, WAF optional)   ← optional, $$$
   │
   ▼
┌────────────── Hub VNet (10.0.0.0/16) ──────────────┐
│  AzureBastionSubnet (10.0.1.0/26) ── [ Bastion ]   │ ← optional, $$$
│  AppGatewaySubnet  (10.0.2.0/24)                   │
└──────┬─────────────────────────────────────────────┘
       │ VNet peering (bidirectional)
       ▼
┌────────────── Spoke VNet (10.1.0.0/16) ────────────┐
│  snet-vm  (10.1.1.0/24) ── NSG ── [ Linux VM/nginx ]│
│  snet-pe  (10.1.2.0/24) ── [ Private Endpoint ]    │─── Storage Account
└────────────────────────────────────────────────────┘
```

## Learning Goals (AZ-104 mapping)

- **Virtual Networks**: hub-spoke topology, address space, subnets
- **Peering**: bidirectional VNet peering, transit
- **NSG**: inbound/outbound rules, service tags, priority
- **Bastion**: SSH/RDP without public IP on the VM
- **Application Gateway**: L7 load balancer + optional WAF
- **Private Endpoint + Private DNS Zone**: lock down PaaS storage to VNet
- **VM**: cloud-init bootstrap, managed identity, boot diagnostics
- **Monitor**: NSG flow logs, diagnostic settings → Log Analytics

## Steps

### Step 1 — Foundation
- [ ] `cp terraform.tfvars.example terraform.tfvars`, fill subscription_id
- [ ] `terraform init && terraform plan && terraform apply`
- [ ] Verify hub VNet + spoke VNet + peering, NSG attached to vm subnet

### Step 2 — VM with cloud-init
- [ ] VM provisioned with nginx via cloud-init
- [ ] No public IP on the VM (private only)

### Step 3 — Bastion (toggle on)
- [ ] Set `enable_bastion = true` in tfvars, `apply`
- [ ] Connect via Azure portal → Bastion → SSH to VM
- [ ] **Destroy when done** (`enable_bastion = false`) — Bastion ~$4.5/day

### Step 4 — Application Gateway (toggle on)
- [ ] Set `enable_app_gateway = true`, `apply`
- [ ] Hit `http://<appgw-public-ip>/` → should reach nginx via private VM
- [ ] **Destroy when done** — AppGW ~$10/day

### Step 5 — Private Endpoint to Storage
- [ ] PE created in spoke, Private DNS zone linked
- [ ] From VM (via Bastion): `nslookup <storage>.blob.core.windows.net` → returns 10.1.2.x
- [ ] Public access on storage = disabled

### Step 6 — Monitoring
- [ ] NSG flow logs enabled to Log Analytics
- [ ] Diagnostic settings on VNet, NSG, AppGW

### Step 7 — Replicate on AWS (later)
- [ ] VPC + Transit Gateway + ALB + EC2 + VPC Endpoint + S3

### Step 8 — Replicate on GCP (later)
- [ ] VPC + Shared VPC + Cloud Load Balancer + GCE + Private Service Connect + GCS

## Cloud Services Used

| Concept | Azure | AWS (later) | GCP (later) |
|---|---|---|---|
| VNet | Virtual Network | VPC | VPC |
| Hub-spoke | VNet Peering | Transit Gateway | Shared VPC / VPC Peering |
| Firewall (basic) | NSG | Security Group + NACL | Firewall Rules |
| Bastion | Azure Bastion | SSM Session Manager / EC2 Instance Connect | IAP Tunneling |
| L7 LB | Application Gateway | ALB | Cloud Load Balancer (HTTPS) |
| VM | Virtual Machine | EC2 | Compute Engine |
| Private link | Private Endpoint + Private DNS | VPC Endpoint (Interface) | Private Service Connect |
| Flow logs | NSG Flow Logs | VPC Flow Logs | VPC Flow Logs |
| IaC | Terraform | Terraform | Terraform |

## Cost Notes

| Resource | Cost (approx) | Toggle |
|---|---|---|
| VNets, subnets, peering, NSG | Free | always on |
| Linux VM B2s | ~$1/day | always on (stop when idle) |
| Storage + Private Endpoint | ~$0.30/day | always on |
| Log Analytics | pay per GB ingest | always on |
| **Azure Bastion (Basic)** | **~$4.5/day** | `enable_bastion` |
| **Application Gateway Standard_v2** | **~$10/day** | `enable_app_gateway` |

`terraform destroy` mỗi tối khi không học, hoặc `az vm deallocate` cho VM.
