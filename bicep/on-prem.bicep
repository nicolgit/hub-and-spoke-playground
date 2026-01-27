param location string = 'francecentral'
param deployVM bool = true 
param username string = 'nicola'
@secure()
param password string = 'password.123'
param virtualMachineSize string = 'Standard_D2_v5'
param deployBastion bool = true
param enableBgp bool = false
param localGatewayFqdn string = ''

var onPremNetworkName = 'on-prem-net'
var bastionName = 'bastion-on-prem'
var vmOnPremName = 'W11-onprem'
var vnetGatewayName = 'on-prem-gateway'
var localGatewayName = 'lab-local-gateway'

var subnets = concat(
  [
    { name: 'GatewaySubnet', properties: { addressPrefix: '192.168.3.0/24' } }
    { name: 'DefaultSubnet', properties: { addressPrefix: '192.168.1.0/24' } }
  ], deployBastion ? [
    {
      name: 'AzureBastionSubnet'
      properties: {
        addressPrefix: '192.168.2.0/24'
      }
    }
  ] : []
)

resource onpremvnet 'Microsoft.Network/virtualNetworks@2019-09-01' = {
  name: onPremNetworkName
  location: location
  properties: { addressSpace: { addressPrefixes: [ '192.168.0.0/16' ] }
    subnets: subnets
  }
}

// Deploy Bastion using module
module bastionDeployment 'deployBASTION.bicep' = if (deployBastion) {
  name: 'bastion-deployment'
  params: {
    bastionName: bastionName
    location: location
    vnetName: onPremNetworkName
    deployBastion: deployBastion
  }
  dependsOn: [
    onpremvnet
  ]
}

// Deploy VM using enhanced module (now supports Windows 11 Desktop)
module vmDeployment 'deployVM.bicep' = if (deployVM) {
  name: 'vm-deployment'
  params: {
    vmName: vmOnPremName
    location: location
    virtualMachineSKU: virtualMachineSize
    vnetName: onPremNetworkName
    subnetName: 'DefaultSubnet'
    username: username
    password: password
    imageType: 'Windows11'
    deployVM: deployVM
    diskSizeGB: 128
  }
  dependsOn: [
    onpremvnet
  ]
}

// Deploy VPN Gateway using enhanced module (now supports BGP ASN configuration)
module vpnGatewayDeployment 'deployVPN.bicep' = {
  name: 'vpn-gateway-deployment'
  params: {
    gatewayName: vnetGatewayName
    location: location
    vnetName: onPremNetworkName
    deployGateway: true
    gatewaySku: 'VpnGw1'
    enableBgp: enableBgp
    bgpAsn: 65510
  }
  dependsOn: [
    onpremvnet
  ]
}

// if we enable bgp we also need a local gateway for the connection
resource localGateway 'Microsoft.Network/localNetworkGateways@2022-09-01' = if (enableBgp) {
  name: localGatewayName
  location: location
  properties: {
    bgpSettings: {
      asn: 65511
      bgpPeeringAddress: '192.168.3.254'
    }
    localNetworkAddressSpace: {
      addressPrefixes: [
        '10.12.0.0/16'
        '10.13.1.0/24'
        '10.13.2.0/24'
        '10.13.3.0/24'
      ]
    }
    fqdn: localGatewayFqdn
  }
}
