#!/bin/bash
# Slither 完整检测脚本 - 运行所有检测器

set +e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Slither 完整安全检测                    ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""

# 切换到项目根目录
cd "$(dirname "$0")/../../.."
PROJECT_ROOT=$(pwd)
OUTPUT_DIR="handbooks/fucktest/slither_analysis/detectors"

# 确保输出目录存在
mkdir -p "$OUTPUT_DIR"

# 检查 slither 是否安装
if ! command -v slither &> /dev/null; then
    echo -e "${RED}✗ Slither 未安装${NC}"
    echo "请安装: pip install slither-analyzer"
    exit 1
fi

echo -e "${GREEN}✓ Slither 已安装: $(slither --version)${NC}"
echo ""

# ============================================
# 1. 运行所有检测器
# ============================================
echo -e "${YELLOW}🔍 运行所有检测器 (--detect all)...${NC}"
echo "这可能需要几分钟时间..."
echo ""

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# 运行完整检测
slither . \
  --filter-paths "node_modules/,test/,mocks/" \
  --exclude-dependencies \
  --json "${OUTPUT_DIR}/full-scan-${TIMESTAMP}.json" \
  2>&1 | tee "${OUTPUT_DIR}/full-scan-${TIMESTAMP}.log"

EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✓ 检测完成（无严重问题）${NC}"
elif [ $EXIT_CODE -eq 255 ]; then
    echo -e "${YELLOW}⚠ 检测完成（发现问题）${NC}"
else
    echo -e "${RED}✗ 检测失败（退出码: $EXIT_CODE）${NC}"
fi

# ============================================
# 2. 按严重性分类
# ============================================
echo ""
echo -e "${YELLOW}📊 分析检测结果...${NC}"

if [ -f "${OUTPUT_DIR}/full-scan-${TIMESTAMP}.json" ]; then
    # 提取各个级别的问题
    jq '.results.detectors[] | select(.impact=="High")' \
        "${OUTPUT_DIR}/full-scan-${TIMESTAMP}.json" \
        > "${OUTPUT_DIR}/high-severity-${TIMESTAMP}.json" 2>/dev/null
    
    jq '.results.detectors[] | select(.impact=="Medium")' \
        "${OUTPUT_DIR}/full-scan-${TIMESTAMP}.json" \
        > "${OUTPUT_DIR}/medium-severity-${TIMESTAMP}.json" 2>/dev/null
    
    jq '.results.detectors[] | select(.impact=="Low")' \
        "${OUTPUT_DIR}/full-scan-${TIMESTAMP}.json" \
        > "${OUTPUT_DIR}/low-severity-${TIMESTAMP}.json" 2>/dev/null
    
    jq '.results.detectors[] | select(.impact=="Informational")' \
        "${OUTPUT_DIR}/full-scan-${TIMESTAMP}.json" \
        > "${OUTPUT_DIR}/informational-${TIMESTAMP}.json" 2>/dev/null
    
    # 统计
    high_count=$(jq -s 'length' "${OUTPUT_DIR}/high-severity-${TIMESTAMP}.json" 2>/dev/null || echo 0)
    medium_count=$(jq -s 'length' "${OUTPUT_DIR}/medium-severity-${TIMESTAMP}.json" 2>/dev/null || echo 0)
    low_count=$(jq -s 'length' "${OUTPUT_DIR}/low-severity-${TIMESTAMP}.json" 2>/dev/null || echo 0)
    info_count=$(jq -s 'length' "${OUTPUT_DIR}/informational-${TIMESTAMP}.json" 2>/dev/null || echo 0)
    
    echo ""
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${YELLOW}检测结果统计${NC}"
    echo ""
    echo -e "  ${RED}🔴 High:          ${high_count}${NC}"
    echo -e "  ${YELLOW}🟡 Medium:        ${medium_count}${NC}"
    echo -e "  ${GREEN}🟢 Low:           ${low_count}${NC}"
    echo -e "  ${BLUE}ℹ️  Informational: ${info_count}${NC}"
    echo ""
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    
    # ============================================
    # 3. 生成可读报告
    # ============================================
    echo ""
    echo -e "${YELLOW}📝 生成分析报告...${NC}"
    
    REPORT_FILE="${OUTPUT_DIR}/summary-${TIMESTAMP}.md"
    
    cat > "$REPORT_FILE" <<EOF
