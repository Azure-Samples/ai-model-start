#!/usr/bin/env bash
# deploy-models.sh — postprovision hook
# Deploys model(s) via Azure CLI to bypass ARM template validation
# limitations with non-OpenAI model formats (DeepSeek, Microsoft, Meta, etc.)

set -euo pipefail

# ── Read configuration from environment / azd ─────────────

RG_NAME="${AZURE_RESOURCE_GROUP}"
ACCOUNT_NAME="${AZURE_AI_FOUNDRY_NAME}"

# Primary model
MODEL_NAME="${AZURE_MODEL_NAME:-DeepSeek-R1-0528}"
MODEL_FORMAT="${AZURE_MODEL_FORMAT:-DeepSeek}"
MODEL_VERSION="${AZURE_MODEL_VERSION:-1}"
DEPLOY_NAME="${AZURE_MODEL_DEPLOYMENT_NAME:-$MODEL_NAME}"
SKU_NAME="${AZURE_DEPLOYMENT_SKU_NAME:-GlobalStandard}"
SKU_CAPACITY="${AZURE_DEPLOYMENT_SKU_CAPACITY:-10}"

# Secondary model (optional)
MODEL2_NAME="${AZURE_MODEL_2_NAME:-gpt-4.1-mini}"
MODEL2_FORMAT="${AZURE_MODEL_2_FORMAT:-OpenAI}"
MODEL2_VERSION="${AZURE_MODEL_2_VERSION:-2025-04-14}"
DEPLOY2_NAME="${AZURE_MODEL_2_DEPLOYMENT_NAME:-$MODEL2_NAME}"
SKU2_NAME="${AZURE_DEPLOYMENT_2_SKU_NAME:-GlobalStandard}"
SKU2_CAPACITY="${AZURE_DEPLOYMENT_2_SKU_CAPACITY:-10}"

# ── Deploy primary model ──────────────────────────────────

echo ""
echo "Deploying model: $MODEL_NAME (format: $MODEL_FORMAT) as '$DEPLOY_NAME'..."

az cognitiveservices account deployment create \
    --resource-group "$RG_NAME" \
    --name "$ACCOUNT_NAME" \
    --deployment-name "$DEPLOY_NAME" \
    --model-name "$MODEL_NAME" \
    --model-format "$MODEL_FORMAT" \
    --model-version "$MODEL_VERSION" \
    --sku-name "$SKU_NAME" \
    --sku-capacity "$SKU_CAPACITY"

echo "  ✓ Model '$DEPLOY_NAME' deployed successfully."

# ── Deploy secondary model (if configured) ────────────────

if [ -n "$MODEL2_NAME" ]; then
    echo ""
    echo "Deploying model: $MODEL2_NAME (format: $MODEL2_FORMAT) as '$DEPLOY2_NAME'..."

    az cognitiveservices account deployment create \
        --resource-group "$RG_NAME" \
        --name "$ACCOUNT_NAME" \
        --deployment-name "$DEPLOY2_NAME" \
        --model-name "$MODEL2_NAME" \
        --model-format "$MODEL2_FORMAT" \
        --model-version "$MODEL2_VERSION" \
        --sku-name "$SKU2_NAME" \
        --sku-capacity "$SKU2_CAPACITY"

    echo "  ✓ Model '$DEPLOY2_NAME' deployed successfully."
fi

echo ""
echo "All model deployments completed."
