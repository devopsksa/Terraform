export PATH="$HOME/.local/bin:$PATH"
command -v uv >/dev/null || pip install -q uv
command -v skillspector >/dev/null || uv tool install -q git+https://github.com/NVIDIA/SkillSpector.git
command -v agent-reach >/dev/null || uv tool install -q git+https://github.com/Panniantong/Agent-Reach.git
command -v graphify >/dev/null || uv tool install -q graphifyy
command -v omniroute >/dev/null || npm install -g --silent omniroute
# Skills for every repo -> ~/.claude/skills
SK="$HOME/.claude/skills"; T=$(mktemp -d); mkdir -p "$SK"
get() { git clone -q --depth 1 --filter=blob:none --sparse "https://github.com/$1.git" "$T/$2" && git -C "$T/$2" sparse-checkout set $3; }
get heygen-com/hyperframes hf skills && cp -r "$T"/hf/skills/*/ "$SK"/
get DietrichGebert/ponytail pt skills && cp -r "$T"/pt/skills/*/ "$SK"/
get Panniantong/Agent-Reach ar agent_reach/skill && cp -r "$T/ar/agent_reach/skill" "$SK/agent-reach"
get NVIDIA/SkillSpector ss skills && cp -r "$T"/ss/skills/*/ "$SK"/
get mromidev/claude-animated-shorts as "references templates" && mkdir -p "$SK/cartoon-3d-short" && cp -r "$T"/as/* "$SK/cartoon-3d-short"/
get safishamsi/graphify gf graphify && mkdir -p "$SK/graphify" && cp "$T/gf/graphify/skill.md" "$SK/graphify/SKILL.md" && cp -r "$T/gf/graphify/skills/claude/references" "$SK/graphify"/
get diegosouzapw/OmniRoute om skills && for d in "$T"/om/skills/*/; do [ "$(basename "$d")" = ponytail ] || cp -r "$d" "$SK"/; done
rm -rf "$T"
# OmniRoute: start on loopback, key in ~/.omniroute, register MCP with Claude Code
export OMNIROUTE_SERVER_HOST=127.0.0.1; U=http://127.0.0.1:20128; D="$HOME/.omniroute"; mkdir -p "$D"; chmod 700 "$D"
curl -sf -m 3 "$U/api/health" >/dev/null || omniroute serve --daemon --no-open --no-tray >/dev/null 2>&1
for _ in $(seq 60); do curl -sf -m 2 "$U/api/health" >/dev/null && break; sleep 1; done
omniroute mcp enable --transport streamable-http >/dev/null 2>&1
if [ ! -s "$D/admin.pass" ]; then (umask 077; openssl rand -hex 24 > "$D/admin.pass"); omniroute setup --non-interactive --password "$(cat "$D/admin.pass")" >/dev/null 2>&1; fi
if [ ! -s "$D/claude.key" ]; then
  J=$(mktemp); curl -s -m 10 -c "$J" -H 'Content-Type: application/json' -d "{\"password\":\"$(cat "$D/admin.pass")\"}" "$U/api/auth/login" >/dev/null
  curl -s -m 10 -b "$J" -H 'Content-Type: application/json' -d '{"name":"claude-code","scopes":["mcp:connect"]}' "$U/api/keys" \
    | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("key") or "")' > "$D/claude.key"; chmod 600 "$D/claude.key"; rm -f "$J"
fi
K=$(cat "$D/claude.key" 2>/dev/null)
if [ -n "$K" ] && command -v claude >/dev/null && ! claude mcp get omniroute >/dev/null 2>&1; then
  claude mcp add --scope user --transport http omniroute "$U/api/mcp/stream" --header "Authorization: Bearer $K" >/dev/null 2>&1
fi
# Global rules: use the skills automatically, keep OmniRoute connected
grep -q 'OmniRoute (auto)' "$HOME/.claude/CLAUDE.md" 2>/dev/null || cat >> "$HOME/.claude/CLAUDE.md" <<'EOF'

## Skills automatisch nutzen (alle Repos)
Bei jeder Code-Arbeit den passenden Skill aus ~/.claude/skills ohne Nachfrage laden:
ponytail (jede Code-Änderung), ponytail-review/-audit (Reviews), graphify (Codebase verstehen),
agent-reach (Web lesen), hyperframes* (Videos aus Code), cartoon-3d-short (animierte Shorts),
omni-*/cli-* (OmniRoute, LLM-Gateway), skill-inspector (vor jeder Skill-Installation).

## OmniRoute (auto)
Vor der ersten Code-Arbeit ohne Nachfrage prüfen: `curl -sf 127.0.0.1:20128/api/health`.
Wenn down: `OMNIROUTE_SERVER_HOST=127.0.0.1 omniroute serve --daemon --no-open --no-tray`.
MCP-Server `omniroute` ist in Claude Code registriert; Zugangsdaten in ~/.omniroute.
EOF
exit 0
