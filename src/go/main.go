// Microsoft Foundry Models - Responses API Example (Plain OpenAI SDK)
// Uses the standard openai-go package with the project endpoint + /openai/v1 suffix.
// No dependency on Azure AI SDKs for model invocation.
package main

import (
	"context"
	"fmt"
	"os"
	"strings"

	"github.com/Azure/azure-sdk-for-go/sdk/azcore/policy"
	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	"github.com/openai/openai-go"
	"github.com/openai/openai-go/option"
	"github.com/openai/openai-go/responses"
)

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

	// Standard OpenAI client — no Azure wrapper
	baseURL := strings.TrimRight(endpoint, "/") + "/openai/v1"
	client := openai.NewClient(
		option.WithBaseURL(baseURL),
		option.WithAPIKey(token.Token),
		option.WithQueryAdd("api-version", "2025-11-15-preview"),
	)

	// --- Example 1: OpenAI model (gpt-4.1-mini) ---
	openaiModel := "gpt-4.1-mini"
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
	fmt.Printf("Response: %s\n", resp1.OutputText())
	fmt.Printf("Status:   %s\n", resp1.Status)
	fmt.Printf("Output tokens: %d\n\n", resp1.Usage.OutputTokens)

	// --- Example 2: Non-OpenAI model (DeepSeek-R1-0528) ---
	deepseekModel := "DeepSeek-R1-0528"
	fmt.Printf("Example 2: Non-OpenAI model (%s)\n\n", deepseekModel)
	fmt.Println("Waiting for response (reasoning models can take 30-60s)...")
	resp2, err := client.Responses.New(ctx, responses.ResponseNewParams{
		Model: deepseekModel,
		Input: responses.ResponseNewParamsInputUnion{
			OfString: openai.String("What are the top 3 benefits of cloud computing? Be concise."),
		},
		MaxOutputTokens: openai.Int(500),
	})
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("Response: %s\n", resp2.OutputText())
	fmt.Printf("Status:   %s\n", resp2.Status)
	fmt.Printf("Output tokens: %d\n", resp2.Usage.OutputTokens)
}
