# Project 09: Self-hosted Jump Host (Bastion VM)

Pattern thực tế 80% SME chạy: 1 VM nhỏ làm jump host với public IP + IP allowlist, từ đó SSH vào các VM private trong VNet. Không phải Azure Bastion service ($4.5/day), tự build với ~$1/day.

## Architecture

```
Bro's laptop (IP X.Y.Z.W)
    │ SSH (port 22)
    ▼
┌─ NSG-bastion ─────────────────────────────────────┐
│  Allow 22 from [allowed_ssh_ips], deny rest        │
└──────────┬─────────────────────────────────────────┘
           ▼
┌─ snet-bastion (10.50.1.0/24) ──────────┐
│  vm-bastion (B-series, public IP)       │
│  cloud-init: fail2ban + key-only auth   │
└──────┬──────────────────────────────────┘
       │ SSH (port 22) within VNet
       ▼
┌─ NSG-private ───────────────────────────────┐
│  Allow 22 from snet-bastion CIDR only        │
└──────────┬──────────────────────────────────┘
           ▼
┌─ snet-private (10.50.2.0/24) ──────────┐
│  vm-app1 (no public IP), nginx          │
│  vm-app2 (no public IP), nginx          │
└─────────────────────────────────────────┘
```

## Learning Goals

- **NSG defense-in-depth**: 2 layer rules (bastion-level + private-level)
- **SSH ProxyJump (`-J`)**: modern SSH way, transparent bounce qua bastion
- **IP allowlist management**: home IP + office IP + VPN exit IP, ops task thật
- **Bastion hardening**: cloud-init install fail2ban, disable password auth
- **Self-hosted vs managed**: cost vs ops burden tradeoff
- **Operational pattern**: patch bastion, rotate SSH key, audit `auth.log`

## Steps

### Step 1 — Provision foundation
- [ ] `cp terraform.tfvars.example terraform.tfvars`, fill subscription_id
- [ ] (Optional) thêm IP văn phòng / VPN exit vào `allowed_ssh_ips`
- [ ] `terraform init && apply`
- [ ] Verify: 1 bastion với public IP + 2 workload VMs no public IP

### Step 2 — SSH vào bastion trực tiếp
- [ ] Lưu SSH key: `terraform output -raw vm_ssh_private_key_pem > ~/.ssh/jump-host.pem && chmod 600 ~/.ssh/jump-host.pem`
- [ ] `ssh -i ~/.ssh/jump-host.pem azureuser@<bastion_public_ip>` → vào được
- [ ] `tail -f /var/log/auth.log` xem login event

### Step 3 — ProxyJump vào workload VMs
- [ ] Paste `terraform output -raw ssh_config_snippet` vào `~/.ssh/config`
- [ ] `ssh vm-app1` → laptop tự bounce qua bastion → tới vm-app1
- [ ] `curl localhost` từ vm-app1 → trả về nginx page
- [ ] `ssh vm-app2` → cùng pattern, không cần re-auth bastion

### Step 6 — Cleanup
- [ ] `terraform destroy`

## Cloud Services Used

| Concept | Azure | AWS | GCP |
|---|---|---|---|
| Jump host VM | Linux VM + Public IP | EC2 + EIP in public subnet | GCE + ephemeral IP |
| Network ACL | NSG | Security Group + NACL | Firewall Rules |
| IP allowlist | NSG `source_address_prefixes` | SG ingress rules | Firewall `source_ranges` |
| Modern alt (managed) | Azure Bastion / Entra ID SSO | Session Manager | IAP TCP forwarding |

## Self-hosted vs Azure Bastion

| | Self-hosted (this lab) | Azure Bastion service (project 02) |
|---|---|---|
| Cost | ~$0.30/day | ~$4.5/day |
| Setup | Tự build, tự patch | Microsoft host |
| Audit | `journalctl -u sshd` trên bastion | Activity Log built-in |
| MFA | Phải setup tay (Google Authenticator PAM) | Built-in qua Entra ID |
| Audience | Startup, SME | Enterprise, regulated cty |
| Bro học gì | Linux ops + NSG | Azure managed service ergonomics |

## Cost Notes

| Resource | $/day approx |
|---|---|
| Bastion VM (B-series) | $0.27 |
| 2 workload VMs | $0.54 |
| Public IP Standard | $0.12 |
| VNet, NSG, NIC | $0 |
| **Total** | **~$0.95/day** |

`az vm deallocate -g rg-jump-host -n <vm>` cho từng VM khi không dùng.

## Mở rộng (nếu muốn)

- **JIT VM Access**: Microsoft Defender for Cloud → tạo NSG rule tạm 1h, expires auto
- **MFA cho SSH**: cài `libpam-google-authenticator` trên bastion
- **Audit ship to Log Analytics**: cài Azure Monitor Agent, ship `/var/log/auth.log`
- **Tag-based access**: NSG dynamic theo Service Tag
- **Tailscale / Twingate alternative**: zero-trust mesh thay bastion entirely
