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
mkdir -p .council-query
cat > .council-query/query.txt <<'__COUNCIL_QUERY__'
$ARGUMENTS
__COUNCIL_QUERY__
COUNCIL_RUNTIME_HOME=1 ~/.codex/bin/council .council-query/query.txt
```
