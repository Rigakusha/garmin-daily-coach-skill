#!/bin/bash
# 用法: ./添加提醒.sh "标题" <小时> <分钟>
# 在「训练」提醒列表里新建一条带当天到期日的提醒
set -euo pipefail

if [ $# -lt 3 ]; then
  echo "用法: $0 \"标题\" <小时> <分钟>" >&2
  exit 2
fi

osascript - "$1" "$2" "$3" <<'EOF'
on run argv
  set theName to item 1 of argv
  set h to (item 2 of argv) as integer
  set m to (item 3 of argv) as integer
  tell application "Reminders"
    set rl to list "训练"
    set d to (current date)
    set hours of d to h
    set minutes of d to m
    set seconds of d to 0
    set newR to make new reminder at end of reminders of rl with properties {name:theName, due date:d}
    return (name of newR) & " → due " & (due date of newR as string)
  end tell
end run
EOF
