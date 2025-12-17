
param dnsZone string
param appAddress string
param appName string
param appServicePlanId string
param location string

resource parentApp 'Microsoft.Web/sites@2021-01-01' existing = {
  name: appName
}

resource appCustomHost 'Microsoft.Web/sites/hostNameBindings@2020-06-01' = {
  parent: parentApp
  name: '${appAddress}.${dnsZone}'
  properties: {
    hostNameType: 'Verified'
    sslState: 'Disabled'
    customHostNameDnsRecordType: 'CName'
    siteName: '${appAddress}.${dnsZone}'
  }
}

resource appCustomHostCertificate 'Microsoft.Web/certificates@2020-06-01' = {
  name: '${appAddress}.${dnsZone}'
  location: location
  dependsOn: [
    appCustomHost
  ]
  properties: any({
    serverFarmId: appServicePlanId
    canonicalName: '${appAddress}.${dnsZone}'
  })
}

module appCustomHostEnable '../modules/sni-enable.bicep' = {
  name: '${deployment().name}-sni-enable'
  params: {
    appName: parentApp.name
    appHost: appCustomHostCertificate.name
    certificateThumbprint: appCustomHostCertificate.properties.thumbprint
  }
}
