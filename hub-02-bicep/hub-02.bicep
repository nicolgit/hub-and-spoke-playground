param location string = 'northeurope'
param username string = 'nicola'

param deployBastion bool = true
param deployGateway bool = true
param deployFirewall bool = true
param deployAdditionalSpokes bool = false

@secure()
param password string = 'password.123'
param virtualMachineSKU string = 'Standard_D2s_v3'

var hublabName = 'hub-lab-02-net'
var spoke__Name = 'spoke-'
var spoke04Name = '${spoke__Name}04'


var firewallName = 'lab-firewall-02'
var firewallIPName = 'lab-firewall-02-ip'

var bastionName = 'lab-bastion-02'
var bastionIPName = 'lab-bastion-02-ip'

var diskName = 'spoke-04-vm-disk'
var vm04NICname = 'spoke-04-vm-nic'
var vm04Name = 'spoke-04-vm'
var autoshutdownName = 'shutdown-computevm-${vm04Name}'

var vnetGatewayIPName = 'lab-gateway-02-ip'
var vnetGatewayName = 'lab-gateway-02'

resource hubvnet 'Microsoft.Network/virtualNetworks@2019-09-01' = {  
  name: hublabName
  location: location
  properties: { addressSpace: { addressPrefixes: [ '10.14.0.0/16' ] }
    subnets: [
      { name: 'GatewaySubnet', properties: { addressPrefix: '10.14.4.0/24' } } 
      { name: 'AzureFirewallSubnet', properties: { addressPrefix: '10.14.3.0/24' } }
      { name: 'AzureBastionSubnet', properties: { addressPrefix: '10.14.2.0/24' } }
      { name: 'DefaultSubnet', properties: { addressPrefix: '10.14.1.0/24' } }
    ]
  }
}

resource spoke04vnet 'Microsoft.Network/virtualNetworks@2019-09-01' = {  
  name: spoke04Name
  location: location
  properties: { addressSpace: { addressPrefixes: [ '10.15.1.0/24' ] }
    subnets: [
      { name: 'default', properties: { addressPrefix: '10.15.1.0/26' } } 
      { name: 'services', properties: { addressPrefix: '10.15.1.64/26' } }
    ]
  }
}

resource spoke05vnet 'Microsoft.Network/virtualNetworks@2019-09-01' =  if(deployAdditionalSpokes) {  
  name: '${spoke__Name}05'
  location: location
  properties: { addressSpace: { addressPrefixes: [ '10.15.5.0/24' ] }
    subnets: [
      { name: 'default', properties: { addressPrefix: '10.15.5.0/26' } } 
      { name: 'services', properties: { addressPrefix: '10.15.5.64/26' } }
    ]
  }
}

resource spoke06vnet 'Microsoft.Network/virtualNetworks@2019-09-01' =  if(deployAdditionalSpokes) {  
  name: '${spoke__Name}06'
  location: location
  properties: { addressSpace: { addressPrefixes: [ '10.15.6.0/24' ] }
    subnets: [
      { name: 'default', properties: { addressPrefix: '10.15.6.0/26' } } 
      { name: 'services', properties: { addressPrefix: '10.15.6.64/26' } }
    ]
  }
}

resource spoke07vnet 'Microsoft.Network/virtualNetworks@2019-09-01' =  if(deployAdditionalSpokes) {  
  name: '${spoke__Name}07'
  location: location
  properties: { addressSpace: { addressPrefixes: [ '10.15.7.0/24' ] }
    subnets: [
      { name: 'default', properties: { addressPrefix: '10.15.7.0/26' } } 
      { name: 'services', properties: { addressPrefix: '10.15.7.64/26' } }
    ]
  }
}

resource spoke08vnet 'Microsoft.Network/virtualNetworks@2019-09-01' =  if(deployAdditionalSpokes) {  
  name: '${spoke__Name}08'
  location: location
  properties: { addressSpace: { addressPrefixes: [ '10.15.8.0/24' ] }
    subnets: [
      { name: 'default', properties: { addressPrefix: '10.15.8.0/26' } } 
      { name: 'services', properties: { addressPrefix: '10.15.8.64/26' } }
    ]
  }
}

resource spoke09vnet 'Microsoft.Network/virtualNetworks@2019-09-01' =  if(deployAdditionalSpokes) {  
  name: '${spoke__Name}09'
  location: location
  properties: { addressSpace: { addressPrefixes: [ '10.15.9.0/24' ] }
    subnets: [
      { name: 'default', properties: { addressPrefix: '10.15.9.0/26' } } 
      { name: 'services', properties: { addressPrefix: '10.15.9.64/26' } }
    ]
  }
}

