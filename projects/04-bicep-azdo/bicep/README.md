### Local Bicep workflow (no pipeline)

```bash
cd projects/04-bicep-azdo/bicep

# 1. Make sure Bicep CLI is up to date (it ships with az CLI)
az bicep upgrade
az bicep version

# 2. Lint + transpile to ARM JSON (validates syntax)
az bicep build --file main.bicep
ls main.json   # the compiled ARM template

# 3. What-If — preview changes against ARM live state (Bicep's "terraform plan")
az deployment sub what-if \
  --location southeastasia \
  --template-file main.bicep \
  --parameters params/dev.bicepparam

# 4. Deploy
az deployment sub create \
  --location southeastasia \
  --template-file main.bicep \
  --parameters params/dev.bicepparam

# 5. Get outputs
az deployment sub show \
  --name main \
  --query properties.outputs
```

Quick verify via cli: 
```bash
RG=rg-bicep-lab-dev
az resource list -g $RG -o table
```

Expected output:
```
Name                         ResourceGroup     Location       Type                               Status
---------------------------  ----------------  -------------  ---------------------------------  ---------
stbiceplab3sxao63f2ylls      rg-bicep-lab-dev  southeastasia  Microsoft.Storage/storageAccounts  Succeeded
plan-bicep-lab               rg-bicep-lab-dev  southeastasia  Microsoft.Web/serverFarms          Succeeded
app-bicep-lab-3sxao63f2ylls  rg-bicep-lab-dev  southeastasia  Microsoft.Web/sites                Succeeded
kv-biceplab-fgfol4gsz7p      rg-bicep-lab-dev  southeastasia  Microsoft.KeyVault/vaults          Succeeded
```

### File layout

```
bicep/
├── main.bicep              # subscription-scope entry, composes modules
├── modules/
│   ├── storage.bicep       # Storage Account (LRS, no public blob)
│   ├── keyvault.bicep      # Key Vault (RBAC mode, soft-delete 7d)
│   └── appservice.bicep    # App Service Plan (F1) + Web App (nginx:alpine)
└── params/
    ├── dev.bicepparam      # type-safe params for dev
    └── prod.bicepparam     # type-safe params for prod
```

### Key Bicep concepts shown here

| File | Concept |
|---|---|
| `main.bicep` | `targetScope = 'subscription'` → tạo cả RG. Module composition (3 modules) |
| `modules/*.bicep` | Local function `uniqueString(resourceGroup().id)` cho global-unique name |
| `params/*.bicepparam` | Bicep parameter file (newer than `parameters.json`) — type-safe, IntelliSense |
| What-if | ARM-side diff, không cần state file (so với `terraform plan` cần state) |

### Cleanup

```bash
az group delete -n rg-bicep-lab-dev --yes --no-wait
```
