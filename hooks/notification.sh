#!/bin/bash
source "$(dirname "$0")/_common.sh"

INPUT=$(cat)
SESSION_ID=$(json_get "$INPUT" "session_id")
CWD=$(json_get "$INPUT" "cwd")

# 提取通知类型
NOTIFICATION_TYPE=$(json_get "$INPUT" "notification_type")

case "$NOTIFICATION_TYPE" in
  permission_prompt)
    # Claude Code 真正弹出权限确认时触发
    # Notification hook 不含 tool_name，从 message 中提取摘要
    MESSAGE=$(json_get "$INPUT" "message" | head -c 80)
    TITLE=$(json_get "$INPUT" "title" | head -c 40)
    write_status "$SESSION_ID" "pending_approval" "Notification" "" "$MESSAGE" "$CWD" "${TITLE:-Approval needed}"
    ;;
esac

exit 0
