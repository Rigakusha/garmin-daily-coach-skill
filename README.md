# garmin-coach-skill

一个可复用的 **Garmin 教练技能**：读取 Garmin 原始数据（睡眠 / HRV / 晨脉 / 负荷 / 活动）和训练日志，用**五信号评级矩阵**做综合裁决（不照搬 Garmin 结论），输出当日训练处方，并写入 macOS 日历与提醒事项（iCloud 同步 iPhone）。附带周复盘 / 月复盘协议。

**本仓库不含任何个人信息。** 所有个人配置由 `setup.sh` 在本机生成 `settings.md`（已被 `.gitignore` 排除），可直接发布到 GitHub。

## 功能

- 每日：读 5 项原始数据 → 新鲜度检查 → 读「训练日志」日历 → 五信号评级（HRV/睡眠/晨脉/负荷/主观）→ 裁决 → 输出固定卡片 → 写入「训练日程」日历 + 3 条提醒（训练 19:30 / 测体重+体脂 21:30 / 营养 22:00）
- 周日：卡片带「复盘日」提醒行 + 第 4 条提醒（周复盘 20:00）
- 复盘：周复盘 / 月复盘（对照月度测试与里程碑）
- 失败处理：数据读不到就明说，绝不编造
- 伤病要点自动带上（来自个人档案）、测试前一天自动减量

## 前置依赖

- **macOS**：日历/提醒写入用 osascript（其他系统会跳过写入，仍能输出卡片）
- **运行环境**：
  - `python3`（数据新鲜度检查）
  - `swift`（写日程 / 清理提醒；macOS 安装 Xcode 命令行工具即自带）
  - `bash`（提醒创建与初始化）
- **Apple 日历与提醒事项**（`setup.sh` 会自动创建，也可手动建同名）：
  - 日历「训练日志」（用户每日日志，01:00–02:00 模板事件）
  - 日历「训练日程」（教练写入当日训练事件）
  - 提醒事项列表「训练」（训练 19:30 / 测体重+体脂 21:30 / 营养 22:00）
- **时区**：默认按 UTC+8（北京时间）核对 HRV 时间；其他时区设环境变量 `HR_TZ_OFFSET`（如 `HR_TZ_OFFSET=9`）
- **Garmin 数据源**（二选一）：
  - DeepSeek Harness + [`dsh-plugin-garmin-connect`](https://github.com/Likenttt/garmin-connect-plugin-for-dsh)
  - 或任何支持 MCP 的 agent + 同一插件的 `garmin-connect-mcp`（支持 Codex / Claude Code / Cursor / Windsurf 等）
- 日历/提醒写入需要 macOS **自动化权限**（首次运行 setup.sh 会弹窗，点允许）

## 安装（DeepSeek Harness）

1. 拷贝本文件夹到任意位置
2. 运行 `./setup.sh`，按提示填工作区路径、Garmin 账号 ID、静息心率基线
3. `plugin_manager` → `install_bundle` → 选择本文件夹
4. 编辑生成的 `settings.md` 与工作区 `个人档案.md`
5. 重启 DSH，说「今天训练计划」

> 不要与同名的私有定制版同时安装（技能名冲突）。

## 安装（其他 agent：Codex / Claude Code / Cursor）

1. 运行 `./setup.sh`
2. 把 `SKILL.md` 放入该 agent 的技能目录
3. 用 `garmin-connect-mcp` 连接 Garmin（见插件 README 的 MCP 配置）
4. 技能会读 `settings.md` 里的 `skill_dir` 来定位脚本；脚本是普通 bash/swift/python，任何有终端权限的 agent 都能执行
5. 注意：日历/提醒的 macOS 自动化权限要**按进程**授权——给运行技能的 agent 进程单独开一次

## 目录结构

```
garmin-coach-public/
├── README.md
├── SKILL.md                  ← 技能正文（通用，无个人数据）
├── index.js                  ← DSH 注册壳（读 SKILL.md 并注册到全局）
├── cordis.patch.yml          ← DSH 插件行声明
├── package.json              ← DSH bundle 声明
├── setup.sh                  ← 新机器初始化
├── settings.example.md       ← 配置模板（setup.sh 据此生成 settings.md）
├── .gitignore                ← 排除 settings.md
├── scripts/                  ← 四个执行脚本（通用，无个人数据）
│   ├── 检查数据新鲜度.py
│   ├── 写今日日程.swift
│   ├── 添加提醒.sh
│   └── 清理过期提醒.swift
└── templates/                ← 工作区文档模板（setup.sh 复制到工作区）
    ├── 训练计划.md.template
    ├── 个人档案.md.template
    └── 每日流程.md.template
```

## 定制入口

| 要改什么 | 在哪改 |
|---|---|
| 提醒时间（19:30 / 21:30 / 22:00） | `SKILL.md` 第 9 步 |
| 五信号阈值（≥85 分 / ±3 bpm…） | `SKILL.md` 五信号矩阵 |
| 日历名「训练日程」 | `scripts/写今日日程.swift` 顶部常量 |
| 提醒列表名「训练」 | `scripts/添加提醒.sh`、`scripts/清理过期提醒.swift` 顶部常量 |
| 个人目标/基线 | 工作区 `个人档案.md`、`训练计划.md`（实时文档，不重启即生效） |
| 技能流程本身 | `SKILL.md`（重启 DSH 生效） |

## 数据流向

```
Garmin（睡眠/HRV/心率/体重）→ 本机 agent / LLM 推理 → 本机日历与提醒事项（经 iCloud 同步到用户自己的设备）
```

- 4 个脚本**无任何网络调用**、无遥测、无第三方服务
- `settings.md`（含账号 ID）只存本机，已被 `.gitignore` 排除
- 本技能不上传任何数据；数据仅在你自己的设备与你的 Garmin / Apple 账户之间流动

## 发布到 GitHub

直接推送**本文件夹**即可。`.gitignore` 已排除 `settings.md`；`settings.example.md`、模板、技能、脚本全部不含个人信息。

**发布前必查**：

1. **只推本文件夹**——不要连父目录一起推（父目录里可能有你已填好的真实档案和私有定制版，含真实健康数据）
2. **查 git 历史**：`git log --all --name-only | grep -E "settings|个人档案|训练计划|每日流程"`，确认没有真实文档进过历史；如果有，需要重写历史或换仓库
3. **邮箱隐私**：不想在提交历史里暴露真实邮箱 → GitHub → Settings → Emails → 勾选 "Keep my email addresses private"，或本仓库 `git config user.email "<id>+<user>@users.noreply.github.com"`
4. **终端历史**：本地测试脚本时在终端输过命令（含日期等数据）没关系——`.zsh_history`/`.bash_history` 在用户主目录，不属于仓库，不会被推送；但别把这类文件手动拷进仓库
5. **压缩/网盘分享前**：若你运行过 `setup.sh`，先删除本目录里的 `settings.md`（含你的账号 ID）
6. **本仓库是"模具"**：下载者运行 `setup.sh` 后会得到本机 `settings.md` 和工作区模板，填入自己的数据——你的成品数据永远不该出现在仓库里

## License

MIT
