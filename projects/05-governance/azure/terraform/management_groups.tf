# --- Step 1: Management Group hierarchy ---
# Root → mg-root → {mg-prod, mg-nonprod}.
# Subscription được gán vào mg-nonprod.

resource "azurerm_management_group" "root" {
  display_name = "mg-root"
  name         = "mg-root"
}

resource "azurerm_management_group" "prod" {
  display_name               = "mg-prod"
  name                       = "mg-prod"
  parent_management_group_id = azurerm_management_group.root.id
}

resource "azurerm_management_group" "nonprod" {
  display_name               = "mg-nonprod"
  name                       = "mg-nonprod"
  parent_management_group_id = azurerm_management_group.root.id

  subscription_ids = [data.azurerm_subscription.current.subscription_id]
}
