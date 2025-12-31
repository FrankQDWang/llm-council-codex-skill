#!/bin/bash
#
# query_codex.sh - Query OpenAI Codex CLI in non-interactive mode
#
# Usage: ./query_codex.sh "Your prompt here"
#
# This script wraps the Codex CLI to provide non-interactive querying
# for the LLM Council orchestration system.
#
# Codex CLI reference: https://github.com/openai/codex

set -euo pipefail

# Configuration
TIMEOUT_SECONDS="${CODEX_TIMEOUT:-120}"
MAX_RETRIES="${CODEX_MAX_RETRIES:-3}"

# Find timeout command (macOS uses gtimeout from coreutils, Linux uses timeout)
TIMEOUT_CMD=""
if command -v timeout &>/dev/null; then
    TIMEOUT_CMD="timeout"
elif command -v gtimeout &>/dev/null; then
    TIMEOUT_CMD="gtimeout"
fi

# Input:
# - If an argument is provided, treat it as the prompt unless it is a prompt-file marker.
# - If no argument is provided, read the prompt from stdin.
PROMPT="${1:-}"
PROMPT_FILE=""
CREATED_TEMP=0

if [[ -n "$PROMPT" ]] && [[ "$PROMPT" == __PROMPT_FILE__:* ]]; then
    PROMPT_FILE="${PROMPT#__PROMPT_FILE__:}"
    PROMPT=""
    if [[ ! -f "$PROMPT_FILE" ]]; then
        echo "Error: Prompt file not found: $PROMPT_FILE" >&2
        exit 1
    fi
fi

if [[ -z "$PROMPT" ]] && [[ -z "$PROMPT_FILE" ]]; then
    PROMPT_FILE="$(mktemp -t council-codex-prompt.XXXXXX)"
    CREATED_TEMP=1
    cat > "$PROMPT_FILE"
fi

# Check if Codex CLI is available
if ! command -v codex &> /dev/null; then
    echo "Error: codex CLI not found" >&2
    echo "Install from: npm install -g @openai/codex" >&2
    exit 1
fi

# Function to execute query with retry logic
query_codex() {
    local attempt=0
    local exit_code=0
    local last_err_log=""

    while [[ $attempt -le $MAX_RETRIES ]]; do
        if [[ $attempt -gt 0 ]]; then
            sleep $((5 * attempt))  # Exponential backoff: 5s, 10s
        fi

        # Execute Codex in non-interactive exec mode.
        # Keep stage outputs clean by capturing ONLY the final message.
        local cmd_result=0
        local last_msg
        local err_log
        last_msg="$(mktemp -t council-codex-last.XXXXXX)"
        err_log="$(mktemp -t council-codex-err.XXXXXX)"

        if [[ -n "$TIMEOUT_CMD" ]]; then
            if [[ -n "$PROMPT_FILE" ]]; then
                $TIMEOUT_CMD "$TIMEOUT_SECONDS" codex exec --skip-git-repo-check --output-last-message "$last_msg" \
                    < "$PROMPT_FILE" > /dev/null 2> "$err_log" || cmd_result=$?
            else
                printf '%s' "$PROMPT" | $TIMEOUT_CMD "$TIMEOUT_SECONDS" codex exec --skip-git-repo-check --output-last-message "$last_msg" \
                    > /dev/null 2> "$err_log" || cmd_result=$?
            fi
        else
            if [[ -n "$PROMPT_FILE" ]]; then
                codex exec --skip-git-repo-check --output-last-message "$last_msg" \
                    < "$PROMPT_FILE" > /dev/null 2> "$err_log" || cmd_result=$?
            else
                printf '%s' "$PROMPT" | codex exec --skip-git-repo-check --output-last-message "$last_msg" \
                    > /dev/null 2> "$err_log" || cmd_result=$?
            fi
        fi

        if [[ $cmd_result -eq 0 ]] && [[ -s "$last_msg" ]]; then
            cat "$last_msg"
            rm -f "$last_msg" "$err_log" "$last_err_log" 2>/dev/null || true
            return 0
        fi

        rm -f "$last_msg" 2>/dev/null || true
        [[ -n "$last_err_log" ]] && rm -f "$last_err_log" 2>/dev/null || true
        last_err_log="$err_log"

        exit_code=$cmd_result

        ((attempt++))
    done

    echo "[ABSENT] Codex: failed after $((MAX_RETRIES + 1)) attempts"
    if [[ -n "$last_err_log" ]] && [[ -s "$last_err_log" ]]; then
        tail -n 60 "$last_err_log" || true
    fi
    rm -f "$last_err_log" 2>/dev/null || true
    return $exit_code
}

# Execute the query
query_codex

if [[ $CREATED_TEMP -eq 1 ]] && [[ -n "${PROMPT_FILE:-}" ]]; then
    rm -f "$PROMPT_FILE" 2>/dev/null || true
fi
