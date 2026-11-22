#!/usr/bin/env bash
# Installs the CLI tools behind the skills in .claude/skills at every session start.
# Idempotent: skips anything already installed. Never fails the session.
set -uo pipefail
export PATH="$HOME/.local/bin:$PATH"

have() { command -v "$1" >/dev/null 2>&1; }

have uv || pip install -q uv

# SkillSpector: scans agent skills for security problems (skill: skill-inspector)
have skillspector || uv tool install -q git+https://github.com/NVIDIA/SkillSpector.git

# Agent Reach: reads the web without API keys (skill: agent-reach)
have agent-reach || uv tool install -q git+https://github.com/Panniantong/Agent-Reach.git

# Graphify: codebase knowledge graph (skill: graphify)
have graphify || uv tool install -q graphifyy

# OmniRoute: AI gateway, one endpoint for many LLM providers (skills: cli-*, omni-*)
have omniroute || npm install -g --silent omniroute >/dev/null 2>&1

# HyperFrames and Remotion (cartoon-3d-short) run on demand via npx; they need Node 22+ and FFmpeg.
have ffmpeg || echo "hint: install ffmpeg for HyperFrames / Remotion rendering" >&2

if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"$HOME/.local/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi

exit 0
