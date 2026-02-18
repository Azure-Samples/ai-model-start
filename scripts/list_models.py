#!/usr/bin/env python3
"""
List models that support the Responses API in your Azure subscription.

Queries the ARM control plane (Microsoft.CognitiveServices) across all available
locations and shows which models have the "responses" capability.

Note: The ARM API only tags OpenAI-format models with the "responses" capability.
Non-OpenAI models (DeepSeek, Meta, xAI, etc.) that support chat completion also
work with the Responses API at runtime, but are not tagged in the control plane.
Use --non-openai to list these models.

Usage:
    python list_models.py                          # OpenAI models with responses
    python list_models.py --non-openai             # non-OpenAI chat models
    python list_models.py --locations              # show per-region breakdown
    python list_models.py --subscription <sub-id>  # explicit subscription
"""

import argparse
import json
import subprocess
import sys
from collections import defaultdict

from azure.identity import DefaultAzureCredential
from azure.mgmt.cognitiveservices import CognitiveServicesManagementClient


# Locations known to host AI Services model catalogs.
# The ARM API is location-scoped, so we query each one.
LOCATIONS = [
    "australiaeast",
    "brazilsouth",
    "canadacentral",
    "canadaeast",
    "eastus",
    "eastus2",
    "francecentral",
    "germanywestcentral",
    "japaneast",
    "koreacentral",
    "northcentralus",
    "norwayeast",
    "polandcentral",
    "southafricanorth",
    "southcentralus",
    "southeastasia",
    "southindia",
    "swedencentral",
    "switzerlandnorth",
    "uksouth",
    "westeurope",
    "westus",
    "westus3",
]


def get_subscription_id():
    """Resolve the default subscription via 'az account show'."""
    try:
        result = subprocess.run(
            ["az", "account", "show", "--query", "id", "-o", "tsv"],
            capture_output=True, text=True, check=True, shell=True,
        )
        return result.stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None


def list_responses_models(subscription_id=None, show_locations=False, non_openai=False):
    credential = DefaultAzureCredential()

    if not subscription_id:
        subscription_id = get_subscription_id()
        if not subscription_id:
            print("Error: could not resolve a subscription. "
                  "Pass --subscription or sign in with 'az login'.")
            sys.exit(1)

    if non_openai:
        label = "non-OpenAI chat-capable models (work with Responses API)"
    else:
        label = "OpenAI models with Responses API support"

    print(f"Subscription: {subscription_id}\n")
    print(f"Scanning {len(LOCATIONS)} locations for {label}...\n")

    client = CognitiveServicesManagementClient(credential, subscription_id)

    # model key -> { "format", "versions": {version -> set(locations)}, "skus" }
    models = defaultdict(lambda: {
        "format": "",
        "versions": defaultdict(set),
        "skus": set(),
    })

    for location in LOCATIONS:
        try:
            for entry in client.models.list(location=location):
                m = entry.model
                caps = m.capabilities or {}
                fmt = m.format or ""

                if non_openai:
                    # Show non-OpenAI models with chatCompletion support.
                    # These work with the Responses API even though the ARM
                    # capabilities object doesn't tag them with "responses".
                    if fmt == "OpenAI":
                        continue
                    if caps.get("chatCompletion") != "true":
                        continue
                else:
                    # Default: OpenAI models explicitly tagged with responses.
                    if caps.get("responses") != "true":
                        continue

                key = (fmt, m.name or "")
                info = models[key]
                info["format"] = fmt
                version = m.version or "(default)"
                info["versions"][version].add(location)
                for sku in (m.skus or []):
                    info["skus"].add(sku.name)
        except Exception:
            # Location may not support the API — skip silently.
            pass

    if not models:
        print(f"No {label} found.")
        return

    # Display results
    all_locations_set = set(LOCATIONS)

    print(f"Found {len(models)} model(s):\n")
    print(f"  {'Model':<35} {'Format':<15} {'Versions':<20} {'Locations'}")
    print(f"  {'-'*35} {'-'*15} {'-'*20} {'-'*20}")

    for (fmt, name), info in sorted(models.items()):
        model_locations = set()
        for locs in info["versions"].values():
            model_locations |= locs

        versions = ", ".join(sorted(info["versions"].keys()))
        is_global = model_locations >= all_locations_set
        location_summary = "All regions" if is_global else f"{len(model_locations)}/{len(LOCATIONS)} regions"

        print(f"  {name:<35} {fmt:<15} {versions:<20} {location_summary}")

    # Show detailed location breakdown when --locations is passed
    if show_locations:
        print(f"\n{'='*90}")
        print("Detailed location breakdown (models not available in all regions):\n")

        any_printed = False
        for (fmt, name), info in sorted(models.items()):
            model_locations = set()
            for locs in info["versions"].values():
                model_locations |= locs

            if model_locations >= all_locations_set:
                continue

            any_printed = True
            print(f"  {name} ({fmt})")
            for ver, locs in sorted(info["versions"].items()):
                print(f"    {ver}: {', '.join(sorted(locs))}")

        if not any_printed:
            print("  All models are available in every region.")

    print(f"\nTotal: {len(models)} model(s) across {len(LOCATIONS)} locations")


def main():
    parser = argparse.ArgumentParser(
        description="List models that support the Responses API via the ARM control plane."
    )
    parser.add_argument(
        "--subscription", "-s",
        help="Azure subscription ID (defaults to your active subscription)",
    )
    parser.add_argument(
        "--locations", "-l",
        action="store_true",
        help="Show per-region breakdown for models not available in all regions",
    )
    parser.add_argument(
        "--non-openai",
        action="store_true",
        dest="non_openai",
        help="List non-OpenAI models (DeepSeek, Meta, xAI, etc.) that support chat completion and work with the Responses API",
    )
    args = parser.parse_args()
    list_responses_models(args.subscription, args.locations, args.non_openai)


if __name__ == "__main__":
    main()
