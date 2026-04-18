# Azure Virtual Machines — For AWS EC2 Users

If you know EC2, you know 80% of Azure VMs. This doc focuses on differences.

## Quick Mapping

```
AWS                              Azure
───────────────────────────────────────────────────
EC2 Instance                 →   Virtual Machine
AMI                          →   VM Image
Instance Type (t3.micro)     →   VM Size (Standard_B1s)
EBS Volume                   →   Managed Disk
Instance Store               →   Temporary Disk (lost on stop)
Security Group               →   NSG (Network Security Group)
VPC + Subnet                 →   VNet + Subnet
Elastic IP                   →   Public IP (Static)
ENI                          →   NIC
Key Pair (.pem)              →   SSH Key or Password
Session Manager              →   Azure Bastion
Auto Scaling Group           →   VM Scale Sets (VMSS)
Launch Template              →   VMSS Image Reference
Spot Instance                →   Spot VM
Reserved Instance            →   Reserved VM Instance
```

## Key Differences

| Topic | AWS | Azure |
|-------|-----|-------|
| **Stop behavior** | Stop = still pay EBS | Deallocate = no charge (loses dynamic public IP) |
| **Disk** | EBS separate service | Managed Disk (OS disk + Data disk) |
| **Security** | SG attached to instance | NSG attached to NIC or Subnet |
| **Bastion** | Session Manager (free) or DIY | Azure Bastion (managed, ~$140/mo) |
| **Scaling** | ASG + Launch Template (separate) | VMSS (all-in-one) |
| **Availability** | AZ only | Availability Zone OR Availability Set |

## The 3 Things You Should Focus On

### 1. Azure Bastion — Managed Secure Access

AWS: Session Manager (free, uses SSM agent) or self-managed bastion host.

Azure: Managed bastion service. Connect via browser, no public IP needed on VM.

```bash
# Create Bastion (requires AzureBastionSubnet in VNet)
az network bastion create \
  --resource-group rg-myapp \
  --name myBastion \
  --vnet-name myVnet \
  --public-ip-address myBastionIP

# Connect via Portal: VM → Connect → Bastion → Enter credentials
```

**Trade-off:** Convenient but costs ~$140/month. For dev/test, just use public IP + NSG.

### 2. VMSS — All-in-One Auto Scaling

AWS separates: Launch Template (what to launch) + ASG (how many) + ALB (load balance).

Azure combines into VMSS: defines image, instance count, scaling rules, and optionally LB.

```bash
# Create VMSS with auto-scaling
az vmss create \
  --resource-group rg-myapp \
  --name myScaleSet \
  --image Ubuntu2204 \
  --vm-sku Standard_B1s \
  --instance-count 2 \
  --admin-username azureuser \
  --generate-ssh-keys

# Add auto-scale rule (scale out when CPU > 70%)
az monitor autoscale create \
  --resource-group rg-myapp \
  --resource myScaleSet \
  --resource-type Microsoft.Compute/virtualMachineScaleSets \
  --min-count 2 \
  --max-count 10 \
  --count 2

az monitor autoscale rule create \
  --resource-group rg-myapp \
  --autoscale-name myScaleSet \
  --condition "Percentage CPU > 70 avg 5m" \
  --scale out 1
```

### 3. Availability Set vs Availability Zone

AWS has only Availability Zones (separate datacenters).

Azure has two concepts:

| Concept | What it is | When to use |
|---------|------------|-------------|
| **Availability Zone** | Separate datacenter (like AWS AZ) | Production, max isolation |
| **Availability Set** | Same datacenter, different racks | Legacy, or when AZ not available |

**Availability Set** splits VMs into:
- **Fault Domain** — different racks (power/network isolation)
- **Update Domain** — Azure won't reboot all VMs at once during maintenance

```bash
# Create Availability Set
az vm availability-set create \
  --resource-group rg-myapp \
  --name myAvailSet \
  --platform-fault-domain-count 2 \
  --platform-update-domain-count 5

# Create VM in Availability Set
az vm create \
  --resource-group rg-myapp \
  --name myVM \
  --availability-set myAvailSet \
  --image Ubuntu2204 \
  --size Standard_B1s

# OR create VM in Availability Zone
az vm create \
  --resource-group rg-myapp \
  --name myVM \
  --zone 1 \
  --image Ubuntu2204 \
  --size Standard_B1s
```

**Rule of thumb:** Use Availability Zone if region supports it. Use Availability Set only for legacy or specific requirements.

## Basic VM Operations

```bash
# Create VM
az vm create \
  --resource-group rg-myapp \
  --name myVM \
  --image Ubuntu2204 \
  --size Standard_B1s \
  --admin-username azureuser \
  --generate-ssh-keys \
  --public-ip-sku Standard

# List VMs
az vm list --resource-group rg-myapp --output table

# Start / Stop / Deallocate
az vm start --resource-group rg-myapp --name myVM
az vm stop --resource-group rg-myapp --name myVM          # still pays for disk
az vm deallocate --resource-group rg-myapp --name myVM    # no charge

# Resize
az vm resize --resource-group rg-myapp --name myVM --size Standard_B2s

# SSH connect
az vm show --resource-group rg-myapp --name myVM --show-details --query publicIps -o tsv
ssh azureuser@<public-ip>

# Delete
az vm delete --resource-group rg-myapp --name myVM --yes
```

## Disk Operations

```bash
# List disks
az disk list --resource-group rg-myapp --output table

# Create and attach data disk
az vm disk attach \
  --resource-group rg-myapp \
  --vm-name myVM \
  --name myDataDisk \
  --size-gb 64 \
  --sku Premium_LRS \
  --new

# Detach disk
az vm disk detach --resource-group rg-myapp --vm-name myVM --name myDataDisk
```

## Multi-Cloud Comparison

| Concept | Azure | AWS | GCP |
|---------|-------|-----|-----|
| VM | Virtual Machine | EC2 Instance | Compute Engine |
| Image | VM Image | AMI | Machine Image |
| Size/Type | VM Size | Instance Type | Machine Type |
| Block storage | Managed Disk | EBS | Persistent Disk |
| Security rules | NSG | Security Group | Firewall Rules |
| Auto scaling | VMSS | ASG | MIG |
| Bastion | Azure Bastion | Session Manager | IAP Tunnel |
