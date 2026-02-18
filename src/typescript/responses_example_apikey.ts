/**
 * Microsoft Foundry Models - Responses API Example (API Key Authentication)
 * Uses the standard openai package with an API key instead of EntraID.
 * For quick dev/test only — use EntraID (responses_example.ts) for production.
 */

import OpenAI from "openai";

const endpoint = process.env.AZURE_AI_FOUNDRY_ENDPOINT;
const apiKey = process.env.AZURE_AI_API_KEY;
if (!endpoint || !apiKey) {
  console.error("Error: AZURE_AI_FOUNDRY_ENDPOINT and AZURE_AI_API_KEY must be set.");
  process.exit(1);
}

console.log("Microsoft Foundry Models - Responses API (API Key Auth - TypeScript)\n");

const client = new OpenAI({
  baseURL: endpoint.replace(/\/+$/, "") + "/openai/v1",
  apiKey,
});

const model = "gpt-4.1-mini";
console.log(`Model: ${model}\n`);
console.log("Waiting for response...");
const response = await client.responses.create({
  model,
  input: "Explain quantum computing in 3 sentences.",
  max_output_tokens: 500,
});
console.log(`Response: ${response.output_text}`);
console.log(`Status:   ${response.status}`);
console.log(`Output tokens: ${response.usage?.output_tokens}`);
