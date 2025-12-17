param profileName string
param defaultEndpointName string
param originGroupName string
param customDomainName string
param customHostname string
param backendAddress string
param routeName string
param dnsZoneName string
param endpointHostName string
param mainResourceGroup string

resource profile 'Microsoft.Cdn/profiles@2024-02-01' existing = {
  name: profileName
}

resource defaultEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2024-02-01' existing = {
  parent: profile
  name: defaultEndpointName
}

// Origin Group
resource originGroup 'Microsoft.Cdn/profiles/originGroups@2024-02-01' = {
  parent: profile
  name: originGroupName
  properties: {
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'GET'
      probeProtocol: 'Http'
      probeIntervalInSeconds: 120
    }
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 2
    }
    sessionAffinityState: 'Disabled'
    trafficRestorationTimeToHealedOrNewEndpointsInMinutes: 5
  }
}

// Origin (child of originGroup)
resource origin 'Microsoft.Cdn/profiles/originGroups/origins@2024-02-01' = {
  parent: originGroup
  name: '${originGroupName}-origin'
  properties: {
    hostName: backendAddress
    httpPort: 80
    httpsPort: 443
    originHostHeader: backendAddress
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
  }
}

resource customDomain 'Microsoft.Cdn/profiles/customDomains@2024-02-01' = {
  parent: profile
  name: customDomainName
  properties: {
    hostName: customHostname
    tlsSettings: {
      certificateType: 'ManagedCertificate'
      minimumTlsVersion: 'TLS12'
    }
  }
}

// Route to connect the custom domain to the backend origin group
resource route 'Microsoft.Cdn/profiles/afdEndpoints/routes@2024-02-01' = {
  parent: defaultEndpoint
  name: routeName
  properties: {
    customDomains: [
      {
        id: customDomain.id
      }
    ]
    originGroup: {
      id: originGroup.id
    }
    enabledState: 'Enabled'
    forwardingProtocol: 'HttpsOnly'
    httpsRedirect: 'Enabled'
    supportedProtocols: [
      'Http'
      'Https'
    ]
    linkToDefaultDomain: 'Disabled'
  }
  dependsOn: [
    cnameRecord
    validationTxtRecord
  ]
}

module cnameRecord '../../modules/dns/dns-cname.bicep' = {
  scope: resourceGroup(mainResourceGroup)
  params: {
    name: replace(customHostname, '.${dnsZoneName}', '')
    alias: endpointHostName
    dnsZone: dnsZoneName
  }
}

module validationTxtRecord '../../modules/dns/dns-txt.bicep' = {
  scope: resourceGroup(mainResourceGroup)
  params: {
    name: '_dnsauth.${replace(customHostname, '.${dnsZoneName}', '')}'
    value: customDomain.properties.validationProperties.validationToken
    dnsZone: dnsZoneName
  }
}
