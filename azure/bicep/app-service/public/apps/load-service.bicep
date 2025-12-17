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

// Load Service
resource loadServiceApp 'Microsoft.Web/sites@2021-01-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    siteConfig: {
      alwaysOn: true
      healthCheckPath: '/health/live'
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
          name: 'AZURESETTINGS__MESSAGEDATAPATH'
          value: '/load-messages'
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
          name: 'LOADSETTINGS_DATA_PATH'
          value: '/load-data'
        }
      ]
      connectionStrings: [
        {
          name: 'TargetConnectionString'
          connectionString: storeConnectionString
          type: 'SQLAzure'
        }
      ]
      linuxFxVersion: 'DOCKER|ghcr.io/aubrisa/andes-load-service:azure-latest'
    }
  }
}

// Load Service Storage - /load-data
resource loadStorageSetting 'Microsoft.Web/sites/config@2021-01-15' = {
  parent: loadServiceApp
  name: 'azurestorageaccounts'
  properties: {
    'load-data': {
      type: 'AzureFiles'
      shareName: 'andes-load-data'
      mountPath: '/load-data'
      accountName: storageAccountName
      accessKey: storageKey
    }
    'load-messages': {
      type: 'AzureFiles'
      shareName: 'andes-load-messages'
      mountPath: '/load-messages'
      accountName: storageAccountName
      accessKey: storageKey
    }
  }
}
