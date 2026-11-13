# 安全策略

## 报告漏洞

如发现安全或隐私问题，请通过 GitHub 的 **Private Vulnerability Reporting**（仓库 Security 页）提交，勿在公开 Issue 中披露细节。

## 设计边界

- 仓库不含任何个人数据；本机配置存放于 `settings.md`，已在 `.gitignore` 中排除。
- 全部脚本无网络调用、无遥测。
- 若在仓库内容（含提交历史）中发现疑似泄露的个人数据，请通过上述渠道报告。
