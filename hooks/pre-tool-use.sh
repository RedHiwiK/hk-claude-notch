#!/bin/bash
source "$(dirname "$0")/_common.sh"

INPUT=$(cat)
SESSION_ID=$(json_get "$INPUT" "session_id")
TOOL_NAME=$(json_get "$INPUT" "tool_name")
CWD=$(json_get "$INPUT" "cwd")

# 提取工具输入摘要
TOOL_SUMMARY=""
case "$TOOL_NAME" in
  Bash)
    TOOL_SUMMARY=$(json_get "$INPUT" "tool_input.command" | head -c 500)
    ;;
  Edit|Write)
    TOOL_SUMMARY=$(json_get "$INPUT" "tool_input.file_path" | head -c 500)
    ;;
  Read)
    TOOL_SUMMARY=$(json_get "$INPUT" "tool_input.file_path" | head -c 500)
    ;;
  Grep)
    TOOL_SUMMARY=$(json_get "$INPUT" "tool_input.pattern" | head -c 200)
    ;;
  Glob)
    TOOL_SUMMARY=$(json_get "$INPUT" "tool_input.pattern" | head -c 200)
    ;;
  Task)
    TOOL_SUMMARY=$(json_get "$INPUT" "tool_input.description" | head -c 200)
    ;;
  *)
    TOOL_SUMMARY="$TOOL_NAME"
    ;;
esac

# 审批检测已交由 Notification hook (permission_prompt) 负责
# PreToolUse 统一写入 tool_running 状态
write_status "$SESSION_ID" "tool_running" "PreToolUse" "$TOOL_NAME" "$TOOL_SUMMARY" "$CWD" "Running $TOOL_NAME"
exit 0
