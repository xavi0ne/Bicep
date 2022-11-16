param sqlPEName string
param location string
param virtualNetworkName string
param subnetName string
param sqlServerName string
param sqlPEDnsGroupName string
param sqlDNSZoneName string
param peVNETLinkName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-05-01' existing = {
  name: virtualNetworkName
}
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' existing = {
  name: subnetName
  parent: virtualNetwork
}
resource sqlserver 'Microsoft.Sql/servers@2022-05-01-preview' existing = {
  name: sqlServerName
}
resource sql_PE 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: sqlPEName
  location: location
  properties: {
    subnet: {
      id: subnet.id
    }
    privateLinkServiceConnections: [
      {
        name: sqlPEName
        properties: {
          privateLinkServiceId: sqlserver.id
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
  }
  dependsOn: [
    sqlserver, virtualNetwork
  ]
}
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: sqlDNSZoneName
  location: 'global'
  properties: {}
  dependsOn: [
   virtualNetwork
  ]
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: peVNETLinkName
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}

resource sqlPEDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  parent: sql_PE
  name: sqlPEDnsGroupName
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
  dependsOn: [
   privateDnsZone
  ]
}
