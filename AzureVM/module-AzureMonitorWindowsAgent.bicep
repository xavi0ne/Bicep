param vms object
param location string
param financialTag string
param userAssignedManagedId string

resource azurevm 'Microsoft.Compute/virtualMachines@2022-11-01' existing = {
  name: vms.Name
}
resource MMA 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = {
  name: 'AzureMonitorWindowsAgent'
  parent: azurevm
  location: location
  tags: {
    financial: financialTag
    deviceId: vms.DeviceIdTagValue
  }
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorWindowsAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {
      authentication: {
        managedIdentity: {
          identifiername: 'mi_res_id'
          identifiervalue: userAssignedManagedId
        }
      }
    }
  }
}
