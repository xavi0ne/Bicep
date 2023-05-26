param vms object
@secure()
param dnsNetworkServer string
param location string 
param subscription string
param vnetResourceGroup string 
param vnet string 
param subnet string 

resource Nic 'Microsoft.Network/networkInterfaces@2022-07-01' = {
    name: '${vms.Name}-Nic'
    location: location
    tags: {
      deviceId: vms.DeviceIdTagValue
      financial: vms.FinancialTagValue
      role: vms.RoleTagValue
    }
    properties: {
      ipConfigurations: [
        {
          name: '${vms.Name}-Nic-Config'
          properties: {
            subnet: {
              id: '/subscriptions/${subscription}/resourceGroups/${vnetResourceGroup}/providers/Microsoft.Network/virtualNetworks/${vnet}/subnets/${subnet}'
            }
            privateIPAddress: vms.IP_Address
            privateIPAllocationMethod: 'Static'
            privateIPAddressVersion: 'IPv4'
            primary: true
          }
        }
      ]
      dnsSettings: {
        dnsServers: [
          dnsNetworkServer
        ]
        internalDnsNameLabel: vms.Name
      }
      enableAcceleratedNetworking: false
      enableIPForwarding: false
    }
  }
  output NicId string = Nic.id
