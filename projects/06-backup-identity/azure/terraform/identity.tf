# --- Step 1: Entra ID group + Custom RBAC role + Role assignment ---

# Resolve UPN → Entra ID user objects (for adding to group).
data "azuread_user" "operators" {
  for_each            = toset(var.operator_group_members)
  user_principal_name = each.value
}

resource "azuread_group" "vm_operators" {
  display_name     = "g-vm-operators"
  description      = "Members can start/stop/restart VMs in rg-${local.name_prefix}"
  security_enabled = true

  owners  = [data.azuread_client_config.current.object_id]
  members = [for u in data.azuread_user.operators : u.object_id]
}

# Custom RBAC role: chỉ start/stop/restart, không create/delete.
resource "azurerm_role_definition" "vm_operator" {
  name        = "VM Operator (${local.name_prefix})"
  scope       = azurerm_resource_group.main.id
  description = "Allows start/stop/restart VM but not create/delete"

  permissions {
    actions = [
      "Microsoft.Compute/virtualMachines/start/action",
      "Microsoft.Compute/virtualMachines/restart/action",
      "Microsoft.Compute/virtualMachines/powerOff/action",
      "Microsoft.Compute/virtualMachines/deallocate/action",
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Resources/subscriptions/resourceGroups/read",
    ]
    not_actions = []
  }

  assignable_scopes = [
    azurerm_resource_group.main.id,
  ]
}

# Assign custom role to the group at RG scope.
resource "azurerm_role_assignment" "vm_operator" {
  scope              = azurerm_resource_group.main.id
  role_definition_id = azurerm_role_definition.vm_operator.role_definition_resource_id
  principal_id       = azuread_group.vm_operators.object_id
}
