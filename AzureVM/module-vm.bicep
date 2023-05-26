param vms object
param location string 
@secure()
param DeploymentAdminAcct string
@secure()
param DeploymentAdminPwd string
param NicId string
param availabilitySetId string
param imageReferenceId string

resource azurevm 'Microsoft.Compute/virtualMachines@2022-11-01' = {
  name: vms.Name
  location: location
  tags: {
    deviceId: vms.DeviceIdTagValue
    financial: vms.FinancialTagValue
    imageVersion: vms.ImageTagValue
    role: vms.RoleTagValue
    schedule: vms.Schedule
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vms.Size
    }
    storageProfile: {
      imageReference: {
        id: imageReferenceId
      }
      osDisk: {
        name: '${vms.Name}_osdisk_${guid(deployment().name)}'
        osType: 'Windows'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        writeAcceleratorEnabled: false
        diskSizeGB: vms.OsDiskSize
        managedDisk: {
          storageAccountType: vms.StorageSku
        }
        deleteOption: 'Detach'
      }
      dataDisks: [
        {
          name: '${vms.Name}datadisk'
          diskSizeGB: vms.DataDisk
          createOption: 'Empty'
          lun: 1
          managedDisk: {
            storageAccountType: vms.DataDiskSKU
          }
          caching: 'None'
          writeAcceleratorEnabled: false
        }
      ]

    }
    osProfile: {
      computerName: vms.Name
      adminUsername: DeploymentAdminAcct
      adminPassword: DeploymentAdminPwd 
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        timeZone: 'Eastern Standard Time'
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
        }
      }
      secrets: []
      allowExtensionOperations: true
    }
    securityProfile: {
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
      securityType: 'TrustedLaunch'
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: NicId
          properties: {
            primary: true
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
    availabilitySet: {
      id: availabilitySetId
    }
  }
}
output vmId string = azurevm.id
