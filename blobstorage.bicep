//This template Deploys Storage Account at Scale using Array objects for storageDetails parameter to include storageName and PrivateEndpointStaticIp//
@description('Environment Name where Azure Storage will deploy')
@allowed([
  'dev'
  'stage'
  'prod'
])
param environmentName string 

param financialTag string 

param location string 
param resourceGroup string
param eventhubname string
param loganalyticsName string

@description('name is 3 to 18 characters only; to be unique and only contain lowercase letters and numbers')
param storageDetails array 

param vnetResourceGroup string 
param vnet string 
param subnet string 
param subscriptionId string

var subnetId = '/subscriptions/${subscriptionId}/resourceGroups/${vnetResourceGroup}/providers/Microsoft.Network/virtualNetworks/${vnet}/subnets/${subnet}'

@description('Resource ID of LAW')
var logAnalyitcsID = '/subscriptions/${subscriptionId}/resourcegroups/${vnetResourceGroup}/providers/microsoft.operationalinsights/workspaces/${loganalyticsName}'

@description('Resource ID of Splunk Event Hub')
var eventHubID = '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup}/providers/Microsoft.EventHub/namespaces/${eventhubname}/authorizationRules/RootManageSharedAccessKey'
var eventHub = 'cmagvatazsplunklogshare-ch'

var pvtDnsZoneId = '/subscriptions/${subscriptionId}/resourceGroups/${vnetResourceGroup}/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.usgovcloudapi.net'

resource storageDeployment 'Microsoft.Storage/storageAccounts@2022-05-01' = [ for storage in storageDetails: {
  name: '${storage.name}${environmentName}'
  location: location
  tags: {
    financial: financialTag
  }
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowCrossTenantReplication: false
    allowSharedKeyAccess: true
    encryption: {
      keySource: 'Microsoft.Storage'
      requireInfrastructureEncryption: true
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
        queue: {
          enabled: true
          keyType: 'Service'
        }
        table: {
          enabled: true
          keyType: 'Service'
        }
      }
    }
    isHnsEnabled: false
    isNfsV3Enabled: false
    keyPolicy: {
      keyExpirationPeriodInDays: 7
    }
    largeFileSharesState: 'Disabled'
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    supportsHttpsTrafficOnly: true
  }
}]

resource storageDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [ for (storage, i) in storageDetails: {
  scope: storageDeployment[i]
  name: 'diagnostics00'
  properties: {
    workspaceId: logAnalyitcsID
    eventHubAuthorizationRuleId: eventHubID
    eventHubName: eventHub
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
  }
}]

resource storageAccountBlob 'Microsoft.Storage/storageAccounts/blobServices@2022-05-01' = [ for (storage, i) in storageDetails: {
  name: 'default'
  parent: storageDeployment[i]
}]

resource storageAccountContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = [ for (storage, i) in storageDetails: {
  name: 'bups'
  parent: storageAccountBlob[i]
}]

resource diagnosticsBlob 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [ for (storage, i) in storageDetails: {
  scope: storageAccountBlob[i]
  name: 'diagnostics01'
  properties: {
    workspaceId: logAnalyitcsID
    eventHubAuthorizationRuleId: eventHubID
    eventHubName: eventHub
    logs: [
      {
        category: 'storageRead'
        enabled: true
      }
    ]
  }

}]

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = [ for (storage, i) in storageDetails: {
  name: '${storage.name}${environmentName}-pe'
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
        name: '${storage.name}${environmentName}-pe'
        properties: {
          privateLinkServiceId: resourceId(resourceGroup().name, 'Microsoft.Storage/storageAccounts', '${storage.name}${environmentName}')
          groupIds: [
            'blob'
          ]
        }
      }
    ]
    ipConfigurations: [
      {
        name: '${storage.name}${environmentName}-pe'
        properties: {
        
          groupId: 'blob'
        
          memberName: 'blob'
          
          privateIPAddress: storage.ip
        }
      }  
    ]
  }
  dependsOn: [
    storageDeployment
  ]
}]

resource pvtEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-05-01' = [ for (storage, i) in storageDetails: {
  name: '${storage.name}${environmentName}-pe/default'
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
}]

