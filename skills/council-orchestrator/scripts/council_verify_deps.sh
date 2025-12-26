#!/usr/bin/env bash
#
# council_verify_deps.sh - Verify required/optional dependencies.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/council_utils.sh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  LLM Council - Dependency Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

required_ok=true
STRICT_ALL_MEMBERS="$(config_get "require_all_members" "1")"

echo "Required:"
if command -v jq &>/dev/null; then
    echo "  ✅ jq      : $(jq --version 2>/dev/null || true)"
else
    echo "  ❌ jq      : missing (security validations disabled)"
    required_ok=false
fi

if command -v claude &>/dev/null; then
    echo "  ✅ claude   : $(claude --version 2>/dev/null | head -n1 || true)"
else
    echo "  ❌ claude   : missing (council requires Claude)"
    required_ok=false
fi

if [[ "$STRICT_ALL_MEMBERS" == "1" || "$STRICT_ALL_MEMBERS" == "true" ]]; then
    if command -v codex &>/dev/null; then
        echo "  ✅ codex   : $(codex --version 2>/dev/null | head -n1 || true)"
    else
        echo "  ❌ codex   : missing (strict mode requires Codex)"
        required_ok=false
    fi

    if command -v gemini &>/dev/null; then
        echo "  ✅ gemini  : $(gemini --version 2>/dev/null | head -n1 || true)"
    else
        echo "  ❌ gemini  : missing (strict mode requires Gemini)"
        required_ok=false
    fi
fi

echo ""
echo "Optional:"
if [[ "$STRICT_ALL_MEMBERS" == "1" || "$STRICT_ALL_MEMBERS" == "true" ]]; then
    echo "  (none; strict mode enabled)"
else
    if command -v codex &>/dev/null; then
        echo "  ✅ codex   : $(codex --version 2>/dev/null | head -n1 || true)"
    else
        echo "  ℹ️  codex   : missing (optional)"
    fi

    if command -v gemini &>/dev/null; then
        echo "  ✅ gemini  : $(gemini --version 2>/dev/null | head -n1 || true)"
    else
        echo "  ℹ️  gemini  : missing (optional)"
    fi
fi

echo ""
if [[ "$required_ok" == true ]]; then
    echo "✅ System is ready for LLM Council."
    exit 0
fi

echo "❌ Missing required dependencies."
exit 1
