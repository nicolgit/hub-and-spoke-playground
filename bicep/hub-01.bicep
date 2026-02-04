param location string = 'westeurope'
param locationSpoke03 string = 'northeurope'

@description('Basic, Standard or Premium tier')
@allowed([ 'Basic', 'Standard', 'Premium' ])
param firewallTier string = 'Premium'
var firewallName = 'lab-firewall'

param deployBastion bool = true
var bastionName = 'lab-bastion'

param deployGateway bool = true
var vnetGatewayName = 'lab-gateway'

var hublabName = 'hub-lab-net'
var spoke01Name = 'spoke-01'
var spoke02Name = 'spoke-02'
var spoke03Name = 'spoke-03'

param deployVmHub bool = true
var vmHubName = 'hub-vm'
param deployVm01 bool = true
var vm01Name = '${spoke01Name}-vm'
param deployVm02 bool = true
var vm02Name = '${spoke02Name}-vm'
param deployVm03 bool = true
var vm03Name = '${spoke03Name}-vm'


@description('username administrator for all VMs')
param username string = 'nicola'

@description('username administrator password for all VMs')
@secure()
param password string = 'password.123'

param virtualMachineSKU string = 'Standard_D2_v5'


var subnets = concat(
  [
    { name: 'GatewaySubnet', properties: { addressPrefix: '10.12.4.0/24' } }
    { name: 'AzureFirewallSubnet', properties: { addressPrefix: '10.12.3.0/24' } }
    { name: 'AzureBastionSubnet', properties: { addressPrefix: '10.12.2.0/24' } }
    { name: 'DefaultSubnet', properties: { addressPrefix: '10.12.1.0/24' } }
  ],
  firewallTier == 'Basic' ? [
    {
      name: 'AzureFirewallManagementSubnet'
      properties: {
        addressPrefix: '10.12.5.0/24'
        privateEndpointNetworkPolicies: 'Enabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
      }
    }
  ] : []
)

resource hubLabVnet 'Microsoft.Network/virtualNetworks@2019-09-01' = {
  name: hublabName
  location: location
  properties: { addressSpace: { addressPrefixes: [ '10.12.0.0/16' ] }
    subnets: subnets
  }
}

module spoke01Deployment './module/deploySPOKE.bicep' = {
  name: 'spoke01Deployment'
  dependsOn: [ hubLabVnet ]
  params: {
    spokeName: spoke01Name
    spokeLocation: location
    hubVnetName: hublabName
    hubVnetId: hubLabVnet.id
    spokeAddressSpace: '10.13.1.0/24'
    defaultSubnetPrefix: '10.13.1.0/26'
    servicesSubnetPrefix: '10.13.1.64/26'
  }
}

module spoke02Deployment './module/deploySPOKE.bicep' = {
  name: 'spoke02Deployment'
  dependsOn: [ hubLabVnet ]
  params: {
    spokeName: spoke02Name
    spokeLocation: location
    hubVnetName: hublabName
    hubVnetId: hubLabVnet.id
    spokeAddressSpace: '10.13.2.0/24'
    defaultSubnetPrefix: '10.13.2.0/26'
    servicesSubnetPrefix: '10.13.2.64/26'
  }
}

module spoke03Deployment './module/deploySPOKE.bicep' = {
  name: 'spoke03Deployment'
  dependsOn: [ hubLabVnet ]
  params: {
    spokeName: spoke03Name
    spokeLocation: locationSpoke03
    hubVnetName: hublabName
    hubVnetId: hubLabVnet.id
    spokeAddressSpace: '10.13.3.0/24'
    defaultSubnetPrefix: '10.13.3.0/26'
    servicesSubnetPrefix: '10.13.3.64/26'
  }
}

module bastionDeployment './module/deployBASTION.bicep' = {
  name: 'bastionDeployment'
  dependsOn: [ hubLabVnet ]
  params: {
    bastionName: bastionName
    location: location
    vnetName: hublabName
    deployBastion: deployBastion
  }
}

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'hub-playground-ws'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

module firewallDeployment './module/deployFIREWALL.bicep' = {
  name: 'firewallDeployment'
  dependsOn: [ hubLabVnet, vpnGatewayDeployment, workspace ] // can run into some weird conflict error with the gateway
  params: {
    firewallName: firewallName
    location: location
    vnetName: hublabName
    firewallTier: firewallTier
    workspaceId: workspace.id
    workspaceName: workspace.name
  }
}

//VPN GATEWAY
module vpnGatewayDeployment './module/deployVPN.bicep' = {
  name: 'vpnGatewayDeployment'
  dependsOn: [ hubLabVnet ]
  params: {
    gatewayName: vnetGatewayName
    location: location
    vnetName: hublabName
    deployGateway: deployGateway
    gatewaySku: 'VpnGw1'
    enableBgp: false
  }
}
//END VPN GATEWAY
//VM HUB
module vmHubDeployment './module/deployVM.bicep' = {
  name: 'vmHubDeployment'
  dependsOn: [ hubLabVnet ]
  params: {
    vmName: vmHubName
    location: location
    virtualMachineSKU: virtualMachineSKU
    vnetName: hublabName
    subnetName: 'DefaultSubnet'
    username: username
    password: password
    imageType: 'WindowsServer'
    deployVM: deployVmHub
  }
}
//END VM HUB
//VM 01
module vm01Deployment './module/deployVM.bicep' = {
  name: 'vm01Deployment'
  dependsOn: [ spoke01Deployment ]
  params: {
    vmName: vm01Name
    location: location
    virtualMachineSKU: virtualMachineSKU
    vnetName: spoke01Name
    subnetName: 'default'
    username: username
    password: password
    imageType: 'WindowsServer'
    deployVM: deployVm01
  }
}
//END VM 01
//VM 02
module vm02Deployment './module/deployVM.bicep' = {
  name: 'vm02Deployment'
  dependsOn: [ spoke02Deployment ]
  params: {
    vmName: vm02Name
    location: location
    virtualMachineSKU: virtualMachineSKU
    vnetName: spoke02Name
    subnetName: 'default'
    username: username
    password: password
    imageType: 'WindowsServer'
    deployVM: deployVm02
  }
}
//END VM 02
//VM 03
module vm03Deployment './module/deployVM.bicep' = {
  name: 'vm03Deployment'
  dependsOn: [ spoke03Deployment ]
  params: {
    vmName: vm03Name
    location: locationSpoke03
    virtualMachineSKU: virtualMachineSKU
    vnetName: spoke03Name
    subnetName: 'default'
    username: username
    password: password
    imageType: 'Linux'
    deployVM: deployVm03
  }
}

//OUTPUTS
output hubVnet object = hubLabVnet
output spoke01Vnet object = spoke01Deployment.outputs.spokeVnet
output spoke02Vnet object = spoke02Deployment.outputs.spokeVnet
output spoke03Vnet object = spoke03Deployment.outputs.spokeVnet
output firewallTier string = string(firewallTier)
//END OUTPUTS
