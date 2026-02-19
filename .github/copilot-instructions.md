# Copilot Instructions — Foundry Models Starter Kit

## Architecture

This is an **Azure Developer CLI (azd) template** that deploys a Microsoft Foundry account with two models (DeepSeek-R1-0528 and gpt-4.1-mini by default) and provides working examples in **Python, TypeScript, C#, Java, and Go** to call them.

- **Infra layer** (`infra/`): Subscription-scoped Bicep. [main.bicep](../infra/main.bicep) creates the resource group and delegates to [foundry.bicep](../infra/foundry.bicep), which provisions `Microsoft.CognitiveServices/accounts` (kind `AIServices`) and a project sub-resource. Model deployments are created by **postprovision hook scripts** (`scripts/deploy-models.ps1` / `scripts/deploy-models.sh`) via Azure CLI, because ARM template validation [rejects non-OpenAI model formats](https://github.com/Azure-Samples/ai-model-start/issues/4).
- **App layer** (`src/`): One self-contained example per language, each using the **Responses API** with that language's standard **OpenAI SDK** (not Azure-specific SDK wrappers). There is no web app, API server, or deployment target — only local scripts.
- **Glue**: [azure.yaml](../azure.yaml) wires azd to the Bicep infra and defines postprovision hooks for model deployment. Environment variables flow from Bicep outputs → azd env → hook scripts → app code via `os.environ` (or equivalent).

## Key Conventions

### The universal pattern (all languages)

Every example follows the same three steps:

1. **Get an EntraID token** via `DefaultAzureCredential` scoped to `https://ai.azure.com/.default`
2. **Create a standard OpenAI client** with `base_url` = project endpoint + `/openai`, passing the token as `api_key`
3. **Pass `api-version=2025-11-15-preview`** as a query parameter (mechanism varies by language)

Do **not** use `azure-ai-projects` (`AIProjectClient`), `openai.AzureOpenAI`, `Azure.AI.OpenAI`, or any Azure-specific OpenAI wrapper. Use each language's standard `openai` library only.

### Python SDK pattern

```python
import os
from azure.identity import DefaultAzureCredential
from openai import OpenAI

credential = DefaultAzureCredential()
token = credential.get_token("https://ai.azure.com/.default").token

endpoint = os.environ["AZURE_AI_PROJECT_ENDPOINT"]
client = OpenAI(
    base_url=endpoint.rstrip("/") + "/openai",
    api_key=token,
    default_query={"api-version": "2025-11-15-preview"},
)
response = client.responses.create(model="gpt-4.1-mini", input="...", max_output_tokens=500)
```

### TypeScript SDK pattern

```typescript
import OpenAI from "openai";
import { DefaultAzureCredential } from "@azure/identity";

const credential = new DefaultAzureCredential();
const token = await credential.getToken("https://ai.azure.com/.default");

const client = new OpenAI({
  baseURL: process.env.AZURE_AI_PROJECT_ENDPOINT!.replace(/\/+$/, "") + "/openai",
  apiKey: token.token,
  defaultQuery: { "api-version": "2025-11-15-preview" },
});
const response = await client.responses.create({ model: "gpt-4.1-mini", input: "...", max_output_tokens: 500 });
```

### C# SDK pattern

The C# OpenAI SDK does not expose a `defaultQuery` option. Use a custom `PipelinePolicy` to inject the `api-version` query parameter on every request. See `src/csharp/Program.cs` for the `ApiVersionPolicy` implementation.

```csharp
var credential = new DefaultAzureCredential();
var token = credential.GetToken(new TokenRequestContext(["https://ai.azure.com/.default"]));

var options = new OpenAIClientOptions();
options.AddPolicy(new ApiVersionPolicy("2025-11-15-preview"), PipelinePosition.BeforeTransport);

var client = new OpenAIClient(
    new ApiKeyCredential(token.Token),
    options with { Endpoint = new Uri(endpoint.TrimEnd('/') + "/openai") });
var responsesClient = client.GetResponseClient();
```

### Java SDK pattern

```java
DefaultAzureCredential credential = new DefaultAzureCredentialBuilder().build();
AccessToken token = credential.getTokenSync(new TokenRequestContext().addScopes("https://ai.azure.com/.default"));

OpenAIClient client = OpenAIOkHttpClient.builder()
    .baseUrl(endpoint.replaceAll("/+$", "") + "/openai")
    .apiKey(token.getToken())
    .putQueryParam("api-version", "2025-11-15-preview")
    .build();
```

Note: The Java SDK's `Response` object does not have an `outputText()` convenience method. Iterate `response.output()` items and cast to `ResponseOutputMessage` → `ContentOutputText` to extract text.

### Go SDK pattern

```go
credential, _ := azidentity.NewDefaultAzureCredential(nil)
token, _ := credential.GetToken(context.Background(), policy.TokenRequestOptions{
    Scopes: []string{"https://ai.azure.com/.default"},
})

client := openai.NewClient(
    option.WithBaseURL(strings.TrimRight(endpoint, "/") + "/openai"),
    option.WithAPIKey(token.Token),
    option.WithQueryAdd("api-version", "2025-11-15-preview"),
)
```

### Authentication
Use **keyless** via `DefaultAzureCredential` (EntraID). Users need the `Azure AI Developer` role on the Microsoft Foundry account. Token audience is always `https://ai.azure.com/.default`.

### Environment variables
Set from `azd env get-values` after provisioning:
- `AZURE_AI_PROJECT_ENDPOINT` — the project endpoint; used as `base_url` with `/openai` suffix
- `AZURE_MODEL_DEPLOYMENT_NAME` — primary model deployment name (default: `DeepSeek-R1-0528`); read by samples for example 2
- `AZURE_MODEL_2_DEPLOYMENT_NAME` — second model deployment name (default: `gpt-4.1-mini`); read by all samples for example 1

Sample code reads model names from `AZURE_MODEL_DEPLOYMENT_NAME` and `AZURE_MODEL_2_DEPLOYMENT_NAME` env vars, falling back to `DeepSeek-R1-0528` and `gpt-4.1-mini` respectively if not set.

### Bicep conventions
- Target scope is `subscription` in `main.bicep`; resource-group-scoped resources go in `foundry.bicep` module.
- API version: `2025-06-01` for all `Microsoft.CognitiveServices` resources.
- Resource naming uses `uniqueString(subscription().id, environmentName, location)` for uniqueness.
- **Model deployments are NOT in Bicep** — they are created by postprovision hook scripts via Azure CLI, because ARM validation rejects non-OpenAI model formats.
- The second model deployment is optional — set `AZURE_MODEL_2_NAME` to empty string to skip it.

## Developer Workflow

```powershell
# Deploy / redeploy infrastructure
azd up

# Change model before deploying
azd env set AZURE_MODEL_NAME "gpt-4.1-mini"
azd env set AZURE_MODEL_FORMAT "OpenAI"
azd env set AZURE_MODEL_VERSION "2025-04-14"
azd up

# Set environment variables
$env:AZURE_AI_PROJECT_ENDPOINT = azd env get-value 'AZURE_AI_PROJECT_ENDPOINT'

# Run any example
cd src/python   && pip install -r requirements.txt && python responses_example.py
cd src/typescript && npm install && npx tsx responses_example.ts
cd src/csharp   && dotnet run
cd src/java     && mvn -q compile exec:java
cd src/go       && go run .

# Tear down all resources
azd down --purge
```

## When Adding New Examples

### Any language
- Place new scripts in `src/<language>/`.
- Follow the universal pattern: get EntraID token (audience `https://ai.azure.com/.default`), create standard OpenAI client with `base_url` = project endpoint + `/openai`, call the Responses API.
- Use the `responses` API, not `chat.completions`.
- Do not add Azure-specific OpenAI wrappers (`azure-ai-projects`, `AzureOpenAI`, `Azure.AI.OpenAI`, etc.).
- Keep scripts self-contained (no shared utility modules exist).

### Language-specific notes
- **Python**: Dependencies go in `src/python/requirements.txt`. Only `openai` + `azure-identity`.
- **TypeScript**: Dependencies go in `src/typescript/package.json`. Only `openai` + `@azure/identity`.
- **C#**: NuGet packages in `src/csharp/*.csproj`. Use `OpenAI` + `Azure.Identity`. Must add `ApiVersionPolicy` (custom `PipelinePolicy`) for api-version injection. Suppress `OPENAI001` warning for experimental Responses API.
- **Java**: Maven dependencies in `src/java/pom.xml`. Use `com.openai:openai-java` + `com.azure:azure-identity`. Use `putQueryParam` for api-version. Must manually iterate output items (no `outputText()` convenience).
- **Go**: Go modules in `src/go/go.mod`. Use `github.com/openai/openai-go` + `github.com/Azure/azure-sdk-for-go/sdk/azidentity`. Use `option.WithQueryAdd` for api-version. Token options from `azcore/policy`, not `azidentity`.

## When Modifying Infrastructure

- Add new Foundry-related resources to `foundry.bicep`, not `main.bicep`.
- Expose any values needed by app code as `output` in both `foundry.bicep` and `main.bicep`, then map them in `main.parameters.json` so azd captures them.
- Use `azd env set VAR=default` syntax in `main.parameters.json` for new configurable parameters.
