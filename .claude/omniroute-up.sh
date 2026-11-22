#!/usr/bin/env bash
# Starts OmniRoute on loopback and registers its MCP server with Claude Code.
# Safe to re-run. Secrets stay in ~/.omniroute (never in the repo).
set -uo pipefail
export PATH="$HOME/.local/bin:/opt/node22/bin:$PATH"
export OMNIROUTE_SERVER_HOST=127.0.0.1
URL=http://127.0.0.1:20128
DIR="$HOME/.omniroute"; mkdir -p "$DIR"; chmod 700 "$DIR"

command -v omniroute >/dev/null || npm install -g --silent omniroute

if ! curl -sf -m 3 "$URL/api/health" >/dev/null; then
  omniroute serve --daemon --no-open --no-tray >/dev/null 2>&1
  for _ in $(seq 60); do curl -sf -m 2 "$URL/api/health" >/dev/null && break; sleep 1; done
fi
omniroute mcp enable --transport streamable-http >/dev/null 2>&1

# One-time: admin password + API key for Claude, kept in ~/.omniroute
if [ ! -s "$DIR/admin.pass" ]; then
  umask 077; openssl rand -hex 24 > "$DIR/admin.pass"
  omniroute setup --non-interactive --password "$(cat "$DIR/admin.pass")" >/dev/null 2>&1
fi
if [ ! -s "$DIR/claude.key" ]; then
  JAR=$(mktemp); umask 077
  curl -s -m 10 -c "$JAR" -H 'Content-Type: application/json' \
    -d "{\"password\":\"$(cat "$DIR/admin.pass")\"}" "$URL/api/auth/login" >/dev/null
  curl -s -m 10 -b "$JAR" -H 'Content-Type: application/json' -d '{"name":"claude-code","scopes":["mcp:connect"]}' "$URL/api/keys" \
    | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("key") or d.get("data",{}).get("key") or "")' > "$DIR/claude.key"
  rm -f "$JAR"
fi

KEY=$(cat "$DIR/claude.key" 2>/dev/null)
if [ -n "$KEY" ] && command -v claude >/dev/null; then
  claude mcp get omniroute >/dev/null 2>&1 || \
    claude mcp add --scope user --transport http omniroute "$URL/api/mcp/stream" \
      --header "Authorization: Bearer $KEY" >/dev/null 2>&1
fi
echo "OmniRoute: $(curl -s -m 3 "$URL/api/health" || echo down) | key: $([ -n "$KEY" ] && echo ok || echo missing)"
exit 0
