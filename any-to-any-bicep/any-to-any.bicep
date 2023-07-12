@description('Basic, Standard or Premium tier')
@allowed([ 'Basic', 'Standard', 'Premium' ])
param firewallTier string = 'Premium'

param disableBgpRoutePropagation bool = false

@description('Additional IP addresses or subnets to add in the firewall rules')
param allowIpAddresses array = []

var routeTables_all_to_firewall_we_name = 'all-to-firewall-we'
var routeTables_all_to_firewall_ne_name = 'all-to-firewall-ne'

var hubName = 'hub-lab-net'
var spoke01Name = 'spoke-01'
var spoke02Name = 'spoke-02'
var spoke03Name = 'spoke-03'

param locationWE string = 'westeurope'
param locationNE string = 'northeurope'

var firewallName = 'lab-firewall'
var firewallIPName = 'lab-firewall-ip'
var firewallIpAddress = '10.12.3.4'

module fwPolicy './fw-policy.bicep' = {
  name: 'fwPolicyDeploy'
  params: {
    firewallTier: firewallTier
    locationWE: locationWE
    allowIpAddresses: allowIpAddresses
  }
}

resource routeTableWE 'Microsoft.Network/routeTables@2020-05-01' = {
  name: routeTables_all_to_firewall_we_name
  location: locationWE
  properties: {
    disableBgpRoutePropagation: disableBgpRoutePropagation
    routes: [
      {
        name: 'all-to-firewall-we'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallIpAddress
        }
      }
    ]
  }
}

resource routeTableGateway 'Microsoft.Network/routeTables@2020-05-01' = {
  name: 'gateway-route'
  location: locationWE
  properties: {
    disableBgpRoutePropagation: disableBgpRoutePropagation
    routes: [
      {
        name: 'spoke-01'
        properties: {
          addressPrefix: '10.13.1.0/24'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallIpAddress
        }
      }
      {
        name: 'spoke-02'
        properties: {
          addressPrefix: '10.13.2.0/24'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallIpAddress
        }
      }
      {
        name: 'spoke-03'
        properties: {
          addressPrefix: '10.13.3.0/24'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallIpAddress
        }
      }
    ]
  }
}

resource routeTableNE 'Microsoft.Network/routeTables@2020-05-01' = {
  name: routeTables_all_to_firewall_ne_name
  location: locationNE
  properties: {
    disableBgpRoutePropagation: disableBgpRoutePropagation
    routes: [
      {
        name: 'all-to-firewall-ne'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallIpAddress
        }
      }
    ]
  }
}

resource subnetS01default 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = {
  name: '${spoke01Name}/default'
  properties: {
    addressPrefix: '10.13.1.0/26'
    routeTable: {
      id: routeTableWE.id
    }
  }
}

resource subnetS01services 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = {
  name: '${spoke01Name}/services'
  dependsOn: [ // possible race condition where the route table is being associated with two different subnets at the same time
    subnetS01default
  ]
  properties: {
    addressPrefix: '10.13.1.64/26'
    routeTable: {
      id: routeTableWE.id
    }
  }
}

resource subnetS02default 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = {
  name: '${spoke02Name}/default'
  properties: {
    addressPrefix: '10.13.2.0/26'
    routeTable: {
      id: routeTableWE.id
    }
  }
}

resource subnetS02services 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = {
  name: '${spoke02Name}/services'
  dependsOn: [ // possible race condition where the route table is being associated with two different subnets at the same time
    subnetS02default
  ]
  properties: {
    addressPrefix: '10.13.2.64/26'
    routeTable: {
      id: routeTableWE.id
    }
  }
}

resource subnetS03default 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = {
  name: '${spoke03Name}/default'
  properties: {
    addressPrefix: '10.13.3.0/26'
    routeTable: {
      id: routeTableNE.id
    }
  }
}

resource subnetS03services 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = {
  name: '${spoke03Name}/services'
  dependsOn: [ // possible race condition where the route table is being associated with two different subnets at the same time
    subnetS03default
  ]
  properties: {
    addressPrefix: '10.13.3.64/26'
    routeTable: {
      id: routeTableNE.id
    }
  }
}

resource subnetGateway 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = {
  name: '${hubName}/GatewaySubnet'
  properties: {
    addressPrefix: '10.12.4.0/24'
    routeTable: {
      id: routeTableGateway.id
    }
  }
}

resource firewallIP 'Microsoft.Network/publicIPAddresses@2019-09-01' = {  
  name: firewallIPName
  location: locationWE
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource azureFirewalls_lab_firewall_name_resource 'Microsoft.Network/azureFirewalls@2022-07-01' = {
  name: firewallName
  location: locationWE
  properties: {
      sku: { name: 'AZFW_VNet', tier: firewallTier }
      ipConfigurations: [ {
          name: 'ipconfig1'
          properties: { 
            subnet: { id: resourceId('Microsoft.Network/virtualNetworks/subnets', hubName, 'AzureFirewallSubnet') }
            publicIPAddress: { id: firewallIP.id } 
          }
        }
      ]
      firewallPolicy: {
          id: fwPolicy.outputs.policyid
    }
  }
}
