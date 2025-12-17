param name string
param location string
param registryUsername string
@secure()
param registryPassword string
@secure()
param apiKey string
@secure()
param appInsightsConnectionString string

@secure()
param serviceBusConnectionString string
param appServicePlanId string

param storeConnectionString string
param appConnectionString string

param storageAccountName string

@secure()
param storageKey string

@secure()
param chatBotDirectLineSecret string

@secure()
param aiApiKey string
param aiChatModelId string
param aiEndpoint string
param aiEmbeddingModelId string
param uiName string
param dnsZone string
param tags object = {}

// API App
resource apiApp 'Microsoft.Web/sites@2022-09-01' = {
  name: name
  location: location
  kind: 'app,linux'
  tags: tags
  properties: {
    serverFarmId: appServicePlanId
    siteConfig: {
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
          name: 'ENTRAID__APISECRET'
          value: apiKey
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
          name: 'WEBSITES_PORT'
          value: '8080'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'REPORTSETTINGS__REPORTPATH'
          value: '/reports'
        }
        {
          name: 'LOADSETTINGS__LOADSPATH'
          value: '/load-definitions'
        }
        {
          name: 'LOADSETTINGS__DATAPATH'
          value: '/load-data'
        }
        {
          name: 'SECURITY__CHATBOTDIRECTLINESECRET'
          value: chatBotDirectLineSecret
        }
        {
          name: 'AISETTINGS__AIAPIKEY'
          value: aiApiKey
        }
        {
          name: 'AISETTINGS__AIENDPOINT'
          value: aiEndpoint
        }
        {
          name: 'AISETTINGS__CHATMODELID'
          value: aiChatModelId
        }
        {
          name: 'AISETTINGS__EMBEDDINGMODELID'
          value: aiEmbeddingModelId
        }
      ]
      connectionStrings: [
        {
          name: 'StoreConnectionString'
          connectionString: storeConnectionString
          type: 'SQLAzure'
        }
        {
          name: 'AppConnectionString'
          connectionString: appConnectionString
          type: 'SQLAzure'
        }
      ]
      cors: {
        allowedOrigins: [
          'https://${uiName}.azurewebsites.net'
          'https://${replace(replace(uiName, 'app-service-', ''), '-ui', '')}.${dnsZone}'
        ]
        supportCredentials: true
      }
      linuxFxVersion: 'DOCKER|ghcr.io/aubrisa/andes-api:azure-latest'
      alwaysOn: true
    }

    httpsOnly: true
  }
}

// Configure app storage - data
resource apiStorageSetting 'Microsoft.Web/sites/config@2021-01-15' = {
  parent: apiApp
  name: 'azurestorageaccounts'
  properties: {
    'api-data': {
      type: 'AzureFiles'
      shareName: 'andes-api-data'
      mountPath: '/data'
      accountName: storageAccountName
      accessKey: storageKey
    }
    'api-reports': {
      type: 'AzureFiles'
      shareName: 'andes-api-reports'
      mountPath: '/reports'
      accountName: storageAccountName
      accessKey: storageKey
    }
    'load-definitions': {
      type: 'AzureFiles'
      shareName: 'andes-load-definitions'
      mountPath: '/load-definitions'
      accountName: storageAccountName
      accessKey: storageKey
    }
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

output apiAppId string = apiApp.id
output defaultHostname string = apiApp.properties.defaultHostName
