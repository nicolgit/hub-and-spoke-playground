@description('The name of the spoke virtual network')
param spokeName string

@description('The location for the spoke resources')
param spokeLocation string

@description('The hub virtual network name')
param hubVnetName string

@description('The hub virtual network ID')
param hubVnetId string

@description('The spoke address space')
param spokeAddressSpace string

@description('The default subnet address prefix')
param defaultSubnetPrefix string

@description('The services subnet address prefix')
param servicesSubnetPrefix string

resource spokeVnet 'Microsoft.Network/virtualNetworks@2019-09-01' = {
  name: spokeName
  location: spokeLocation
  properties: { 
    addressSpace: { addressPrefixes: [ spokeAddressSpace ] }
    subnets: [
      { name: 'default', properties: { addressPrefix: defaultSubnetPrefix } }
      { name: 'services', properties: { addressPrefix: servicesSubnetPrefix } }
    ]
  }
}



resource peeringSpokeHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-09-01' = {
  parent: spokeVnet
  name: '${spokeName}-to-${hubVnetName}'
  properties: { 
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: { id: hubVnetId }
  }
}

resource peeringHubSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-09-01' = {
  name: '${hubVnetName}/${hubVnetName}-to-${spokeName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: { id: spokeVnet.id }
  }
}

output spokeVnetId string = spokeVnet.id
output spokeVnetName string = spokeVnet.name
output spokeVnet object = spokeVnet
