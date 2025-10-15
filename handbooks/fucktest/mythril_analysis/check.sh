#!/bin/bash
# 检查 Mythril 分析文件的完整性

set +e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Mythril 分析完整性检查                  ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""

cd "$(dirname "$0")/../../.."
PROJECT_ROOT=$(pwd)

# 统计变量
total_errors=0
total_warnings=0
total_checks=0

# 检查函数
check_pass() {
    echo -e "  ${GREEN}✓${NC} $1"
    ((total_checks++))
}

check_fail() {
    echo -e "  ${RED}✗${NC} $1"
    ((total_errors++))
    ((total_checks++))
}

check_warn() {
    echo -e "  ${YELLOW}⚠${NC} $1"
    ((total_warnings++))
    ((total_checks++))
}

# ============================================
# 1. 检查 Mythril 安装
# ============================================
echo -e "${YELLOW}🔧 检查工具安装...${NC}"

if command -v myth &> /dev/null; then
    check_pass "Mythril 已安装: $(myth version 2>&1 | head -1)"
else
    check_fail "Mythril 未安装（pip install mythril）"
fi

echo ""

# ============================================
# 2. 检查目录结构
# ============================================
echo -e "${YELLOW}📁 检查目录结构...${NC}"

if [ -d "handbooks/fucktest/mythril_analysis/symbolic-execution" ]; then
    check_pass "Symbolic-execution 目录存在"
else
    check_warn "Symbolic-execution 目录不存在（需要运行 extract-symbolic-execution.sh）"
fi

echo ""

# ============================================
# 3. 检查分析结果
# ============================================
echo -e "${YELLOW}📊 检查分析结果...${NC}"

SYMB_DIR="handbooks/fucktest/mythril_analysis/symbolic-execution"

if [ -d "$SYMB_DIR" ]; then
    json_count=$(find "$SYMB_DIR" -name "*.json" 2>/dev/null | wc -l)
    md_count=$(find "$SYMB_DIR" -name "*.md" 2>/dev/null | wc -l)
    
    if [ "$json_count" -gt 0 ]; then
        check_pass "找到 ${json_count} 个 JSON 报告"
    else
        check_warn "未找到 JSON 报告"
    fi
    
    if [ "$md_count" -gt 0 ]; then
        check_pass "找到 ${md_count} 个 Markdown 报告"
    else
        check_warn "未找到 Markdown 报告"
    fi
    
    # 检查 JSON 文件是否有效
    if [ "$json_count" -gt 0 ]; then
        for jsonfile in "$SYMB_DIR"/*.json; do
            if [ -f "$jsonfile" ]; then
                if jq empty "$jsonfile" 2>/dev/null; then
                    check_pass "$(basename "$jsonfile") 格式有效"
                else
                    check_fail "$(basename "$jsonfile") JSON 格式无效"
                fi
            fi
        done
    fi
fi

echo ""

# ============================================
# 4. 总结
# ============================================
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}📈 检查统计${NC}"
echo "  总检查项: $total_checks"
echo -e "  通过: ${GREEN}$((total_checks - total_errors - total_warnings))${NC}"
echo -e "  警告: ${YELLOW}${total_warnings}${NC}"
echo -e "  错误: ${RED}${total_errors}${NC}"
echo ""

echo -e "${YELLOW}📁 文件统计${NC}"
if [ -d "$SYMB_DIR" ]; then
    echo "  JSON 报告: $(find "$SYMB_DIR" -name "*.json" 2>/dev/null | wc -l) 个"
    echo "  Markdown 报告: $(find "$SYMB_DIR" -name "*.md" 2>/dev/null | wc -l) 个"
    echo "  总大小: $(du -sh handbooks/fucktest/mythril_analysis 2>/dev/null | cut -f1)"
fi
echo ""

# ============================================
# 5. 建议
# ============================================
if [ $total_errors -gt 0 ]; then
    echo -e "${RED}❌ 发现错误，请修复后重试${NC}"
    exit 1
elif [ $total_warnings -gt 0 ]; then
    echo -e "${YELLOW}⚠️  有警告项，建议检查${NC}"
    exit 0
else
    echo -e "${GREEN}✅ 所有检查通过！${NC}"
    exit 0
fi

