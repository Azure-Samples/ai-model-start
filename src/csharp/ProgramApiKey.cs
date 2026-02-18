// Microsoft Foundry Models - Responses API Example (API Key Authentication)
// Uses the standard OpenAI NuGet package with an API key instead of EntraID.
// For quick dev/test only — use EntraID (Program.cs) for production.
//
// To run:  dotnet run -- --apikey
// Or:      dotnet run               (runs the EntraID version)

using System.ClientModel;
using OpenAI;
using OpenAI.Responses;

public static class ApiKeyExample
{
    public static async Task<int> RunAsync()
    {
        var endpoint = Environment.GetEnvironmentVariable("AZURE_AI_FOUNDRY_ENDPOINT");
        var apiKey = Environment.GetEnvironmentVariable("AZURE_AI_API_KEY");
        if (string.IsNullOrEmpty(endpoint) || string.IsNullOrEmpty(apiKey))
        {
            Console.Error.WriteLine("Error: AZURE_AI_FOUNDRY_ENDPOINT and AZURE_AI_API_KEY must be set.");
            return 1;
        }

        Console.WriteLine("Microsoft Foundry Models - Responses API (API Key Auth - C#)\n");

        var baseUrl = endpoint.TrimEnd('/') + "/openai/v1";
        var options = new OpenAIClientOptions { Endpoint = new Uri(baseUrl) };
        var client = new OpenAIClient(new ApiKeyCredential(apiKey), options);

        var model = "gpt-4.1-mini";
        Console.WriteLine($"Model: {model}\n");
        Console.WriteLine("Waiting for response...");
        var responseClient = client.GetOpenAIResponseClient(model);
        var result = await responseClient.CreateResponseAsync(
            "Explain quantum computing in 3 sentences.",
            new ResponseCreationOptions { MaxOutputTokenCount = 500 }
        );
        Console.WriteLine($"Response: {result.Value.GetOutputText()}");
        Console.WriteLine($"Status:   {result.Value.Status}");
        Console.WriteLine($"Output tokens: {result.Value.Usage.OutputTokenCount}");

        return 0;
    }
}
