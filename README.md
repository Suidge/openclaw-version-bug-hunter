# OpenClaw Version Bug Hunter

**OpenClaw 版本 Bug 猎人** — 升级前查询特定版本的已知 bug 和 regression，帮助避坑🔍

![License](https://img.shields.io/github/license/Suidge/openclaw-version-bug-hunter)
![Version](https://img.shields.io/badge/version-1.0.0-blue)

---

## 🌟 功能特性

- 🔍 **版本搜索** - 输入版本号，自动搜索 GitHub issues
- 📊 **分类展示** - 按严重程度分类（Critical / Regression / General）
- 📈 **统计信息** - 未解决/已解决 issues 数量
- ✅ **修复状态** - 显示已合并的修复 PR
- 🎨 **彩色输出** - 清晰的视觉层次

---

## 🚀 快速开始

### 前置要求

- **GitHub CLI** (`gh`) - [安装指南](https://cli.github.com/)
- **Bash** - macOS/Linux 默认自带

### 安装 GitHub CLI

```bash
# macOS
brew install gh

# 验证安装
gh --version

# 认证 GitHub
gh auth login
```

### 使用方法

```bash
# 方式一：直接调用脚本
~/.openclaw/workspace/skills/openclaw-version-bug-hunter/scripts/bug-hunt.sh 2026.4.9

# 方式二：添加到 PATH 后
bug-hunt.sh 2026.4.9
```

---

## 📋 输出示例

```bash
$ bug-hunt.sh 2026.4.9

🔍 正在搜索 OpenClaw v2026.4.9 的 bug 报告...

### 🔴 Critical / 严重问题
  无

### 🟠 Regression / 回归问题
- #64552: Severe Performance Regression - 30-60 Second Delay Per API Call
- #64636: Version 2026.4.9 ignore the system environment proxy variables
- #64174: openai-codex OAuth runtime fails on 2026.4.9 with 403 HTML

### 🟡 General Bugs / 一般问题
- #64296: WhatsApp Web connection ended before fully opening
- #63862: pnpm ELF binary executed via Node.js in WSL due to npm_execpath misdetection
...

### 📊 统计信息
- 未解决 issues: 100
- 已解决 issues: 26

### ✅ 修复状态
已合并的修复 PR: 1
  - #63346: fix: coerce integer plugin config input

---
搜索完成时间：2026-04-11 18:35:51
数据源：https://github.com/openclaw/openclaw/issues
```

---

## 🎯 使用场景

### 升级前避坑

```bash
# 在升级到 v2026.4.10 之前
bug-hunt.sh 2026.4.10
```

### 比较两个版本

```bash
# 比较 v2026.4.8 和 v2026.4.9
bug-hunt.sh 2026.4.8
bug-hunt.sh 2026.4.9
```

### 检查当前版本

```bash
# 查看当前版本
openclaw status | grep "app"

# 查询该版本的 bug
bug-hunt.sh 2026.4.8
```

---

## 📊 升级决策建议

| Critical | Regression | 建议 |
|----------|------------|------|
| 0 | 0-2 | ✅ 推荐升级 |
| 0 | 3-5 | ⚠️ 谨慎升级 |
| 1-2 | 任意 | ⚠️ 谨慎升级（评估影响） |
| 3+ | 任意 | ❌ 暂缓升级 |

---

## 🔧 故障排查

### 问题：`gh: command not found`

**解决**：安装 GitHub CLI
```bash
brew install gh
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
gh issue list --repo openclaw/openclaw --label bug --search "v2026.4.9 OR 2026.4.9"
```

---

## 📁 项目结构

```
openclaw-version-bug-hunter/
├── README.md                           # 本文件
├── LICENSE                             # MIT 许可证
├── SKILL.md                            # OpenClaw 技能说明
├── scripts/
│   └── bug-hunt.sh                     # 核心搜索脚本
└── references/
    └── severity-rules.md               # 严重程度判定规则
```

---

## 🛠️ 开发

### 本地测试

```bash
# 克隆仓库
git clone https://github.com/Suidge/openclaw-version-bug-hunter.git
cd openclaw-version-bug-hunter

# 添加执行权限
chmod +x scripts/bug-hunt.sh

# 测试
./scripts/bug-hunt.sh 2026.4.9
```

### 修改后测试

```bash
# 编辑脚本
vim scripts/bug-hunt.sh

# 测试
./scripts/bug-hunt.sh 2026.4.9
```

---

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

---

## 👥 作者

**Initiated by Neo Shi and executed by 银月**

---

## 🙏 致谢

- [OpenClaw](https://github.com/openclaw/openclaw) - 强大的 AI 代理框架
- [GitHub CLI](https://cli.github.com/) - 让 GitHub 操作更简单

---

*🌙 银月注：升级前查一查，避坑省心又省力～*
