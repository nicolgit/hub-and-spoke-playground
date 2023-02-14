param location string = 'francecentral'
param username string = 'nicola'
param password string = 'password.123'
param virtualMachineSKU string = 'Standard_D2s_v3'

var onPremNetworkName = 'on-prem-net'

var bastionName = 'bastion-on-prem'
var bastionIPName = 'bastion-on-prem-publicip'

var vmOnPremDiskName = 'vm-w10-onprem-disk'
var vmOnPremNicName = 'vm-w10-onprem-nic'
var vmOnPremName = 'W10-onprem'
var autoshutdownName = 'shutdown-computevm-${vmOnPremName}'

var vnetGatewayIPName = 'onprem-gateway-virtualip'
var vnetGatewayName = 'on-prem-gateway'

resource onpremvnet 'Microsoft.Network/virtualNetworks@2019-09-01' = {  
  name: onPremNetworkName
  location: location
  properties: { addressSpace: { addressPrefixes: [ '192.168.0.0/16' ] }
    subnets: [
      { name: 'GatewaySubnet', properties: { addressPrefix: '192.168.3.0/24' } } 
      { name: 'AzureBastionSubnet', properties: { addressPrefix: '192.168.2.0/24' } }
      { name: 'DefaultSubnet', properties: { addressPrefix: '192.168.1.0/24' } }
    ]
  }
}

resource bastionIP 'Microsoft.Network/publicIPAddresses@2019-09-01' = {  
  name: bastionIPName
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource bastion 'Microsoft.Network/bastionHosts@2019-09-01' = {  
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
  dependsOn: [  ]
  properties: { 
    hardwareProfile: { vmSize: virtualMachineSKU }
    storageProfile: { 
      imageReference: { publisher: 'MicrosoftWindowsServer', offer: 'WindowsServer', sku: '2019-Datacenter', version: 'latest'}
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

resource vnetGatewayIP 'Microsoft.Network/publicIPAddresses@2019-09-01' = {  
  name: vnetGatewayIPName
  location: location
  sku: { name: 'Basic'}
  properties: { publicIPAllocationMethod: 'Dynamic' }
}

resource vnetGateway 'Microsoft.Network/virtualNetworkGateways@2019-09-01' = {  
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
    enableBgp: false
    sku: { name: 'VpnGw1', tier: 'VpnGw1' }
  }
}
