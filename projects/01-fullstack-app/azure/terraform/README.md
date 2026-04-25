### Tutorial when you working xDD

Update `terraform.tfvars` with subscription_id. But you can remove it as well, Terraform will get it from `az account show` by default. Cleaner? xD

```bash
git clone <repo> && cd projects/01-fullstack-app/azure/terraform
az login
terraform init
terraform plan
```