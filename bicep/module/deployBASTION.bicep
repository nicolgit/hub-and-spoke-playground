@description('The name of the Azure Bastion')
param bastionName string

@description('The location for the resources')
param location string

@description('The name of the virtual network')
param vnetName string

@description('Whether to deploy the Bastion')
param deployBastion bool

@description('The bastion subnet name')
param bastionSubnetName string = 'AzureBastionSubnet'

var bastionIPName = '${bastionName}-ip'

resource bastionHubIP 'Microsoft.Network/publicIPAddresses@2020-08-01' = if (deployBastion) {
  name: bastionIPName
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource bastion 'Microsoft.Network/bastionHosts@2019-09-01' = if (deployBastion) {
  name: bastionName
  location: location
  properties: {
    ipConfigurations: [ {
        name: 'ipconfig1'
        properties: {
          subnet: { id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, bastionSubnetName) }
          publicIPAddress: { id: bastionHubIP.id }
        }
      }
    ]
  }
}

output bastionId string = deployBastion ? bastion.id : ''
output bastionIPId string = deployBastion ? bastionHubIP.id : ''
output bastionName string = deployBastion ? bastion.name : ''
