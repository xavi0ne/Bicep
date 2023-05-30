@description('name is 3 to 18 characters only; to be unique and only contain lowercase letters and numbers')
param storageDetails array = [
  {
    storageName: 'buduskatest1'
    ipAddress: '10.11.0.5'
  }
]
param financialTag string = 'mo-acr-dollars'
param location string  = 'usgovvirginia'
param vnetResourceGroup string = 'automate-rg'
param vnet string = 'cmagvadev-vn'
param subnet string = 'cmagvadevvn-sn'

//variables of existing resources in Azure subscription 
var subnetId = '/subscriptions/a5cdc8eb-472c-4b8b-a3a8-70c2ba30f7bb/resourceGroups/${vnetResourceGroup}/providers/Microsoft.Network/virtualNetworks/${vnet}/subnets/${subnet}'

@description('Resource ID of LAW')
var logAnalyitcsID = '/subscriptions/a5cdc8eb-472c-4b8b-a3a8-70c2ba30f7bb/resourcegroups/automate-rg/providers/microsoft.operationalinsights/workspaces/cmagvasqlstrg007'

@description('Resource ID of Splunk Event Hub')
var eventHubID = '/subscriptions/a5cdc8eb-472c-4b8b-a3a8-70c2ba30f7bb/resourceGroups/automate-rg/providers/Microsoft.EventHub/namespaces/cmagvatazsplunklogshare-ch/authorizationRules/RootManageSharedAccessKey'
var eventHub = 'cmagvatazsplunklogshare-ch'

var pvtDnsZoneId = '/subscriptions/a5cdc8eb-472c-4b8b-a3a8-70c2ba30f7bb/resourceGroups/networking-rg/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.usgovcloudapi.net'

module deployStorageAccount 'module-storageAccount.bicep' = [ for (storage, i) in storageDetails: {
  name: 'deployBlobStorage${i}'
  scope: resourceGroup('automate-rg')
  params: {
    financialTag: financialTag
    location: location
    storageDetails: storage
  }
}]

module deployPrivateEndpoints 'module-storagePrivateEndpoint.bicep' = [ for (storage, i) in storageDetails: {
  name: 'deployStoragePE${i}'
  scope: resourceGroup('automate-rg')
  params: {
    financialTag: financialTag
    location: location
    pvtDnsZoneId: pvtDnsZoneId
    subnetId: subnetId
    storageDetails: storage
    storageAccountID: deployStorageAccount[i].outputs.storageAccountID
  }
  dependsOn: [
    deployStorageAccount
  ]
}]

module deployDiagnostics 'module-storageDiagnostics.bicep' = [ for (storage, i) in storageDetails: {
  name: 'deployStorageDiag${i}'
  scope: resourceGroup('automate-rg')
  params: {
    eventHub: eventHub
    eventHubID: eventHubID
    logAnalyitcsID: logAnalyitcsID
    storageDetails: storage
  }
  dependsOn: [
    deployPrivateEndpoints
  ]
}]

output storageAccountID array = [ for (storage, i) in storageDetails: {
  id: deployStorageAccount[i] 
}]
