#!/usr/bin/env bash
# openclaw-version-bug-hunter - 查询 OpenClaw 特定版本的 GitHub bug 报告
# Author: Initiated by Neo Shi and executed by 银月
# License: MIT

set -e

REPO="openclaw/openclaw"
VERSION=""
SHOW_HELP=false

# 颜色定义
RED='\e[0;31m'
ORANGE='\e[0;33m'
YELLOW='\e[1;33m'
GREEN='\e[0;32m'
NC='\e[0m' # No Color

usage() {
    cat << EOF
用法：bug-hunt.sh <版本号>

查询 OpenClaw 特定版本的 GitHub bug 报告，帮助升级前避坑。

参数:
  VERSION    版本号，例如 2026.4.9 或 2026.4.8

示例:
  bug-hunt.sh 2026.4.9
  bug-hunt.sh 2026.4.8

EOF
    exit 1
}

# 解析参数
if [ $# -eq 0 ]; then
    usage
fi

while [ $# -gt 0 ]; do
    case $1 in
        -h|--help)
            SHOW_HELP=true
            shift
            ;;
        *)
            VERSION=$1
            shift
            ;;
    esac
done

if [ -z "$VERSION" ]; then
    usage
fi

echo "🔍 正在搜索 OpenClaw v${VERSION} 的 bug 报告..."
echo ""

# 搜索 Critical 级别的 issues
echo "${RED}### 🔴 Critical / 严重问题${NC}"
CRITICAL_ISSUES=$(gh issue list --repo $REPO --state open --label "Critical" --search "$VERSION" --limit 20 --json number,title 2>/dev/null || echo "[]")
if [ "$CRITICAL_ISSUES" != "[]" ] && [ -n "$CRITICAL_ISSUES" ]; then
    echo "$CRITICAL_ISSUES" | jq -r '.[] | "- #\(.number): \(.title)"' 2>/dev/null || echo "  无"
else
    echo "  无"
fi
echo ""

# 搜索 Regression 级别的 issues
echo "${ORANGE}### 🟠 Regression / 回归问题${NC}"
REGRESSION_ISSUES=$(gh issue list --repo $REPO --state open --label "regression" --search "$VERSION" --limit 20 --json number,title 2>/dev/null || echo "[]")
if [ "$REGRESSION_ISSUES" != "[]" ] && [ -n "$REGRESSION_ISSUES" ]; then
    echo "$REGRESSION_ISSUES" | jq -r '.[] | "- #\(.number): \(.title)"' 2>/dev/null || echo "  无"
else
    echo "  无"
fi
echo ""

# 搜索一般 bug
echo "${YELLOW}### 🟡 General Bugs / 一般问题${NC}"
BUG_ISSUES=$(gh issue list --repo $REPO --state open --label "bug" --search "$VERSION" --limit 30 --json number,title,labels 2>/dev/null || echo "[]")
if [ "$BUG_ISSUES" != "[]" ] && [ -n "$BUG_ISSUES" ]; then
    echo "$BUG_ISSUES" | jq -r '.[] | select(.labels[].name != "Critical" and .labels[].name != "regression") | "- #\(.number): \(.title)"' 2>/dev/null || echo "  无"
else
    echo "  无"
fi
echo ""

# 统计信息
echo "${GREEN}### 📊 统计信息${NC}"
TOTAL_OPEN=$(gh issue list --repo $REPO --state open --search "$VERSION" --limit 100 2>/dev/null | wc -l | tr -d ' ' || echo "0")
TOTAL_CLOSED=$(gh issue list --repo $REPO --state closed --search "$VERSION" --limit 100 2>/dev/null | wc -l | tr -d ' ' || echo "0")

echo "- 未解决 issues: $TOTAL_OPEN"
echo "- 已解决 issues: $TOTAL_CLOSED"
echo ""

# 检查是否有修复 PR
echo "${GREEN}### ✅ 修复状态${NC}"
PR_COUNT=$(gh pr list --repo $REPO --state merged --search "$VERSION" --limit 20 2>/dev/null | wc -l | tr -d ' ' || echo "0")
if [ "$PR_COUNT" -gt 0 ]; then
    echo "已合并的修复 PR: $PR_COUNT"
    gh pr list --repo $REPO --state merged --search "$VERSION" --limit 10 --json number,title 2>/dev/null | jq -r '.[] | "  - #\(.number): \(.title)"' 2>/dev/null
else
    echo "  暂无已合并的修复 PR"
fi
echo ""

echo "---"
echo "搜索完成时间：$(date '+%Y-%m-%d %H:%M:%S')"
echo "数据源：https://github.com/$REPO/issues"
