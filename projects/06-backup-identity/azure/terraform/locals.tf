locals {
  name_prefix = var.project_name
  suffix      = random_string.suffix.result

  alphanumeric_name = replace(var.project_name, "-", "")

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }
}
