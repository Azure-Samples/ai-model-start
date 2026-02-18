#!/usr/bin/env python3
"""
Microsoft Foundry Models - Responses API Example (Plain OpenAI SDK)
Uses the standard openai.OpenAI client with the project endpoint + /openai suffix.
No dependency on azure.ai.projects.
"""

import os
import sys

from azure.identity import DefaultAzureCredential
from openai import OpenAI


def get_token():
    """Get an EntraID access token for the Microsoft Foundry project endpoint."""
    credential = DefaultAzureCredential()
    token = credential.get_token("https://ai.azure.com/.default")
    return token.token


def main():
    """Run Responses API examples using the plain OpenAI SDK."""
    print("Microsoft Foundry Models - Responses API (Plain OpenAI SDK)\n")

    endpoint = os.environ.get("AZURE_AI_PROJECT_ENDPOINT")
    if not endpoint:
        print("Error: AZURE_AI_PROJECT_ENDPOINT must be set.")
        sys.exit(1)

    # Build the base URL: project endpoint + /openai
    base_url = endpoint.rstrip("/") + "/openai"
    token = get_token()

    # Standard OpenAI client — no AzureOpenAI, no AIProjectClient
    client = OpenAI(
        base_url=base_url,
        api_key=token,
        default_query={"api-version": "2025-11-15-preview"},
    )

    # --- Example 1: OpenAI model (gpt-4.1-mini) ---
    openai_model = "gpt-4.1-mini"
    print(f"Example 1: OpenAI model ({openai_model})\n")
    print("Waiting for response...", flush=True)
    response = client.responses.create(
        model=openai_model,
        input="Explain quantum computing in 3 sentences.",
        max_output_tokens=500,
    )
    print(f"Response: {response.output_text}")
    print(f"Status:   {response.status}")
    print(f"Output tokens: {response.usage.output_tokens}\n")

    # --- Example 2: Non-OpenAI model (DeepSeek-R1-0528) ---
    deepseek_model = "DeepSeek-R1-0528"
    print(f"Example 2: Non-OpenAI model ({deepseek_model})\n")
    print("Waiting for response (reasoning models can take 30-60s)...", flush=True)
    response = client.responses.create(
        model=deepseek_model,
        input="What are the top 3 benefits of cloud computing? Be concise.",
        max_output_tokens=500,
    )
    print(f"Response: {response.output_text}")
    print(f"Status:   {response.status}")
    print(f"Output tokens: {response.usage.output_tokens}")


if __name__ == "__main__":
    main()
