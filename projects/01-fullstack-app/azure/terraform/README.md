### Tutorial when you working xDD

Update `terraform.tfvars` with subscription_id. But you can remove it as well, Terraform will get it from `az account show` by default. Cleaner? xD

```bash
git clone <repo> && cd projects/01-fullstack-app/azure/terraform
az login --use-device-code
terraform init
terraform plan
```

### Refactor
Yeah, everything was putted in single file `main.tf`.

Demo desired structure
```
azure/terraform/
├── providers.tf       # terraform{}, provider{}, backend
├── variables.tf       # input variables
├── locals.tf          # naming, common tags, computed values
├── compute.tf         # Service Plan + Web App + UAMI
├── storage.tf         # Storage Account + Static Website
├── keyvault.tf        # Key Vault + Secrets + Role Assignments
├── monitor.tf         # Log Analytics + Diagnostic Settings
├── postgres.tf        # PostgreSQL + Firewall + Database
├── outputs.tf         # All outputs
├── terraform.tfvars.example
└── terraform.tfvars   # gitignored
```

Plan: No fucking module which will create over-engineer for this learning project.

```
- Create providers.tf (terraform block + provider + backend)
- Create variables.tf (existing + new vars from magic values)
- Create locals.tf (naming + common_tags)
- Create compute.tf (Service Plan + UAMI + Web App)
- Create storage.tf (Storage Account + Static Website)
- Create keyvault.tf (KV + secrets + role assignments + time_sleep)
- Create monitor.tf (Log Analytics + Diagnostic Settings)
- Create postgres.tf (random_password + http data + postgres + firewall + db)
- Create outputs.tf (all outputs)
- Slim main.tf to shared foundation (random_string + client_config + RG)
- Run terraform fmt + validate
- Run terraform plan and verify only tag additions (no recreate)
```

Remember to validate by terraform fmt && terraform validate

### Terraform Plan
Not big things change, validate by `terraform plan -out=tfplan`. We added some tags only. For example

```
  # azurerm_service_plan.main will be updated in-place
  ~ resource "azurerm_service_plan" "main" {
        id                              = "/subscriptions/subscription-id-here-bro/resourceGroups/rg-fullstack-app/providers/Microsoft.Web/serverFarms/plan-fullstack-app"
        name                            = "plan-fullstack-app"
      ~ tags                            = {
          + "Environment" = "dev"
          + "ManagedBy"   = "Terraform"
          + "Owner"       = "kien"
          + "Project"     = "fullstack-app"
        }
        # (12 unchanged attributes hidden)
    }

Apply complete! Resources: 0 added, 8 changed, 0 destroyed.

Outputs:
```