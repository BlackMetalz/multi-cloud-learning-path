# --- Step 1: N workload VMs trong private subnet (no public IP) ---
# Cùng SSH key với bastion để demo ProxyJump dễ dàng.

locals {
  workload_cloud_init = <<-EOT
    #cloud-config
    package_update: true
    packages:
      - nginx
    write_files:
      - path: /var/www/html/index.html
        content: |
          <h1>Workload VM</h1>
          <p>Hostname: $(hostname)</p>
          <p>Reached via ProxyJump through bastion.</p>
    runcmd:
      - systemctl enable --now nginx
  EOT
}

resource "azurerm_network_interface" "workload" {
  count = var.workload_vm_count

  name                = "nic-app${count.index + 1}-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.private.id
    private_ip_address_allocation = "Dynamic"
    # No public_ip_address_id → no public IP. Đó là điểm chính của pattern.
  }
}

resource "azurerm_linux_virtual_machine" "workload" {
  count = var.workload_vm_count

  name                            = "vm-app${count.index + 1}-${local.name_prefix}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = var.vm_size
  admin_username                  = var.vm_admin_username
  network_interface_ids           = [azurerm_network_interface.workload[count.index].id]
  disable_password_authentication = true
  custom_data                     = base64encode(local.workload_cloud_init)
  tags                            = local.common_tags

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = tls_private_key.vm.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}
