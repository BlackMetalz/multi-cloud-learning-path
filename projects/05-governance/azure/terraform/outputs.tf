output "mg_root_id" {
  value = azurerm_management_group.root.id
}

output "mg_nonprod_id" {
  value = azurerm_management_group.nonprod.id
}

output "policy_initiative_id" {
  value = azurerm_policy_set_definition.baseline.id
}

output "action_group_id" {
  value = azurerm_monitor_action_group.main.id
}

output "budget_amount_usd" {
  value = azurerm_consumption_budget_subscription.main.amount
}
