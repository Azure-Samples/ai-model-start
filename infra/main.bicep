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

// ── Primary model deployment parameters ─────

@description('Name of the primary model to deploy (e.g., "DeepSeek-R1-0528", "Phi-4", "MAI-DS-R1").')
param modelName string = 'DeepSeek-R1-0528'

@description('Format of the primary model (e.g., "DeepSeek", "Microsoft", "OpenAI").')
param modelFormat string = 'DeepSeek'

@description('Version of the primary model. Leave empty to omit (API picks default).')
param modelVersion string = '1'

@description('Custom name for the primary deployment. Defaults to the model name.')
param deploymentName string = ''

@description('SKU name for the primary deployment (e.g., "GlobalStandard", "Standard").')
param deploymentSkuName string = 'GlobalStandard'

@description('SKU capacity for the primary deployment.')
param deploymentSkuCapacity int = 10

// ── Secondary model deployment parameters ───

@description('Name of the secondary model to deploy. Leave empty to skip.')
param model2Name string = 'gpt-4.1-mini'

@description('Format of the secondary model.')
param model2Format string = 'OpenAI'

@description('Version of the secondary model.')
param model2Version string = '2025-04-14'

@description('Custom name for the secondary deployment. Defaults to the model name.')
param deployment2Name string = ''

@description('SKU name for the secondary deployment.')
param deployment2SkuName string = 'GlobalStandard'

@description('SKU capacity for the secondary deployment.')
param deployment2SkuCapacity int = 10

// ── Tags ─────────────────────────────────────

param tags object = {}

// ──────────────────────────────────────────────
// Variables
// ──────────────────────────────────────────────

var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var effectiveFoundryName = !empty(aiFoundryName) ? aiFoundryName : 'foundry-${resourceToken}'
var effectiveProjectName = !empty(aiProjectName) ? aiProjectName : '${effectiveFoundryName}-proj'
var effectiveDeploymentName = !empty(deploymentName) ? deploymentName : modelName
var effectiveDeployment2Name = !empty(deployment2Name) ? deployment2Name : model2Name
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
    modelName: modelName
    modelFormat: modelFormat
    modelVersion: modelVersion
    deploymentName: effectiveDeploymentName
    deploymentSkuName: deploymentSkuName
    deploymentSkuCapacity: deploymentSkuCapacity
    model2Name: model2Name
    model2Format: model2Format
    model2Version: model2Version
    deployment2Name: effectiveDeployment2Name
    deployment2SkuName: deployment2SkuName
    deployment2SkuCapacity: deployment2SkuCapacity
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
output AZURE_MODEL_DEPLOYMENT_NAME string = effectiveDeploymentName
output AZURE_MODEL_2_DEPLOYMENT_NAME string = effectiveDeployment2Name
