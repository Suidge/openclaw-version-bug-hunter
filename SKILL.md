---
name: openclaw-version-bug-hunter
description: 查询 OpenClaw 特定版本的 GitHub bug/issue 报告。当用户想要：(1) 查询 OpenClaw 特定版本的 bug/issue，(2) 升级前查看避坑指南，(3) 搜索 GitHub 社区反馈的版本问题，(4) 获取版本稳定性评估，(5) 分析某个版本有多少严重 bug 或 regression 时使用。
---

# OpenClaw Version Bug Hunter

**作者**: Initiated by Neo Shi and executed by 银月  
**许可证**: MIT

## 快速开始

```bash
# 查询特定版本的 bug 报告
~/.openclaw/workspace/skills/openclaw-version-bug-hunter/scripts/bug-hunt.sh 2026.4.9
```

## 功能

此技能封装了 GitHub CLI (`gh`)，自动搜索并分类 OpenClaw 官方仓库中与特定版本相关的 issue 报告。

### 输出内容

1. **🔴 Critical / 严重问题** - 导致崩溃、数据丢失、系统不稳定的 bug
2. **🟠 Regression / 回归问题** - 之前版本正常，当前版本失效的功能
3. **🟡 General Bugs / 一般问题** - 其他 bug 报告
4. **📊 统计信息** - 未解决/已解决 issues 数量
5. **✅ 修复状态** - 已合并的修复 PR 列表

### 严重程度判定规则

详细规则见 `references/severity-rules.md`（按需加载）。

**快速参考**：
- **Critical**: 崩溃、数据丢失、安全漏洞、无限循环
- **Regression**: 标记为 `regression` 标签的 issue
- **General**: 标记为 `bug` 但非 critical/regression

## 使用场景

### 升级前避坑

```bash
# 在升级到 v2026.4.9 之前
bug-hunt.sh 2026.4.9
```

输出示例：
```
### 🔴 Critical / 严重问题
- #64745: macOS 2026.4.8 app causes infinite self-replication...

### 🟠 Regression / 回归问题
- #64552: Severe Performance Regression - 30-60 Second Delay...
- #64636: Version 2026.4.9 ignore the system environment proxy...

### 📊 统计信息
- 未解决 issues: 25
- 已解决 issues: 8
```

### 比较两个版本

```bash
# 比较 v2026.4.8 和 v2026.4.9
bug-hunt.sh 2026.4.8
bug-hunt.sh 2026.4.9
```

### 检查当前版本的已知问题

```bash
# 先用 openclaw status 查看当前版本
openclaw status | grep "app"

# 然后查询该版本的 bug
bug-hunt.sh 2026.4.8
```

## 依赖

- **GitHub CLI** (`gh`) - 必须已安装并认证
- **Bash** - 脚本运行环境

### 检查依赖

```bash
# 检查 gh 是否安装
gh --version

# 检查是否已认证
gh auth status
```

## 输出解读

### 推荐升级 ✅
- Critical issues: 0
- Regression issues: 0-1（非阻塞性）
- 有已合并的修复 PR

### 谨慎升级 ⚠️
- Critical issues: 1-2（但有 workaround）
- Regression issues: 2-5
- 暂无修复 PR

### 暂缓升级 ❌
- Critical issues: 3+
- Regression issues: 5+（影响核心功能）
- 社区反馈集中爆发

## 高级用法

### 搜索特定标签

```bash
# 只搜索 regression
gh issue list --repo openclaw/openclaw --label regression --search "2026.4.9"

# 只搜索 Critical
gh issue list --repo openclaw/openclaw --label Critical --search "2026.4.9"
```

### 查看 issue 详情

```bash
gh issue view 64552 --comments
```

### 导出为 Markdown

```bash
bug-hunt.sh 2026.4.9 > bug-report-2026.4.9.md
```

## 限制

1. **需要 gh CLI 认证** - 未认证用户无法访问 GitHub API
2. **API 速率限制** - 未认证用户每小时 60 次请求，认证后 5000 次
3. **搜索精度** - 依赖 GitHub 搜索算法，可能遗漏未明确提及版本号的 issue

## 故障排查

### 问题：`gh: command not found`

**解决**：安装 GitHub CLI
```bash
# macOS
brew install gh

# 验证
gh --version
```

### 问题：`gh: not authenticated`

**解决**：认证 GitHub
```bash
gh auth login
```

### 问题：搜索结果太少

**原因**：issue 标题/正文未明确提及版本号

**解决**：手动搜索关键词
```bash
gh issue list --repo openclaw/openclaw --label bug --search "v2026.4.9 OR 2026.4.9 OR 2026.4.8"
```

## 相关文件

- `scripts/bug-hunt.sh` - 核心搜索脚本
- `references/severity-rules.md` - 严重程度判定规则（详细版）

## 发布渠道

- **ClawHub**: `clawhub install openclaw-version-bug-hunter`
- **GitHub**: https://github.com/neoshi/openclaw-version-bug-hunter

---

*银月注：此技能专为 OpenClaw 用户设计，帮助大家在升级前避开已知坑点～🌙*
