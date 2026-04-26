# --- Step 3: GitHub Actions OIDC federated identity ---
# UAMI that GHA assumes via federated credential. No client secret stored anywhere.

resource "azurerm_user_assigned_identity" "gha_deploy" {
  name                = "id-gha-deploy-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.common_tags
}

resource "azurerm_federated_identity_credential" "gha_deploy_main" {
  name      = "gha-${var.github_main_branch}"
  user_assigned_identity_id = azurerm_user_assigned_identity.gha_deploy.id
  audience  = ["api://AzureADTokenExchange"]
  issuer    = "https://token.actions.githubusercontent.com"
  subject   = "repo:${var.github_repo}:ref:refs/heads/${var.github_main_branch}"
}

# GHA needs to: push images to ACR, get admin kubeconfig from AKS, kubectl apply.
resource "azurerm_role_assignment" "gha_acrpush" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_user_assigned_identity.gha_deploy.principal_id
}

# Cluster Admin lets GHA fetch admin kubeconfig (--admin) and run kubectl.
# For prod, downgrade to "Azure Kubernetes Service Cluster User Role" + AKS RBAC roles.
resource "azurerm_role_assignment" "gha_aks_admin" {
  scope                = azurerm_kubernetes_cluster.main.id
  role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
  principal_id         = azurerm_user_assigned_identity.gha_deploy.principal_id
}

# --- Step 4: Workload Identity demo ---
# UAMI that a Pod (via K8s ServiceAccount) assumes — no secrets in the container.

resource "azurerm_user_assigned_identity" "workload" {
  name                = "id-workload-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.common_tags
}

# Federated credential maps K8s SA "default/demo-sa" → this UAMI.
resource "azurerm_federated_identity_credential" "workload_sa" {
  name      = "k8s-default-demo-sa"
  user_assigned_identity_id = azurerm_user_assigned_identity.workload.id
  audience  = ["api://AzureADTokenExchange"]
  issuer    = azurerm_kubernetes_cluster.main.oidc_issuer_url
  subject   = "system:serviceaccount:default:demo-sa"
}
