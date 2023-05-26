param vms object
param location string
param financialTag string

resource azurevm 'Microsoft.Compute/virtualMachines@2022-11-01' existing = {
  name: vms.Name
}
resource networkWatcherExt 'Microsoft.Compute/virtualMachines/extensions@2022-11-01' = {
  parent: azurevm
  name: 'NetworkWatcherAgentWindows'
  location: location
  tags: {
    financial: financialTag
  }
  properties: {
    publisher: 'Microsoft.Azure.NetworkWatcher'
    type: 'NetworkWatcherAgentWindows'
    typeHandlerVersion: '1.4'
    autoUpgradeMinorVersion: true
  }
}
