# --- Step 1: Subscription budget ---

resource "azurerm_consumption_budget_subscription" "main" {
  name            = "budget-${var.project_name}"
  subscription_id = data.azurerm_subscription.current.id

  amount     = var.monthly_budget_usd
  time_grain = "Monthly"

  time_period {
    start_date = formatdate("YYYY-MM-01'T'00:00:00'Z'", timestamp())
  }

  notification {
    enabled        = true
    threshold      = 50.0
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = [var.alert_email]
  }

  notification {
    enabled        = true
    threshold      = 90.0
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = [var.alert_email]
  }

  notification {
    enabled        = true
    threshold      = 100.0
    operator       = "GreaterThan"
    threshold_type = "Forecasted"
    contact_emails = [var.alert_email]
  }

  # `start_date` thay đổi mỗi lần plan vì timestamp() — ignore để tránh recreate.
  lifecycle {
    ignore_changes = [time_period]
  }
}
