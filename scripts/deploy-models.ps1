#!/usr/bin/env pwsh
# deploy-models.ps1 — postprovision hook
# Deploys model(s) via Azure CLI to bypass ARM template validation
# limitations with non-OpenAI model formats (DeepSeek, Microsoft, Meta, etc.)

$ErrorActionPreference = "Stop"

# ── Read configuration from environment / azd ─────────────

$rgName        = $env:AZURE_RESOURCE_GROUP
$accountName   = $env:AZURE_AI_FOUNDRY_NAME

# Primary model
$modelName     = if ($env:AZURE_MODEL_NAME)     { $env:AZURE_MODEL_NAME }     else { "DeepSeek-R1-0528" }
$modelFormat   = if ($env:AZURE_MODEL_FORMAT)   { $env:AZURE_MODEL_FORMAT }   else { "DeepSeek" }
$modelVersion  = if ($env:AZURE_MODEL_VERSION)  { $env:AZURE_MODEL_VERSION }  else { "1" }
$deployName    = if ($env:AZURE_MODEL_DEPLOYMENT_NAME) { $env:AZURE_MODEL_DEPLOYMENT_NAME } else { $modelName }
$skuName       = if ($env:AZURE_DEPLOYMENT_SKU_NAME)     { $env:AZURE_DEPLOYMENT_SKU_NAME }     else { "GlobalStandard" }
$skuCapacity   = if ($env:AZURE_DEPLOYMENT_SKU_CAPACITY) { $env:AZURE_DEPLOYMENT_SKU_CAPACITY } else { "10" }

# Secondary model (optional)
$model2Name    = if ($env:AZURE_MODEL_2_NAME)    { $env:AZURE_MODEL_2_NAME }    else { "gpt-4.1-mini" }
$model2Format  = if ($env:AZURE_MODEL_2_FORMAT)  { $env:AZURE_MODEL_2_FORMAT }  else { "OpenAI" }
$model2Version = if ($env:AZURE_MODEL_2_VERSION) { $env:AZURE_MODEL_2_VERSION } else { "2025-04-14" }
$deploy2Name   = if ($env:AZURE_MODEL_2_DEPLOYMENT_NAME) { $env:AZURE_MODEL_2_DEPLOYMENT_NAME } else { $model2Name }
$sku2Name      = if ($env:AZURE_DEPLOYMENT_2_SKU_NAME)     { $env:AZURE_DEPLOYMENT_2_SKU_NAME }     else { "GlobalStandard" }
$sku2Capacity  = if ($env:AZURE_DEPLOYMENT_2_SKU_CAPACITY) { $env:AZURE_DEPLOYMENT_2_SKU_CAPACITY } else { "10" }

# ── Deploy primary model ──────────────────────────────────

Write-Host ""
Write-Host "Deploying model: $modelName (format: $modelFormat) as '$deployName'..."

$args1 = @(
    "cognitiveservices", "account", "deployment", "create",
    "--resource-group", $rgName,
    "--name", $accountName,
    "--deployment-name", $deployName,
    "--model-name", $modelName,
    "--model-format", $modelFormat,
    "--model-version", $modelVersion,
    "--sku-name", $skuName,
    "--sku-capacity", $skuCapacity
)

az @args1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to deploy model '$modelName'."
    exit 1
}
Write-Host "  ✓ Model '$deployName' deployed successfully."

# ── Deploy secondary model (if configured) ────────────────

if ($model2Name) {
    Write-Host ""
    Write-Host "Deploying model: $model2Name (format: $model2Format) as '$deploy2Name'..."

    $args2 = @(
        "cognitiveservices", "account", "deployment", "create",
        "--resource-group", $rgName,
        "--name", $accountName,
        "--deployment-name", $deploy2Name,
        "--model-name", $model2Name,
        "--model-format", $model2Format,
        "--model-version", $model2Version,
        "--sku-name", $sku2Name,
        "--sku-capacity", $sku2Capacity
    )

    az @args2
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to deploy model '$model2Name'."
        exit 1
    }
    Write-Host "  ✓ Model '$deploy2Name' deployed successfully."
}

Write-Host ""
Write-Host "All model deployments completed."
