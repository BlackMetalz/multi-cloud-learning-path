# --- Step 1: Bastion VM với cloud-init harden (fail2ban) ---

resource "tls_private_key" "vm" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_public_ip" "bastion" {
  name                = "pip-bastion-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

resource "azurerm_network_interface" "bastion" {
  name                = "nic-bastion-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.bastion.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.bastion.id
  }
}

# Cloud-init: install fail2ban, default jail config bann sau 5 fails trong 10 min.
locals {
  bastion_cloud_init = <<-EOT
    #cloud-config
    package_update: true
    packages:
      - fail2ban
    write_files:
      - path: /etc/fail2ban/jail.local
        content: |
          [DEFAULT]
          bantime  = 1h
          findtime = 10m
          maxretry = 5

          [sshd]
          enabled = true
          port    = 22
    runcmd:
      - systemctl enable --now fail2ban
      - fail2ban-client status sshd > /var/log/fail2ban-startup.log
  EOT
}

resource "azurerm_linux_virtual_machine" "bastion" {
  name                            = "vm-bastion-${local.name_prefix}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = var.vm_size
  admin_username                  = var.vm_admin_username
  network_interface_ids           = [azurerm_network_interface.bastion.id]
  disable_password_authentication = true
  custom_data                     = base64encode(local.bastion_cloud_init)
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
