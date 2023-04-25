param vnetGateway1Name string = 'on-prem-gateway'
param vnetGateway1Rg string = 'rg-playground-onprem'
param vnetGateway2Name string = 'lab-gateway'
param vnetGateway2Rg string = 'rg-playground-hub'
param gateway1Location string = 'francecentral'
param gateway2Location string = 'westeurope'
@secure()
param psk string = 'password.123'

resource vnetGateway1 'Microsoft.Network/virtualNetworkGateways@2019-09-01' existing = {
  name: vnetGateway1Name
  scope: resourceGroup(vnetGateway1Rg)
}

resource vnetGateway2 'Microsoft.Network/virtualNetworkGateways@2019-09-01' existing = {
  name: vnetGateway2Name
  scope: resourceGroup(vnetGateway2Rg)
}

// represents azure networks
resource localGateway1 'Microsoft.Network/localNetworkGateways@2022-09-01' existing = {
  name: 'lab-local-gateway'
  scope: resourceGroup(vnetGateway1Rg)
}

// represents onprem networks
resource localGateway2 'Microsoft.Network/localNetworkGateways@2022-09-01' existing = {
  name: 'lab-local-gateway'
  scope: resourceGroup(vnetGateway2Rg)
}

resource connection1 'Microsoft.Network/connections@2022-07-01' = {
  name: 'onprem-to-cloud'
  location: gateway1Location
  properties: {
    connectionType: 'IPsec'
    virtualNetworkGateway1: {
      id: vnetGateway1.id
      properties: {}
    }
    localNetworkGateway2: {
      id: localGateway1.id
      properties: {}
    }
    sharedKey: psk
    connectionProtocol: 'IKEv2'
    enableBgp: true
  }
}

resource connection2 'Microsoft.Network/connections@2022-07-01' = {
  name: 'cloud-to-onprem'
  location: gateway2Location
  properties: {
    connectionType: 'IPsec'
    virtualNetworkGateway1: {
      id: vnetGateway2.id
      properties: {}
    }
    localNetworkGateway2: {
      id: localGateway2.id
      properties: {}
    }
    sharedKey: psk
    connectionProtocol: 'IKEv2'
    enableBgp: true
  }
}
