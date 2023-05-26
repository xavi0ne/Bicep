param vms object
param location string
param financialTag string
@secure()
param DeploymentAdminAcct string
@secure()
param DeploymentAdminPwd string

resource azurevm 'Microsoft.Compute/virtualMachines@2022-11-01' existing = {
  name: vms.Name
}
resource VMAccessAgent 'Microsoft.Compute/virtualMachines/extensions@2023-03-01'= {
  name: 'VMAccessAgent'
  parent: azurevm
  location: location
  tags: {
    financial: financialTag
    deviceId: vms.DeviceIdTagValue
  }
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'VMAccessAgent'
    typeHandlerVersion: '2.4'
    autoUpgradeMinorVersion: true
    settings: {}
    protectedSettings: {
      username: DeploymentAdminAcct
      password: DeploymentAdminPwd
    }
  }
}
