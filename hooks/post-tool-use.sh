#!/bin/bash
source "$(dirname "$0")/_common.sh"

INPUT=$(cat)
SESSION_ID=$(json_get "$INPUT" "session_id")
TOOL_NAME=$(json_get "$INPUT" "tool_name")
CWD=$(json_get "$INPUT" "cwd")

write_status "$SESSION_ID" "thinking" "PostToolUse" "$TOOL_NAME" "" "$CWD" "Thinking..."
exit 0
