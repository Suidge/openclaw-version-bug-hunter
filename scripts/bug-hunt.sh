#!/usr/bin/env bash
# openclaw-version-bug-hunter - 查询 OpenClaw 特定版本的 GitHub bug 报告
# Author: Initiated by Neo Shi and executed by 银月
# License: MIT

set -e

REPO="openclaw/openclaw"
VERSION=""
SHOW_HELP=false

# 颜色定义
RED='\033[0;31m'
ORANGE='\033[0;33m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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

# ============================================================
# 质量评估函数（纯 bash/jq，零 LLM 依赖）
# ============================================================

# 检查 issue 是否模糊（正文太短或缺乏技术细节）
is_vague() {
    local body="$1"
    local body_len=${#body}
    # 正文 < 50 字符
    if [ "$body_len" -lt 50 ]; then
        echo "vague"
        return
    fi
    # 缺少所有技术关键词
    local has_tech=0
    for kw in "error" "fail" "crash" "bug" "issue" "broken" "cannot" "unable" "exception" "panic"; do
        if echo "$body" | grep -qi "$kw"; then
            has_tech=1
            break
        fi
    done
    if [ "$has_tech" -eq 0 ]; then
        echo "vague"
        return
    fi
    echo ""
}

# 检查 issue 可行动性
check_actionable() {
    local body="$1"
    local score=0

    # 有复现步骤关键词
    if echo "$body" | grep -qiE "(step|reproduce|repro|how to|to reproduce|steps)"; then
        score=$((score + 2))
    fi
    # 有错误堆栈/消息
    if echo "$body" | grep -qiE "(error|exception|stack trace|panic|traceback|segfault|TypeError|ReferenceError)"; then
        score=$((score + 2))
    fi
    # 有环境信息
    if echo "$body" | grep -qiE "(environment|version|os|platform|node|macos|linux|windows|docker|browser)"; then
        score=$((score + 1))
    fi
    # 有代码/文件引用
    if echo "$body" | grep -qiE "(\.ts:|\.js:|\.py:|\.rs:|line \d+|at \w+\(|file:)"; then
        score=$((score + 2))
    fi
    # 有截图/日志提及
    if echo "$body" | grep -qiE "(screenshot|log|attached|image|png|jpg|gif|video|gif)"; then
        score=$((score + 1))
    fi

    if [ "$score" -ge 4 ]; then
        echo "actionable"
    elif [ "$score" -ge 2 ]; then
        echo "partial"
    else
        echo "needs-info"
    fi
}

# 重复检测：同批次中标题相似度检测
# 输入：所有 issues 的 JSON 数组，输出每个 issue 的 dup 信息
detect_duplicates() {
    local json_input="$1"
    local count
    count=$(echo "$json_input" | jq 'length')

    local result="{}"
    for ((i = 0; i < count; i++)); do
        local title_i
        title_i=$(echo "$json_input" | jq -r ".[$i].title" | tr '[:upper:]' '[:lower:]')
        local num_i
        num_i=$(echo "$json_input" | jq -r ".[$i].number")
        local dup_of=""

        for ((j = 0; j < i; j++)); do
            local title_j
            title_j=$(echo "$json_input" | jq -r ".[$j].title" | tr '[:upper:]' '[:lower:]')
            local num_j
            num_j=$(echo "$json_input" | jq -r ".[$j].number")

            # 简单相似度：标题包含关系或词重叠
            local overlap=0
            local total_words=0
            for word in $title_i; do
                total_words=$((total_words + 1))
                if echo "$title_j" | grep -qF "$word"; then
                    overlap=$((overlap + 1))
                fi
            done
            # 如果重叠词 > 60% 且标题长度 > 10
            if [ "$total_words" -gt 3 ] && [ $((overlap * 100 / total_words)) -gt 60 ]; then
                dup_of="$num_j"
                break
            fi
            # 或标题完全包含
            if echo "$title_j" | grep -qF "$title_i" || echo "$title_i" | grep -qF "$title_j"; then
                if [ ${#title_i} -gt 15 ] || [ ${#title_j} -gt 15 ]; then
                    dup_of="$num_j"
                    break
                fi
            fi
        done

        result=$(echo "$result" | jq --arg key "$num_i" --arg val "$dup_of" '. + {($key): $val}')
    done
    echo "$result"
}

# ============================================================
# 主流程：获取所有 issues（含 body）
# ============================================================

echo "🔍 正在搜索 OpenClaw v${VERSION} 的 bug 报告..."
echo ""

# 获取所有 open issues（含 body 用于质量评估）
ALL_ISSUES_JSON=$(gh issue list --repo "$REPO" --state open --search "$VERSION" --limit 100 \
    --json number,title,body,labels 2>/dev/null || echo "[]")

# 运行重复检测
DUP_MAP=$(detect_duplicates "$ALL_ISSUES_JSON")

# 分类函数：输出带质量标签的 issue 列表
emit_issues() {
    local label_filter="$1"
    local issues
    issues=$(echo "$ALL_ISSUES_JSON" | jq -c --arg lf "$label_filter" '
        if $lf == "" then
            .[]
        elif $lf == "general" then
            .[] | select(.labels | map(.name) | (contains(["Critical"]) or contains(["regression"])) | not)
        else
            .[] | select(.labels | map(.name) | contains([$lf]))
        end
    ')

    local count=0
    while IFS= read -r issue; do
        [ -z "$issue" ] && continue
        local num title body quality dup_of marker
        num=$(echo "$issue" | jq -r '.number')
        title=$(echo "$issue" | jq -r '.title')
        body=$(echo "$issue" | jq -r '.body // ""')

        # 质量评估
        quality=$(check_actionable "$body")
        local vague_tag
        vague_tag=$(is_vague "$body")

        # 重复检测
        dup_of=$(echo "$DUP_MAP" | jq -r --arg n "$num" '.[$n] // ""')

        # 构建标记
        marker=""
        if [ "$dup_of" != "" ] && [ "$dup_of" != "null" ]; then
            marker=" [🔁 dup of #$dup_of]"
        elif [ "$vague_tag" = "vague" ]; then
            marker=" [⚠️ vague]"
        elif [ "$quality" = "actionable" ]; then
            marker=" [✅ actionable]"
        elif [ "$quality" = "partial" ]; then
            marker=" [⚡ partial]"
        else
            marker=" [❓ needs info]"
        fi

        echo "- #$num: $title$marker"
        count=$((count + 1))
    done <<< "$issues"

    # 返回计数
    echo "$count"
}

# ============================================================
# 输出各分类
# ============================================================

# Critical
echo -e "${RED}### 🔴 Critical / 严重问题${NC}"
critical_lines=$(emit_issues "Critical")
critical_body=$(echo "$critical_lines" | head -n -1)
critical_count=$(echo "$critical_lines" | tail -1)
if [ -n "$critical_body" ] && [ "$critical_count" -gt 0 ] 2>/dev/null; then
    echo "$critical_body"
else
    echo "  无"
    critical_count=0
fi
echo ""

# Regression
echo -e "${ORANGE}### 🟠 Regression / 回归问题${NC}"
regression_lines=$(emit_issues "regression")
regression_body=$(echo "$regression_lines" | head -n -1)
regression_count=$(echo "$regression_lines" | tail -1)
if [ -n "$regression_body" ] && [ "$regression_count" -gt 0 ] 2>/dev/null; then
    echo "$regression_body"
else
    echo "  无"
    regression_count=0
fi
echo ""

# General
echo -e "${YELLOW}### 🟡 General Bugs / 一般问题${NC}"
general_lines=$(emit_issues "general")
general_body=$(echo "$general_lines" | head -n -1)
general_count=$(echo "$general_lines" | tail -1)
if [ -n "$general_body" ] && [ "$general_count" -gt 0 ] 2>/dev/null; then
    echo "$general_body"
else
    echo "  无"
    general_count=0
fi
echo ""

# ============================================================
# 质量统计
# ============================================================

echo -e "${CYAN}### 📋 质量评估${NC}"

# 统计各质量等级
actionable_count=0
partial_count=0
needs_info_count=0
vague_count=0
dup_count=0
total_evaluated=0

while IFS= read -r issue; do
    [ -z "$issue" ] && continue
    body=$(echo "$issue" | jq -r '.body // ""')
    num=$(echo "$issue" | jq -r '.number')

    quality=$(check_actionable "$body")
    vague_tag=$(is_vague "$body")
    dup_of=$(echo "$DUP_MAP" | jq -r --arg n "$num" '.[$n] // ""')

    total_evaluated=$((total_evaluated + 1))
    if [ "$dup_of" != "" ] && [ "$dup_of" != "null" ]; then
        dup_count=$((dup_count + 1))
    elif [ "$vague_tag" = "vague" ]; then
        vague_count=$((vague_count + 1))
    elif [ "$quality" = "actionable" ]; then
        actionable_count=$((actionable_count + 1))
    elif [ "$quality" = "partial" ]; then
        partial_count=$((partial_count + 1))
    else
        needs_info_count=$((needs_info_count + 1))
    fi
done <<< "$(echo "$ALL_ISSUES_JSON" | jq -c '.[]')"

echo "- 总 issue 数: $total_evaluated"
echo "- ✅ actionable: $actionable_count"
echo "- ⚡ partial: $partial_count"
echo "- ❓ needs info: $needs_info_count"
echo "- ⚠️ vague: $vague_count"
echo "- 🔁 duplicate: $dup_count"
echo ""

# 升级建议
effective_bugs=$((critical_count + regression_count - dup_count))
if [ "$effective_bugs" -lt 0 ]; then
    effective_bugs=0
fi

echo -e "${GREEN}### 📊 统计信息${NC}"
total_open=$(echo "$ALL_ISSUES_JSON" | jq 'length')
total_closed=$(gh issue list --repo "$REPO" --state closed --search "$VERSION" --limit 100 2>/dev/null | wc -l | tr -d ' ' || echo "0")

echo "- 未解决 issues: $total_open"
echo "- 已解决 issues: $total_closed"
echo ""

echo -e "${GREEN}### ✅ 修复状态${NC}"
pr_count=$(gh pr list --repo "$REPO" --state merged --search "$VERSION" --limit 20 2>/dev/null | wc -l | tr -d ' ' || echo "0")
if [ "$pr_count" -gt 0 ]; then
    echo "已合并的修复 PR: $pr_count"
    gh pr list --repo "$REPO" --state merged --search "$VERSION" --limit 10 \
        --json number,title 2>/dev/null | jq -r '.[] | "  - #\(.number): \(.title)"' 2>/dev/null
else
    echo "  暂无已合并的修复 PR"
fi
echo ""

# 升级建议
echo "---"
if [ "$actionable_count" -eq 0 ] && [ "$critical_count" -eq 0 ] && [ "$regression_count" -eq 0 ]; then
    echo "🟢 推荐升级 — 无已知的可行动严重问题"
elif [ "$actionable_count" -le 3 ] && [ "$critical_count" -le 1 ]; then
    echo "🟡 谨慎升级 — 有少量可行动 issue，建议查看具体描述"
else
    echo "🔴 暂缓升级 — 存在 $actionable_count 个可行动 issue（含 $critical_count 个 Critical）"
fi
echo ""
echo "搜索完成时间：$(date '+%Y-%m-%d %H:%M:%S')"
echo "数据源：https://github.com/$REPO/issues"
