// Microsoft Foundry Models - Responses API Example (Plain OpenAI SDK)
// Uses the standard openai-go package with the project endpoint + /openai/v1 suffix.
// No api-version query parameter needed. No dependency on Azure AI SDKs for model invocation.
//
// Surfaces structured reasoning summaries for any model that emits a `reasoning`
// output item. As of the May 2026 Foundry service update, non-OpenAI reasoning
// models (e.g. DeepSeek-R1) emit reasoning summaries through the same in-schema
// shape as native OpenAI reasoning models — no special handling per model family.
package main

import (
	"context"
	"fmt"
	"os"
	"strings"

	"github.com/Azure/azure-sdk-for-go/sdk/azcore/policy"
	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	"github.com/openai/openai-go/v3"
	"github.com/openai/openai-go/v3/option"
	"github.com/openai/openai-go/v3/responses"
)

// extractReasoningSummary returns the concatenated reasoning summary text from
// a Responses API result. It walks resp.Output for items of type "reasoning"
// and joins the Text field of each entry in their Summary list. Returns ""
// if no reasoning items or no summary text are present.
func extractReasoningSummary(resp *responses.Response) string {
	var parts []string
	for _, item := range resp.Output {
		if item.Type != "reasoning" {
			continue
		}
		for _, s := range item.Summary {
			if s.Text != "" {
				parts = append(parts, s.Text)
			}
		}
	}
	return strings.TrimSpace(strings.Join(parts, "\n"))
}

func printResponse(resp *responses.Response) {
	fmt.Printf("Response: %s\n", resp.OutputText())

	if summary := extractReasoningSummary(resp); summary != "" {
		fmt.Printf("\nReasoning summary:\n%s\n", summary)
	}

	fmt.Printf("\nStatus:   %s\n", resp.Status)
	fmt.Printf("Output tokens: %d (reasoning: %d)\n\n",
		resp.Usage.OutputTokens,
		resp.Usage.OutputTokensDetails.ReasoningTokens)
}

func main() {
	fmt.Println("Microsoft Foundry Models - Responses API (Plain OpenAI SDK - Go)\n")

	endpoint := os.Getenv("AZURE_AI_PROJECT_ENDPOINT")
	if endpoint == "" {
		fmt.Fprintln(os.Stderr, "Error: AZURE_AI_PROJECT_ENDPOINT must be set.")
		os.Exit(1)
	}

	ctx := context.Background()

	// Get EntraID token for keyless auth
	credential, err := azidentity.NewDefaultAzureCredential(nil)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to create credential: %v\n", err)
		os.Exit(1)
	}
	token, err := credential.GetToken(ctx, policy.TokenRequestOptions{
		Scopes: []string{"https://ai.azure.com/.default"},
	})
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to get token: %v\n", err)
		os.Exit(1)
	}

	// Standard OpenAI client — no Azure wrapper (no api-version needed with /v1 path)
	baseURL := strings.TrimRight(endpoint, "/") + "/openai/v1"
	client := openai.NewClient(
		option.WithBaseURL(baseURL),
		option.WithAPIKey(token.Token),
	)

	// --- Example 1: OpenAI model (gpt-4.1-mini) ---
	openaiModel := os.Getenv("AZURE_MODEL_2_DEPLOYMENT_NAME")
	if openaiModel == "" {
		openaiModel = "gpt-4.1-mini"
	}
	fmt.Printf("Example 1: OpenAI model (%s)\n\n", openaiModel)
	fmt.Println("Waiting for response...")
	resp1, err := client.Responses.New(ctx, responses.ResponseNewParams{
		Model: openaiModel,
		Input: responses.ResponseNewParamsInputUnion{
			OfString: openai.String("Explain quantum computing in 3 sentences."),
		},
		MaxOutputTokens: openai.Int(500),
	})
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
	printResponse(resp1)

	// --- Example 2: Non-OpenAI reasoning model (DeepSeek-R1-0528) ---
	// As of the May 2026 Foundry service update, DeepSeek-R1 emits a structured
	// `reasoning` output item with Summary[].Text populated by default — the same
	// shape OpenAI reasoning models use when summaries are enabled.
	deepseekModel := os.Getenv("AZURE_MODEL_DEPLOYMENT_NAME")
	if deepseekModel == "" {
		deepseekModel = "DeepSeek-R1-0528"
	}
	fmt.Printf("Example 2: Non-OpenAI reasoning model (%s)\n\n", deepseekModel)
	fmt.Println("Waiting for response (reasoning models can take 30-60s)...")
	resp2, err := client.Responses.New(ctx, responses.ResponseNewParams{
		Model: deepseekModel,
		Input: responses.ResponseNewParamsInputUnion{
			OfString: openai.String("What are the top 3 benefits of cloud computing? Be concise."),
		},
		MaxOutputTokens: openai.Int(2000),
	})
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
	printResponse(resp2)
}
