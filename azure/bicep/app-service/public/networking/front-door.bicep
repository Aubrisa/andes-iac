param profileName string
param location string = 'Global'
param wafPolicyName string
param dnsZoneName string
param mainResourceGroup string

// Define the custom hostnames and their corresponding backend App Service hostnames
param endpoints array

// Temporarily commenting out WAF policy due to ARM resource ID formatting issues
// Will re-enable once the basic Front Door deployment is working

// Azure Front Door Profile - create if not exists
resource profile 'Microsoft.Cdn/profiles@2024-02-01' = {
  name: profileName
  location: location
  sku: {
    name: 'Standard_AzureFrontDoor'
  }
}

// Default endpoint for the Front Door profile - create if not exists
resource defaultEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2024-02-01' = {
  parent: profile
  location: location
  name: '${profileName}-endpoint'
  properties: {
    enabledState: 'Enabled'
  }
}

// Loop through the endpoints to create origin groups, custom domains, and routes
@batchSize(1)
module endpointConfiguration './front-door-endpoint.bicep' = [
  for (endpoint, i) in endpoints: {
    name: 'endpoint-config-${i + 1}'
    params: {
      profileName: profile.name
      defaultEndpointName: defaultEndpoint.name
      originGroupName: '${endpoint.name}-origin-group'
      customDomainName: '${endpoint.name}-${replace(dnsZoneName, '.', '-')}'
      customHostname: endpoint.customHostname
      backendAddress: endpoint.backendAddress
      routeName: '${endpoint.name}-route'
      dnsZoneName: dnsZoneName
      endpointHostName: defaultEndpoint.properties.hostName
      mainResourceGroup: mainResourceGroup
    }
  }
]

// Commenting out security policy for now due to Standard tier limitations
// resource securityPolicy 'Microsoft.Cdn/profiles/securityPolicies@2023-05-01' = {
//   parent: profile
//   name: 'waf-policy'
//   properties: {
//     parameters: {
//       type: 'WebApplicationFirewall'
//       wafPolicy: {
//         id: wafPolicy.id
//       }
//       associations: [
//         {
//           domains: [
//             for (endpoint, i) in endpoints: {
//               id: resourceId(
//                 'Microsoft.Cdn/profiles/customDomains',
//                 profile.name,
//                 replace(endpoint.customHostname, '.', '-')
//               )
//             }
//           ]
//           patternsToMatch: [
//             '/*'
//           ]
//         }
//       ]
//     }
//   }
// }

output endpointHostName string = defaultEndpoint.properties.hostName
