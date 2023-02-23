@description('The name for the AKS managed cluster')
param name string

@description('The name of the resource group for the managed resources of the AKS cluster')
param nodeResourceGroupName string = ''

@description('The Azure region/location for the AKS resources')
param location string = resourceGroup().location

@description('Custom tags to apply to the AKS resources')
param tags object = {}

@description('Kubernetes Version')
param kubernetesVersion string = '1.23.12'

@description('Whether RBAC is enabled for local accounts')
param enableRbac bool = true

// Add-ons
@description('Whether web app routing (preview) add-on is enabled')
param webAppRoutingAddon bool = true

// AAD Integration
@description('Enable Azure Active Directory integration')
param enableAad bool = false

@description('Enable RBAC using AAD')
param enableAzureRbac bool = false

@description('The Tenant ID associated to the Azure Active Directory')
param aadTenantId string = ''

@description('The load balancer SKU to use for ingress into the AKS cluster')
@allowed([ 'basic', 'standard' ])
param loadBalancerSku string = 'standard'

@description('Network plugin used for building the Kubernetes network.')
@allowed([ 'azure', 'kubenet', 'none' ])
param networkPlugin string = 'azure'

@description('Network policy used for building the Kubernetes network.')
@allowed([ 'azure', 'calico' ])
param networkPolicy string = 'azure'

@description('If set to true, getting static credentials will be disabled for this cluster.')
param disableLocalAccounts bool = false

@description('The managed cluster SKU.')
@allowed([ 'Paid', 'Free' ])
param sku string = 'Free'

@description('Configuration of AKS add-ons')
param addOns object = {}

@description('The log analytics workspace id used for logging & monitoring')
param workspaceId string = ''

@description('The node pool configuration for the System agent pool')
param systemPoolConfig object

resource aks 'Microsoft.ContainerService/managedClusters@2022-11-02-preview' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Basic'
    tier: sku
  }
  properties: {
    nodeResourceGroup: !empty(nodeResourceGroupName) ? nodeResourceGroupName : 'rg-mc-${name}'
    kubernetesVersion: kubernetesVersion
    dnsPrefix: '${name}-dns'
    enableRBAC: enableRbac
    aadProfile: enableAad ? {
      managed: true
      enableAzureRBAC: enableAzureRbac
      tenantID: aadTenantId
    } : null
    agentPoolProfiles: [
      systemPoolConfig
    ]
    networkProfile: {
      loadBalancerSku: loadBalancerSku
      networkPlugin: networkPlugin
      networkPolicy: networkPolicy
    }
    disableLocalAccounts: disableLocalAccounts && enableAad
    addonProfiles: addOns
    ingressProfile: {
      webAppRouting: {
        enabled: webAppRoutingAddon
      }
    }
  }
}

var aksDiagCategories = [
  'cluster-autoscaler'
  'kube-controller-manager'
  'kube-audit-admin'
  'guard'
]

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(workspaceId)) {
  name: 'aks-diagnostics'
  tags: tags
  scope: aks
  properties: {
    workspaceId: workspaceId
    logs: [for category in aksDiagCategories: {
      category: category
      enabled: true
    }]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

@description('The resource name of the AKS cluster')
output aksClusterName string = aks.name

@description('The AKS cluster identity')
output aksClusterIdentity object = {
  clientId: aks.properties.identityProfile.kubeletidentity.clientId
  objectId: aks.properties.identityProfile.kubeletidentity.objectId
  resourceId: aks.properties.identityProfile.kubeletidentity.resourceId
}
