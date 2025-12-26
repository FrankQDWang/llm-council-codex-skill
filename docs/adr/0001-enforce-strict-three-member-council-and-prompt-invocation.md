# ADR 0001: Enforce strict 3-member council and prompt invocation

- Status: Accepted
- Date: 2025-12-26

## Context

The Codex CLI chat UI does not support adding custom `/council` slash-commands via `~/.codex/prompts/`. Additionally, degraded runs (missing Gemini) were being treated as successful, which conflicts with the requirement to always run with 3 members.

## Decision

- Switch documented usage to `-/prompts:council <question>` (and `/prompts:council ARGUMENTS="..."` as an alternative).
- Provide an optional helper binary installed to `~/.codex/bin/council` for terminal usage.
- Default to strict 3-member operation via config default `require_all_members=1` and quorum defaults `min_quorum=3`, failing fast if any of Claude/Codex/Gemini is missing or produces no output.

## Alternatives Considered

- Continue to advertise `/council "question"`: rejected because Codex CLI does not dynamically register custom slash commands from local prompt files.
- Allow degraded runs by default: rejected because it violates the “3 members must all participate” requirement.

## Consequences

- Users must install/configure `gemini` to run the council by default, or explicitly disable strict mode via config.
- Documentation and prompt templates are aligned with Codex CLI’s actual prompt invocation behavior.

## Outcome

- Strict 3-member council is the default; degraded mode remains available via config (`require_all_members=0`).

