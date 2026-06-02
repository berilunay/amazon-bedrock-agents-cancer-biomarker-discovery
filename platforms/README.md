# Platform Connection Guides

Per-platform guides for connecting the HCLS MCP servers (Biomni Research Gateway + OLS Runtime) and skills to your preferred AI platform.

## Supported Platforms

| Platform | Folder | Skills | MCP Transport | Auto Token Refresh |
|----------|--------|--------|---------------|-------------------|
| [Claude Code](claude-code/) | claude-code/ | `.claude/skills/` or plugin | HTTP with env vars | No (re-source script) |
| [Kiro](kiro/) | kiro/ | POWER.md + steering/ | stdio via mcp-proxy-for-aws | Yes |
| [Amazon Quick](amazon-quick/) | amazon-quick/ | Skills via Settings UI | HTTP via Settings UI | No (manual update) |
| [Strands Agents (Python)](strands-python/) | strands-python/ | N/A (system prompt) | streamablehttp_client | Yes (custom TokenManager) |
| [Codex](codex/) | codex/ | AGENTS.md + skill/ | config.toml | No |

## Quick Setup

Run the interactive installer for Claude Code, Kiro, Codex, or Amazon Quick:

```bash
./setup.sh
```

## Authentication

Both HCLS MCP servers use Cognito M2M (client_credentials) tokens:

- **Biomni Research Gateway** -- 30+ biomedical database tools (OpenTargets, ChEMBL, UniProt, etc.)
- **Ontology Lookup Service** -- Biomedical terminology search (EFO, MONDO, HP, etc.)

Tokens expire in **60 minutes**. Each platform guide explains the refresh pattern.

### Token Scripts

```bash
# Biomni Research Tools
source mcp-servers/agentcore-gateway/biomni-research-tools/get-token.sh
# Exports: BIOMNI_MCP_TOKEN, BIOMNI_GATEWAY_URL

# Ontology Lookup Service
source mcp-servers/agentcore-runtime/ontology-lookup-service/get-token.sh
# Exports: OLS_MCP_TOKEN, OLS_MCP_URL
```

## Public MCP Servers (No Auth Required)

These servers work on all platforms without authentication:

| Server | URL |
|--------|-----|
| AWS Knowledge | `https://knowledge-mcp.global.api.aws` |
| PubMed | `https://pubmed.mcp.claude.com/mcp` |
| Open Targets | `https://mcp.platform.opentargets.org/mcp` |

## What You Get

Regardless of platform, connecting gives you:

- **MCP Tools** -- Biomedical database queries, ontology lookups, literature search, genomics analysis
- **Skills** -- Domain workflow guidance for drug discovery, clinical trials, regulatory, and genomics
- **Rules** -- HCLS-aware behavior (data handling, compliance awareness, citation standards)
