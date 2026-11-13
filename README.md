# garmin-coach-skill

面向 Garmin 用户的每日训练教练技能。读取 Garmin 原始健康数据与用户日历中的训练日志，依据五信号评级生成当日训练处方，写入 macOS 日历与提醒事项，经 iCloud 同步至 iPhone。适用于 DeepSeek Harness 及支持 MCP 的客户端。

个人配置存于本机 `settings.md`（由 `setup.sh` 生成），仓库不含任何个人数据。

## 概述

技能每日执行以下流程：

1. 读取睡眠、HRV、晨脉、急性负荷、近期活动五项原始数据，先进行新鲜度校验；数据未同步时提示用户，不以旧数据生成处方。
2. 读取「训练日志」日历中前一日的记录，包括体重、体脂率、备注及各条训练记录。
3. 依据五信号评级矩阵（HRV、睡眠、晨脉、负荷、主观感受）判定恢复状态：正常、减量或恢复。
4. 按周计划输出当日训练部位与要点，卡片格式固定，判断依据可追溯。
5. 写入「训练日程」日历事件及三条提醒（训练 19:30、测体重 21:30、营养 22:00）；周日追加复盘提醒。

另内置周复盘与月度复盘流程，对照测试成绩与阶段里程碑。

## 特性

- 处方直接写入系统日历与提醒事项，经 iCloud 同步，无需安装额外应用。
- 决策基于原始数据而非厂商综合分数，各信号阈值可调，卡片内附判断依据。
- 全部脚本无网络调用、无遥测、无第三方服务；健康数据仅在用户自身设备与账户间流转。
- 仅依赖系统自带 python3、swift、bash 与 EventKit，无第三方包与订阅。
- 日志输入成本低：每晚在日历中填写三行，训练后追加一条训练记录。
- 支持 DeepSeek Harness bundle 与 MCP 两种接入方式。

## 环境要求

- macOS：日历与提醒写入依赖 osascript。其他平台仅生成卡片，不写入。
- `python3`、`bash`、`swift`（随 Xcode 命令行工具提供）。
- Apple 日历：「训练日志」「训练日程」；提醒事项列表：「训练」。（`setup.sh` 自动创建，亦可手动创建同名项。）
- Garmin 数据源，二选一：
  - DeepSeek Harness + [dsh-plugin-garmin-connect](https://github.com/Likenttt/garmin-connect-plugin-for-dsh)
  - 支持 MCP 的客户端 + `garmin-connect-mcp`（Codex、Claude Code、Cursor、Windsurf 等）
- 首次运行 `setup.sh` 时，macOS 会请求「日历」「提醒事项」自动化权限，须允许。
- 时区默认按 UTC+8 核对；其他时区设置环境变量 `HR_TZ_OFFSET`。

## 安装

### DeepSeek Harness

1. 复制本文件夹至目标位置。
2. 运行 `./setup.sh`，按提示填写工作区路径、Garmin 账号 ID、静息心率基线。
3. 在 plugin_manager 中执行 install_bundle，选择本文件夹。
4. 编辑生成的 `settings.md` 及工作区 `个人档案.md`。
5. 重启 DSH，发送「今天训练计划」。

同名私有定制版不可与本技能同时安装。

### 其他客户端（Codex / Claude Code / Cursor）

1. 运行 `./setup.sh`。
2. 将 `SKILL.md` 放入客户端技能目录。
3. 通过 `garmin-connect-mcp` 连接 Garmin。
4. 脚本为通用 bash/swift/python；自动化权限按进程授予，新客户端需单独授权。

## 目录结构

```
.
├── README.md
├── SKILL.md                 技能正文
├── index.js                 DSH 注册入口
├── cordis.patch.yml / package.json
├── setup.sh                 初始化脚本
├── settings.example.md
├── .gitignore               排除 settings.md
├── scripts/                 检查数据新鲜度.py / 写今日日程.swift / 添加提醒.sh / 清理过期提醒.swift
└── templates/               工作区文档模板
```

## 定制

| 项目 | 位置 |
|---|---|
| 提醒时间 | `SKILL.md` 第 9 步 |
| 评级阈值 | `SKILL.md` 五信号矩阵 |
| 日历名称 | `scripts/写今日日程.swift` 顶部常量 |
| 提醒列表名称 | `scripts/添加提醒.sh`、`scripts/清理过期提醒.swift` 顶部常量 |
| 目标与基线 | 工作区 `个人档案.md`、`训练计划.md` |
| 流程逻辑 | `SKILL.md`（修改后需重启 DSH） |

## 数据与隐私

数据流向：Garmin → 本机推理 → 本机日历与提醒（iCloud 同步）。脚本不含网络调用与遥测。`settings.md` 仅存本机。仓库不含任何个人数据。

## 发布注意

1. 仅提交本文件夹；父目录可能含个人档案。
2. 提交前执行 `git log --all --name-only | grep -E "settings|个人档案|训练计划|每日流程"` 检查历史。
3. 提交身份使用 noreply 邮箱，避免真实邮箱进入提交历史。
4. 压缩或网盘分享前删除 `settings.md`。

## 初次使用

1. 安装并完成 `setup.sh` 初始化。
2. 编辑 `settings.md`：确认 Garmin 账号 ID 与静息心率基线。
3. 编辑工作区 `个人档案.md`：填写伤病、基线、目标。
4. 编辑工作区 `训练计划.md`：确认周结构与课表。
5. 重启 DSH。
6. 每日早晨发送「今天训练计划」，获取当日处方。
7. 每晚按提醒测量体重与体脂，并在「训练日志」日历中填写当日记录；训练后追加训练记录事件。
8. 周日按卡片提示进行周复盘；每月第一个周日进行月复盘。

## License

MIT
