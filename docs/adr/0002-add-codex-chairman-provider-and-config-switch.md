# ADR 0002: Add Codex chairman provider and configurable Stage 3 selection

- Status: Accepted
- Date: 2025-12-26

## Context

Stage 3 synthesis (“chairman”) was hard-coded to run via the Claude-based chairman flow. On this machine, the installed workflow supports selecting a chairman provider (Codex vs Claude), and defaults to using Codex when available.

## Decision

- Add a Codex-based chairman implementation (`run_chairman_codex_cli.sh`) that embeds Stage 1/2 evidence and writes `final_report.md` from Codex stdout.
- Make Stage 3 provider configurable via:
  - `chairman_provider=codex|claude|auto` in `~/.council/config`, and/or
  - `COUNCIL_CHAIRMAN_PROVIDER=codex|claude|auto` environment variable.
- Default to `codex` for Stage 3 unless overridden.

## Alternatives Considered

- Keep Claude-only chairman: rejected because it diverges from the installed behavior and prevents users from choosing a local/default Codex synthesis path.
- Always auto-select: rejected as default because explicit selection is useful for reproducibility and debugging.

## Consequences

- Stage 3 behavior changes unless users explicitly set `chairman_provider=claude`.
- Adds an extra script dependency on the `codex` CLI when `chairman_provider=codex` or `auto` selects it.

## Outcome

- Stage 3 synthesis is configurable and matches the installed local workflow.

