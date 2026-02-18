// Microsoft Foundry Models - Responses API Example (API Key Authentication)
// Uses the standard openai-go package with an API key instead of EntraID.
// For quick dev/test only — use EntraID (main.go) for production.
package main

import (
	"context"
	"fmt"
	"os"
	"strings"

	"github.com/openai/openai-go"
	"github.com/openai/openai-go/option"
	"github.com/openai/openai-go/responses"
)

func main() {
	fmt.Println("Microsoft Foundry Models - Responses API (API Key Auth - Go)\n")

	endpoint := os.Getenv("AZURE_AI_FOUNDRY_ENDPOINT")
	apiKey := os.Getenv("AZURE_AI_API_KEY")
	if endpoint == "" || apiKey == "" {
		fmt.Fprintln(os.Stderr, "Error: AZURE_AI_FOUNDRY_ENDPOINT and AZURE_AI_API_KEY must be set.")
		os.Exit(1)
	}

	baseURL := strings.TrimRight(endpoint, "/") + "/openai/v1"
	client := openai.NewClient(
		option.WithBaseURL(baseURL),
		option.WithAPIKey(apiKey),
	)

	model := "gpt-4.1-mini"
	fmt.Printf("Model: %s\n\n", model)
	fmt.Println("Waiting for response...")
	resp, err := client.Responses.New(context.Background(), responses.ResponseNewParams{
		Model: model,
		Input: responses.ResponseNewParamsInputUnion{
			OfString: openai.String("Explain quantum computing in 3 sentences."),
		},
		MaxOutputTokens: openai.Int(500),
	})
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("Response: %s\n", resp.OutputText())
	fmt.Printf("Status:   %s\n", resp.Status)
	fmt.Printf("Output tokens: %d\n", resp.Usage.OutputTokens)
}
