# Arbeitsregeln für Claude in diesem Repo

Die Skills in `.claude/skills/` sind fester Teil dieses Repos. Bei jeder Code-Arbeit
den passenden Skill automatisch laden, ohne nachzufragen:

| Aufgabe | Skill |
|---|---|
| Jede Code-Änderung, Bugfix, Refactor | `ponytail` (Standard-Stufe `full`) |
| Review einer Änderung / des ganzen Repos | `ponytail-review` / `ponytail-audit` |
| Fragen zur Architektur, Datei-Beziehungen, Codebase verstehen | `graphify` |
| Webseiten, Links, YouTube, GitHub, Reddit lesen, wenn eigene Tools nicht reichen | `agent-reach` |
| Video aus Code, Erklärvideo, Titelkarten, Slideshow | `hyperframes` (+ `hyperframes-cli`, `hyperframes-registry`, `media-use`, `slideshow`) |
| Kurzes animiertes Hochformat-Video (Cartoon in 3D-Welt) | `cartoon-3d-short` |
| LLM-Gateway, Provider, Routing, kostenlose LLM-APIs | `omni-*` / `cli-*` (OmniRoute) |
| Neuen Skill installieren | vorher `skill-inspector` (NVIDIA SkillSpector) laufen lassen |

## OmniRoute (immer aktiv)

OmniRoute ist als stdio-MCP-Server `omniroute` bei Claude Code registriert. Claude Code startet ihn
bei jedem Sitzungsstart selbst über `~/.omniroute/mcp-launch.sh`; dieser startet auch den Server
`127.0.0.1:20128` (OpenAI-kompatibel: `http://127.0.0.1:20128/v1`). Nie stoppen.
Falls die Registrierung fehlt, ohne Nachfrage ausführen: `.claude/omniroute-up.sh`.

Die CLI-Programme (`skillspector`, `agent-reach`, `graphify`, `omniroute`) installiert das
Setup-Skript der Cloud-Umgebung „Terraform“ bei jedem neuen Container; es startet auch
OmniRoute, bevor Claude startet. Falls ein Programm fehlt: `.claude/hooks/session-start.sh`.
