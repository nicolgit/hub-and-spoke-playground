param location string = 'germanywestcentral'
param username string = 'nicola'
@secure()
param password string = 'password.123'
param virtualMachineSKU string = 'Standard_D2_v5'

var onPremNetworkName = 'on-prem-net-2'
var bastionName = 'bastion-on-prem-2'
var vmOnPremLinux01Name = 'lin-onprem'
var vmOnPremLinux02Name = 'lin-onprem-2'
var vnetGatewayName = 'on-prem-2-gateway'

resource onpremvnet2 'Microsoft.Network/virtualNetworks@2019-09-01' = {  
  name: onPremNetworkName
  location: location
  properties: { addressSpace: { addressPrefixes: [ '10.20.0.0/16' ] }
    subnets: [
      { name: 'GatewaySubnet', properties: { addressPrefix: '10.20.3.0/24' } } 
      { name: 'AzureBastionSubnet', properties: { addressPrefix: '10.20.2.0/24' } }
      { name: 'DefaultSubnet', properties: { addressPrefix: '10.20.1.0/24' } }
    ]
  }
}

module bastion './module/deployBASTION.bicep' = {
  name: 'deploy-bastion-onprem-2'
  dependsOn: [ onpremvnet2 ]
  params: {
    bastionName: bastionName
    location: location
    vnetName: onPremNetworkName
    deployBastion: true
  }
}

module vmOnPrem01 './module/deployVM.bicep' = {
  name: 'deploy-vm-onprem-01'
  dependsOn: [ onpremvnet2 ]
  params: {
    vmName: vmOnPremLinux01Name
    location: location
    virtualMachineSKU: virtualMachineSKU
    vnetName: onPremNetworkName
    subnetName: 'DefaultSubnet'
    username: username
    password: password
    imageType: 'Linux'
    deployVM: true
  }
}

module vmOnPrem02 './module/deployVM.bicep' = {
  name: 'deploy-vm-onprem-02'
  dependsOn: [ onpremvnet2 ]
  params: {
    vmName: vmOnPremLinux02Name
    location: location
    virtualMachineSKU: virtualMachineSKU
    vnetName: onPremNetworkName
    subnetName: 'DefaultSubnet'
    username: username
    password: password
    imageType: 'Linux'
    deployVM: true
  }
}

module vpnGateway './module/deployVPN.bicep' = {
  name: 'deploy-vpn-gateway-onprem-2'
  dependsOn: [ onpremvnet2 ]
  params: {
    gatewayName: vnetGatewayName
    location: location
    vnetName: onPremNetworkName
    deployGateway: true
    enableBgp: false
  }
}
