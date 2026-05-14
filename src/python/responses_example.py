#!/usr/bin/env python3
"""
Microsoft Foundry Models - Responses API Example (Plain OpenAI SDK)
Uses the standard OpenAI client with the Foundry project endpoint + /openai/v1 suffix.

Surfaces structured reasoning summaries for any model that emits a `reasoning`
output item. As of the May 2026 Foundry service update, non-OpenAI reasoning
models (e.g. DeepSeek-R1) emit reasoning summaries through the same in-schema
shape as native OpenAI reasoning models — no special handling per model family.
"""

import os
import sys

from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from dotenv import load_dotenv
from openai import OpenAI


def extract_reasoning_summary(response) -> str:
    """Return concatenated reasoning summary text from a Responses API result.

    Walks `response.output` for items of type `reasoning` and joins the `text`
    field of each entry in their `summary` list. Returns "" if no reasoning
    items or no summary text are present (e.g. non-reasoning models, or
    reasoning models where summaries are not enabled).
    """
    parts: list[str] = []
    for item in getattr(response, "output", None) or []:
        if getattr(item, "type", None) != "reasoning":
            continue
        for s in getattr(item, "summary", None) or []:
            text = getattr(s, "text", None) or (s.get("text") if isinstance(s, dict) else None)
            if text:
                parts.append(text)
    return "\n".join(parts).strip()


def print_response(label: str, response) -> None:
    """Print final answer, optional reasoning summary, status, and token usage."""
    print(f"Response: {response.output_text}")

    summary = extract_reasoning_summary(response)
    if summary:
        print(f"\nReasoning summary:\n{summary}")

    print(f"\nStatus:   {response.status}")
    usage = response.usage
    out_tokens = getattr(usage, "output_tokens", None)
    details = getattr(usage, "output_tokens_details", None)
    reasoning_tokens = getattr(details, "reasoning_tokens", None) if details else None
    if reasoning_tokens is not None:
        print(f"Output tokens: {out_tokens} (reasoning: {reasoning_tokens})\n")
    else:
        print(f"Output tokens: {out_tokens}\n")


def main():
    """Run Responses API examples using the plain OpenAI SDK."""
    load_dotenv(override=True)
    print("Microsoft Foundry Models - Responses API (Plain OpenAI SDK)\n")

    endpoint = os.environ.get("AZURE_AI_PROJECT_ENDPOINT")
    if not endpoint:
        print("Error: AZURE_AI_PROJECT_ENDPOINT must be set.")
        sys.exit(1)

    # Build the base URL: project endpoint + /openai/v1 (no api-version needed)
    base_url = endpoint.rstrip("/") + "/openai/v1"

    # Use get_bearer_token_provider for automatic token refresh
    credential = DefaultAzureCredential()
    client = OpenAI(
        base_url=base_url,
        api_key=get_bearer_token_provider(credential, "https://ai.azure.com/.default"),
    )

    # --- Example 1: OpenAI model (gpt-4.1-mini) ---
    openai_model = os.environ.get("AZURE_MODEL_2_DEPLOYMENT_NAME", "gpt-4.1-mini")
    print(f"Example 1: OpenAI model ({openai_model})\n")
    print("Waiting for response...", flush=True)
    response1 = client.responses.create(
        model=openai_model,
        input="Explain quantum computing in 3 sentences.",
        max_output_tokens=500,
    )
    print_response(f"Example 1: {openai_model}", response1)

    # --- Example 2: Non-OpenAI reasoning model (DeepSeek-R1-0528) ---
    # As of the May 2026 Foundry service update, DeepSeek-R1 emits a structured
    # `reasoning` output item with `summary[].text` populated by default — the
    # same shape OpenAI reasoning models use when summaries are enabled.
    deepseek_model = os.environ.get("AZURE_MODEL_DEPLOYMENT_NAME", "DeepSeek-R1-0528")
    print(f"Example 2: Non-OpenAI reasoning model ({deepseek_model})\n")
    print("Waiting for response (reasoning models can take 30-60s)...", flush=True)
    response2 = client.responses.create(
        model=deepseek_model,
        input="What are the top 3 benefits of cloud computing? Be concise.",
        max_output_tokens=2000,
    )
    print_response(f"Example 2: {deepseek_model}", response2)


if __name__ == "__main__":
    main()
