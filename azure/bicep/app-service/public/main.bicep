/*
  ** AUBRISA Andes Azure Deployment
  ** ------------------------------
  **
  ** Usage: 
            az deployment group create `
              --resource-group [resource group] `
              --template-file main.bicep `
              --parameters parameters\[environment].json

    Application
    -----------
    - App Service
      - API Service
      - UI Service
      - Load Service
      - Report Service
      - Murex Calculation Service
      - Chat Bot Service

    - SQL Database
      - Store Database
      - App Database

    - Storage
    
    - Service Bus

    - Application Insights

    Network
    -------

    - VNet
    - Azure Front Door
      - WAF policy

*/

param registryUsername string

@secure()
param registryPassword string

@secure()
param apiKey string

@secure()
param chatApiKey string

param clientId string
param tenantId string

param BotAppId string

param dnsZone string

param mainResourceGroup string = 'aubrisa-main'

param appName string
param displayName string

param databaseUsername string

@secure()
param databasePassword string

param sku string = 'P1v3' // The SKU of App Service Plan

param location string = resourceGroup().location

// Standard tags for all resources
var standardTags = {
  Environment: appName
  Project: 'Andes'
  ManagedBy: 'Bicep'
  CostCenter: 'Aubrisa'
}

var appServicePlanName = toLower('app-service-plan-${appName}')

var apiName = toLower('app-service-${appName}-api')

var uiName = toLower('app-service-${appName}-ui')

var loadServiceName = toLower('app-service-${appName}-load-service')

var reportServiceName = toLower('app-service-${appName}-report-service')

var adjustmentServiceName = toLower('app-service-${appName}-adjustment-service')

var murexCalculationServiceName = toLower('app-service-${appName}-murex-calculation-service')

var storageAccountName = toLower(replace('${appName}apistorage', '-', ''))

var databaseServerName = '${appName}-database-server'

var storeDatabaseName = 'Andes_Store_${displayName}'

var appDatabaseName = 'Andes_App_${displayName}'

var serviceBusName = toLower('service-bus-${appName}')

var chatApiAppName = toLower('app-service-${appName}-chat-api')

var BotOAuthConnectionName = 'Azure AD'

var apiUrl = 'https://api.${appName}.${dnsZone}'

@secure()
param aiApiKey string

@secure()
param aiSearchApiKey string

var aiEndpoint = 'https://aubrisa-openai-research.openai.azure.com/'
var aiSearchEndpoint = 'https://ai-search-andes-docs.search.windows.net/'
var aiSearchIndexName = 'vector-docs-user'
var aiChatModelId = 'gpt4'
var aiEmbeddingModelId = 'text-embedding-ada-002'

module logging './logging.bicep' = {
  name: 'logging-${appName}'
  params: {
    appName: appName
    location: location
    tags: standardTags
  }
}

module database './database.bicep' = {
  name: 'database-${appName}'
  params: {
    databaseServerName: databaseServerName
    location: location
    databaseUsername: databaseUsername
    databasePassword: databasePassword
    storeDatabaseName: storeDatabaseName
    appDatabaseName: appDatabaseName
    tags: standardTags
  }
}

var sqlServerName = database.outputs.sqlServerName

var storeConnectionString = 'Server=tcp:${sqlServerName}${environment().suffixes.sqlServerHostname},1433;Initial Catalog=${storeDatabaseName};Persist Security Info=False;User ID=${databaseUsername};Password=${databasePassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
var appConnectionString = 'Server=tcp:${sqlServerName}${environment().suffixes.sqlServerHostname},1433;Initial Catalog=${appDatabaseName};Persist Security Info=False;User ID=${databaseUsername};Password=${databasePassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'

resource appServicePlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appServicePlanName
  location: location
  tags: standardTags
  properties: {
    reserved: true
  }
  sku: {
    name: sku
  }
  kind: 'linux'
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  tags: standardTags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }

  resource service 'fileServices' = {
    name: 'default'

    resource shareData 'shares' = {
      name: 'andes-api-data'
    }

    resource shareReports 'shares' = {
      name: 'andes-api-reports'
    }

    resource shareLoadData 'shares' = {
      name: 'andes-load-data'
    }

    resource shareLoadDefinitions 'shares' = {
      name: 'andes-load-definitions'
    }

    resource shareLoadMessages 'shares' = {
      name: 'andes-load-messages'
    }
  }
}

var storageKey = storageAccount.listKeys().keys[0].value

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' = {
  name: serviceBusName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {}
}

var serviceBusEndpoint = '${serviceBusNamespace.id}/AuthorizationRules/RootManageSharedAccessKey'
var serviceBusConnectionString = listKeys(serviceBusEndpoint, serviceBusNamespace.apiVersion).primaryConnectionString

