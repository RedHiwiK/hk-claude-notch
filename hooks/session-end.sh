#!/bin/bash
MONITOR_DIR="$HOME/.claude/notch-monitor/sessions"

INPUT=$(cat)

# 提取 session_id
if command -v jq &>/dev/null; then
  SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""')
else
  SESSION_ID=$(echo "$INPUT" | /usr/bin/python3 -c "import sys,json; print(json.load(sys.stdin).get('session_id',''))" 2>/dev/null)
fi

# 删除会话状态文件
if [ -n "$SESSION_ID" ]; then
  rm -f "$MONITOR_DIR/${SESSION_ID}.json" "$MONITOR_DIR/${SESSION_ID}.json.tmp"
fi
exit 0
