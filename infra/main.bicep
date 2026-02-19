targetScope = 'subscription'

// ──────────────────────────────────────────────
// Parameters
// ──────────────────────────────────────────────

@minLength(1)
@maxLength(64)
@description('Name of the azd environment, used for resource naming.')
param environmentName string

@description('Primary location for all resources.')
param location string

@description('Name of the Microsoft Foundry account. Defaults to a generated name.')
param aiFoundryName string = ''

@description('Name of the Microsoft Foundry project. Defaults to "<foundryName>-proj".')
param aiProjectName string = ''

@description('Name of the resource group. Defaults to "rg-<environmentName>".')
param resourceGroupName string = ''

// ── Model deployment parameters ─────────────
// NOTE: Model deployments are created via a postprovision hook
// (scripts/deploy-models.ps1 / deploy-models.sh) because ARM
// template validation does not yet support non-OpenAI model
// formats (e.g., DeepSeek, Microsoft, Meta).

@description('Name of the primary model deployment (used for azd output only).')
param deploymentName string = 'DeepSeek-R1-0528'

@description('Name of the second model deployment (used for azd output only).')
param deployment2Name string = 'gpt-4.1-mini'

// ── Tags ─────────────────────────────────────

param tags object = {}

// ──────────────────────────────────────────────
// Variables
// ──────────────────────────────────────────────

var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var effectiveFoundryName = !empty(aiFoundryName) ? aiFoundryName : 'foundry-${resourceToken}'
var effectiveProjectName = !empty(aiProjectName) ? aiProjectName : '${effectiveFoundryName}-proj'
var effectiveTags = union(tags, { 'azd-env-name': environmentName })

// ──────────────────────────────────────────────
// Resource Group
// ──────────────────────────────────────────────

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : 'rg-${environmentName}'
  location: location
  tags: effectiveTags
}

// ──────────────────────────────────────────────
// Microsoft Foundry resources (deployed into the RG)
// ──────────────────────────────────────────────

module foundry 'foundry.bicep' = {
  name: 'foundry'
  scope: rg
  params: {
    aiFoundryName: effectiveFoundryName
    aiProjectName: effectiveProjectName
    location: location
    tags: effectiveTags
  }
}

// ──────────────────────────────────────────────
// Outputs (consumed by azd)
// ──────────────────────────────────────────────

output AZURE_RESOURCE_GROUP string = rg.name
output AZURE_AI_FOUNDRY_NAME string = foundry.outputs.aiFoundryName
output AZURE_AI_FOUNDRY_ENDPOINT string = foundry.outputs.aiFoundryEndpoint
output AZURE_AI_PROJECT_NAME string = foundry.outputs.aiProjectName
output AZURE_AI_PROJECT_ENDPOINT string = '${foundry.outputs.aiFoundryEndpoint}api/projects/${foundry.outputs.aiProjectName}'
output AZURE_MODEL_DEPLOYMENT_NAME string = deploymentName
output AZURE_MODEL_2_DEPLOYMENT_NAME string = deployment2Name