resource spoke10vnet 'Microsoft.Network/virtualNetworks@2019-09-01' =  if(deployAdditionalSpokes) {  
  name: '${spoke__Name}10'
  location: location
  properties: { addressSpace: { addressPrefixes: [ '10.15.10.0/24' ] }
    subnets: [
      { name: 'default', properties: { addressPrefix: '10.15.10.0/26' } } 
      { name: 'services', properties: { addressPrefix: '10.15.10.64/26' } }
    ]
  }
}

resource peeringHubSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-09-01' = {  
  parent: hubvnet
  name: 'hub-to-spoke-04'
  properties: { allowVirtualNetworkAccess: true, allowForwardedTraffic: true, allowGatewayTransit: false, useRemoteGateways: false, remoteVirtualNetwork: { id: spoke04vnet.id } }
}

resource peeringSpokeHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-09-01' = {  
  parent: spoke04vnet
  name: 'spoke-04-to-hub'
  properties: { allowVirtualNetworkAccess: true, allowForwardedTraffic: true, allowGatewayTransit: false, useRemoteGateways: false, remoteVirtualNetwork: { id: hubvnet.id } }
}

resource peeringHubSpoke05 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-09-01' = if (deployAdditionalSpokes) {  
  parent: hubvnet
  name: 'hub-to-spoke-05'
  properties: { allowVirtualNetworkAccess: true, allowForwardedTraffic: true, allowGatewayTransit: false, useRemoteGateways: false, remoteVirtualNetwork: { id: spoke05vnet.id } }
}

resource peeringSpokeHub05 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-09-01' = if (deployAdditionalSpokes) {  
  parent: spoke05vnet
  name: 'spoke-05-to-hub'
  properties: { allowVirtualNetworkAccess: true, allowForwardedTraffic: true, allowGatewayTransit: false, useRemoteGateways: false, remoteVirtualNetwork: { id: hubvnet.id } }
}

resource peeringHubSpoke06 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-09-01' = if (deployAdditionalSpokes) {  
  parent: hubvnet
  name: 'hub-to-spoke-06'
  properties: { allowVirtualNetworkAccess: true, allowForwardedTraffic: true, allowGatewayTransit: false, useRemoteGateways: false, remoteVirtualNetwork: { id: spoke06vnet.id } }
}

resource peeringSpokeHub06 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-09-01' = if (deployAdditionalSpokes) {  
  parent: spoke06vnet
  name: 'spoke-06-to-hub'
  properties: { allowVirtualNetworkAccess: true, allowForwardedTraffic: true, allowGatewayTransit: false, useRemoteGateways: false, remoteVirtualNetwork: { id: hubvnet.id } }
}

resource peeringHubSpoke07 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-09-01' = if (deployAdditionalSpokes) {  
  parent: hubvnet
  name: 'hub-to-spoke-07'
  properties: { allowVirtualNetworkAccess: true, allowForwardedTraffic: true, allowGatewayTransit: false, useRemoteGateways: false, remoteVirtualNetwork: { id: spoke07vnet.id } }
}

resource peeringSpokeHub07 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-09-01' = if (deployAdditionalSpokes) {  
  parent: spoke07vnet
  name: 'spoke-07-to-hub'
  properties: { allowVirtualNetworkAccess: true, allowForwardedTraffic: true, allowGatewayTransit: false, useRemoteGateways: false, remoteVirtualNetwork: { id: hubvnet.id } }
}

resource peeringHubSpoke08 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-09-01' = if (deployAdditionalSpokes) {  
  parent: hubvnet
  name: 'hub-to-spoke-08'
  properties: { allowVirtualNetworkAccess: true, allowForwardedTraffic: true, allowGatewayTransit: false, useRemoteGateways: false, remoteVirtualNetwork: { id: spoke08vnet.id } }
}

resource peeringSpokeHub08 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-09-01' = if (deployAdditionalSpokes) {  
  parent: spoke08vnet
  name: 'spoke-08-to-hub'
  properties: { allowVirtualNetworkAccess: true, allowForwardedTraffic: true, allowGatewayTransit: false, useRemoteGateways: false, remoteVirtualNetwork: { id: hubvnet.id } }
}

resource peeringHubSpoke09 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-09-01' = if (deployAdditionalSpokes) {  
  parent: hubvnet
  name: 'hub-to-spoke-09'
  properties: { allowVirtualNetworkAccess: true, allowForwardedTraffic: true, allowGatewayTransit: false, useRemoteGateways: false, remoteVirtualNetwork: { id: spoke09vnet.id } }
}

resource peeringSpokeHub09 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-09-01' = if (deployAdditionalSpokes) {  
  parent: spoke09vnet
  name: 'spoke-09-to-hub'
  properties: { allowVirtualNetworkAccess: true, allowForwardedTraffic: true, allowGatewayTransit: false, useRemoteGateways: false, remoteVirtualNetwork: { id: hubvnet.id } }
}

