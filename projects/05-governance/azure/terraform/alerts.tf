# --- Step 1: Action Group + Activity Log Alert ---

resource "azurerm_monitor_action_group" "main" {
  name                = "ag-${var.project_name}"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "kienAG" # max 12 chars
  tags                = local.common_tags

  email_receiver {
    name                    = "primary-email"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }
}

# Fire khi ai đó xoá / sửa policy assignment ở subscription scope.
resource "azurerm_monitor_activity_log_alert" "policy_changed" {
  name                = "alert-policy-assignment-changed"
  resource_group_name = azurerm_resource_group.main.name
  location            = "global"
  scopes              = [data.azurerm_subscription.current.id]
  description         = "Fire when a policy assignment is created/updated/deleted"
  tags                = local.common_tags

  criteria {
    category       = "Administrative"
    operation_name = "Microsoft.Authorization/policyAssignments/delete"
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}

# Fire khi ai đó tạo role assignment mới (privilege escalation watch).
resource "azurerm_monitor_activity_log_alert" "role_assignment" {
  name                = "alert-role-assignment-created"
  resource_group_name = azurerm_resource_group.main.name
  location            = "global"
  scopes              = [data.azurerm_subscription.current.id]
  description         = "Fire when a role assignment is created"
  tags                = local.common_tags

  criteria {
    category       = "Administrative"
    operation_name = "Microsoft.Authorization/roleAssignments/write"
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}
