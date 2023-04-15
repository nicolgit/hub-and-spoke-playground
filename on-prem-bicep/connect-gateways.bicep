param vnetGateway1Name string = 'on-prem-gateway'
param vnetGateway1Rg string = 'rg-playground-onprem'
param vnetGateway2Name string = 'lab-gateway'
param vnetGateway2Rg string = 'rg-playground-hub'
param gateway1Location string = 'francecentral'
param gateway2Location string = 'westeurope'
@secure()
param psk string = 'password.123'
param enableBgp bool = false

resource vnetGateway1 'Microsoft.Network/virtualNetworkGateways@2019-09-01' existing = {
  name: vnetGateway1Name
  scope: resourceGroup(vnetGateway1Rg)
}

resource vnetGateway2 'Microsoft.Network/virtualNetworkGateways@2019-09-01' existing = {
  name: vnetGateway2Name
  scope: resourceGroup(vnetGateway2Rg)
}

resource connection1 'Microsoft.Network/connections@2022-07-01' = {
  name: 'onprem-to-cloud'
  location: gateway1Location
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
  name: 'cloud-to-onprem'
  location: gateway2Location
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
