locals {
  name_prefix = var.project_name
  suffix      = random_string.suffix.result

  # Storage account và Key Vault name không cho dấu "-"
  alphanumeric_name = replace(var.project_name, "-", "")

  # Apply cho mọi resource — dùng cho cost tracking, ownership, automation
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }
}
