#!/usr/bin/env python3
"""Test the Biomni Research Tools MCP Gateway endpoint.

Usage:
    # List available tools
    python tests/test_gateway.py --list-tools

    # Call a specific tool
    python tests/test_gateway.py --tool query_uniprot --prompt "Find human insulin protein"

    # Run all smoke tests
    python tests/test_gateway.py --smoke-test

Requires: AWS_PROFILE set to a profile with access to account 942514891246
"""

import argparse
import json
import os
import subprocess
import sys
import urllib.request

APP_NAME = os.environ.get("APP_NAME", "biomni-research-tools")
REGION = os.environ.get("AWS_REGION", "us-west-2")


def get_ssm_param(name):
    result = subprocess.run(
        ["aws", "ssm", "get-parameter", "--name", name,
         "--query", "Parameter.Value", "--output", "text", "--region", REGION],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        raise RuntimeError(f"Failed to get SSM param {name}: {result.stderr}")
    return result.stdout.strip()


def get_token():
    client_id = get_ssm_param(f"/app/{APP_NAME}/agentcore/machine_client_id")
    client_secret = get_ssm_param(f"/app/{APP_NAME}/agentcore/cognito_secret")
    cognito_domain = get_ssm_param(f"/app/{APP_NAME}/agentcore/cognito_domain")
    auth_scope = get_ssm_param(f"/app/{APP_NAME}/agentcore/cognito_auth_scope")

    domain_clean = cognito_domain.replace("https://", "")
    token_url = f"https://{domain_clean}/oauth2/token"

    data = (
        f"grant_type=client_credentials"
        f"&client_id={client_id}"
        f"&client_secret={client_secret}"
        f"&scope={auth_scope}"
    ).encode()

    req = urllib.request.Request(token_url, data=data, headers={
        "Content-Type": "application/x-www-form-urlencoded"
    })
    resp = urllib.request.urlopen(req, timeout=10)
    return json.loads(resp.read())["access_token"]


def mcp_call(gateway_url, token, method, params=None):
    body = {"jsonrpc": "2.0", "method": method, "id": 1}
    if params:
        body["params"] = params

    req = urllib.request.Request(
        gateway_url,
        data=json.dumps(body).encode(),
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
    )
    resp = urllib.request.urlopen(req, timeout=60)
    return json.loads(resp.read())


def list_tools(gateway_url, token):
    result = mcp_call(gateway_url, token, "tools/list")
    tools = result.get("result", {}).get("tools", [])
    print(f"\nAvailable tools ({len(tools)}):\n")
    for t in sorted(tools, key=lambda x: x["name"]):
        name = t["name"].replace("DatabaseLambda___", "").replace("LiteratureLambda___", "")
        print(f"  {name:<35} {t.get('description', '')[:60]}")
    return tools


def call_tool(gateway_url, token, tool_name, arguments):
    result = mcp_call(gateway_url, token, "tools/call", {
        "name": tool_name,
        "arguments": arguments
    })
    if "result" in result:
        content = result["result"].get("content", [])
        for item in content:
            if item.get("type") == "text":
                text = item["text"]
                try:
                    parsed = json.loads(text)
                    print(json.dumps(parsed, indent=2)[:2000])
                except json.JSONDecodeError:
                    print(text[:2000])
    elif "error" in result:
        print(f"Error: {result['error']}")
    return result


SMOKE_TESTS = [
    ("DatabaseLambda___query_uniprot", {"prompt": "Find human insulin protein", "max_results": 2}),
    ("DatabaseLambda___query_clinvar", {"prompt": "BRCA1 pathogenic variants"}),
    ("DatabaseLambda___query_reactome", {"prompt": "insulin signaling pathway"}),
    ("LiteratureLambda___query_pubmed", {"prompt": "CRISPR gene therapy 2024"}),
]


def smoke_test(gateway_url, token):
    print("\nRunning smoke tests...\n")
    passed = 0
    failed = 0
    for tool_name, args in SMOKE_TESTS:
        short_name = tool_name.split("___")[-1]
        print(f"  Testing {short_name}...", end=" ")
        try:
            result = mcp_call(gateway_url, token, "tools/call", {
                "name": tool_name, "arguments": args
            })
            if "result" in result:
                print("PASS")
                passed += 1
            else:
                print(f"FAIL: {result.get('error', 'unknown')}")
                failed += 1
        except Exception as e:
            print(f"FAIL: {e}")
            failed += 1

    print(f"\nResults: {passed} passed, {failed} failed")
    return failed == 0


def main():
    parser = argparse.ArgumentParser(description="Test Biomni Research Tools MCP Gateway")
    parser.add_argument("--list-tools", action="store_true", help="List available tools")
    parser.add_argument("--tool", type=str, help="Tool name to call")
    parser.add_argument("--prompt", type=str, help="Prompt to pass to the tool")
    parser.add_argument("--smoke-test", action="store_true", help="Run smoke tests")
    args = parser.parse_args()

    gateway_url = get_ssm_param(f"/app/{APP_NAME}/agentcore/gateway_url")
    print(f"Gateway: {gateway_url}")
    print(f"Getting token...")
    token = get_token()
    print(f"Token obtained.")

    if args.list_tools:
        list_tools(gateway_url, token)
    elif args.tool:
        tool_args = {"prompt": args.prompt} if args.prompt else {}
        call_tool(gateway_url, token, args.tool, tool_args)
    elif args.smoke_test:
        success = smoke_test(gateway_url, token)
        sys.exit(0 if success else 1)
    else:
        list_tools(gateway_url, token)


if __name__ == "__main__":
    main()