resource peeringHubSpoke10 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-09-01' = if (deployAdditionalSpokes) {  
  parent: hubvnet
  name: 'hub-to-spoke-10'
  properties: { allowVirtualNetworkAccess: true, allowForwardedTraffic: true, allowGatewayTransit: false, useRemoteGateways: false, remoteVirtualNetwork: { id: spoke10vnet.id } }
}

resource peeringSpokeHub10 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-09-01' = if (deployAdditionalSpokes) {  
  parent: spoke10vnet
  name: 'spoke-10-to-hub'
  properties: { allowVirtualNetworkAccess: true, allowForwardedTraffic: true, allowGatewayTransit: false, useRemoteGateways: false, remoteVirtualNetwork: { id: hubvnet.id } }
}

resource firewallIP 'Microsoft.Network/publicIPAddresses@2019-09-01' = if (deployFirewall) {  
  name: firewallIPName
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource firewall 'Microsoft.Network/azureFirewalls@2019-09-01' = if (deployFirewall) {  
  name: firewallName
  location: location
  dependsOn: [ hubvnet ]
  properties: {
    ipConfigurations: [ {
        name: 'ipconfig1'
        properties: { 
          subnet: { id: resourceId('Microsoft.Network/virtualNetworks/subnets', hublabName, 'AzureFirewallSubnet') }
          publicIPAddress: { id: firewallIP.id } 
        }
      }
     ]
    sku: { name: 'AZFW_VNet', tier: 'Standard' }
  }
}

resource bastionIP 'Microsoft.Network/publicIPAddresses@2019-09-01' = if (deployBastion) {  
  name: bastionIPName
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource bastion 'Microsoft.Network/bastionHosts@2019-09-01' = if (deployBastion) {  
  name: bastionName
  location: location
  dependsOn: [ hubvnet ]
  properties: {
    ipConfigurations: [ {
        name: 'ipconfig1'
        properties: { 
          subnet: { id: resourceId('Microsoft.Network/virtualNetworks/subnets', hublabName, 'AzureBastionSubnet') }
          publicIPAddress: { id: bastionIP.id } 
        }
      }
     ]
  }
}

resource disk 'Microsoft.Compute/disks@2019-07-01' = {  
  name: diskName
  location: location
  properties: { 
    creationData: { createOption: 'Empty' }
    diskSizeGB: 128
  }
}

resource vm04NIC 'Microsoft.Network/networkInterfaces@2019-09-01' = {  
  name: vm04NICname
  location: location
  dependsOn: [ spoke04vnet ]
  properties: { 
    ipConfigurations: [ {
        name: 'ipconfig1'
        properties: { 
          subnet: { id: resourceId('Microsoft.Network/virtualNetworks/subnets', spoke04Name, 'default') }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
     ]
  }
}

resource vm04 'Microsoft.Compute/virtualMachines@2019-07-01' = {  
  name: vm04Name
  location: location
  dependsOn: [  ]
  properties: { 
    hardwareProfile: { vmSize: virtualMachineSKU }
    storageProfile: { 
      imageReference: { publisher: 'MicrosoftWindowsServer', offer: 'WindowsServer', sku: '2019-Datacenter', version: 'latest'}
      dataDisks: [ {
          lun: 0
          name: diskName
          createOption: 'Attach'
          managedDisk: { id: disk.id }
        }
       ]
    }
    osProfile: { 
      computerName: vm04Name
      adminUsername: username
      adminPassword: password
      windowsConfiguration: { enableAutomaticUpdates: true }
    }
    networkProfile: { 
      networkInterfaces: [ {
          id: vm04NIC.id
        }
       ]
    }
  }
}

resource shutdownVm04 'microsoft.devtestlab/schedules@2018-09-15' = {  
  name: autoshutdownName
  location: location
  properties: { 
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    timeZoneId: 'UTC'
    dailyRecurrence: { time: '20:00' }
    notificationSettings: { status: 'Disabled' }
    targetResourceId: vm04.id
  }
}

resource vnetGatewayIP 'Microsoft.Network/publicIPAddresses@2019-09-01' = if (deployGateway) {  
  name: vnetGatewayIPName
  location: location
  sku: { name: 'Basic'}
  properties: { publicIPAllocationMethod: 'Dynamic' }
}

resource vnetGateway 'Microsoft.Network/virtualNetworkGateways@2019-09-01' =  if (deployGateway) {  
  name: vnetGatewayName
  location: location
  dependsOn: [ hubvnet, spoke04vnet ]
  properties: { 
    ipConfigurations: [ {
        name: 'ipconfig1'
        properties: { 
          subnet: { id: resourceId('Microsoft.Network/virtualNetworks/subnets', hublabName, 'GatewaySubnet') }
          publicIPAddress: { id: vnetGatewayIP.id } 
        }
      }
     ]
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: false
    sku: { name: 'VpnGw1', tier: 'VpnGw1' }
  }
}
