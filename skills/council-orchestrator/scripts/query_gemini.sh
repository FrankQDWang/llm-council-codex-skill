#!/bin/bash
#
# query_gemini.sh - Query Google Gemini CLI in non-interactive mode
#
# Usage: ./query_gemini.sh "Your prompt here"
#
# This script wraps the Gemini CLI to provide non-interactive querying
# for the LLM Council orchestration system.
#
# Gemini CLI reference: https://github.com/google-gemini/gemini-cli

set -euo pipefail

# Configuration
TIMEOUT_SECONDS="${GEMINI_TIMEOUT:-120}"
MAX_RETRIES="${GEMINI_MAX_RETRIES:-1}"

# Best-effort proxy auto-detect (helps in environments where Google endpoints require a local proxy).
# `~/.codex/bin/council` typically sets these, but this script can also be run directly.
if [[ -z "${HTTP_PROXY:-}" ]] && command -v nc >/dev/null 2>&1 && nc -z 127.0.0.1 7890 >/dev/null 2>&1; then
    export HTTP_PROXY="http://127.0.0.1:7890"
    export HTTPS_PROXY="http://127.0.0.1:7890"
    export ALL_PROXY="http://127.0.0.1:7890"
    export http_proxy="$HTTP_PROXY"
    export https_proxy="$HTTPS_PROXY"
    export all_proxy="$ALL_PROXY"
fi

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
    PROMPT_FILE="$(mktemp -t council-gemini-prompt.XXXXXX)"
    CREATED_TEMP=1
    cat > "$PROMPT_FILE"
fi

if [[ -z "$PROMPT_FILE" ]]; then
    PROMPT_FILE="$(mktemp -t council-gemini-prompt.XXXXXX)"
    CREATED_TEMP=1
    printf '%s' "$PROMPT" > "$PROMPT_FILE"
fi

# Check if Gemini CLI is available
if ! command -v gemini &> /dev/null; then
    echo "Error: gemini CLI not found" >&2
    echo "Install from: npm install -g @google/gemini-cli" >&2
    exit 1
fi

# Function to parse JSON output and extract text
# Gemini CLI with --output-format json returns structured data
parse_gemini_output() {
    local output="$1"

    # Check if jq is available for JSON parsing
    if command -v jq &>/dev/null; then
        # Try to extract text from JSON response
        # Gemini output format may vary; try common paths
        local text
        text=$(echo "$output" | jq -r '.response // .text // .content // .' 2>/dev/null) || text="$output"
        echo "$text"
    else
        # Fallback: return raw output if jq is not available
        echo "$output"
    fi
}

# Function to execute query with retry logic
query_gemini() {
    local attempt=0
    local exit_code=0
    local last_err=""
    local wrapped_prompt=""

    while [[ $attempt -le $MAX_RETRIES ]]; do
        if [[ $attempt -gt 0 ]]; then
            sleep $((5 * attempt))  # Exponential backoff: 5s, 10s
        fi

        # Execute Gemini in non-interactive mode.
        # IMPORTANT: Avoid passing long prompts via argv. Gemini's --prompt is appended
        # to stdin, so we pass an empty prompt and stream the full content via stdin.
        local cmd_result=0
        local out
        local err
        out="$(mktemp -t council-gemini-out.XXXXXX)"
        err="$(mktemp -t council-gemini-err.XXXXXX)"
        wrapped_prompt="$(mktemp -t council-gemini-wrapped.XXXXXX)"

        cat >"$wrapped_prompt" <<'__COUNCIL_GEMINI_INSTRUCTIONS__'
[COUNCIL OUTPUT REQUIREMENTS]
- Output ONLY the final report/review content.
- Do NOT include planning text like “I will …”, “I’m going to …”, or step-by-step tool usage narration.
- Do NOT claim to have edited files, run commands, or produced test results unless you explicitly include the exact command and its captured output.
- If information is missing, state what you could not verify.
__COUNCIL_GEMINI_INSTRUCTIONS__
        printf '\n\n' >>"$wrapped_prompt"
        cat "$PROMPT_FILE" >>"$wrapped_prompt"

        if [[ -n "$TIMEOUT_CMD" ]]; then
            $TIMEOUT_CMD "$TIMEOUT_SECONDS" gemini --sandbox --approval-mode yolo --include-directories "$PWD" -p "" -o text \
                < "$wrapped_prompt" > "$out" 2> "$err" || cmd_result=$?
        else
            gemini --sandbox --approval-mode yolo --include-directories "$PWD" -p "" -o text \
                < "$wrapped_prompt" > "$out" 2> "$err" || cmd_result=$?
        fi

        rm -f "$wrapped_prompt" 2>/dev/null || true
        wrapped_prompt=""

        if [[ $cmd_result -eq 0 ]] && [[ -s "$out" ]]; then
            cat "$out"
            rm -f "$out" "$err" "$last_err" 2>/dev/null || true
            return 0
        fi

        rm -f "$out" 2>/dev/null || true
        [[ -n "$last_err" ]] && rm -f "$last_err" 2>/dev/null || true
        last_err="$err"

        exit_code=$cmd_result

        ((attempt++))
    done

    echo "[ABSENT] Gemini: failed after $((MAX_RETRIES + 1)) attempts"
    if [[ -n "$last_err" ]] && [[ -s "$last_err" ]]; then
        tail -n 60 "$last_err" || true
    fi
    rm -f "$last_err" 2>/dev/null || true
    return $exit_code
}

# Execute the query
query_gemini

if [[ $CREATED_TEMP -eq 1 ]] && [[ -n "${PROMPT_FILE:-}" ]]; then
    rm -f "$PROMPT_FILE" 2>/dev/null || true
fi
