/**
 * Microsoft Foundry Models - Responses API Example (Plain OpenAI SDK)
 * Uses the standard openai package with the project endpoint + /openai suffix.
 * No dependency on @azure/openai.
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

async function main() {
  console.log(
    "Microsoft Foundry Models - Responses API (Plain OpenAI SDK - TypeScript)\n"
  );

  const endpoint = process.env.AZURE_AI_PROJECT_ENDPOINT;
  if (!endpoint) {
    console.error("Error: AZURE_AI_PROJECT_ENDPOINT must be set.");
    process.exit(1);
  }

  const baseURL = endpoint.replace(/\/+$/, "") + "/openai";
  const token = await getToken();

  const client = new OpenAI({
    baseURL,
    apiKey: token,
    defaultQuery: { "api-version": "2025-11-15-preview" },
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
  console.log(`Response: ${response1.output_text}`);
  console.log(`Status:   ${response1.status}`);
  console.log(`Output tokens: ${response1.usage?.output_tokens}\n`);

  // --- Example 2: Non-OpenAI model (DeepSeek-R1-0528) ---
  const deepseekModel = process.env.AZURE_MODEL_DEPLOYMENT_NAME ?? "DeepSeek-R1-0528";
  console.log(`Example 2: Non-OpenAI model (${deepseekModel})\n`);
  console.log("Waiting for response (reasoning models can take 30-60s)...");
  const response2 = await client.responses.create({
    model: deepseekModel,
    input: "What are the top 3 benefits of cloud computing? Be concise.",
    max_output_tokens: 500,
  });
  console.log(`Response: ${response2.output_text}`);
  console.log(`Status:   ${response2.status}`);
  console.log(`Output tokens: ${response2.usage?.output_tokens}`);
}

main().catch(console.error);
