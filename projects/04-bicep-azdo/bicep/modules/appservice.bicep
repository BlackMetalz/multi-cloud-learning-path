param projectName string
param location string
param tags object

var suffix = uniqueString(resourceGroup().id)

resource plan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: 'plan-${projectName}'
  location: location
  tags: tags
  sku: {
    name: 'F1'
    tier: 'Free'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource app 'Microsoft.Web/sites@2024-04-01' = {
  name: 'app-${projectName}-${suffix}'
  location: location
  tags: tags
  kind: 'app,linux,container'
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|nginx:alpine'
      alwaysOn: false
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
    }
  }
}

output url string = 'https://${app.properties.defaultHostName}'
output name string = app.name
