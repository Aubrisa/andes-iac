param name string
param location string
param registryUsername string
@secure()
param registryPassword string
param appServicePlanId string
param storeConnectionString string
param serviceBusConnectionString string
param appInsightsConnectionString string
param storageAccountName string

@secure()
param storageKey string
param tags object = {}

resource reportServiceApp 'Microsoft.Web/sites@2021-01-01' = {
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
          name: 'AZURESETTINGS_MESSAGEDATAPATH'
          value: '/report-messages'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'REPORTSETTINGS__REPORTPATH'
          value: '/reports'
        }
      ]
      connectionStrings: [
        {
          name: 'StoreConnectionString'
          connectionString: storeConnectionString
          type: 'SQLAzure'
        }
      ]
      linuxFxVersion: 'DOCKER|ghcr.io/aubrisa/andes-report-engine-service:azure-latest'
    }
  }
}

// Report Service Storage - /reports
resource reportServiceStorageSetting 'Microsoft.Web/sites/config@2021-01-15' = {
  parent: reportServiceApp
  name: 'azurestorageaccounts'
  properties: {
    'api-reports': {
      type: 'AzureFiles'
      shareName: 'andes-api-reports'
      mountPath: '/reports'
      accountName: storageAccountName
      accessKey: storageKey
    }
  }
}
