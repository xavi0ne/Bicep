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
param kvResourceGroup string
param financialTag string 

// Resource ID's of existing resources that will be used in the deployment
var availabilitySetId = '/subscriptions/<subscriptionName>/resourceGroups/<resourceGroupName>/providers/Microsoft.Compute/<availabilitySetName>'
var imageReferenceId = '/subscriptions/<subscriptionName>/resourceGroups/${imageResourceGroup}/providers/Microsoft.Compute/galleries/<ComputeGalleryName>/images/<imageDefinitionName>/versions/${imageVersion}'

//Existing key vault URL and KEK URL
var kekUrl = '<yourkekUrl>'
var keyvaultURL = '<kvUrl>'

//existing managedID to be used for Azure Monitoring Extension resource
var userAssignedManagedId = '<yourUserAssignedManagedID>' 


//Required to pass the KeyVault Secret into Azure VM Module and for Azure Disk Encryption Extension 
resource kv 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: kvName
  scope: az.resourceGroup(kvResourceGroup)
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
  scope: az.resourceGroup(resourceGroup)
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
  scope: az.resourceGroup(resourceGroup)
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
  scope: az.resourceGroup(resourceGroup)
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
  scope: az.resourceGroup(resourceGroup)
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
  scope: az.resourceGroup(resourceGroup)
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
  scope: az.resourceGroup(resourceGroup)
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
  scope: az.resourceGroup(resourceGroup)
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
