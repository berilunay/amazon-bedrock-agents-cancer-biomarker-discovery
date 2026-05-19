#!/usr/bin/env python3
"""Test the OLS (Ontology Lookup Service) MCP Runtime endpoint.

Usage:
    # List available tools
    python tests/test_ols.py --list-tools

    # Call a specific tool with arguments
    python tests/test_ols.py --tool search_terms --args '{"query": "diabetes"}'

    # Run all smoke tests
    python tests/test_ols.py --smoke-test

    # Quick search test
    python tests/test_ols.py --search "diabetes"

Requires: AWS_PROFILE set to a profile with access to account 942514891246
Environment: AWS_REGION=us-west-2 (default)
"""

import argparse
import json
import os
import subprocess
import sys
import urllib.request

APP_NAME = os.environ.get("APP_NAME", "ontology-lookup-service")
REGION = os.environ.get("AWS_REGION", "us-west-2")


def get_ssm_param(name):
    """Retrieve a parameter from AWS SSM Parameter Store."""
    result = subprocess.run(
        ["aws", "ssm", "get-parameter", "--name", name,
         "--query", "Parameter.Value", "--output", "text", "--region", REGION],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        raise RuntimeError(f"Failed to get SSM param {name}: {result.stderr}")
    return result.stdout.strip()


def get_token(app_name=None):
    """Get a Cognito M2M access token via client_credentials grant."""
    app = app_name or APP_NAME
    client_id = get_ssm_param(f"/app/{app}/agentcore/machine_client_id")
    client_secret = get_ssm_param(f"/app/{app}/agentcore/cognito_secret")
    cognito_domain = get_ssm_param(f"/app/{app}/agentcore/cognito_domain")
    auth_scope = get_ssm_param(f"/app/{app}/agentcore/cognito_auth_scope")

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
    token_resp = json.loads(resp.read())

    if "access_token" not in token_resp:
        raise RuntimeError(f"Token response missing access_token: {token_resp}")

    return token_resp["access_token"]


def mcp_call(mcp_url, token, method, params=None):
    """Make a JSON-RPC call to the MCP endpoint."""
    body = {"jsonrpc": "2.0", "method": method, "id": 1}
    if params:
        body["params"] = params

    req = urllib.request.Request(
        mcp_url,
        data=json.dumps(body).encode(),
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "Accept": "application/json, text/event-stream"
        }
    )
    resp = urllib.request.urlopen(req, timeout=60)
    response_data = resp.read().decode()

    # Handle SSE (Server-Sent Events) format from streamable-http
    if response_data.startswith("event:") or response_data.startswith("data:"):
        return _parse_sse_response(response_data)

    return json.loads(response_data)


def _parse_sse_response(sse_data):
    """Parse Server-Sent Events response to extract JSON-RPC result."""
    lines = sse_data.strip().split("\n")
    last_data = None
    for line in lines:
        if line.startswith("data:"):
            data_str = line[5:].strip()
            if data_str:
                last_data = data_str
    if last_data:
        return json.loads(last_data)
    raise RuntimeError(f"No data found in SSE response: {sse_data[:500]}")


def list_tools(mcp_url, token):
    """List all tools available on the MCP endpoint."""
    result = mcp_call(mcp_url, token, "tools/list")
    tools = result.get("result", {}).get("tools", [])
    print(f"\nAvailable tools ({len(tools)}):\n")
    for t in sorted(tools, key=lambda x: x["name"]):
        desc = t.get("description", "")[:70]
        print(f"  {t['name']:<25} {desc}")
    print()
    return tools


