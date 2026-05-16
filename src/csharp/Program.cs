// Microsoft Foundry Models - Responses API Example (Plain OpenAI SDK)
// Uses the standard OpenAI NuGet package with the project endpoint + /openai/v1 suffix.
// No api-version query parameter needed. No dependency on Azure.AI.OpenAI.
//
// Surfaces structured reasoning summaries for any model that emits a `reasoning`
// output item. As of the May 2026 Foundry service update, non-OpenAI reasoning
// models (e.g. DeepSeek-R1) emit reasoning summaries through the same in-schema
// shape as native OpenAI reasoning models — no special handling per model family.

using System.ClientModel;
using System.Text;
using Azure.Identity;
using OpenAI;
using OpenAI.Responses;

var endpoint = Environment.GetEnvironmentVariable("AZURE_AI_PROJECT_ENDPOINT");
if (string.IsNullOrEmpty(endpoint))
{
    Console.Error.WriteLine("Error: AZURE_AI_PROJECT_ENDPOINT must be set.");
    return 1;
}

Console.WriteLine("Microsoft Foundry Models - Responses API (Plain OpenAI SDK - C#)\n");

// Get EntraID token for keyless auth
var credential = new DefaultAzureCredential();
var token = await credential.GetTokenAsync(
    new Azure.Core.TokenRequestContext(["https://ai.azure.com/.default"])
);

// Standard OpenAI client — no AzureOpenAI wrapper (no api-version needed with /v1 path)
var baseUrl = endpoint.TrimEnd('/') + "/openai/v1";
var client = new OpenAIClient(
    new ApiKeyCredential(token.Token),
    new OpenAIClientOptions { Endpoint = new Uri(baseUrl) });

// --- Example 1: OpenAI model (gpt-4.1-mini) ---
// Note: gpt-4.1-mini is not a reasoning model. If you swap in an OpenAI
// reasoning model (o4-mini, o3, gpt-5.x), set ReasoningOptions with an effort
// level (low/medium/high) on CreateResponseOptions to control reasoning compute.
// Recovering human-readable summary text via ReasoningOptions.Summary currently
// requires OpenAI organization verification — see
// https://github.com/Azure-Samples/ai-model-start/issues/13.
var openaiModel = Environment.GetEnvironmentVariable("AZURE_MODEL_2_DEPLOYMENT_NAME") ?? "gpt-4.1-mini";
Console.WriteLine($"Example 1: OpenAI model ({openaiModel})\n");
Console.WriteLine("Waiting for response...");
var responseClient1 = client.GetResponsesClient(openaiModel);
var result1 = await responseClient1.CreateResponseAsync(new CreateResponseOptions(
    [ResponseItem.CreateUserMessageItem("Explain quantum computing in 3 sentences.")])
    { MaxOutputTokenCount = 500 }
);
PrintResponse(result1.Value);

// --- Example 2: Non-OpenAI reasoning model (DeepSeek-R1-0528) ---
// As of the May 2026 Foundry service update, DeepSeek-R1 emits a structured
// `reasoning` output item with summary parts populated by default — the same
// shape OpenAI reasoning models use when summaries are enabled.
var deepseekModel = Environment.GetEnvironmentVariable("AZURE_MODEL_DEPLOYMENT_NAME") ?? "DeepSeek-R1-0528";
Console.WriteLine($"Example 2: Non-OpenAI reasoning model ({deepseekModel})\n");
Console.WriteLine("Waiting for response (reasoning models can take 30-60s)...");
var responseClient2 = client.GetResponsesClient(deepseekModel);
var result2 = await responseClient2.CreateResponseAsync(new CreateResponseOptions(
    [ResponseItem.CreateUserMessageItem("What are the top 3 benefits of cloud computing? Be concise.")])
    { MaxOutputTokenCount = 2000 }
);
PrintResponse(result2.Value);

return 0;

// Return concatenated reasoning summary text from a Responses API result.
// Walks OutputItems for ReasoningResponseItem entries and joins the Text field
// of each ReasoningSummaryTextPart. Returns "" if no reasoning summary is present.
static string ExtractReasoningSummary(ResponseResult response)
{
    var sb = new StringBuilder();
    foreach (var item in response.OutputItems)
    {
        if (item is not ReasoningResponseItem reasoning) continue;
        foreach (var part in reasoning.SummaryParts)
        {
            if (part is ReasoningSummaryTextPart textPart && !string.IsNullOrEmpty(textPart.Text))
            {
                if (sb.Length > 0) sb.Append('\n');
                sb.Append(textPart.Text);
            }
        }
    }
    return sb.ToString().Trim();
}

static void PrintResponse(ResponseResult response)
{
    Console.WriteLine($"Response: {response.GetOutputText()}");

    var summary = ExtractReasoningSummary(response);
    if (!string.IsNullOrEmpty(summary))
    {
        Console.WriteLine($"\nReasoning summary:\n{summary}");
    }

    Console.WriteLine($"\nStatus:   {response.Status}");
    var outputTokens = response.Usage.OutputTokenCount;
    var reasoningTokens = response.Usage.OutputTokenDetails?.ReasoningTokenCount;
    if (reasoningTokens.HasValue)
    {
        Console.WriteLine($"Output tokens: {outputTokens} (reasoning: {reasoningTokens.Value})\n");
    }
    else
    {
        Console.WriteLine($"Output tokens: {outputTokens}\n");
    }
}
