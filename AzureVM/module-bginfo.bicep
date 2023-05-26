param vms object
param location string
param financialTag string

resource azurevm 'Microsoft.Compute/virtualMachines@2022-11-01' existing = {
  name: vms.Name
}
resource BGInfo 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = {
  name: 'BGInfo'
  parent: azurevm
  location: location
  tags: {
    financial: financialTag
  }
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'BGInfo'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true 
  }
}
