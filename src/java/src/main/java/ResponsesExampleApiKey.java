/**
 * Microsoft Foundry Models - Responses API Example (API Key Authentication)
 * Uses the standard OpenAI Java SDK with an API key instead of EntraID.
 * For quick dev/test only — use EntraID (ResponsesExample.java) for production.
 */

import com.openai.client.OpenAIClient;
import com.openai.client.okhttp.OpenAIOkHttpClient;
import com.openai.models.responses.ResponseCreateParams;

public class ResponsesExampleApiKey {

    static String getOutputText(com.openai.models.responses.Response response) {
        var sb = new StringBuilder();
        response.output().stream()
                .flatMap(item -> item.message().stream())
                .flatMap(message -> message.content().stream())
                .flatMap(content -> content.outputText().stream())
                .forEach(outputText -> sb.append(outputText.text()));
        return sb.toString();
    }

    public static void main(String[] args) {
        System.out.println("Microsoft Foundry Models - Responses API (API Key Auth - Java)\n");

        String endpoint = System.getenv("AZURE_AI_FOUNDRY_ENDPOINT");
        String apiKey = System.getenv("AZURE_AI_API_KEY");
        if (endpoint == null || endpoint.isEmpty() || apiKey == null || apiKey.isEmpty()) {
            System.err.println("Error: AZURE_AI_FOUNDRY_ENDPOINT and AZURE_AI_API_KEY must be set.");
            System.exit(1);
        }

        String baseUrl = endpoint.replaceAll("/+$", "") + "/openai/v1";
        OpenAIClient client = OpenAIOkHttpClient.builder()
                .baseUrl(baseUrl)
                .apiKey(apiKey)
                .build();

        String model = "gpt-4.1-mini";
        System.out.printf("Model: %s%n%n", model);
        System.out.println("Waiting for response...");
        var response = client.responses().create(
                ResponseCreateParams.builder()
                        .model(model)
                        .input("Explain quantum computing in 3 sentences.")
                        .maxOutputTokens(500)
                        .build()
        );
        System.out.printf("Response: %s%n", getOutputText(response));
        System.out.printf("Status:   %s%n", response.status());
        response.usage().ifPresent(u ->
                System.out.printf("Output tokens: %d%n", u.outputTokens()));
    }
}
