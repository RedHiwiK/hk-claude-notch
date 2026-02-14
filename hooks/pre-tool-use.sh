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
    TOOL_SUMMARY=$(json_get "$INPUT" "tool_input.command" | head -c 60)
    ;;
  Edit|Write)
    TOOL_SUMMARY=$(json_get "$INPUT" "tool_input.file_path" | xargs basename 2>/dev/null)
    ;;
  Read)
    TOOL_SUMMARY=$(json_get "$INPUT" "tool_input.file_path" | xargs basename 2>/dev/null)
    ;;
  Grep)
    TOOL_SUMMARY=$(json_get "$INPUT" "tool_input.pattern" | head -c 40)
    ;;
  Glob)
    TOOL_SUMMARY=$(json_get "$INPUT" "tool_input.pattern" | head -c 40)
    ;;
  Task)
    TOOL_SUMMARY=$(json_get "$INPUT" "tool_input.description" | head -c 40)
    ;;
  *)
    TOOL_SUMMARY="$TOOL_NAME"
    ;;
esac

# 判断工具是否通常需要用户审批（default 权限模式下）
# Bash、Edit、Write 等修改性工具通常需要审批
NEEDS_APPROVAL=false
case "$TOOL_NAME" in
  Bash|Edit|Write|NotebookEdit)
    NEEDS_APPROVAL=true
    ;;
esac

# 检查是否设置了 CLAUDE_NOTCH_AUTO_APPROVE 标记（通过环境变量控制）
if [ "$NEEDS_APPROVAL" = "true" ] && [ "${CLAUDE_NOTCH_NO_APPROVAL:-}" != "1" ]; then
  write_status "$SESSION_ID" "pending_approval" "PreToolUse" "$TOOL_NAME" "$TOOL_SUMMARY" "$CWD" "Approval needed: $TOOL_NAME"
else
  write_status "$SESSION_ID" "tool_running" "PreToolUse" "$TOOL_NAME" "$TOOL_SUMMARY" "$CWD" "Running $TOOL_NAME"
fi
exit 0
