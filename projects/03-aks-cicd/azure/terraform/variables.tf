variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "project_name" {
  default = "gitops"
}

variable "location" {
  description = "Pre-flight check before changing: az vm list-skus -l <region> --size Standard_D2s_v3 --query \"[?length(restrictions)==\\`0\\`].name\" -o tsv"
  default     = "Southeast Asia"
}

variable "environment" {
  default = "dev"
}

variable "owner" {
  default = "kien"
}

# --- Network ---

variable "vnet_cidr" {
  default = "10.20.0.0/16"
}

variable "aks_subnet_cidr" {
  description = "Subnet for AKS nodes — Azure CNI Overlay uses 1 IP per node, so /24 is plenty"
  default     = "10.20.1.0/24"
}

# --- AKS ---

variable "aks_node_count" {
  description = "Number of nodes in default pool — keep at 1 for cram, 2-3 for HA learning"
  default     = 1
}

variable "aks_node_size" {
  description = "VM size for AKS nodes. D2s_v3 (2c/8g) is widely available; B2s often restricted"
  default     = "Standard_D2s_v3"
}

variable "aks_kubernetes_version" {
  description = "K8s version (null = AKS picks latest stable)"
  type        = string
  default     = null
}

# --- GitHub Actions OIDC ---

variable "github_repo" {
  description = "GitHub repo in 'owner/repo' format — used as OIDC subject for federated credential"
  type        = string
}

variable "github_main_branch" {
  description = "Branch authorized to deploy via OIDC"
  default     = "main"
}

# --- Monitor ---

variable "log_retention_days" {
  default = 30
}
