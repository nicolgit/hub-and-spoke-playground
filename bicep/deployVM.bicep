@description('The name of the virtual machine')
param vmName string

@description('The location for the resources')
param location string

@description('The SKU for the virtual machine')
param virtualMachineSKU string

@description('The name of the virtual network')
param vnetName string

@description('The name of the subnet')
param subnetName string

@description('The admin username for the VM')
param username string

@description('The admin password for the VM')
@secure()
param password string

@description('The operating system type')
@allowed(['WindowsServer', 'Linux', 'Windows11'])
param imageType string

@description('Whether to deploy the VM')
param deployVM bool

@description('The size of the data disk in GB')
param diskSizeGB int = 128

var diskName = '${vmName}-disk'
var nicName = '${vmName}-nic'
var autoshutdownName = 'shutdown-computevm-${vmName}'

var windowsServerImageReference = {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: '2019-Datacenter'
  version: 'latest'
}

var linuxImageReference = {
  publisher: 'Canonical'
  offer: '0001-com-ubuntu-server-jammy'
  sku: '22_04-lts-gen2'
  version: 'latest'
}

var windows11ImageReference = {
  publisher: 'MicrosoftWindowsDesktop'
  offer: 'windows-11'
  sku: 'win11-24h2-ent'
  version: 'latest'
}

var imageReference = imageType == 'WindowsServer' ? windowsServerImageReference : (imageType == 'Linux' ? linuxImageReference : windows11ImageReference)

var windowsOSProfile = {
  computerName: vmName
  adminUsername: username
  adminPassword: password
  windowsConfiguration: {
    enableAutomaticUpdates: true
  }
}

var linuxOSProfile = {
  computerName: vmName
  adminUsername: username
  adminPassword: password
  linuxConfiguration: {
    disablePasswordAuthentication: false
    provisionVMAgent: true
  }
  allowExtensionOperations: true
}

resource vmDisk 'Microsoft.Compute/disks@2019-07-01' = if (deployVM) {
  name: diskName
  location: location
  properties: {
    creationData: { createOption: 'Empty' }
    diskSizeGB: diskSizeGB
  }
}

resource vmNIC 'Microsoft.Network/networkInterfaces@2019-09-01' = if (deployVM) {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [ {
        name: 'ipconfig1'
        properties: {
          subnet: { id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName) }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2019-07-01' = if (deployVM) {
  name: vmName
  location: location
  properties: {
    hardwareProfile: { vmSize: virtualMachineSKU }
    storageProfile: {
      imageReference: imageReference
      dataDisks: [ {
          lun: 0
          name: diskName
          createOption: 'Attach'
          managedDisk: { id: vmDisk.id }
        }
      ]
    }
    osProfile: imageType == 'Linux' ? linuxOSProfile : windowsOSProfile
    networkProfile: {
      networkInterfaces: [ {
          id: vmNIC.id
        }
      ]
    }
  }
}

resource vmAutoshutdown 'microsoft.devtestlab/schedules@2018-09-15' = if (deployVM) {
  name: autoshutdownName
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    timeZoneId: 'UTC'
    dailyRecurrence: { time: '20:00' }
    notificationSettings: { status: 'Disabled' }
    targetResourceId: vm.id
  }
}

output vmId string = deployVM ? vm.id : ''
output nicId string = deployVM ? vmNIC.id : ''
output diskId string = deployVM ? vmDisk.id : ''
