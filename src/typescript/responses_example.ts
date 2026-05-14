/**
 * Microsoft Foundry Models - Responses API Example (Plain OpenAI SDK)
 * Uses the standard openai package with the project endpoint + /openai/v1 suffix.
 * No api-version query parameter needed. No dependency on @azure/openai.
 *
 * Surfaces structured reasoning summaries for any model that emits a `reasoning`
 * output item. As of the May 2026 Foundry service update, non-OpenAI reasoning
 * models (e.g. DeepSeek-R1) emit reasoning summaries through the same in-schema
 * shape as native OpenAI reasoning models — no special handling per model family.
 */

import OpenAI from "openai";
import { DefaultAzureCredential } from "@azure/identity";

async function getToken(): Promise<string> {
  const credential = new DefaultAzureCredential();
  const tokenResponse = await credential.getToken(
    "https://ai.azure.com/.default"
  );
  return tokenResponse.token;
}

/**
 * Return concatenated reasoning summary text from a Responses API result.
 * Walks `response.output` for items of type `reasoning` and joins the `text`
 * field of each entry in their `summary` list. Returns "" if no reasoning
 * items or no summary text are present.
 */
function extractReasoningSummary(response: any): string {
  const parts: string[] = [];
  for (const item of response?.output ?? []) {
    if (item?.type !== "reasoning") continue;
    for (const s of item?.summary ?? []) {
      const text = s?.text;
      if (text) parts.push(text);
    }
  }
  return parts.join("\n").trim();
}

function printResponse(response: any): void {
  console.log(`Response: ${response.output_text}`);

  const summary = extractReasoningSummary(response);
  if (summary) {
    console.log(`\nReasoning summary:\n${summary}`);
  }

  console.log(`\nStatus:   ${response.status}`);
  const out = response?.usage?.output_tokens;
  const reasoningTokens = response?.usage?.output_tokens_details?.reasoning_tokens;
  if (reasoningTokens !== undefined && reasoningTokens !== null) {
    console.log(`Output tokens: ${out} (reasoning: ${reasoningTokens})\n`);
  } else {
    console.log(`Output tokens: ${out}\n`);
  }
}

async function main() {
  console.log(
    "Microsoft Foundry Models - Responses API (Plain OpenAI SDK - TypeScript)\n"
  );

  const endpoint = process.env.AZURE_AI_PROJECT_ENDPOINT;
  if (!endpoint) {
    console.error("Error: AZURE_AI_PROJECT_ENDPOINT must be set.");
    process.exit(1);
  }

  const baseURL = endpoint.replace(/\/+$/, "") + "/openai/v1";
  const token = await getToken();

  const client = new OpenAI({
    baseURL,
    apiKey: token,
  });

  // --- Example 1: OpenAI model (gpt-4.1-mini) ---
  const openaiModel = process.env.AZURE_MODEL_2_DEPLOYMENT_NAME ?? "gpt-4.1-mini";
  console.log(`Example 1: OpenAI model (${openaiModel})\n`);
  console.log("Waiting for response...");
  const response1 = await client.responses.create({
    model: openaiModel,
    input: "Explain quantum computing in 3 sentences.",
    max_output_tokens: 500,
  });
  printResponse(response1);

  // --- Example 2: Non-OpenAI reasoning model (DeepSeek-R1-0528) ---
  // As of the May 2026 Foundry service update, DeepSeek-R1 emits a structured
  // `reasoning` output item with `summary[].text` populated by default — the
  // same shape OpenAI reasoning models use when summaries are enabled.
  const deepseekModel = process.env.AZURE_MODEL_DEPLOYMENT_NAME ?? "DeepSeek-R1-0528";
  console.log(`Example 2: Non-OpenAI reasoning model (${deepseekModel})\n`);
  console.log("Waiting for response (reasoning models can take 30-60s)...");
  const response2 = await client.responses.create({
    model: deepseekModel,
    input: "What are the top 3 benefits of cloud computing? Be concise.",
    max_output_tokens: 2000,
  });
  printResponse(response2);
}

main().catch(console.error);
