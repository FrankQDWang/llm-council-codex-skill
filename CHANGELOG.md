# Changelog

## [Unreleased]

- Switch Codex usage to `-/prompts:...` / `/prompts:...` (instead of `/council`) and install optional `~/.codex/bin/council` helper.
- Enforce strict 3-member council by default (`require_all_members=1`, `min_quorum=3`), requiring Claude + Codex + Gemini to all respond.
- Add `chairman_provider=codex|claude|auto` to select Stage 3 synthesis provider (default `codex`).
- Make all 3 members able to read the current repo by default; speed up Codex member with `model_reasoning_effort="low"`.
