@description('name is 3 to 24 characters only; to be unique and only contain lowercase letters and numbers')
param storageDetails array 
param financialTag string
param location string  
param vnetResourceGroup string 
param vnet string
param subnet string

//variables of existing resources in Azure subscription 
var subnetId = '/subscriptions/<subscriptionName>/resourceGroups/${vnetResourceGroup}/providers/Microsoft.Network/virtualNetworks/${vnet}/subnets/${subnet}'

@description('Resource ID of existing LAW')
var logAnalyitcsID = '/subscriptions/<subscriptionName>/resourcegroups/<resourceGroupName>/providers/microsoft.operationalinsights/workspaces/<logAnalyticsName>'

@description('Resource ID of existing Event Hub')
var eventHubID = '/subscriptions/<subscriptionName>/resourceGroups/<resourceGroupName>/providers/Microsoft.EventHub/namespaces/<eventHubName>/authorizationRules/RootManageSharedAccessKey'
var eventHub = '<eventHubName>'
@description('Resource ID of existing Private DNS Zone for Blob Storage in Azure Government')
var pvtDnsZoneId = '/subscriptions/<subscriptionName>/resourceGroups/<resourceGroupName>/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.usgovcloudapi.net'

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
