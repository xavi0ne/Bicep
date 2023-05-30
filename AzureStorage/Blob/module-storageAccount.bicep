param financialTag string 
param location string 
param storageDetails object

resource storageDeployment 'Microsoft.Storage/storageAccounts@2022-05-01' = {
    name: '${storageDetails.storageName}sg'
    location: location
    tags: {
      financial: financialTag
    }
    sku: {
      name: 'Standard_LRS'
    }
    kind: 'StorageV2'
    properties: {
      accessTier: 'Hot'
      allowBlobPublicAccess: false
      allowCrossTenantReplication: false
      allowSharedKeyAccess: true
      encryption: {
        keySource: 'Microsoft.Storage'
        requireInfrastructureEncryption: true
        services: {
          blob: {
            enabled: true
            keyType: 'Account'
          }
          file: {
            enabled: true
            keyType: 'Account'
          }
          queue: {
            enabled: true
            keyType: 'Service'
          }
          table: {
            enabled: true
            keyType: 'Service'
          }
        }
      }
      isHnsEnabled: false
      isNfsV3Enabled: false
      keyPolicy: {
        keyExpirationPeriodInDays: 7
      }
      largeFileSharesState: 'Disabled'
      minimumTlsVersion: 'TLS1_2'
      allowedCopyScope: 'PrivateLink'
      publicNetworkAccess: 'Disabled'
      networkAcls: {
        bypass: 'AzureServices'
        defaultAction: 'Deny'
      }
      supportsHttpsTrafficOnly: true
    }
  }
  resource storageAccountBlob 'Microsoft.Storage/storageAccounts/blobServices@2022-05-01' = {
    name: 'default'
    parent: storageDeployment
    properties: {
      containerDeleteRetentionPolicy: {
        enabled: true
        days: 7
      }
      deleteRetentionPolicy: {
        enabled: true
        days: 7
      }
    }
  }
  resource storageAccountContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = {
    name: 'bups'
    parent: storageAccountBlob
  }

  output storageAccountID string = storageDeployment.id
