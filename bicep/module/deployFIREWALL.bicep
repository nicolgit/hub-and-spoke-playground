@description('The name of the Azure Firewall')
param firewallName string

@description('The location for the resources')
param location string

@description('The name of the virtual network')
param vnetName string

@description('The firewall tier')
@allowed(['Basic', 'Standard', 'Premium'])
param firewallTier string

@description('The firewall subnet name')
param firewallSubnetName string = 'AzureFirewallSubnet'

@description('The firewall management subnet name')
param firewallManagementSubnetName string = 'AzureFirewallManagementSubnet'

@description('Log Analytics workspace ID for diagnostics')
param workspaceId string

@description('Log Analytics workspace name for diagnostics')
param workspaceName string

var firewallIPName = '${firewallName}-ip'
var firewallManagementIPName = '${firewallName}-mgt-ip'

resource firewallIP 'Microsoft.Network/publicIPAddresses@2020-08-01' = {
  name: firewallIPName
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource firewallManagementIP 'Microsoft.Network/publicIPAddresses@2020-08-01' = if (firewallTier == 'Basic') {
  name: firewallManagementIPName
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource firewall 'Microsoft.Network/azureFirewalls@2022-09-01' = {
  name: firewallName
  location: location
  properties: {
    managementIpConfiguration: firewallTier == 'Basic' ? {
      name: 'ipconfig-mgt'
      properties: {
        subnet: { id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, firewallManagementSubnetName) }
        publicIPAddress: { id: firewallManagementIP.id }
      }
    } : null
    ipConfigurations: [ {
        name: 'ipconfig1'
        properties: {
          subnet: { id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, firewallSubnetName) }
          publicIPAddress: { id: firewallIP.id }
        }
      } ]
    sku: { name: 'AZFW_VNet', tier: firewallTier }
  }
}

resource firewallDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: workspaceName
  scope: firewall
  properties: {
    workspaceId: workspaceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: true
        }
      }
    ]
    logAnalyticsDestinationType: null
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: true
        }
      }
    ]
  }
}

output firewallId string = firewall.id
output firewallIPId string = firewallIP.id
output firewallManagementIPId string = firewallTier == 'Basic' ? firewallManagementIP.id : ''
output firewallName string = firewall.name
