param name string
param location string
param registryUsername string
@secure()
param registryPassword string
param appServicePlanId string
param clientId string
param tenantId string
@secure()
param appInsightsConnectionString string
param apiUrl string
param tags object = {}

// UI App
resource uiApp 'Microsoft.Web/sites@2021-01-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    httpsOnly: true
    serverFarmId: appServicePlanId
    siteConfig: {
      alwaysOn: true
      appSettings: [
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
          name: 'WEBSITES_PORT'
          value: '8080'
        }
        {
          name: 'ANDES_SETTINGS_API_URL'
          value: apiUrl
        }
        {
          name: 'ANDES_SETTINGS_CLIENT_ID'
          value: clientId
        }
        {
          name: 'ANDES_SETTINGS_TENANT_ID'
          value: tenantId
        }
        {
          name: 'ANDES_SETTINGS_APP_INSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
      ]
      linuxFxVersion: 'DOCKER|ghcr.io/aubrisa/andes-ui:latest'
    }
  }
}

output defaultHostname string = uiApp.properties.defaultHostName
