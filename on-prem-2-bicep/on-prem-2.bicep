param location string = 'germanywestcentral'
param username string = 'nicola'
param password string = 'password.123'
param virtualMachineSKU string = 'Standard_D2s_v3'

var onPremNetworkName = 'on-prem-net-2'

var bastionName = 'bastion-on-prem-2'
var bastionIPName = 'bastion-on-prem-2-publicip'

var vmOnPremLinux01DiskName = 'vm-linux-onprem-01-disk'
var vmOnPremLinux01NicName = 'vm-linux-01-onprem-nic'
var vmOnPremLinux01Name = 'lin-onprem'
var autoshutdownLinux01Name = 'shutdown-computevm-${vmOnPremLinux01Name}'

var vmOnPremLinux02DiskName = 'vm-linux-onprem-02-disk'
var vmOnPremLinux02NicName = 'vm-linux-02-onprem-nic'
var vmOnPremLinux02Name = 'lin-onprem-2'
var autoshutdownLinux02Name = 'shutdown-computevm-${vmOnPremLinux02Name}'

var vnetGatewayIPName = 'onprem-2-gateway-virtualip'
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

resource bastionIP 'Microsoft.Network/publicIPAddresses@2019-09-01' = {  
  name: bastionIPName
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource bastion 'Microsoft.Network/bastionHosts@2019-09-01' = {  
  name: bastionName
  location: location
  dependsOn: [ onpremvnet2 ]
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

resource onpremdisk01 'Microsoft.Compute/disks@2019-07-01' = {  
  name: vmOnPremLinux01DiskName
  location: location
  properties: { 
    creationData: { createOption: 'Empty' }
    diskSizeGB: 128
  }
}

resource vmonpremnic01 'Microsoft.Network/networkInterfaces@2019-09-01' = {  
  name: vmOnPremLinux01NicName
  location: location
  dependsOn: [ onpremvnet2 ]
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

resource vmonprem01 'Microsoft.Compute/virtualMachines@2019-07-01' = {  
  name: vmOnPremLinux01Name
  location: location
  dependsOn: [  ]
  properties: { 
    hardwareProfile: { vmSize: virtualMachineSKU }
    storageProfile: { 
      imageReference: { publisher: 'Canonical', offer: 'UbuntuServer', sku: '19_04-gen2', version: 'latest'}
      dataDisks: [ {
          lun: 0
          name: vmOnPremLinux01DiskName
          createOption: 'Attach'
          managedDisk: { id: onpremdisk01.id }
        }
       ]
    }
    osProfile: { 
      computerName: vmOnPremLinux01Name
      adminUsername: username
      adminPassword: password
      linuxConfiguration: {
        disablePasswordAuthentication: false
        provisionVMAgent: true
      }
    }
    networkProfile: { 
      networkInterfaces: [ {
          id: vmonpremnic01.id
        }
       ]
    }
  }
}

resource shutdownVm01 'microsoft.devtestlab/schedules@2018-09-15' = {  
  name: autoshutdownLinux01Name
  location: location
  properties: { 
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    timeZoneId: 'UTC'
    dailyRecurrence: { time: '20:00' }
    notificationSettings: { status: 'Disabled' }
    targetResourceId: vmonprem01.id
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
  dependsOn: [ onpremvnet2 ]
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

resource onpremdisk02 'Microsoft.Compute/disks@2019-07-01' = {  
  name: vmOnPremLinux02DiskName
  location: location
  properties: { 
    creationData: { createOption: 'Empty' }
    diskSizeGB: 128
  }
}

resource vmonpremnic02 'Microsoft.Network/networkInterfaces@2019-09-01' = {  
  name: vmOnPremLinux02NicName
  location: location
  dependsOn: [ onpremvnet2 ]
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

resource vmonprem02 'Microsoft.Compute/virtualMachines@2019-07-01' = {  
  name: vmOnPremLinux02Name
  location: location
  dependsOn: [  ]
  properties: { 
    hardwareProfile: { vmSize: virtualMachineSKU }
    storageProfile: { 
      imageReference: { publisher: 'Canonical', offer: 'UbuntuServer', sku: '19_04-gen2', version: 'latest'}
      dataDisks: [ {
          lun: 0
          name: vmOnPremLinux02DiskName
          createOption: 'Attach'
          managedDisk: { id: onpremdisk02.id }
        }
       ]
    }
    osProfile: { 
      computerName: vmOnPremLinux02Name
      adminUsername: username
      adminPassword: password
      linuxConfiguration: {
        disablePasswordAuthentication: false
        provisionVMAgent: true
      }
    }
    networkProfile: { 
      networkInterfaces: [ {
          id: vmonpremnic02.id
        }
       ]
    }
  }
}

resource shutdownVm02 'microsoft.devtestlab/schedules@2018-09-15' = {  
  name: autoshutdownLinux02Name
  location: location
  properties: { 
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    timeZoneId: 'UTC'
    dailyRecurrence: { time: '20:00' }
    notificationSettings: { status: 'Disabled' }
    targetResourceId: vmonprem02.id
  }
}
