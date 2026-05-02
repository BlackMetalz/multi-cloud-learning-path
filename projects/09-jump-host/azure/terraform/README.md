### Tutorial

```bash
cd projects/09-jump-host/azure/terraform
az login --use-device-code

# Pre-flight 1: SKU available
# Standard_B1s
az vm list-skus -l southeastasia --size Standard_D2alds_v7 \
  --query "[?length(restrictions)==\`0\`].name" -o tsv

az vm list-skus -l southeastasia --size Standard_B1s \
  --query "[?length(restrictions)==\`0\`].name" -o tsv


# Pre-flight 2: Core quota — credit/trial sub thường giới hạn 4 cores/region
az vm list-usage -l southeastasia \
  --query "[?contains(name.value, 'cores') && contains(localName, 'Total Regional')].{quota:limit, used:currentValue, available:[limit, currentValue]}" \
  -o table
# Math: D2alds_v7 = 2 cores. Bastion (2) + N×workload (2 each) phải ≤ quota.
# Quota=4 → bastion + 1 workload là max. Tăng quota: https://aka.ms/ProdportalCRP

cp terraform.tfvars.example terraform.tfvars
# edit subscription_id; allowed_ssh_ips để rỗng nếu chỉ test từ máy bro

terraform init
terraform plan -out=tfplan
# Plan: 12 to add, 0 to change, 0 to destroy.
terraform apply "tfplan"
```

### File layout

```
azure/terraform/
├── providers.tf        # azurerm 4.x + tls + http, key=jump-host.tfstate
├── variables.tf        # CIDRs, VM size, allowed_ssh_ips, workload_vm_count
├── locals.tf           # naming + tags + effective_allowed_ips fallback
├── main.tf             # RG + suffix + my-IP data
├── network.tf          # VNet + 2 subnets + 2 NSGs (bastion + private)
├── bastion.tf          # bastion VM với cloud-init fail2ban
├── workload.tf         # N workload VMs (count = var.workload_vm_count)
├── outputs.tf          # bastion IP + private IPs + ssh_config_snippet
└── terraform.tfvars.example
```

### Step 1 — Setup SSH key local

```bash
# Save private key
terraform output -raw vm_ssh_private_key_pem > ~/.ssh/jump-host.pem
chmod 600 ~/.ssh/jump-host.pem
```

### Step 2 — SSH thẳng vào bastion (test layer 1 NSG)

```bash
# Quick way:
eval "$(terraform output -raw bastion_ssh_command)"

# Hoặc:
BASTION_IP=$(terraform output -raw bastion_public_ip)
ssh -i ~/.ssh/jump-host.pem azureuser@$BASTION_IP

# Trong bastion:
sudo fail2ban-client status sshd      # fail2ban đang chạy
sudo tail -20 /var/log/auth.log       # xem login event của bro
hostname                              # vm-bastion-jump-host
exit
```

### Step 3 — ProxyJump vào workload (test layer 2 NSG)

```bash
# Setup SSH config 1 lần
terraform output -raw ssh_config_snippet >> ~/.ssh/config

# Verify config
grep -A5 "Host vm-app" ~/.ssh/config

# ProxyJump vào — laptop tự bounce qua bastion, transparent
ssh vm-app1-jump-host

# Trong vm-app1:
hostname                              # vm-app1-jump-host
curl localhost                        # nginx page với hostname
exit

# Nếu workload_vm_count > 1 (cần tăng quota trước):
# ssh vm-app2-jump-host
```

> **Tip ProxyJump syntax**: thay vì alias trong config, có thể dùng one-liner:
> ```bash
> ssh -J azureuser@$BASTION_IP -i ~/.ssh/jump-host.pem azureuser@10.50.2.4
> ```
> `-J` = ProxyJump flag, đáp ứng cùng outcome.

### Cleanup

```bash
terraform destroy

# Cleanup local SSH artifacts
rm ~/.ssh/jump-host.pem
# Edit ~/.ssh/config, remove Host bastion + vm-app* blocks
```

### Mở rộng

- **MFA SSH**: cài `libpam-google-authenticator` trên bastion (Google Auth TOTP)
- **JIT VM Access**: Microsoft Defender for Cloud tạo NSG rule tạm 1h
- **Audit ship**: Azure Monitor Agent → Log Analytics, query `auth.log` events
- **Tailscale alternative**: install Tailscale trên bastion + workload, dùng MagicDNS thay public IP
