#!/usr/bin/env python3
"""
Microsoft Foundry Models - Responses API Example (API Key Authentication)
Uses the standard openai.OpenAI client with an API key instead of EntraID.
For quick dev/test only — use EntraID (responses_example.py) for production.
"""

import os
import sys

from openai import OpenAI


def main():
    print("Microsoft Foundry Models - Responses API (API Key Auth)\n")

    endpoint = os.environ.get("AZURE_AI_FOUNDRY_ENDPOINT")
    api_key = os.environ.get("AZURE_AI_API_KEY")
    if not endpoint or not api_key:
        print("Error: AZURE_AI_FOUNDRY_ENDPOINT and AZURE_AI_API_KEY must be set.")
        sys.exit(1)

    base_url = endpoint.rstrip("/") + "/openai/v1"
    client = OpenAI(
        base_url=base_url,
        api_key=api_key,
    )

    # --- Example: OpenAI model (gpt-4.1-mini) ---
    model = "gpt-4.1-mini"
    print(f"Model: {model}\n")
    print("Waiting for response...", flush=True)
    response = client.responses.create(
        model=model,
        input="Explain quantum computing in 3 sentences.",
        max_output_tokens=500,
    )
    print(f"Response: {response.output_text}")
    print(f"Status:   {response.status}")
    print(f"Output tokens: {response.usage.output_tokens}")


if __name__ == "__main__":
    main()
