/**
 * Microsoft Foundry Models - Responses API Example (Plain OpenAI SDK)
 * Uses the standard OpenAI Java SDK with the project endpoint + /openai/v1 suffix.
 * The Java SDK sends its own internal API version header, so we use the /v1 path
 * (which does not require an api-version query parameter) instead of /openai.
 * No dependency on Azure AI SDKs for model invocation.
 */

import com.azure.core.credential.TokenRequestContext;
import com.azure.identity.DefaultAzureCredentialBuilder;
import com.openai.client.OpenAIClient;
import com.openai.client.okhttp.OpenAIOkHttpClient;
import com.openai.models.responses.ResponseCreateParams;

public class ResponsesExample {

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
        System.out.println("Microsoft Foundry Models - Responses API (Plain OpenAI SDK - Java)\n");

        String endpoint = System.getenv("AZURE_AI_PROJECT_ENDPOINT");
        if (endpoint == null || endpoint.isEmpty()) {
            System.err.println("Error: AZURE_AI_PROJECT_ENDPOINT must be set.");
            System.exit(1);
        }

        // Get EntraID token for keyless auth
        var credential = new DefaultAzureCredentialBuilder().build();
        var context = new TokenRequestContext().addScopes("https://ai.azure.com/.default");
        String token = credential.getToken(context).block().getToken();

        // Standard OpenAI client — no Azure wrapper
        // Java SDK uses /openai/v1 path (no api-version needed; SDK manages versioning internally)
        String baseUrl = endpoint.replaceAll("/+$", "") + "/openai/v1";
        OpenAIClient client = OpenAIOkHttpClient.builder()
                .baseUrl(baseUrl)
                .apiKey(token)
                .build();

        // --- Example 1: OpenAI model (gpt-4.1-mini) ---
        String openaiModel = System.getenv().getOrDefault("AZURE_MODEL_2_DEPLOYMENT_NAME", "gpt-4.1-mini");
        System.out.printf("Example 1: OpenAI model (%s)%n%n", openaiModel);
        System.out.println("Waiting for response...");
        var response1 = client.responses().create(
                ResponseCreateParams.builder()
                        .model(openaiModel)
                        .input("Explain quantum computing in 3 sentences.")
                        .maxOutputTokens(500)
                        .build()
        );
        System.out.printf("Response: %s%n", getOutputText(response1));
        System.out.printf("Status:   %s%n", response1.status());
        response1.usage().ifPresent(u ->
                System.out.printf("Output tokens: %d%n%n", u.outputTokens()));

        // --- Example 2: Non-OpenAI model (DeepSeek-R1-0528) ---
        String deepseekModel = System.getenv().getOrDefault("AZURE_MODEL_DEPLOYMENT_NAME", "DeepSeek-R1-0528");
        System.out.printf("Example 2: Non-OpenAI model (%s)%n%n", deepseekModel);
        System.out.println("Waiting for response (reasoning models can take 30-60s)...");
        var response2 = client.responses().create(
                ResponseCreateParams.builder()
                        .model(deepseekModel)
                        .input("What are the top 3 benefits of cloud computing? Be concise.")
                        .maxOutputTokens(500)
                        .build()
        );
        System.out.printf("Response: %s%n", getOutputText(response2));
        System.out.printf("Status:   %s%n", response2.status());
        response2.usage().ifPresent(u ->
                System.out.printf("Output tokens: %d%n", u.outputTokens()));
    }
}
