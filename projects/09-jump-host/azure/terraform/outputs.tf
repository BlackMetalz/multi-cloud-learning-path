output "bastion_public_ip" {
  value = azurerm_public_ip.bastion.ip_address
}

output "bastion_ssh_command" {
  description = "Quick one-liner để SSH vào bastion"
  value       = "ssh -i ~/.ssh/jump-host.pem ${var.vm_admin_username}@${azurerm_public_ip.bastion.ip_address}"
}

output "workload_private_ips" {
  value = azurerm_network_interface.workload[*].private_ip_address
}

output "workload_vm_names" {
  value = azurerm_linux_virtual_machine.workload[*].name
}

output "vm_ssh_private_key_pem" {
  description = "Save vào ~/.ssh/jump-host.pem và chmod 600. Cùng key cho tất cả VMs."
  value       = tls_private_key.vm.private_key_pem
  sensitive   = true
}

output "allowed_ssh_ips_effective" {
  description = "List IP đang được phép SSH vào bastion"
  value       = local.effective_allowed_ips
}

# SSH config snippet — paste vào ~/.ssh/config rồi `ssh vm-app1`, `ssh vm-app2` work ngay.
output "ssh_config_snippet" {
  description = "Paste vào ~/.ssh/config để dùng ProxyJump"
  value = join("\n", concat(
    [
      "Host bastion",
      "  HostName ${azurerm_public_ip.bastion.ip_address}",
      "  User ${var.vm_admin_username}",
      "  IdentityFile ~/.ssh/jump-host.pem",
      "  StrictHostKeyChecking accept-new",
      "",
    ],
    flatten([
      for i, vm in azurerm_linux_virtual_machine.workload : [
        "Host ${vm.name}",
        "  HostName ${azurerm_network_interface.workload[i].private_ip_address}",
        "  User ${var.vm_admin_username}",
        "  IdentityFile ~/.ssh/jump-host.pem",
        "  ProxyJump bastion",
        "  StrictHostKeyChecking accept-new",
        "",
      ]
    ])
  ))
}
