param location string = 'francecentral'
param username string = 'nicola'
@secure()
param password string = 'password.123'
param virtualMachineSKU string = 'Standard_D2_v5'
param deployBastion bool = true
param vnetGatewayDnsLabel string = ''
param enableBgp bool = false
param localGatewayFqdn string = ''

var onPremNetworkName = 'on-prem-net'

var bastionName = 'bastion-on-prem'
var bastionIPName = 'bastion-on-prem-publicip'

var vmOnPremDiskName = 'vm-w11-onprem-disk'
var vmOnPremNicName = 'vm-w11-onprem-nic'
var vmOnPremName = 'W11-onprem'
var autoshutdownName = 'shutdown-computevm-${vmOnPremName}'

var vnetGatewayIPName = 'onprem-gateway-virtualip'
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

resource bastionIP 'Microsoft.Network/publicIPAddresses@2020-08-01' = if (deployBastion) {
  name: bastionIPName
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource bastion 'Microsoft.Network/bastionHosts@2019-09-01' = if (deployBastion) {
  name: bastionName
  location: location
  dependsOn: [ onpremvnet ]
  properties: {
    ipConfigurations: [ {
        name: 'ipconfig1'
        properties: {
          subnet: { id: resourceId('Microsoft.Network/virtualNetworks/subnets', onPremNetworkName, 'AzureBastionSubnet') }
          publicIPAddress: { id: bastionIP.id }
        }
      }
    ]
  }
}

resource onpremdisk 'Microsoft.Compute/disks@2019-07-01' = {
  name: vmOnPremDiskName
  location: location
  properties: {
    creationData: { createOption: 'Empty' }
    diskSizeGB: 128
  }
}

resource vmonpremnic 'Microsoft.Network/networkInterfaces@2019-09-01' = {
  name: vmOnPremNicName
  location: location
  dependsOn: [ onpremvnet ]
  properties: {
    ipConfigurations: [ {
        name: 'ipconfig1'
        properties: {
          subnet: { id: resourceId('Microsoft.Network/virtualNetworks/subnets', onPremNetworkName, 'DefaultSubnet') }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource vmonprem 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: vmOnPremName
  location: location
  dependsOn: []
  properties: {
    hardwareProfile: { vmSize: virtualMachineSKU }
    storageProfile: {
      imageReference: { publisher: 'MicrosoftWindowsDesktop', offer: 'windows-11', sku: 'win11-24h2-ent', version: 'latest' }
      dataDisks: [ {
          lun: 0
          name: vmOnPremDiskName
          createOption: 'Attach'
          managedDisk: { id: onpremdisk.id }
        }
      ]
    }
    osProfile: {
      computerName: vmOnPremName
      adminUsername: username
      adminPassword: password
      windowsConfiguration: { enableAutomaticUpdates: true }
    }
    networkProfile: {
      networkInterfaces: [ {
          id: vmonpremnic.id
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
    targetResourceId: vmonprem.id
  }
}

resource vnetGatewayIP 'Microsoft.Network/publicIPAddresses@2020-08-01' = {
  name: vnetGatewayIPName
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static'}
}

resource vnetGateway1 'Microsoft.Network/virtualNetworkGateways@2022-09-01' = {
  name: vnetGatewayName
  location: location
  dependsOn: [ onpremvnet ]
  properties: {
    ipConfigurations: [ {
        name: 'ipconfig1'
        properties: {
          subnet: { id: resourceId('Microsoft.Network/virtualNetworks/subnets', onPremNetworkName, 'GatewaySubnet') }
          publicIPAddress: { id: vnetGatewayIP.id }
        }
      }
    ]
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: enableBgp
    bgpSettings: enableBgp ? {
      asn: 65510
    } : null
    sku: { name: 'VpnGw1', tier: 'VpnGw1' }
  }
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
