param name string
param location string
param registryUsername string
@secure()
param registryPassword string
param appServicePlanId string
param storeConnectionString string
param serviceBusConnectionString string
param appInsightsConnectionString string
param tags object = {}

// Adjustment Service
resource adjustmentServiceApp 'Microsoft.Web/sites@2021-01-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    siteConfig: {
      alwaysOn: true
      appSettings: [
        {
          name: 'WEBSITES_PORT'
          value: '8080'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: registryPassword
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'ghcr.io'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: registryUsername
        }
        {
          name: 'AZURESETTINGS__SERVICEBUSCONNECTIONSTRING'
          value: serviceBusConnectionString
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
      ]
      connectionStrings: [
        {
          name: 'StoreConnectionString'
          connectionString: storeConnectionString
          type: 'SQLAzure'
        }
      ]
      linuxFxVersion: 'DOCKER|ghcr.io/aubrisa/andes-adjustment-service:azure-latest'
    }
  }
}