def call_tool(mcp_url, token, tool_name, arguments):
    """Call a specific tool and print the result."""
    print(f"\nCalling tool: {tool_name}")
    print(f"Arguments: {json.dumps(arguments)}")
    print("-" * 60)

    result = mcp_call(mcp_url, token, "tools/call", {
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
                    print(json.dumps(parsed, indent=2)[:3000])
                except json.JSONDecodeError:
                    print(text[:3000])
        is_error = result["result"].get("isError", False)
        if is_error:
            print("\n[TOOL RETURNED ERROR]")
    elif "error" in result:
        print(f"Error: {json.dumps(result['error'], indent=2)}")

    return result


# Smoke tests covering all 7 OLS tools
SMOKE_TESTS = [
    ("search_terms", {"query": "diabetes"},
     "Search for diabetes terms"),
    ("get_ontology_info", {"ontology_id": "mondo"},
     "Get MONDO ontology info"),
    ("search_ontologies", {},
     "Search ontologies (list all)"),
    ("get_term_info", {"id": "HP:0001250"},
     "Get term info for HP:0001250 (seizures)"),
    ("get_term_children", {"term_iri": "http://purl.obolibrary.org/obo/HP_0001250", "ontology": "hp"},
     "Get children of HP:0001250"),
    ("get_term_ancestors", {"term_iri": "http://purl.obolibrary.org/obo/HP_0001250", "ontology": "hp"},
     "Get ancestors of HP:0001250"),
    ("find_similar_terms", {"term_iri": "http://purl.obolibrary.org/obo/HP_0001250", "ontology": "hp"},
     "Find terms similar to HP:0001250"),
]


def smoke_test(mcp_url, token, verbose=False):
    """Run smoke tests against all OLS tools."""
    print("\n" + "=" * 60)
    print("OLS MCP Server - Smoke Tests")
    print("=" * 60)
    print(f"Endpoint: {mcp_url}")
    print(f"Tests:    {len(SMOKE_TESTS)}")
    print("=" * 60 + "\n")

    passed = 0
    failed = 0
    results = []

    for tool_name, args, description in SMOKE_TESTS:
        print(f"  [{len(results)+1}/{len(SMOKE_TESTS)}] {description}...", end=" ", flush=True)
        try:
            result = mcp_call(mcp_url, token, "tools/call", {
                "name": tool_name, "arguments": args
            })
            if "result" in result:
                content = result["result"].get("content", [])
                is_error = result["result"].get("isError", False)
                if is_error:
                    print("FAIL (tool error)")
                    if verbose and content:
                        print(f"       {content[0].get('text', '')[:200]}")
                    failed += 1
                    results.append((tool_name, "FAIL", "tool error"))
                else:
                    # Check we got some content back
                    text_content = ""
                    for item in content:
                        if item.get("type") == "text":
                            text_content += item["text"]
                    if text_content:
                        print(f"PASS ({len(text_content)} chars)")
                        if verbose:
                            try:
                                parsed = json.loads(text_content)
                                preview = json.dumps(parsed, indent=2)[:200]
                            except json.JSONDecodeError:
                                preview = text_content[:200]
                            print(f"       {preview}")
                    else:
                        print("PASS (empty response)")
                    passed += 1
                    results.append((tool_name, "PASS", f"{len(text_content)} chars"))
            else:
                error_msg = str(result.get("error", "unknown"))[:100]
                print(f"FAIL: {error_msg}")
                failed += 1
                results.append((tool_name, "FAIL", error_msg))
        except Exception as e:
            print(f"FAIL: {e}")
            failed += 1
            results.append((tool_name, "FAIL", str(e)[:100]))

    print("\n" + "-" * 60)
    print(f"Results: {passed} passed, {failed} failed, {len(SMOKE_TESTS)} total")
    print("-" * 60)

    if failed > 0:
        print("\nFailed tests:")
        for name, status, detail in results:
            if status == "FAIL":
                print(f"  - {name}: {detail}")

    return failed == 0


def main():
    parser = argparse.ArgumentParser(
        description="Test OLS (Ontology Lookup Service) MCP Runtime endpoint"
    )
    parser.add_argument("--list-tools", action="store_true",
                        help="List available tools")
    parser.add_argument("--tool", type=str,
                        help="Tool name to call")
    parser.add_argument("--args", type=str, default="{}",
                        help='JSON arguments for the tool (e.g. \'{"query": "diabetes"}\')')
    parser.add_argument("--search", type=str,
                        help="Quick search: calls search_terms with the given query")
    parser.add_argument("--smoke-test", action="store_true",
                        help="Run smoke tests against all tools")
    parser.add_argument("--verbose", "-v", action="store_true",
                        help="Show response previews in smoke tests")
    parser.add_argument("--app-name", type=str, default=None,
                        help=f"Override APP_NAME (default: {APP_NAME})")
    args = parser.parse_args()

    app_name = args.app_name if args.app_name else APP_NAME

    # Get MCP URL from SSM
    print(f"App:    {app_name}")
    print(f"Region: {REGION}")
    mcp_url = get_ssm_param(f"/app/{app_name}/agentcore/mcp_url")
    print(f"MCP:    {mcp_url}")
    print("Getting token...", end=" ", flush=True)
    token = get_token(app_name)
    print("OK")

    if args.list_tools:
        list_tools(mcp_url, token)
    elif args.search:
        call_tool(mcp_url, token, "search_terms", {"query": args.search, "limit": 5})
    elif args.tool:
        tool_args = json.loads(args.args)
        call_tool(mcp_url, token, args.tool, tool_args)
    elif args.smoke_test:
        success = smoke_test(mcp_url, token, verbose=args.verbose)
        sys.exit(0 if success else 1)
    else:
        # Default: list tools then run a quick search
        list_tools(mcp_url, token)
        print("\nQuick test - search_terms('diabetes'):")
        call_tool(mcp_url, token, "search_terms", {"query": "diabetes", "limit": 3})


if __name__ == "__main__":
    main()