# Slither 安全检测报告

> 生成时间: $(date '+%Y-%m-%d %H:%M:%S')
> 项目: BakerFi
> Slither 版本: $(slither --version 2>&1 | head -1)

---

## 📊 检测统计

| 严重性 | 数量 |
|--------|------|
| 🔴 High | ${high_count} |
| 🟡 Medium | ${medium_count} |
| 🟢 Low | ${low_count} |
| ℹ️ Informational | ${info_count} |

**总计**: $((high_count + medium_count + low_count + info_count)) 个发现

---

## 🔴 高危问题 (High Severity)

EOF

    # 添加高危问题详情
    if [ "$high_count" -gt 0 ]; then
        jq -r '.[] | "### \(.check)\n\n**影响**: \(.impact)  \n**置信度**: \(.confidence)\n\n**描述**: \(.description)\n\n**位置**:\n```\n\(.elements[0].source_mapping.filename_short):\(.elements[0].source_mapping.lines[0])\n```\n\n---\n"' \
            "${OUTPUT_DIR}/high-severity-${TIMESTAMP}.json" >> "$REPORT_FILE" 2>/dev/null
    else
        echo "✅ 未发现高危问题" >> "$REPORT_FILE"
    fi
    
    cat >> "$REPORT_FILE" <<EOF

---

## 🟡 中危问题 (Medium Severity)

EOF

    # 添加中危问题详情
    if [ "$medium_count" -gt 0 ]; then
        jq -r '.[] | "### \(.check)\n\n**影响**: \(.impact)  \n**置信度**: \(.confidence)\n\n**描述**: \(.description)\n\n---\n"' \
            "${OUTPUT_DIR}/medium-severity-${TIMESTAMP}.json" >> "$REPORT_FILE" 2>/dev/null
    else
        echo "✅ 未发现中危问题" >> "$REPORT_FILE"
    fi
    
    cat >> "$REPORT_FILE" <<EOF

---

## 📁 生成文件

- 完整JSON: \`full-scan-${TIMESTAMP}.json\`
- 完整日志: \`full-scan-${TIMESTAMP}.log\`
- 高危问题: \`high-severity-${TIMESTAMP}.json\`
- 中危问题: \`medium-severity-${TIMESTAMP}.json\`
- 低危问题: \`low-severity-${TIMESTAMP}.json\`
- 信息级别: \`informational-${TIMESTAMP}.json\`

---

**报告生成时间**: $(date '+%Y-%m-%d %H:%M:%S')
EOF

    echo -e "${GREEN}✓ 报告已生成: ${REPORT_FILE}${NC}"
    
    # ============================================
    # 4. 显示关键问题
    # ============================================
    if [ "$high_count" -gt 0 ]; then
        echo ""
        echo -e "${RED}⚠️  发现 ${high_count} 个高危问题！${NC}"
        echo ""
        echo "高危问题列表:"
        jq -r '.[] | "  - \(.check): \(.description | split("\n")[0] | .[0:80])"' \
            "${OUTPUT_DIR}/high-severity-${TIMESTAMP}.json" 2>/dev/null | head -10
        echo ""
    fi
    
    if [ "$medium_count" -gt 0 ]; then
        echo -e "${YELLOW}注意: 发现 ${medium_count} 个中危问题${NC}"
    fi
    
else
    echo -e "${RED}✗ 未生成 JSON 文件${NC}"
    exit 1
fi

# ============================================
# 5. 创建最新链接
# ============================================
ln -sf "full-scan-${TIMESTAMP}.json" "${OUTPUT_DIR}/latest.json"
ln -sf "summary-${TIMESTAMP}.md" "${OUTPUT_DIR}/latest-report.md"

echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ 检测完成！${NC}"
echo ""
echo "查看报告:"
echo "  cat ${OUTPUT_DIR}/latest-report.md"
echo ""
echo "查看 JSON:"
echo "  jq . ${OUTPUT_DIR}/latest.json | less"
echo ""

