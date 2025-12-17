param dnsZone string

param name string
param alias string

resource zone 'Microsoft.Network/dnsZones@2023-07-01-preview' existing = {
  name: dnsZone
}

resource dnsCname 'Microsoft.Network/dnsZones/CNAME@2018-05-01' = {
  parent: zone
  name: name
  properties: {
    TTL: 3600
    CNAMERecord: {
      cname: alias
    }
  }
}
