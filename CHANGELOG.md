# Changelog

## [Unreleased]

- Switch Codex usage to `-/prompts:...` / `/prompts:...` (instead of `/council`) and install optional `~/.codex/bin/council` helper.
- Enforce strict 3-member council by default (`require_all_members=1`, `min_quorum=3`), requiring Claude + Codex + Gemini to all respond.

