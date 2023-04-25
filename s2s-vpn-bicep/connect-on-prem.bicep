@description('Select the on-premises location to connect with the hub')
@allowed([ 'on-prem-gateway', 'on-prem-2-gateway' ])
param gatewayOnPremName string = 'on-prem-gateway'
param gatewayOnPremLocation string = 'francecentral'
param gatewayOnPremResourceGroup string = 'hub-and-spoke-playground'

param hubGatewayName string = 'lab-gateway'
param hubGatewayResourceGroup string = 'hub-and-spoke-playground'
param hubGatewayLocation string = 'westeurope'

@secure()
param psk string = 'pAsSwOrD.123'
param enableBgp bool = false

resource vnetGateway1 'Microsoft.Network/virtualNetworkGateways@2019-09-01' existing = {
  name: gatewayOnPremName
  scope: resourceGroup(gatewayOnPremResourceGroup)
}

resource vnetGateway2 'Microsoft.Network/virtualNetworkGateways@2019-09-01' existing = {
  name: hubGatewayName
  scope: resourceGroup(hubGatewayResourceGroup)
}

resource connection1 'Microsoft.Network/connections@2022-07-01' = {
  name: '${gatewayOnPremName}-to-cloud'
  location: gatewayOnPremLocation
  properties: {
    connectionType: 'Vnet2Vnet'
    virtualNetworkGateway1: {
      id: vnetGateway1.id
      properties: {}
    }
    virtualNetworkGateway2: {
      id: vnetGateway2.id
      properties: {}
    }
    sharedKey: psk
    connectionProtocol: 'IKEv2'
    enableBgp: enableBgp
  }
}

resource connection2 'Microsoft.Network/connections@2022-07-01' = {
  name: 'cloud-to-${gatewayOnPremName}' 
  location: hubGatewayLocation
  properties: {
    connectionType: 'Vnet2Vnet'
    virtualNetworkGateway1: {
      id: vnetGateway2.id
      properties: {}
    }
    virtualNetworkGateway2: {
      id: vnetGateway1.id
      properties: {}
    }
    sharedKey: psk
    connectionProtocol: 'IKEv2'
    enableBgp: enableBgp
  }
}
