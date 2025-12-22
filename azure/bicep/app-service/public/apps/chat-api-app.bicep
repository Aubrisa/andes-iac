param name string
param location string
param registryUsername string
@secure()
param registryPassword string
param appServicePlanId string
param serviceBusConnectionString string
param appInsightsConnectionString string
param BotAppId string
param tenantId string
@secure()
param chatApiKey string
param BotOAuthConnectionName string
@secure()
param aiApiKey string
param aiEndpoint string

@secure()
param aiSearchApiKey string

param aiChatSearchEndpoint string
param aiChatSearchIndexName string
param aiChatModelId string
param aiEmbeddingModelId string
param tags object = {}

resource chatApiApp 'Microsoft.Web/sites@2021-01-01' = {
  name: name
  location: location
  tags: tags
  properties: {
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
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'APPLICATIONINSIGHTSAGENT_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'MicrosoftAppType'
          value: 'Singletenant'
        }
        {
          name: 'MicrosoftAppId'
          value: BotAppId
        }
        {
          name: 'MicrosoftAppTenantId'
          value: tenantId
        }
        {
          name: 'MicrosoftAppPassword'
          value: chatApiKey
        }
        {
          name: 'CHATSETTINGS__AUTHENTICATIONCONFIGNAME'
          value: BotOAuthConnectionName
        }
        {
          name: 'CHATSETTINGS__AIAPIKEY'
          value: aiApiKey
        }
        {
          name: 'CHATSETTINGS__AIENDPOINT'
          value: aiEndpoint
        }
        {
          name: 'CHATSETTINGS__CHATMODELID'
          value: aiChatModelId
        }
        {
          name: 'CHATSETTINGS__EMBEDDINGMODELID'
          value: aiEmbeddingModelId
        }
        {
          name: 'CHATSETTINGS__SEARCHENDPOINT'
          value: aiChatSearchEndpoint
        }
        {
          name: 'CHATSETTINGS__SEARCHINDEXNAME'
          value: aiChatSearchIndexName
        }
        {
          name: 'CHATSETTINGS__SEARCHAPIKEY'
          value: aiSearchApiKey
        }
      ]
      linuxFxVersion: 'DOCKER|ghcr.io/aubrisa/andes-chat-api:azure-latest'
    }

    serverFarmId: appServicePlanId
  }
}

output defaultHostname string = chatApiApp.properties.defaultHostName
