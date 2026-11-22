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
get Panniantong/Agent-Reach ar agent_reach/skill && cp -r "$T/ar/agent_reach/skill" "$SK/agent-reach"
get NVIDIA/SkillSpector ss skills && cp -r "$T"/ss/skills/*/ "$SK"/
get mromidev/claude-animated-shorts as "references templates" && mkdir -p "$SK/cartoon-3d-short" && cp -r "$T"/as/* "$SK/cartoon-3d-short"/
get safishamsi/graphify gf graphify && mkdir -p "$SK/graphify" && cp "$T/gf/graphify/skill.md" "$SK/graphify/SKILL.md" && cp -r "$T/gf/graphify/skills/claude/references" "$SK/graphify"/
get diegosouzapw/OmniRoute om skills && for d in "$T"/om/skills/*/; do [ "$(basename "$d")" = ponytail ] || cp -r "$d" "$SK"/; done
rm -rf "$T"
# Ponytail as Claude Code plugin (always-on hooks), Graphify registered in ~/.claude/CLAUDE.md
command -v claude >/dev/null && { claude plugin marketplace add DietrichGebert/ponytail >/dev/null 2>&1; claude plugin install ponytail@ponytail --scope user >/dev/null 2>&1; }
graphify install --platform claude >/dev/null 2>&1
# OmniRoute: Claude Code starts it itself at every session start (stdio MCP launcher)
D="$HOME/.omniroute"; mkdir -p "$D"; chmod 700 "$D"
printf '%s\n' '#!/usr/bin/env bash' 'export PATH="$HOME/.local/bin:/opt/node22/bin:$PATH" OMNIROUTE_SERVER_HOST=127.0.0.1' \
  'curl -sf -m 2 http://127.0.0.1:20128/api/health >/dev/null || (setsid omniroute serve --daemon --no-open --no-tray </dev/null >/dev/null 2>&1 &)' \
  'exec omniroute --mcp' > "$D/mcp-launch.sh"; chmod 700 "$D/mcp-launch.sh"
command -v claude >/dev/null && { claude mcp remove --scope user omniroute >/dev/null 2>&1; claude mcp add --scope user omniroute -- "$D/mcp-launch.sh" >/dev/null 2>&1; }
# Global rules: use the skills automatically, keep OmniRoute connected
grep -q 'Immer aktiv (nie abschalten)' "$HOME/.claude/CLAUDE.md" 2>/dev/null || cat >> "$HOME/.claude/CLAUDE.md" <<'EOF'

## Immer aktiv (nie abschalten): Ponytail, OmniRoute, Graphify, Agent Skills
- Ponytail: Plugin, Stufe full, bei jeder Code-Aufgabe aktiv.
- OmniRoute: MCP-Server `omniroute`, bei jeder Sitzung verbunden.
- Graphify: bei jeder Frage zur Codebase zuerst nutzen.
- Agent Skills: alle Skills in ~/.claude/skills passend automatisch laden.

## Skills automatisch nutzen (alle Repos)
Bei jeder Code-Arbeit den passenden Skill aus ~/.claude/skills ohne Nachfrage laden:
ponytail (jede Code-Änderung), ponytail-review/-audit (Reviews), graphify (Codebase verstehen),
agent-reach (Web lesen), hyperframes* (Videos aus Code), cartoon-3d-short (animierte Shorts),
omni-*/cli-* (OmniRoute, LLM-Gateway), skill-inspector (vor jeder Skill-Installation).

## OmniRoute (auto)
MCP-Server `omniroute` (stdio) startet Claude Code selbst bei jedem Sitzungsstart; der Starter
~/.omniroute/mcp-launch.sh startet auch den Server 127.0.0.1:20128. Immer aktiv lassen, nie stoppen.
Falls down: `~/.omniroute/mcp-launch.sh` gibt es; Server per `curl -sf 127.0.0.1:20128/api/health` prüfen.
EOF
exit 0
