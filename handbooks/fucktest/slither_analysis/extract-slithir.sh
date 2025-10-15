#!/bin/bash
# 提取 SlithIR（中间表示，控制流图）

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== BakerFi SlithIR 提取工具 ===${NC}\n"

# 切换到项目根目录
cd "$(dirname "$0")/../../.."
PROJECT_ROOT=$(pwd)
OUTPUT_DIR="handbooks/fucktest/slither_analysis/slithir"

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
OUTPUT_FILE="${OUTPUT_DIR}/slithir-${TIMESTAMP}.txt"

echo -e "${YELLOW}📊 生成 SlithIR 中间表示...${NC}"
echo "（这可能需要几分钟时间...）"
echo ""

# 运行 slithir printer
slither . \
  --filter-paths "node_modules/,test/,mocks/" \
  --exclude-dependencies \
  --print slithir \
  > "$OUTPUT_FILE" 2>&1

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✓ 生成完成${NC}"
elif [ $EXIT_CODE -eq 255 ]; then
    echo -e "${YELLOW}⚠ 生成完成（有警告）${NC}"
else
    echo -e "${RED}✗ 生成失败（退出码: $EXIT_CODE）${NC}"
fi

echo ""
echo -e "${GREEN}=== 完成! ===${NC}"
echo "结果文件: $(basename $OUTPUT_FILE)"
echo "完整路径: $OUTPUT_FILE"
echo ""

echo "统计信息:"
echo "  总行数: $(wc -l < "$OUTPUT_FILE")"
echo "  文件大小: $(du -h "$OUTPUT_FILE" | cut -f1)"
echo ""

echo "查看 SlithIR:"
echo "  cat $OUTPUT_FILE | less"
echo "  grep -A 20 'Function functionName' $OUTPUT_FILE"
echo ""

echo "提示: SlithIR 是 Slither 的中间表示（SSA 形式），包含："
echo "  - 控制流信息"
echo "  - 底层操作（Low-level operations）"
echo "  - 变量赋值和使用"
echo ""

