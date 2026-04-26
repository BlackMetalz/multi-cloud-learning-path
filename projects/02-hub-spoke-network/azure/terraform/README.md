### Tutorial when you working xDD

```bash
cd projects/02-hub-spoke-network/azure/terraform
az login --use-device-code
cp terraform.tfvars.example terraform.tfvars  # fill subscription_id
terraform init
terraform plan
terraform apply
```

### File layout

```
azure/terraform/
├── providers.tf            # terraform{}, provider{}, backend (shared with project 01)
├── variables.tf            # CIDRs, VM size, toggles
├── locals.tf               # naming + common tags
├── main.tf                 # RG + random suffix + my-IP data source
├── network.tf              # Hub + Spoke VNets, subnets, peering, NSG
├── vm.tf                   # Linux VM + cloud-init nginx + SSH keypair
├── bastion.tf              # Bastion + public IP (toggle: enable_bastion)
├── appgw.tf                # Application Gateway + public IP (toggle: enable_app_gateway)
├── storage.tf              # Storage account (public access disabled)
├── private_endpoint.tf     # PE + Private DNS zone for blob
├── monitor.tf              # Log Analytics + diagnostic settings
├── outputs.tf
├── terraform.tfvars.example
└── terraform.tfvars        # gitignored
```

### Toggles (control credit burn)

```hcl
enable_bastion     = false # ~$4.5/day — turn on, learn, turn off
enable_app_gateway = false # ~$10/day — turn on, learn, turn off
```

To flip a toggle:
```bash
# edit terraform.tfvars → enable_bastion = true
terraform apply
# done learning?
# edit terraform.tfvars → enable_bastion = false
terraform apply
```

### Connecting to the VM

**Without Bastion** (default): SSH from your machine — NSG opens 22 to your current public IP.
```bash
terraform output -raw vm_ssh_private_key_pem > /tmp/vm.pem && chmod 600 /tmp/vm.pem
ssh -i /tmp/vm.pem azureuser@<vm_private_ip>   # only works if you're on the same VNet (you're not)
```
Wait — you can't reach the private IP from your laptop. Two options:
- Toggle `enable_bastion = true` and connect via Azure Portal → Bastion
- Or temporarily add a public IP to the NIC (don't, just use Bastion)

**With Bastion**: Portal → VM → Connect → Bastion → paste private key from `terraform output -raw vm_ssh_private_key_pem`.

### Validating Private Endpoint

From the VM (via Bastion):
```bash
nslookup <storage_account_name>.blob.core.windows.net
# Expected: returns 10.1.2.x (private IP), NOT a public Azure IP
```

### Cleanup
```bash
terraform destroy
```

Or for partial savings, just disable toggles:
```hcl
enable_bastion     = false
enable_app_gateway = false
```

VM B2s costs ~$1/day if running. `az vm deallocate -g rg-hub-spoke-net -n <vm-name>` to stop billing for compute.
