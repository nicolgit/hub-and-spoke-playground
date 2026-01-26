@description('The name of the VPN Gateway')
param gatewayName string

@description('The location for the resources')
param location string

@description('The name of the virtual network')
param vnetName string

@description('The name of the gateway subnet')
param gatewaySubnetName string = 'GatewaySubnet'

@description('Whether to deploy the VPN Gateway')
param deployGateway bool

@description('The VPN Gateway SKU')
param gatewaySku string = 'VpnGw1'

@description('Whether to enable BGP')
param enableBgp bool = false

var gatewayIPName = '${gatewayName}-ip'

resource vnetGatewayIP 'Microsoft.Network/publicIPAddresses@2020-08-01' = if (deployGateway) {
  name: gatewayIPName
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource vnetGateway 'Microsoft.Network/virtualNetworkGateways@2019-09-01' = if (deployGateway) {
  name: gatewayName
  location: location
  properties: {
    ipConfigurations: [ {
        name: 'ipconfig1'
        properties: {
          subnet: { id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, gatewaySubnetName) }
          publicIPAddress: { id: vnetGatewayIP.id }
        }
      }
    ]
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: enableBgp
    bgpSettings: enableBgp ? {} : null
    sku: { name: gatewaySku, tier: gatewaySku }
  }
}

output gatewayId string = deployGateway ? vnetGateway.id : ''
output gatewayIPId string = deployGateway ? vnetGatewayIP.id : ''
output gatewayName string = deployGateway ? vnetGateway.name : ''
