param dnsZone string

param name string
param value string

var dnsRecordTimeToLive = 3600

resource zone 'Microsoft.Network/dnsZones@2023-07-01-preview' existing = {
  name: dnsZone
}

resource dnsTxt 'Microsoft.Network/dnsZones/TXT@2018-05-01' = {
  parent: zone
  name: name
  properties: {
    TTL: dnsRecordTimeToLive
    TXTRecords: [
      {
        value: [
          value
        ]
      }
    ]
  }
}
