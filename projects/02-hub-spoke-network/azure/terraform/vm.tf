# --- Step 2: Linux VM + cloud-init ---

# Generate an SSH keypair so we don't depend on a local ~/.ssh.
resource "tls_private_key" "vm" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_network_interface" "vm" {
  name                = "nic-vm-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm.id
    private_ip_address_allocation = "Dynamic"
    # No public IP on purpose — access via Bastion or AppGW.
  }
}

# Cloud-init: install nginx, write a tiny landing page.
locals {
  cloud_init = <<-EOT
    #cloud-config
    package_update: true
    packages:
      - nginx
    write_files:
      - path: /var/www/html/index.html
        content: |
          <h1>Hello from VM behind hub-spoke</h1>
          <p>Hostname: $(hostname)</p>
    runcmd:
      - systemctl enable --now nginx
  EOT
}

resource "azurerm_linux_virtual_machine" "main" {
  name                            = "vm-${local.name_prefix}-${local.suffix}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = var.vm_size
  admin_username                  = var.vm_admin_username
  network_interface_ids           = [azurerm_network_interface.vm.id]
  disable_password_authentication = true
  custom_data                     = base64encode(local.cloud_init)
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

  identity {
    type = "SystemAssigned"
  }
}
