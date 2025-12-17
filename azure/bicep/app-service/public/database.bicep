param databaseServerName string
param location string
param databaseUsername string
@secure()
param databasePassword string
param storeDatabaseName string
param appDatabaseName string
param tags object = {}

// Create SQL Server and disable public access
resource sqlServer 'Microsoft.Sql/servers@2024-05-01-preview' = {
  name: databaseServerName
  location: location
  tags: tags
  properties: {
    administratorLogin: databaseUsername
    administratorLoginPassword: databasePassword
    publicNetworkAccess: 'Enabled'
  }
}

// Create Store Database on SQL Server
resource sqlStoreDatabase 'Microsoft.Sql/servers/databases@2024-05-01-preview' = {
  parent: sqlServer
  name: storeDatabaseName
  location: location
  tags: tags
  sku: {
    name: 'HS_S_Gen5'
    tier: 'Hyperscale'
    family: 'Gen5'
    capacity: 2
  }
}

// Create App Database on SQL Server
resource appDatabase 'Microsoft.Sql/servers/databases@2024-05-01-preview' = {
  parent: sqlServer
  name: appDatabaseName
  location: location
  tags: tags
  sku: {
    name: 'HS_S_Gen5'
    tier: 'Hyperscale'
    family: 'Gen5'
    capacity: 2
  }
}

// Allow Azure services to access the SQL Server
resource allowAzureServices 'Microsoft.Sql/servers/firewallRules@2024-05-01-preview' = {
  parent: sqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

output sqlServerName string = sqlServer.name
