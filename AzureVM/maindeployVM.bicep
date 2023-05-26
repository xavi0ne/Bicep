param vms array 
param location string 
param subscription string 
param resourceGroup string 
param imageResourceGroup string 
param imageVersion string 
param vnetResourceGroup string 
param vnet string 
param subnet string 
param kvName string 

param financialTag string 

var availabilitySetId = '/subscriptions/94f0d762-4d1d-4342-b494-dd09fa1219ef/resourceGroups/cmagvadtecompute-rg/providers/Microsoft.Compute/availabilitySets/dte-as'
var imageReferenceId = '/subscriptions/94f0d762-4d1d-4342-b494-dd09fa1219ef/resourceGroups/${imageResourceGroup}/providers/Microsoft.Compute/galleries/tazImages/images/taz1/versions/${imageVersion}'

var kekUrl = 'https://cmagvadteadminade-kv10.vault.usgovcloudapi.net/keys/DTE-KEK01/221ae866aed642d0b8c44ae2d48c2d6c'
var keyvaultURL = 'https://cmagvadteadminade-kv10.vault.usgovcloudapi.net/'

var userAssignedManagedId = '202cc4ba-3f71-4caa-b756-1e98723814ed' 


//Required to pass the KeyVault Secret into Azure VM Module and for Azure Disk Encryption Extension 
resource kv 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: kvName
  scope: az.resourceGroup('cmagvadteadminmgmt-rg')
}

module Nic 'module-NicVM.bicep' = [ for (vm, i) in vms: {
  name: 'Nic${i}'
  scope: az.resourceGroup(subscription, resourceGroup)
  params: {
    location: location
    dnsNetworkServer: kv.getSecret('dnsNetworkServer')
    subscription: subscription
    vnetResourceGroup: vnetResourceGroup
    vnet: vnet
    subnet: subnet
    vms: vm
  }
}]

module azureVM 'module-vm.bicep' = [ for (vm, i) in vms: {
  name: 'azureVM${i}'
  scope: az.resourceGroup('cmagvadtecompute-rg')
  params: {
    DeploymentAdminAcct: kv.getSecret('deploymentadminacct') 
    DeploymentAdminPwd:  kv.getSecret('deploymentAdminPwd')
    location: location
    vms: vm
    NicId: Nic[i].outputs.NicId
    availabilitySetId: availabilitySetId
    imageReferenceId: imageReferenceId
  }
  dependsOn: [
    Nic
  ]
}]

//Deploy Azure Disk Encryption VM Extension
module ade 'module-azureDiskEncryption.bicep' = [ for (vm, i) in vms: {
  name: 'adeExtension${i}'
  scope: az.resourceGroup('cmagvadtecompute-rg')
  params: {
    financialTag: financialTag 
    KeyEncryptionKeyURL: kekUrl
    KeyVaultURL: keyvaultURL
    kvId: kv.id
    KekVaultResourceId: kv.id
    location: location
    vms: vm
  }
  dependsOn: [
    azureVM
  ]
}]

//Deploy Network Watcher VM Extension 
module netwatcher 'module-networkWatcherExt.bicep' = [ for (vm, i) in vms: {
  name: 'netwatcher${i}'
  scope: az.resourceGroup('cmagvadtecompute-rg')
  params: {
    financialTag: financialTag
    location: location 
    vms: vm
  }
  dependsOn: [
    azureVM, ade
  ]
}]

//Deploy JsonADDomain VM Extension
module jsonADDomain 'module-jsonADDomain.bicep' = [ for (vm, i) in vms: {
  name: 'jsonADDomain${i}'
  scope: az.resourceGroup('cmagvadtecompute-rg')
  params: {
    location: location
    ProdNetworkGovDomainJoinAcct: kv.getSecret('ProdNetworkGovDomainJoinAcct1')
    ProdNetworkGovDomainJoinPwd: kv.getSecret('ProdNetworkGovDomainJoinPwd')
    financialTag: financialTag
    vms: vm
  }
  dependsOn: [
    azureVM, netwatcher
  ]
}]

//Deploy VMAccessAgent
module VMAccessAgent 'module-vmAccessAgent.bicep' = [ for (vm, i) in vms: {
  name: 'VMAccessAgent${i}'
  scope: az.resourceGroup('cmagvadtecompute-rg')
  params: {
    DeploymentAdminAcct: kv.getSecret('deploymentadminacct')
    DeploymentAdminPwd: kv.getSecret('deploymentAdminPwd')
    financialTag: financialTag
    location: location
    vms: vm
  }
  dependsOn: [
    azureVM, jsonADDomain
  ]
}]

//Deploy VM Monitoring Agent 
module AzureMonitorWindowsAgent 'module-AzureMonitorWindowsAgent.bicep' = [ for (vm, i) in vms: {
  name: 'AzureMonitorWindowsAgent${i}'
  scope: az.resourceGroup('cmagvadtecompute-rg')
  params: {
    location: location
    financialTag: financialTag
    userAssignedManagedId: userAssignedManagedId
    vms: vm
  }
  dependsOn: [
    azureVM, VMAccessAgent
  ]
}]

//Deploy VM BGInfo Extension 
module BGInfoExtension 'module-bginfo.bicep' = [ for (vm, i) in vms: {
  name: 'BGInfo${i}'
  scope: az.resourceGroup('cmagvadtecompute-rg')
  params: {
    location: location
    financialTag: financialTag
    vms: vm
  }
  dependsOn: [
    azureVM, AzureMonitorWindowsAgent
  ]
}]

output nicId array = [for (vm, i) in vms:{
  id: Nic[i]
}]
