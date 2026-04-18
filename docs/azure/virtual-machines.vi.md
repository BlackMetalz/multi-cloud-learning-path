# Azure Virtual Machines — Dành cho người biết AWS EC2

Nếu đã biết EC2, bạn đã biết 80% Azure VM. Doc này focus vào điểm khác biệt.

## Quick Mapping

```
AWS                              Azure
───────────────────────────────────────────────────
EC2 Instance                 →   Virtual Machine
AMI                          →   VM Image
Instance Type (t3.micro)     →   VM Size (Standard_B1s)
EBS Volume                   →   Managed Disk
Instance Store               →   Temporary Disk (mất khi stop)
Security Group               →   NSG (Network Security Group)
VPC + Subnet                 →   VNet + Subnet
Elastic IP                   →   Public IP (Static)
ENI                          →   NIC
Key Pair (.pem)              →   SSH Key hoặc Password
Session Manager              →   Azure Bastion
Auto Scaling Group           →   VM Scale Sets (VMSS)
Launch Template              →   VMSS Image Reference
Spot Instance                →   Spot VM
Reserved Instance            →   Reserved VM Instance
```

## Điểm khác biệt chính

| Topic | AWS | Azure |
|-------|-----|-------|
| **Stop behavior** | Stop = vẫn trả tiền EBS | Deallocate = không tính tiền (mất dynamic public IP) |
| **Disk** | EBS service riêng | Managed Disk (OS disk + Data disk) |
| **Security** | SG attach vào instance | NSG attach vào NIC hoặc Subnet |
| **Bastion** | Session Manager (free) hoặc tự dựng | Azure Bastion (managed, ~$140/tháng) |
| **Scaling** | ASG + Launch Template (tách riêng) | VMSS (all-in-one) |
| **Availability** | Chỉ có AZ | Availability Zone HOẶC Availability Set |

## 3 Thứ Cần Focus

### 1. Azure Bastion — Truy cập an toàn qua browser

AWS: Session Manager (free, dùng SSM agent) hoặc tự dựng bastion host.

Azure: Managed bastion service. Connect qua browser, không cần public IP trên VM.

```bash
# Tạo Bastion (cần AzureBastionSubnet trong VNet)
az network bastion create \
  --resource-group rg-myapp \
  --name myBastion \
  --vnet-name myVnet \
  --public-ip-address myBastionIP

# Connect qua Portal: VM → Connect → Bastion → Nhập credentials
```

**Trade-off:** Tiện nhưng tốn ~$140/tháng. Dev/test thì dùng public IP + NSG cho rẻ.

### 2. VMSS — Auto Scaling All-in-One

AWS tách riêng: Launch Template (launch cái gì) + ASG (bao nhiêu) + ALB (load balance).

Azure gộp thành VMSS: định nghĩa image, số lượng, scaling rules, và có thể kèm LB luôn.

```bash
# Tạo VMSS với auto-scaling
az vmss create \
  --resource-group rg-myapp \
  --name myScaleSet \
  --image Ubuntu2204 \
  --vm-sku Standard_B1s \
  --instance-count 2 \
  --admin-username azureuser \
  --generate-ssh-keys

# Thêm auto-scale rule (scale out khi CPU > 70%)
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

AWS chỉ có Availability Zones (datacenter riêng).

Azure có 2 concepts:

| Concept | Là gì | Khi nào dùng |
|---------|-------|--------------|
| **Availability Zone** | Datacenter riêng (như AWS AZ) | Production, cần isolation tối đa |
| **Availability Set** | Cùng datacenter, khác rack | Legacy, hoặc region không có AZ |

**Availability Set** chia VMs thành:
- **Fault Domain** — rack khác nhau (tách power/network)
- **Update Domain** — Azure không reboot tất cả VM cùng lúc khi maintenance

```bash
# Tạo Availability Set
az vm availability-set create \
  --resource-group rg-myapp \
  --name myAvailSet \
  --platform-fault-domain-count 2 \
  --platform-update-domain-count 5

# Tạo VM trong Availability Set
az vm create \
  --resource-group rg-myapp \
  --name myVM \
  --availability-set myAvailSet \
  --image Ubuntu2204 \
  --size Standard_B1s

# HOẶC tạo VM trong Availability Zone
az vm create \
  --resource-group rg-myapp \
  --name myVM \
  --zone 1 \
  --image Ubuntu2204 \
  --size Standard_B1s
```

**Nguyên tắc:** Dùng Availability Zone nếu region hỗ trợ. Dùng Availability Set chỉ khi legacy hoặc yêu cầu đặc biệt.

## Các thao tác VM cơ bản

```bash
# Tạo VM
az vm create \
  --resource-group rg-myapp \
  --name myVM \
  --image Ubuntu2204 \
  --size Standard_B1s \
  --admin-username azureuser \
  --generate-ssh-keys \
  --public-ip-sku Standard

# Liệt kê VMs
az vm list --resource-group rg-myapp --output table

# Start / Stop / Deallocate
az vm start --resource-group rg-myapp --name myVM
az vm stop --resource-group rg-myapp --name myVM          # vẫn trả tiền disk
az vm deallocate --resource-group rg-myapp --name myVM    # không tính tiền

# Resize
az vm resize --resource-group rg-myapp --name myVM --size Standard_B2s

# SSH connect
az vm show --resource-group rg-myapp --name myVM --show-details --query publicIps -o tsv
ssh azureuser@<public-ip>

# Xóa
az vm delete --resource-group rg-myapp --name myVM --yes
```

## Thao tác Disk

```bash
# Liệt kê disks
az disk list --resource-group rg-myapp --output table

# Tạo và attach data disk
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

## So sánh Multi-Cloud

| Concept | Azure | AWS | GCP |
|---------|-------|-----|-----|
| VM | Virtual Machine | EC2 Instance | Compute Engine |
| Image | VM Image | AMI | Machine Image |
| Size/Type | VM Size | Instance Type | Machine Type |
| Block storage | Managed Disk | EBS | Persistent Disk |
| Security rules | NSG | Security Group | Firewall Rules |
| Auto scaling | VMSS | ASG | MIG |
| Bastion | Azure Bastion | Session Manager | IAP Tunnel |
