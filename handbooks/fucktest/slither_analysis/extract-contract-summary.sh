#!/bin/bash
# 提取合约摘要信息

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== BakerFi 合约摘要提取工具 ===${NC}\n"

# 切换到项目根目录
cd "$(dirname "$0")/../../.."
PROJECT_ROOT=$(pwd)
OUTPUT_DIR="handbooks/fucktest/slither_analysis/contract-summary"

# 创建输出目录
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
OUTPUT_FILE="${OUTPUT_DIR}/contract-summary-${TIMESTAMP}.txt"

echo -e "${YELLOW}📋 生成合约摘要...${NC}"
echo ""

# 运行 contract-summary printer
slither . \
  --filter-paths "node_modules/,test/,mocks/" \
  --exclude-dependencies \
  --print contract-summary \
  > "$OUTPUT_FILE" 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 摘要生成成功${NC}"
else
    echo -e "${YELLOW}⚠ 生成完成（可能有警告）${NC}"
fi

echo ""
echo -e "${GREEN}=== 完成! ===${NC}"
echo "结果文件: $(basename $OUTPUT_FILE)"
echo "完整路径: $OUTPUT_FILE"
echo ""
echo "查看摘要:"
echo "  cat $OUTPUT_FILE | less"
echo ""
echo "统计信息:"
echo "  总行数: $(wc -l < "$OUTPUT_FILE")"
echo "  文件大小: $(du -h "$OUTPUT_FILE" | cut -f1)"
echo ""

