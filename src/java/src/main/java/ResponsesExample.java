/**
 * Microsoft Foundry Models - Responses API Example (Plain OpenAI SDK)
 * Uses the standard OpenAI Java SDK with the project endpoint + /openai/v1 suffix.
 * The Java SDK sends its own internal API version header, so we use the /v1 path
 * (which does not require an api-version query parameter) instead of /openai.
 * No dependency on Azure AI SDKs for model invocation.
 *
 * Surfaces structured reasoning summaries for any model that emits a `reasoning`
 * output item. As of the May 2026 Foundry service update, non-OpenAI reasoning
 * models (e.g. DeepSeek-R1) emit reasoning summaries through the same in-schema
 * shape as native OpenAI reasoning models — no special handling per model family.
 */

import com.azure.core.credential.TokenRequestContext;
import com.azure.identity.DefaultAzureCredentialBuilder;
import com.openai.client.OpenAIClient;
import com.openai.client.okhttp.OpenAIOkHttpClient;
import com.openai.models.responses.Response;
import com.openai.models.responses.ResponseCreateParams;

public class ResponsesExample {

    /** Return the final assistant message text from a Responses API result. */
    static String getOutputText(Response response) {
        var sb = new StringBuilder();
        response.output().stream()
                .flatMap(item -> item.message().stream())
                .flatMap(message -> message.content().stream())
                .flatMap(content -> content.outputText().stream())
                .forEach(outputText -> sb.append(outputText.text()));
        return sb.toString();
    }

    /**
     * Return concatenated reasoning summary text from a Responses API result.
     * Walks `response.output()` for items of type `reasoning` and joins the
     * `text` field of each entry in their `summary` list. Returns "" if no
     * reasoning items or no summary text are present.
     */
    static String getReasoningSummary(Response response) {
        var sb = new StringBuilder();
        response.output().stream()
                .flatMap(item -> item.reasoning().stream())
                .flatMap(reasoning -> reasoning.summary().stream())
                .forEach(summary -> {
                    String text = summary.text();
                    if (text != null && !text.isEmpty()) {
                        if (sb.length() > 0) sb.append("\n");
                        sb.append(text);
                    }
                });
        return sb.toString().trim();
    }

    static void printResponse(Response response) {
        System.out.printf("Response: %s%n", getOutputText(response));

        String summary = getReasoningSummary(response);
        if (!summary.isEmpty()) {
            System.out.printf("%nReasoning summary:%n%s%n", summary);
        }

        System.out.printf("%nStatus:   %s%n", response.status());
        response.usage().ifPresent(u -> {
            long out = u.outputTokens();
            long reasoning = u.outputTokensDetails().reasoningTokens();
            System.out.printf("Output tokens: %d (reasoning: %d)%n%n", out, reasoning);
        });
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
        printResponse(response1);

        // --- Example 2: Non-OpenAI reasoning model (DeepSeek-R1-0528) ---
        // As of the May 2026 Foundry service update, DeepSeek-R1 emits a structured
        // `reasoning` output item with `summary[].text` populated by default — the
        // same shape OpenAI reasoning models use when summaries are enabled.
        String deepseekModel = System.getenv().getOrDefault("AZURE_MODEL_DEPLOYMENT_NAME", "DeepSeek-R1-0528");
        System.out.printf("Example 2: Non-OpenAI reasoning model (%s)%n%n", deepseekModel);
        System.out.println("Waiting for response (reasoning models can take 30-60s)...");
        var response2 = client.responses().create(
                ResponseCreateParams.builder()
                        .model(deepseekModel)
                        .input("What are the top 3 benefits of cloud computing? Be concise.")
                        .maxOutputTokens(2000)
                        .build()
        );
        printResponse(response2);
    }
}
