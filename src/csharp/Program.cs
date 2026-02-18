// Microsoft Foundry Models - Responses API Example (Plain OpenAI SDK)
// Uses the standard OpenAI NuGet package with the project endpoint + /openai/v1 suffix.
// No dependency on Azure.AI.OpenAI.

using System.ClientModel;
using System.ClientModel.Primitives;
using Azure.Identity;
using OpenAI;
using OpenAI.Responses;

// Route to API key example if --apikey flag is passed
if (args.Contains("--apikey"))
{
    return await ApiKeyExample.RunAsync();
}

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

// Standard OpenAI client — no AzureOpenAI wrapper
// Add api-version query parameter via a custom pipeline policy
var baseUrl = endpoint.TrimEnd('/') + "/openai/v1";
var options = new OpenAIClientOptions { Endpoint = new Uri(baseUrl) };
options.AddPolicy(new ApiVersionPolicy("2025-11-15-preview"), PipelinePosition.BeforeTransport);
var client = new OpenAIClient(new ApiKeyCredential(token.Token), options);

// --- Example 1: OpenAI model (gpt-4.1-mini) ---
var openaiModel = "gpt-4.1-mini";
Console.WriteLine($"Example 1: OpenAI model ({openaiModel})\n");
Console.WriteLine("Waiting for response...");
var responseClient1 = client.GetOpenAIResponseClient(openaiModel);
var result1 = await responseClient1.CreateResponseAsync(
    "Explain quantum computing in 3 sentences.",
    new ResponseCreationOptions { MaxOutputTokenCount = 500 }
);
Console.WriteLine($"Response: {result1.Value.GetOutputText()}");
Console.WriteLine($"Status:   {result1.Value.Status}");
Console.WriteLine($"Output tokens: {result1.Value.Usage.OutputTokenCount}\n");

// --- Example 2: Non-OpenAI model (DeepSeek-R1-0528) ---
var deepseekModel = "DeepSeek-R1-0528";
Console.WriteLine($"Example 2: Non-OpenAI model ({deepseekModel})\n");
Console.WriteLine("Waiting for response (reasoning models can take 30-60s)...");
var responseClient2 = client.GetOpenAIResponseClient(deepseekModel);
var result2 = await responseClient2.CreateResponseAsync(
    "What are the top 3 benefits of cloud computing? Be concise.",
    new ResponseCreationOptions { MaxOutputTokenCount = 500 }
);
Console.WriteLine($"Response: {result2.Value.GetOutputText()}");
Console.WriteLine($"Status:   {result2.Value.Status}");
Console.WriteLine($"Output tokens: {result2.Value.Usage.OutputTokenCount}");

return 0;

/// <summary>
/// Pipeline policy that appends api-version query parameter to every request.
/// </summary>
class ApiVersionPolicy(string apiVersion) : PipelinePolicy
{
    public override void Process(PipelineMessage message, IReadOnlyList<PipelinePolicy> pipeline, int currentIndex)
    {
        AddApiVersion(message);
        ProcessNext(message, pipeline, currentIndex);
    }

    public override async ValueTask ProcessAsync(PipelineMessage message, IReadOnlyList<PipelinePolicy> pipeline, int currentIndex)
    {
        AddApiVersion(message);
        await ProcessNextAsync(message, pipeline, currentIndex);
    }

    private void AddApiVersion(PipelineMessage message)
    {
        var uri = message.Request.Uri!;
        var separator = uri.Query.Contains('?') ? "&" : "?";
        message.Request.Uri = new Uri($"{uri}{separator}api-version={apiVersion}");
    }
}
