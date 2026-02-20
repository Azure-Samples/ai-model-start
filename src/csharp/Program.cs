// Microsoft Foundry Models - Responses API Example (Plain OpenAI SDK)
// Uses the standard OpenAI NuGet package with the project endpoint + /openai/v1 suffix.
// No api-version query parameter needed. No dependency on Azure.AI.OpenAI.

using System.ClientModel;
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
var openaiModel = Environment.GetEnvironmentVariable("AZURE_MODEL_2_DEPLOYMENT_NAME") ?? "gpt-4.1-mini";
Console.WriteLine($"Example 1: OpenAI model ({openaiModel})\n");
Console.WriteLine("Waiting for response...");
var responseClient1 = client.GetResponsesClient(openaiModel);
var result1 = await responseClient1.CreateResponseAsync(new CreateResponseOptions(
    [ResponseItem.CreateUserMessageItem("Explain quantum computing in 3 sentences.")])
    { MaxOutputTokenCount = 500 }
);
Console.WriteLine($"Response: {result1.Value.GetOutputText()}");
Console.WriteLine($"Status:   {result1.Value.Status}");
Console.WriteLine($"Output tokens: {result1.Value.Usage.OutputTokenCount}\n");

// --- Example 2: Non-OpenAI model (DeepSeek-R1-0528) ---
var deepseekModel = Environment.GetEnvironmentVariable("AZURE_MODEL_DEPLOYMENT_NAME") ?? "DeepSeek-R1-0528";
Console.WriteLine($"Example 2: Non-OpenAI model ({deepseekModel})\n");
Console.WriteLine("Waiting for response (reasoning models can take 30-60s)...");
var responseClient2 = client.GetResponsesClient(deepseekModel);
var result2 = await responseClient2.CreateResponseAsync(new CreateResponseOptions(
    [ResponseItem.CreateUserMessageItem("What are the top 3 benefits of cloud computing? Be concise.")])
    { MaxOutputTokenCount = 500 }
);
Console.WriteLine($"Response: {result2.Value.GetOutputText()}");
Console.WriteLine($"Status:   {result2.Value.Status}");
Console.WriteLine($"Output tokens: {result2.Value.Usage.OutputTokenCount}");

return 0;
