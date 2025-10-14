#!/bin/bash
# Slither Printers - 生成合约分析图表和摘要

set +e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Slither Printers - 生成分析图表         ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""

cd "$(dirname "$0")/../../.."
PROJECT_ROOT=$(pwd)
REPORTS_DIR="handbooks/fucktest/slither_analysis/reports"
GRAPHS_DIR="handbooks/fucktest/slither_analysis/graphs"

mkdir -p "$REPORTS_DIR" "$GRAPHS_DIR"

# 检查 slither
if ! command -v slither &> /dev/null; then
    echo "请安装: pip install slither-analyzer"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TARGET_CONTRACT="contracts/core/Vault.sol"

# ============================================
# 1. 合约摘要
# ============================================
echo -e "${YELLOW}📋 生成合约摘要...${NC}"

slither "$TARGET_CONTRACT" \
  --print contract-summary \
  > "${REPORTS_DIR}/contract-summary-${TIMESTAMP}.txt" 2>&1
echo -e "${GREEN}✓${NC} contract-summary-${TIMESTAMP}.txt"

slither "$TARGET_CONTRACT" \
  --print human-summary \
  > "${REPORTS_DIR}/human-summary-${TIMESTAMP}.txt" 2>&1
echo -e "${GREEN}✓${NC} human-summary-${TIMESTAMP}.txt"

# ============================================
# 2. 函数分析
# ============================================
echo ""
echo -e "${YELLOW}🔧 生成函数分析...${NC}"

slither "$TARGET_CONTRACT" \
  --print function-summary \
  > "${REPORTS_DIR}/function-summary-${TIMESTAMP}.txt" 2>&1
echo -e "${GREEN}✓${NC} function-summary-${TIMESTAMP}.txt"

slither "$TARGET_CONTRACT" \
  --print modifiers \
  > "${REPORTS_DIR}/modifiers-${TIMESTAMP}.txt" 2>&1
echo -e "${GREEN}✓${NC} modifiers-${TIMESTAMP}.txt"

# ============================================
# 3. 调用图
# ============================================
echo ""
echo -e "${YELLOW}🕸️  生成调用图...${NC}"

slither "$TARGET_CONTRACT" \
  --print call-graph \
  2>&1 | tee "${REPORTS_DIR}/call-graph-${TIMESTAMP}.log"

# 移动生成的 dot 文件
if [ -f "Vault.call-graph.dot" ]; then
    mv Vault.call-graph.dot "${GRAPHS_DIR}/call-graph-${TIMESTAMP}.dot"
    echo -e "${GREEN}✓${NC} call-graph-${TIMESTAMP}.dot"
    
    # 转换为 PNG（如果安装了 graphviz）
    if command -v dot &> /dev/null; then
        dot -Tpng "${GRAPHS_DIR}/call-graph-${TIMESTAMP}.dot" \
            -o "${GRAPHS_DIR}/call-graph-${TIMESTAMP}.png" 2>/dev/null
        echo -e "${GREEN}✓${NC} call-graph-${TIMESTAMP}.png"
    fi
fi

# ============================================
# 4. 继承图
# ============================================
echo ""
echo -e "${YELLOW}🧬 生成继承图...${NC}"

slither "$TARGET_CONTRACT" \
  --print inheritance-graph \
  2>&1 | tee "${REPORTS_DIR}/inheritance-${TIMESTAMP}.log"

if [ -f "Vault.inheritance-graph.dot" ]; then
    mv Vault.inheritance-graph.dot "${GRAPHS_DIR}/inheritance-${TIMESTAMP}.dot"
    echo -e "${GREEN}✓${NC} inheritance-${TIMESTAMP}.dot"
    
    if command -v dot &> /dev/null; then
        dot -Tpng "${GRAPHS_DIR}/inheritance-${TIMESTAMP}.dot" \
            -o "${GRAPHS_DIR}/inheritance-${TIMESTAMP}.png" 2>/dev/null
        echo -e "${GREEN}✓${NC} inheritance-${TIMESTAMP}.png"
    fi
fi

# ============================================
# 5. 数据依赖图
# ============================================
echo ""
echo -e "${YELLOW}🔗 生成数据依赖图...${NC}"

slither "$TARGET_CONTRACT" \
  --print data-dependency \
  > "${REPORTS_DIR}/data-dependency-${TIMESTAMP}.txt" 2>&1
echo -e "${GREEN}✓${NC} data-dependency-${TIMESTAMP}.txt"

# ============================================
# 6. 存储布局
# ============================================
echo ""
echo -e "${YELLOW}💾 生成存储布局...${NC}"

slither "$TARGET_CONTRACT" \
  --print vars-and-auth \
  > "${REPORTS_DIR}/vars-and-auth-${TIMESTAMP}.txt" 2>&1
echo -e "${GREEN}✓${NC} vars-and-auth-${TIMESTAMP}.txt"

# ============================================
# 7. SlithIR (中间表示)
# ============================================
echo ""
echo -e "${YELLOW}🧠 生成 SlithIR...${NC}"

slither "$TARGET_CONTRACT" \
  --print slithir \
  > "${REPORTS_DIR}/slithir-${TIMESTAMP}.txt" 2>&1
echo -e "${GREEN}✓${NC} slithir-${TIMESTAMP}.txt"

# ============================================
# 8. 创建最新链接
# ============================================
cd "$REPORTS_DIR"
ln -sf "contract-summary-${TIMESTAMP}.txt" "latest-contract-summary.txt"
ln -sf "function-summary-${TIMESTAMP}.txt" "latest-function-summary.txt"
ln -sf "call-graph-${TIMESTAMP}.log" "latest-call-graph.log"
ln -sf "data-dependency-${TIMESTAMP}.txt" "latest-data-dependency.txt"

cd "$GRAPHS_DIR"
if [ -f "call-graph-${TIMESTAMP}.dot" ]; then
    ln -sf "call-graph-${TIMESTAMP}.dot" "latest-call-graph.dot"
fi
if [ -f "inheritance-${TIMESTAMP}.dot" ]; then
    ln -sf "inheritance-${TIMESTAMP}.dot" "latest-inheritance.dot"
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ 所有图表和报告已生成！${NC}"
echo ""
echo "查看报告:"
echo "  ls -lh ${REPORTS_DIR}/"
echo ""
echo "查看图表:"
echo "  ls -lh ${GRAPHS_DIR}/"
echo ""

