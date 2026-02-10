param location string = 'northeurope'
param username string = 'nicola'

param deployBastion bool = true
param deployGateway bool = true
@allowed(['None', 'Basic', 'Standard', 'Premium'])
param firewallTier string = 'Premium'
param deployAdditionalSpokes bool = false
param deployVMSpoke04 bool = true

@secure()
param password string = 'password.123'
param virtualMachineSKU string = 'Standard_D2_v5'

var hublabName = 'hub-lab-02-net'
var spoke__Name = 'spoke-'
var firewallName = 'lab-firewall-02'
var firewallIPName = 'lab-firewall-02-ip'

// Spoke configuration arrays for cleaner iteration
var spokeConfigs = [
  {
    name: '${spoke__Name}04'
    addressSpace: '10.15.1.0/24'
    defaultSubnet: '10.15.1.0/26'
    servicesSubnet: '10.15.1.64/26'
    deploy: true
  }
  {
    name: '${spoke__Name}05'
    addressSpace: '10.15.5.0/24'
    defaultSubnet: '10.15.5.0/26'
    servicesSubnet: '10.15.5.64/26'
    deploy: deployAdditionalSpokes
  }
  {
    name: '${spoke__Name}06'
    addressSpace: '10.15.6.0/24'
    defaultSubnet: '10.15.6.0/26'
    servicesSubnet: '10.15.6.64/26'
    deploy: deployAdditionalSpokes
  }
  {
    name: '${spoke__Name}07'
    addressSpace: '10.15.7.0/24'
    defaultSubnet: '10.15.7.0/26'
    servicesSubnet: '10.15.7.64/26'
    deploy: deployAdditionalSpokes
  }
  {
    name: '${spoke__Name}08'
    addressSpace: '10.15.8.0/24'
    defaultSubnet: '10.15.8.0/26'
    servicesSubnet: '10.15.8.64/26'
    deploy: deployAdditionalSpokes
  }
  {
    name: '${spoke__Name}09'
    addressSpace: '10.15.9.0/24'
    defaultSubnet: '10.15.9.0/26'
    servicesSubnet: '10.15.9.64/26'
    deploy: deployAdditionalSpokes
  }
  {
    name: '${spoke__Name}10'
    addressSpace: '10.15.10.0/24'
    defaultSubnet: '10.15.10.0/26'
    servicesSubnet: '10.15.10.64/26'
    deploy: deployAdditionalSpokes
  }
]

// Hub Virtual Network
resource hubvnet 'Microsoft.Network/virtualNetworks@2019-09-01' = {
  name: hublabName
  location: location
  properties: {
    addressSpace: { addressPrefixes: ['10.14.0.0/16'] }
    subnets: [
      { name: 'GatewaySubnet', properties: { addressPrefix: '10.14.4.0/24' } }
      { name: 'AzureFirewallSubnet', properties: { addressPrefix: '10.14.3.0/24' } }
      { name: 'AzureBastionSubnet', properties: { addressPrefix: '10.14.2.0/24' } }
      { name: 'DefaultSubnet', properties: { addressPrefix: '10.14.1.0/24' } }
    ]
  }
}

// Deploy Spokes using module
module spokes 'module/deploySPOKE.bicep' = [
  for (spoke, i) in spokeConfigs: if (spoke.deploy) {
    name: 'deploy-${spoke.name}'
    params: {
      spokeName: spoke.name
      spokeLocation: location
      hubVnetName: hubvnet.name
      hubVnetId: hubvnet.id
      spokeAddressSpace: spoke.addressSpace
      defaultSubnetPrefix: spoke.defaultSubnet
      servicesSubnetPrefix: spoke.servicesSubnet
    }
  }
]

// Firewall (kept inline - module requires Log Analytics workspace)
resource firewallIP 'Microsoft.Network/publicIPAddresses@2020-08-01' = if (firewallTier != 'None') {
  name: firewallIPName
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource firewall 'Microsoft.Network/azureFirewalls@2022-09-01' = if (firewallTier != 'None') {
  name: firewallName
  location: location
  dependsOn: [hubvnet]
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: { id: resourceId('Microsoft.Network/virtualNetworks/subnets', hublabName, 'AzureFirewallSubnet') }
          publicIPAddress: { id: firewallIP.id }
        }
      }
    ]
    sku: { name: 'AZFW_VNet', tier: firewallTier }
  }
}

// Bastion using module
module bastion 'module/deployBASTION.bicep' = {
  name: 'deploy-bastion'
  dependsOn: [hubvnet]
  params: {
    bastionName: 'lab-bastion-02'
    location: location
    vnetName: hublabName
    deployBastion: deployBastion
  }
}

// VM in Spoke-04 using module
module spoke04vm 'module/deployVM.bicep' = if (deployVMSpoke04) {
  name: 'deploy-spoke04-vm'
  dependsOn: [spokes]
  params: {
    vmName: 'spoke-04-vm'
    location: location
    virtualMachineSKU: virtualMachineSKU
    vnetName: '${spoke__Name}04'
    subnetName: 'default'
    username: username
    password: password
    imageType: 'WindowsServer'
    deployVM: true
  }
}

// VPN Gateway using module
module vpnGateway 'module/deployVPN.bicep' = {
  name: 'deploy-vpn-gateway'
  dependsOn: [hubvnet, spokes]
  params: {
    gatewayName: 'lab-gateway-02'
    location: location
    vnetName: hublabName
    deployGateway: deployGateway
    enableBgp: false
    gatewaySku: 'VpnGw1'
  }
}
