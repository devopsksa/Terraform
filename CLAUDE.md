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

Die CLI-Programme (`skillspector`, `agent-reach`, `graphify`, `omniroute`) installiert
`.claude/hooks/session-start.sh` automatisch bei jedem Sitzungsstart.
