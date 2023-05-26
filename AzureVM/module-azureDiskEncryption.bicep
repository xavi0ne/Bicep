param vms object
param location string
param financialTag string
param KeyVaultURL string
param KeyEncryptionKeyURL string
param kvId string
param KekVaultResourceId string



resource azurevm 'Microsoft.Compute/virtualMachines@2022-11-01' existing = {
  name: vms.Name
}
resource ADEExtension 'Microsoft.Compute/virtualMachines/extensions@2022-08-01' = {
  parent: azurevm
  name: 'AzureDiskEncryption'
  location: location
  tags: {
    financial: financialTag
  }
  properties: {
    publisher: 'Microsoft.Azure.Security'
    type: 'AzureDiskEncryption'
    typeHandlerVersion: '2.2'
    autoUpgradeMinorVersion: true
    forceUpdateTag: guid(deployment().name)
    settings: {
      EncryptionOperation: 'EnableEncryption'
      KeyVaultURL: KeyVaultURL
      KeyVaultResourceId: kvId
      KeyEncryptionKeyURL: KeyEncryptionKeyURL
      KekVaultResourceId: KekVaultResourceId
      KeyEncryptionAlgorithm: 'RSA-OAEP'
      VolumeType: 'All'
      ResizeOSDisk: 'false'
    }
  }
} 
