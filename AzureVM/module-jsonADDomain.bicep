param vms object
param location string
param financialTag string
@secure()
param ProdNetworkGovDomainJoinAcct string
@secure()
param ProdNetworkGovDomainJoinPwd string

resource azurevm 'Microsoft.Compute/virtualMachines@2022-11-01' existing = {
  name: vms.Name
}
resource JsonADDomainVMExtension 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = {
  parent: azurevm
  name: 'JsonADDomainExtension'
  tags: {
    financial: financialTag
    deviceId: vms.DeviceIdTagValue
  }
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    autoUpgradeMinorVersion: true
    settings: {
      Name: vms.Domain
      User: ProdNetworkGovDomainJoinAcct
      Restart: true
      Options: 3
    }
    protectedSettings: {
      Password: ProdNetworkGovDomainJoinPwd
    }
    typeHandlerVersion: '1.3'
  }
}
