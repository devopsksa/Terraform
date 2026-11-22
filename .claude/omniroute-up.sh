#!/usr/bin/env bash
# Registers OmniRoute with Claude Code as a stdio MCP server. Claude Code starts the
# launcher at every session start; the launcher also starts the OmniRoute server
# (127.0.0.1:20128) if it is not running. So OmniRoute stays on in every session.
set -uo pipefail
export PATH="$HOME/.local/bin:/opt/node22/bin:$PATH"
D="$HOME/.omniroute"; mkdir -p "$D"; chmod 700 "$D"
command -v omniroute >/dev/null || npm install -g --silent omniroute

cat > "$D/mcp-launch.sh" <<'EOF'
#!/usr/bin/env bash
export PATH="$HOME/.local/bin:/opt/node22/bin:$PATH" OMNIROUTE_SERVER_HOST=127.0.0.1
command -v omniroute >/dev/null || npm install -g --silent omniroute >/dev/null 2>&1
curl -sf -m 2 http://127.0.0.1:20128/api/health >/dev/null || \
  (nohup omniroute serve --daemon --no-open --no-tray </dev/null >/dev/null 2>&1 &)
exec omniroute --mcp
EOF
chmod 700 "$D/mcp-launch.sh"

if command -v claude >/dev/null; then
  claude mcp get omniroute 2>/dev/null | grep -q mcp-launch.sh || {
    claude mcp remove --scope user omniroute >/dev/null 2>&1
    claude mcp add --scope user omniroute -- "$D/mcp-launch.sh" >/dev/null 2>&1
  }
fi
curl -sf -m 2 http://127.0.0.1:20128/api/health >/dev/null || \
  (OMNIROUTE_SERVER_HOST=127.0.0.1 nohup omniroute serve --daemon --no-open --no-tray </dev/null >/dev/null 2>&1 &)
echo "OmniRoute MCP: registered (stdio, auto-start)"
exit 0
