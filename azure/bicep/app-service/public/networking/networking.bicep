param appName string
param dnsZoneName string
param mainResourceGroup string
param uiAddress string
param apiAddress string
param chatAddress string

var uiCustomHostname = '${appName}.${dnsZoneName}'
var apiCustomHostname = 'api.${appName}.${dnsZoneName}'
var chatApiCustomHostname = 'chat.${appName}.${dnsZoneName}'

module frontDoorModule './front-door.bicep' = {
  name: 'frontdoor-config-${appName}'
  scope: resourceGroup(mainResourceGroup)
  params: {
    dnsZoneName: dnsZoneName
    mainResourceGroup: mainResourceGroup
    profileName: 'aubrisa-main-fd'
    wafPolicyName: 'aubrisa-main-waf'
    endpoints: [
      {
        name: 'ui-${appName}'
        customHostname: uiCustomHostname
        backendAddress: uiAddress
      }
      {
        name: 'api-${appName}'
        customHostname: apiCustomHostname
        backendAddress: apiAddress
      }
      {
        name: 'chat-api-${appName}'
        customHostname: chatApiCustomHostname
        backendAddress: chatAddress
      }
    ]
  }
}
