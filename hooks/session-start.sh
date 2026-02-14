#!/bin/bash
source "$(dirname "$0")/_common.sh"

INPUT=$(cat)
SESSION_ID=$(json_get "$INPUT" "session_id")
CWD=$(json_get "$INPUT" "cwd")

write_status "$SESSION_ID" "started" "SessionStart" "" "" "$CWD" "Session started"
exit 0
