---
description: View/set/reset LLM Council config (~/.council/config).
argument-hint: config-command
---

# LLM Council Config (prompt: `council-config`)

Manage LLM Council configuration stored at `~/.council/config`.

Usage:
- `-/prompts:council-config`
- `-/prompts:council-config set <key> <value>`
- `-/prompts:council-config reset`

```bash
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
"$CODEX_HOME/skills/council-orchestrator/scripts/council_config.sh" $ARGUMENTS
```
