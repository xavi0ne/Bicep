param financialTag string 
param location string 
param subnetId string
param pvtDnsZoneId string
param storageDetails object
param storageAccountID string

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: '${storageDetails.storageName}pe'
  location: location
  tags: {
    financial: financialTag
  }
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${storageDetails.storageName}pe'
        properties: {
          privateLinkServiceId: storageAccountID
          groupIds: [
            'blob'
          ]
        }
      }
    ]
    ipConfigurations: [
      {
        name: '${storageDetails.storageName}pe'
        properties: {
        
          groupId: 'blob'
        
          memberName: 'blob'
          
          privateIPAddress: storageDetails.ipAddress
        }
      }  
    ]
  }
}

resource pvtEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-05-01' = {
  name: '${storageDetails.storageName}pe/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: pvtDnsZoneId
        }
      }
    ]
  }
  dependsOn: [
    privateEndpoint
  ]
}
