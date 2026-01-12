# /council-help

LLM Council commands:

- `-/prompts:council "question"`: inserts the council prompt and lets you pass the question as plain text
- `/prompts:council ARGUMENTS="question"`: same, but `/prompts:...` requires `key=value` arguments
- `-/prompts:council-cleanup`: delete `.council/`
- `-/prompts:council-status`: show CLI/config readiness
- `-/prompts:council-config`: view/set/reset `~/.council/config`
- `-/prompts:council-verify-deps`: verify required/optional dependencies

Tips:
- In Codex CLI, custom `/...` chat commands are not supported; use prompt refs like `-/prompts:council "question"` (or install the `council` shell helper in `~/.codex/bin/`).
- `+` 拼接（例如 `/prompts:council+question`）不是有效语法：它不会把 `+question` 当作参数传给 prompt，而是会导致 prompt 无法展开/或被当成普通文本。用 `-/prompts:council question` 或 `/prompts:council ARGUMENTS="question"`。
- If you need a local proxy for Gemini, prefer `proxy_url=...` in `~/.council/config` or `COUNCIL_PROXY_URL=...` when invoking `~/.codex/bin/council`. If no proxy is configured, `~/.codex/bin/council` will auto-use `http://127.0.0.1:7890` when it is reachable.
- Strict mode (default): set `enabled_members=claude,codex,gemini`, `min_quorum=3`, `require_all_members=1` via the config prompt.
- If Gemini is installed but not configured, disable it: `-/prompts:council-config set enabled_members claude,codex`
- Increase long-question limit: `-/prompts:council-config set max_prompt_length 200000`
