#!/bin/bash
# 提取调用图（Call Graph）

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== BakerFi 调用图提取工具 ===${NC}\n"

# 切换到项目根目录
cd "$(dirname "$0")/../../.."
PROJECT_ROOT=$(pwd)
OUTPUT_DIR="handbooks/fucktest/slither_analysis/call-graph"

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
OUTPUT_PREFIX="${OUTPUT_DIR}/call-graph-${TIMESTAMP}"

echo -e "${YELLOW}📊 生成调用图...${NC}"
echo ""

# 运行 call-graph printer
slither . \
  --filter-paths "node_modules/,test/,mocks/" \
  --exclude-dependencies \
  --print call-graph \
  > /dev/null 2>&1

# Slither 会在当前目录生成文件，需要移动到输出目录
if ls *.dot 1> /dev/null 2>&1; then
    echo -e "${GREEN}✓ DOT 文件生成成功${NC}"
    echo ""
    
    # 移动所有 .dot 文件到输出目录
    for dotfile in *.dot; do
        mv "$dotfile" "${OUTPUT_DIR}/${dotfile}"
        echo "  📄 $(basename "$dotfile")"
    done
else
    echo -e "${YELLOW}⚠ 未生成 DOT 文件${NC}"
fi

echo ""
echo -e "${GREEN}=== 完成! ===${NC}"
echo "输出目录: $OUTPUT_DIR"
echo ""

# 统计文件
dot_count=$(find "$OUTPUT_DIR" -name "*.dot" 2>/dev/null | wc -l)

echo "统计信息:"
echo "  DOT 文件: ${dot_count} 个"
echo ""

echo "查看调用图:"
echo "  在线渲染: https://dreampuf.github.io/GraphvizOnline/"
echo "  生成图片: dot -Tpng file.dot -o file.png"
echo "  生成 SVG: dot -Tsvg file.dot -o file.svg"
echo ""

