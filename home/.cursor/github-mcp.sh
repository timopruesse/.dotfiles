#!/usr/bin/env bash
# GitHub MCP stdio server via Docker; token from `gh auth token`.
# Live-installed to ~/.cursor/github-mcp.sh by home/sync (like statusline.sh).
set -euo pipefail
TOKEN="$(gh auth token 2>/dev/null || true)"
if [[ -z "${TOKEN}" ]]; then
  echo "github-mcp: no token from \`gh auth token\`. Run: gh auth login" >&2
  exit 1
fi
exec docker run -i --rm \
  -e "GITHUB_PERSONAL_ACCESS_TOKEN=${TOKEN}" \
  ghcr.io/github/github-mcp-server:latest \
  stdio
