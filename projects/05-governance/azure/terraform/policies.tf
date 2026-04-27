# --- Step 1: Azure Policy ---
# 3 policies (2 built-in + 1 custom) gom thành 1 initiative, gán ở mg-nonprod scope.

# Built-in 1: Allowed locations
data "azurerm_policy_definition" "allowed_locations" {
  display_name = "Allowed locations"
}

# Built-in 2: Require a tag and its value on resource groups
data "azurerm_policy_definition" "require_tag_on_rg" {
  display_name = "Require a tag and its value on resource groups"
}

# Custom: Deny RG nếu không có tag "Environment"
resource "azurerm_policy_definition" "deny_untagged_rg" {
  name                = "deny-untagged-rg"
  policy_type         = "Custom"
  mode                = "All"
  display_name        = "Deny resource groups without Environment tag"
  management_group_id = azurerm_management_group.root.id

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Resources/subscriptions/resourceGroups"
        },
        {
          field  = "tags['Environment']"
          exists = "false"
        }
      ]
    }
    then = {
      effect = "deny"
    }
  })
}

# --- Initiative gom 3 policies ---

resource "azurerm_management_group_policy_set_definition" "baseline" {
  name                = "baseline-governance"
  policy_type         = "Custom"
  display_name        = "Baseline Governance Initiative"
  description         = "Allowed locations + required tags"
  management_group_id = azurerm_management_group.root.id

  parameters = jsonencode({
    allowedLocations = {
      type = "Array"
      metadata = {
        displayName = "Allowed locations"
      }
    }
    tagName = {
      type = "String"
      metadata = {
        displayName = "Required tag name on RG"
      }
      defaultValue = "Project"
    }
    tagValue = {
      type = "String"
      metadata = {
        displayName = "Required tag value on RG"
      }
      defaultValue = "fullstack-app"
    }
  })

  policy_definition_reference {
    policy_definition_id = data.azurerm_policy_definition.allowed_locations.id
    reference_id         = "AllowedLocations"
    parameter_values = jsonencode({
      listOfAllowedLocations = {
        value = "[parameters('allowedLocations')]"
      }
    })
  }

  policy_definition_reference {
    policy_definition_id = data.azurerm_policy_definition.require_tag_on_rg.id
    reference_id         = "RequireTagOnRG"
    parameter_values = jsonencode({
      tagName  = { value = "[parameters('tagName')]" }
      tagValue = { value = "[parameters('tagValue')]" }
    })
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.deny_untagged_rg.id
    reference_id         = "DenyUntaggedRG"
  }
}

# --- Assignment ở mg-nonprod scope ---

resource "azurerm_management_group_policy_assignment" "baseline" {
  name                 = "baseline-nonprod"
  display_name         = "Baseline Governance — nonprod"
  management_group_id  = azurerm_management_group.nonprod.id
  policy_definition_id = azurerm_management_group_policy_set_definition.baseline.id

  parameters = jsonencode({
    allowedLocations = {
      value = var.allowed_locations
    }
  })
}