module chatApiApp './apps/chat-api-app.bicep' = {
  name: chatApiAppName
  params: {
    name: chatApiAppName
    location: location
    registryUsername: registryUsername
    registryPassword: registryPassword
    appServicePlanId: appServicePlan.id
    serviceBusConnectionString: serviceBusConnectionString
    appInsightsConnectionString: logging.outputs.appInsightsConnectionString
    BotAppId: BotAppId
    tenantId: tenantId
    chatApiKey: chatApiKey
    BotOAuthConnectionName: BotOAuthConnectionName
    aiApiKey: aiApiKey
    aiEndpoint: aiEndpoint
    aiSearchApiKey: aiSearchApiKey
    aiChatSearchEndpoint: aiSearchEndpoint
    aiChatSearchIndexName: aiSearchIndexName
    aiChatModelId: aiChatModelId
    aiEmbeddingModelId: aiEmbeddingModelId
    tags: standardTags
  }
  dependsOn: [
    database
  ]
}

module apiApp './apps/api-app.bicep' = {
  name: apiName
  params: {
    name: apiName
    location: location
    appServicePlanId: appServicePlan.id
    registryUsername: registryUsername
    registryPassword: registryPassword
    apiKey: apiKey
    serviceBusConnectionString: serviceBusConnectionString
    appConnectionString: appConnectionString
    storeConnectionString: storeConnectionString
    appInsightsConnectionString: logging.outputs.appInsightsConnectionString
    storageAccountName: storageAccount.name
    storageKey: storageKey
    chatBotDirectLineSecret: 'todo'
    aiApiKey: aiApiKey
    aiEndpoint: aiEndpoint
    aiChatModelId: aiChatModelId
    aiEmbeddingModelId: aiEmbeddingModelId
    dnsZone: dnsZone
    uiName: uiName
    tags: standardTags
  }
}

module uiApp './apps/ui-app.bicep' = {
  name: uiName
  params: {
    name: uiName
    location: location
    clientId: clientId
    tenantId: tenantId
    apiUrl: apiUrl
    appInsightsConnectionString: logging.outputs.appInsightsConnectionString
    registryUsername: registryUsername
    registryPassword: registryPassword
    appServicePlanId: appServicePlan.id
    tags: standardTags
  }
}

module reportService 'apps/report-service.bicep' = {
  name: reportServiceName
  params: {
    name: reportServiceName
    location: location
    registryUsername: registryUsername
    registryPassword: registryPassword
    appServicePlanId: appServicePlan.id
    storeConnectionString: storeConnectionString
    serviceBusConnectionString: serviceBusConnectionString
    appInsightsConnectionString: logging.outputs.appInsightsConnectionString
    storageAccountName: storageAccount.name
    storageKey: storageKey
  }
  dependsOn: []
}

module adjustmentService 'apps/adjustments-service.bicep' = {
  name: adjustmentServiceName
  params: {
    name: adjustmentServiceName
    location: location
    registryUsername: registryUsername
    registryPassword: registryPassword
    appServicePlanId: appServicePlan.id
    storeConnectionString: storeConnectionString
    serviceBusConnectionString: serviceBusConnectionString
    appInsightsConnectionString: logging.outputs.appInsightsConnectionString
    tags: standardTags
  }
  dependsOn: []
}

module loadService 'apps/load-service.bicep' = {
  name: loadServiceName
  params: {
    name: loadServiceName
    location: location
    registryUsername: registryUsername
    registryPassword: registryPassword
    appServicePlanId: appServicePlan.id
    storeConnectionString: storeConnectionString
    serviceBusConnectionString: serviceBusConnectionString
    appInsightsConnectionString: logging.outputs.appInsightsConnectionString
    storageAccountName: storageAccount.name
    storageKey: storageKey
    tags: standardTags
  }
  dependsOn: []
}

module murexCalculationService 'apps/murex-calculation-service.bicep' = {
  name: murexCalculationServiceName
  params: {
    name: murexCalculationServiceName
    location: location
    registryUsername: registryUsername
    registryPassword: registryPassword
    appServicePlanId: appServicePlan.id
    storeConnectionString: storeConnectionString
    serviceBusConnectionString: serviceBusConnectionString
    appInsightsConnectionString: logging.outputs.appInsightsConnectionString
    tags: standardTags
  }
  dependsOn: []
}

module networking './networking/networking.bicep' = {
  name: 'networking-${appName}'
  params: {
    dnsZoneName: dnsZone
    mainResourceGroup: mainResourceGroup
    appName: appName
    uiAddress: uiApp.outputs.defaultHostname
    apiAddress: apiApp.outputs.defaultHostname
    chatAddress: chatApiApp.outputs.defaultHostname
  }
}
