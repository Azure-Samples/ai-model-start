// ──────────────────────────────────────────────
// Based on: https://github.com/microsoft-foundry/foundry-samples/blob/main/infrastructure/infrastructure-setup-bicep/00-basic/main.bicep
// ──────────────────────────────────────────────

@description('Name of the Microsoft Foundry account (CognitiveServices/accounts).')
param aiFoundryName string

@description('Name of the Microsoft Foundry project.')
param aiProjectName string

@description('Location for all resources.')
param location string

@description('Tags for all resources.')
param tags object = {}

// ── Primary model deployment parameters ─────
@description('Name of the primary model to deploy.')
param modelName string

@description('Format of the primary model (e.g., "DeepSeek", "OpenAI", "Microsoft").')
param modelFormat string

@description('Version of the primary model.')
param modelVersion string = ''

@description('Name for the primary deployment.')
param deploymentName string

@description('SKU name for the primary deployment.')
param deploymentSkuName string = 'GlobalStandard'

@description('SKU capacity for the primary deployment.')
param deploymentSkuCapacity int = 10

// ── Secondary model deployment parameters ───
@description('Name of the secondary model to deploy. Leave empty to skip.')
param model2Name string = ''

@description('Format of the secondary model.')
param model2Format string = 'OpenAI'

@description('Version of the secondary model.')
param model2Version string = ''

@description('Name for the secondary deployment.')
param deployment2Name string = ''

@description('SKU name for the secondary deployment.')
param deployment2SkuName string = 'GlobalStandard'

@description('SKU capacity for the secondary deployment.')
param deployment2SkuCapacity int = 10

// ──────────────────────────────────────────────
// Microsoft Foundry account
//   A CognitiveServices/account with kind 'AIServices'
//   and allowProjectManagement = true
// ──────────────────────────────────────────────

resource aiFoundry 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: aiFoundryName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'S0'
  }
  kind: 'AIServices'
  properties: {
    // Required to work in Microsoft Foundry
    allowProjectManagement: true
    // Defines developer API endpoint subdomain
    customSubDomainName: aiFoundryName
    disableLocalAuth: false
    publicNetworkAccess: 'Enabled'
  }
}

// ──────────────────────────────────────────────
// Microsoft Foundry project
//   Projects group in- and outputs for one use case.
//   Development teams can get started right away.
// ──────────────────────────────────────────────

resource aiProject 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = {
  name: aiProjectName
  parent: aiFoundry
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {}
}

// ──────────────────────────────────────────────
// Primary model deployment
// ──────────────────────────────────────────────

resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = {
  parent: aiFoundry
  name: deploymentName
  sku: {
    capacity: deploymentSkuCapacity
    name: deploymentSkuName
  }
  properties: {
    model: {
      name: modelName
      format: modelFormat
      version: !empty(modelVersion) ? modelVersion : null
    }
  }
  dependsOn: [
    aiProject
  ]
}

// ──────────────────────────────────────────────
// Secondary model deployment (optional)
// ──────────────────────────────────────────────

resource model2Deployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = if (!empty(model2Name)) {
  parent: aiFoundry
  name: !empty(deployment2Name) ? deployment2Name : model2Name
  sku: {
    capacity: deployment2SkuCapacity
    name: deployment2SkuName
  }
  properties: {
    model: {
      name: model2Name
      format: model2Format
      version: !empty(model2Version) ? model2Version : null
    }
  }
  dependsOn: [
    modelDeployment
  ]
}

// ── Identity / RBAC ──────────────────────────

@description('Principal ID of the deploying user. If provided, assigns Cognitive Services User role.')
param principalId string = ''

// Cognitive Services User — grants full data-plane access including Responses API
var cognitiveServicesUserRoleId = 'a97b65f3-24c7-4388-baec-2e87135dc908'

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(principalId)) {
  name: guid(aiFoundry.id, principalId, cognitiveServicesUserRoleId)
  scope: aiFoundry
  properties: {
    principalId: principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', cognitiveServicesUserRoleId)
    principalType: 'User'
  }
}

// ──────────────────────────────────────────────
// Outputs
// ──────────────────────────────────────────────

output aiFoundryName string = aiFoundry.name
output aiFoundryEndpoint string = aiFoundry.properties.endpoint
output aiFoundryId string = aiFoundry.id
output aiProjectName string = aiProject.name
