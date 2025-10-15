#!/bin/bash
# Slither 检测器 - 运行完整安全扫描

set +e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== BakerFi Slither 安全检测工具 ===${NC}\n"

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
echo "📁 输出目录: $OUTPUT_DIR"
echo ""

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="${OUTPUT_DIR}/full-scan-${TIMESTAMP}.json"

echo -e "${YELLOW}🔍 运行检测器...${NC}"
echo ""

# 运行完整检测
slither . \
  --filter-paths "node_modules/,test/,mocks/" \
  --exclude-dependencies \
  --json "$OUTPUT_FILE"

EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✓ 检测完成（无严重问题）${NC}"
elif [ $EXIT_CODE -eq 255 ]; then
    echo -e "${YELLOW}⚠ 检测完成（发现问题）${NC}"
else
    echo -e "${RED}✗ 检测失败（退出码: $EXIT_CODE）${NC}"
fi

# 分析结果统计
echo ""
echo -e "${YELLOW}📊 分析检测结果...${NC}"

if [ -f "$OUTPUT_FILE" ]; then
    # 直接从 JSON 统计各级别问题数量（不保存分类文件）
    high_count=$(jq '[.results.detectors[] | select(.impact=="High")] | length' "$OUTPUT_FILE" 2>/dev/null || echo 0)
    medium_count=$(jq '[.results.detectors[] | select(.impact=="Medium")] | length' "$OUTPUT_FILE" 2>/dev/null || echo 0)
    low_count=$(jq '[.results.detectors[] | select(.impact=="Low")] | length' "$OUTPUT_FILE" 2>/dev/null || echo 0)
    info_count=$(jq '[.results.detectors[] | select(.impact=="Informational")] | length' "$OUTPUT_FILE" 2>/dev/null || echo 0)
    
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
    
    # 显示高危问题预览
    if [ "$high_count" -gt 0 ]; then
        echo ""
        echo -e "${RED}⚠️  发现 ${high_count} 个高危问题！${NC}"
        echo ""
        echo "高危问题预览:"
        jq -r '.results.detectors[] | select(.impact=="High") | "  - \(.check): \(.description | split("\n")[0] | .[0:80])"' \
            "$OUTPUT_FILE" 2>/dev/null | head -5
        echo ""
    fi
    
    if [ "$medium_count" -gt 0 ]; then
        echo -e "${YELLOW}注意: 发现 ${medium_count} 个中危问题${NC}"
    fi
    
else
    echo -e "${RED}✗ 未生成 JSON 文件${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}=== 完成! ===${NC}"
echo "结果文件: $(basename $OUTPUT_FILE)"
echo "完整路径: $OUTPUT_FILE"
echo ""
echo "查看详细结果:"
echo "  jq . $OUTPUT_FILE | less"
echo ""
echo "按严重性查看:"
echo "  jq '.results.detectors[] | select(.impact==\"High\")' $OUTPUT_FILE"
echo ""

