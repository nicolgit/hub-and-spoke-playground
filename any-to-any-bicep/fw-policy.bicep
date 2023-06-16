param allowIpAddresses array = []
param locationWE string = 'westeurope'

@description('Basic, Standard or Premium tier')
@allowed([ 'Basic', 'Standard', 'Premium' ])
param firewallTier string = 'Premium'

var ipGroups_all_spokes_subnets_name = 'all-spokes-subnets'
var firewallPolicyName = 'my-firewall-policy'

var ipGroupAddresses = concat([
    '10.13.1.0/24'
    '10.13.2.0/24'
    '10.13.3.0/24'
  ], allowIpAddresses)

resource ipGroup 'Microsoft.Network/ipGroups@2020-05-01' = {
  name: ipGroups_all_spokes_subnets_name
  location: locationWE
  properties: {
    ipAddresses: ipGroupAddresses
  }
}

resource myFirewallPolicy 'Microsoft.Network/firewallPolicies@2020-05-01' = {
  name: firewallPolicyName
  location: locationWE
  properties: {
      threatIntelMode: 'Alert'
      sku: {
          tier: 'Premium'
      }
    }
}

resource toInternetCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2022-07-01' = {
  parent: myFirewallPolicy
  name: 'DefaultApplicationRuleCollectionGroup'
  properties: {
    priority: 300
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'ApplicationRule'
            name: 'allow-internet-traffic-out'
            protocols: [
              {
                protocolType: 'Http'
                port: 80
              }
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            fqdnTags: []
            webCategories: []
            targetFqdns: [
              '*'
            ]
            targetUrls: []
            terminateTLS: false
            sourceAddresses: []
            destinationAddresses: []
            sourceIpGroups: [ ipGroup.id ]
          }
        ]
        name: 'internet-out-collection'
        priority: 200
      }
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Deny'
        }
        // Basic tier does not allow use of webCategories
        rules: firewallTier == 'Basic' ? null : [
          {
            ruleType: 'ApplicationRule'
            name: 'block-porn-sites'
            protocols: [
              {
                protocolType: 'Http'
                port: 80
              }
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            fqdnTags: []
            webCategories: [
              'Nudity'
              'PornographyAndSexuallyExplicit'
              'ChildInappropriate'
            ]
            targetFqdns: []
            targetUrls: []
            terminateTLS: false
            sourceAddresses: []
            destinationAddresses: []
            sourceIpGroups: [ ipGroup.id ]
          }
        ]
        name: 'block-some-stuff'
        priority: 150
      }
    ]
  }
}

resource anyToAnyCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2020-05-01' = {
  parent: myFirewallPolicy
  name: 'DefaultNetworkRuleCollectionGroup'
  dependsOn: [ toInternetCollectionGroup ] // RM deploys all the ruleCollectionGroups in parallel or at least not sequentially - https://learn.microsoft.com/en-us/answers/questions/673917/update-of-azure-firewall-policies-failes-faulted-r
  properties: {
    priority: 300
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'any-to-any-collection'
        priority: 1000
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'allow-spoke-to-spoke-traffic'
            ipProtocols: [ 'Any' ]
            sourceIpGroups: [
              ipGroup.id
            ]
            destinationPorts: [
              '*'
            ]
            destinationIpGroups: [
              ipGroup.id
            ]
          }
        ]
      }
    ]
  }
}

output policy object = myFirewallPolicy
