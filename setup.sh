#!/bin/bash
# garmin-coach 初始化脚本：新机器首次使用（macOS）
# 会生成 settings.md、创建工作区文档、创建日历/提醒列表和 30 天日志模板。
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"

echo "== Garmin 教练 · 初始化 =="
echo

# 1. 工作区
read -r -p "工作区目录（默认 ~/Documents/garmin-coach）：" WS
WS="${WS:-$HOME/Documents/garmin-coach}"
mkdir -p "$WS"
for f in 训练计划.md 个人档案.md 每日流程.md Plan1_阶段计划.md 登神长阶.md; do
  if [ ! -f "$WS/$f" ]; then
    cp "$DIR/templates/$f.template" "$WS/$f"
    echo "已生成 $WS/$f"
  fi
done

# 2. 本机配置
read -r -p "Garmin 账号 ID（DSH 插件设置页的稳定 ID；可留空稍后填）：" ACCOUNT
read -r -p "静息心率基线 bpm（可留空稍后填）：" RHR
cat > "$DIR/settings.md" <<EOF
# 本机配置（setup.sh 生成，勿提交到 GitHub）

skill_dir: $DIR
workspace: $WS
garmin_account: ${ACCOUNT:-待填}
resting_hr_baseline: ${RHR:-待填}
EOF
echo "已生成 $DIR/settings.md"

# 3. 日历 + 提醒列表（需要 macOS 自动化权限：日历、提醒事项）
osascript <<'APPLESCRIPT' || echo "⚠️ 日历/提醒初始化失败：请到 系统设置 → 隐私与安全性 → 自动化，给运行本脚本的应用授权「日历」「提醒事项」后重跑本脚本。"
tell application "Calendar"
  if not (exists calendar "训练日志") then make new calendar with properties {name:"训练日志"}
  if not (exists calendar "训练日程") then make new calendar with properties {name:"训练日程"}
end tell
tell application "Reminders"
  if not (exists list "训练") then make new list with properties {name:"训练"}
end tell
APPLESCRIPT

# 4. 30 天日志模板
osascript <<'APPLESCRIPT' || true
set templateText to "体重：
体脂率：
备注："
tell application "Calendar"
  set logCal to calendar "训练日志"
  repeat with i from 1 to 30
    set d to (current date) + (i * days)
    set sd to d
    set hours of sd to 1
    set minutes of sd to 0
    set seconds of sd to 0
    set ed to d
    set hours of ed to 2
    set minutes of ed to 0
    set seconds of ed to 0
    make new event at end of events of logCal with properties {summary:"训练日志", start date:sd, end date:ed, description:templateText}
  end repeat
end tell
APPLESCRIPT

echo
echo "== 完成。下一步 =="
echo "1. 编辑 $DIR/settings.md 补全账号与基线（若上面留空）"
echo "2. 编辑 $WS/个人档案.md：伤病、基线、目标"
echo "3. 编辑 $WS/训练计划.md：按模板完善自己的计划"
echo "4. 接入：DSH 用 plugin_manager 安装本文件夹；其他 agent 见 README.md"
