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

// ── Model deployment parameters ─────────────

@description('Name of the model to deploy.')
param modelName string

@description('Format of the model (e.g., "OpenAI", "Microsoft").')
param modelFormat string

@description('Version of the model.')
param modelVersion string = ''

@description('Name for the deployment.')
param deploymentName string

@description('SKU name for the deployment.')
param deploymentSkuName string = 'GlobalStandard'

@description('SKU capacity for the deployment.')
param deploymentSkuCapacity int = 1

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
// Model deployment
//   Deploy any Foundry model to use in playground,
//   agents and other tools.
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
// Outputs
// ──────────────────────────────────────────────

output aiFoundryName string = aiFoundry.name
output aiFoundryEndpoint string = aiFoundry.properties.endpoint
output aiFoundryId string = aiFoundry.id
output aiProjectName string = aiProject.name
