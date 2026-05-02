locals {
  name_prefix = var.project_name
  suffix      = random_string.suffix.result

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }

  # Nếu user không cung cấp allowed_ssh_ips, fallback về current public IP.
  effective_allowed_ips = length(var.allowed_ssh_ips) > 0 ? var.allowed_ssh_ips : [
    "${chomp(data.http.myip.response_body)}/32"
  ]
}
