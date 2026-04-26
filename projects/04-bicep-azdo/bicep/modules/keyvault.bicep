param projectName string
param location string
param tags object
param tenantId string

var nameRaw = replace(projectName, '-', '')
var suffix = uniqueString(resourceGroup().id)

resource kv 'Microsoft.KeyVault/vaults@2024-04-01-preview' = {
  name: 'kv-${nameRaw}-${suffix}'
  location: location
  tags: tags
  properties: {
    tenantId: tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    softDeleteRetentionInDays: 7
    enablePurgeProtection: false
    publicNetworkAccess: 'Enabled'
  }
}

output name string = kv.name
output id string = kv.id
