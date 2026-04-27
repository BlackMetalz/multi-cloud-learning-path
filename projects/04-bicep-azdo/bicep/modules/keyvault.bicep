param projectName string
param location string
param tags object
param tenantId string

var nameRaw = replace(projectName, '-', '')
// KV name limit: 3-24 alphanumeric. `kv-` + nameRaw (8) + `-` + 13-char uniqueString = 25 → over.
// Extra seed 'v2' để né soft-deleted KV cũ (tránh auto-recover với property mismatch).
var suffix = take(uniqueString(resourceGroup().id, 'v2'), 11)

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
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
    // KHÔNG set enablePurgeProtection — preview API treat explicit `false` như attempt to disable.
    // Omit field = default off, đúng cho lab.
    publicNetworkAccess: 'Enabled'
  }
}

output name string = kv.name
output id string = kv.id
