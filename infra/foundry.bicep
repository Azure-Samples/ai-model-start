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
// NOTE: Model deployments are created via a postprovision hook
// (scripts/deploy-models.ps1 / deploy-models.sh) because ARM
// template validation does not yet support non-OpenAI model
// formats (e.g., DeepSeek, Microsoft, Meta). The CLI bypasses
// this validation and works for all model formats.

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
// Outputs
// ──────────────────────────────────────────────

output aiFoundryName string = aiFoundry.name
output aiFoundryEndpoint string = aiFoundry.properties.endpoint
output aiFoundryId string = aiFoundry.id
output aiProjectName string = aiProject.name
