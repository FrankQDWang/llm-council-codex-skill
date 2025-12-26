---
description: Run LLM Council (multi-model consensus) and print `.council/final_report.md`.
argument-hint: question
---

# LLM Council (prompt: `council`)

## User Question

$ARGUMENTS

## Execution

Run the council helper (this resets `./.council/` for this run):

```bash
~/.codex/bin/council "$ARGUMENTS"
```
