// Subscription-scope deployment: tạo RG + tất cả resources bên trong.
// Không có state file — ARM API là source of truth.

targetScope = 'subscription'

@description('Project name (used in resource names + tags)')
param projectName string = 'bicep-lab'

@description('Environment')
@allowed(['dev', 'prod'])
param environment string = 'dev'

@description('Azure region')
param location string = 'southeastasia'

@description('Owner tag')
param owner string = 'kien'

var commonTags = {
  Project: projectName
  Environment: environment
  ManagedBy: 'Bicep'
  Owner: owner
}

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-${projectName}-${environment}'
  location: location
  tags: commonTags
}

module storage 'modules/storage.bicep' = {
  scope: rg
  name: 'deploy-storage'
  params: {
    projectName: projectName
    location: location
    tags: commonTags
  }
}

module kv 'modules/keyvault.bicep' = {
  scope: rg
  name: 'deploy-keyvault'
  params: {
    projectName: projectName
    location: location
    tags: commonTags
    tenantId: subscription().tenantId
  }
}

module appsvc 'modules/appservice.bicep' = {
  scope: rg
  name: 'deploy-appservice'
  params: {
    projectName: projectName
    location: location
    tags: commonTags
  }
}

output resourceGroupName string = rg.name
output appServiceUrl string = appsvc.outputs.url
output storageAccountName string = storage.outputs.name
output keyVaultName string = kv.outputs.name
