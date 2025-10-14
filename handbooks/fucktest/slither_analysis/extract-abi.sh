#!/bin/bash
# 批量提取合约 ABI 到规范目录

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== BakerFi 合约 ABI 提取工具 ===${NC}\n"

# 确保在正确的目录
cd "$(dirname "$0")/../../.."
PROJECT_ROOT=$(pwd)
OUTPUT_DIR="handbooks/fucktest/analysis/abi"

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

echo "📁 输出目录: $OUTPUT_DIR"
echo ""

# 提取核心合约
echo "📦 提取核心合约 ABI..."
CORE_CONTRACTS=(
  "Vault"
  "VaultBase"
  "VaultSettings"
  "VaultRegistry"
  "VaultRouter"
  "GovernableOwnable"
  "MultiCommand"
  "MultiStrategy"
  "MultiStrategyVault"
)

for contract in "${CORE_CONTRACTS[@]}"; do
  file="artifacts/contracts/core/${contract}.sol/${contract}.json"
  if [ -f "$file" ]; then
    cat "$file" | jq . > "${OUTPUT_DIR}/${contract}.json"
    echo -e "  ${GREEN}✓${NC} ${contract}.json"
  else
    echo -e "  ⚠ ${contract}.json (未找到)"
  fi
done

# 提取策略合约
echo ""
echo "🎯 提取策略合约 ABI..."
STRATEGY_DIR="artifacts/contracts/core/strategies"
if [ -d "$STRATEGY_DIR" ]; then
  for file in "$STRATEGY_DIR"/*.sol/*.json; do
    if [ -f "$file" ] && [[ ! "$file" =~ \.dbg\.json$ ]]; then
      name=$(basename "$file")
      cat "$file" | jq . > "${OUTPUT_DIR}/${name}"
      echo -e "  ${GREEN}✓${NC} ${name}"
    fi
  done
fi

# 提取 Oracle 合约
echo ""
echo "🔮 提取 Oracle 合约 ABI..."
ORACLE_DIR="artifacts/contracts/oracles"
if [ -d "$ORACLE_DIR" ]; then
  for file in "$ORACLE_DIR"/*.sol/*.json; do
    if [ -f "$file" ] && [[ ! "$file" =~ \.dbg\.json$ ]]; then
      name=$(basename "$file")
      cat "$file" | jq . > "${OUTPUT_DIR}/${name}"
      echo -e "  ${GREEN}✓${NC} ${name}"
    fi
  done
fi

# 统计
echo ""
echo -e "${GREEN}=== 完成! ===${NC}"
echo "总计: $(ls -1 "$OUTPUT_DIR"/*.json 2>/dev/null | wc -l) 个文件"
echo "位置: $OUTPUT_DIR/"

