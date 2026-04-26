param projectName string
param location string
param tags object

var nameRaw = replace(projectName, '-', '')
var suffix = uniqueString(resourceGroup().id)

resource sa 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'st${nameRaw}${suffix}'
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
}

output name string = sa.name
output id string = sa.id
