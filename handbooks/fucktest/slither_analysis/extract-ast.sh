#!/bin/bash
# 提取合约 AST（抽象语法树）

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== BakerFi 合约 AST 提取工具 ===${NC}\n"

# 确保在正确的目录
cd "$(dirname "$0")/../../.."
PROJECT_ROOT=$(pwd)
OUTPUT_DIR="handbooks/fucktest/slither_analysis/ast"

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 查找 build-info 文件
BUILD_INFO=$(ls -t artifacts/build-info/*.json 2>/dev/null | head -1)

if [ -z "$BUILD_INFO" ]; then
  echo -e "${YELLOW}⚠ 未找到 build-info 文件，请先运行: npx hardhat compile${NC}"
  exit 1
fi

echo "📁 使用 build-info: $(basename $BUILD_INFO)"
echo "📁 输出目录: $OUTPUT_DIR"
echo ""

# 要提取的合约列表
CONTRACTS=(
  "contracts/core/Vault.sol"
  "contracts/core/VaultBase.sol"
  "contracts/core/VaultSettings.sol"
  "contracts/core/VaultRegistry.sol"
  "contracts/core/VaultRouter.sol"
  "contracts/core/GovernableOwnable.sol"
  "contracts/core/MultiCommand.sol"
  "contracts/core/MultiStrategy.sol"
  "contracts/core/MultiStrategyVault.sol"
)

echo "🌳 提取 AST..."
for contract_path in "${CONTRACTS[@]}"; do
  contract_name=$(basename "$contract_path" .sol)
  
  # 提取完整源码信息（包括 AST、id 等）
  cat "$BUILD_INFO" | \
    jq ".output.sources[\"$contract_path\"]" \
    > "${OUTPUT_DIR}/${contract_name}-full.json"
  
  # 只提取 AST 部分
  cat "$BUILD_INFO" | \
    jq ".output.sources[\"$contract_path\"].ast" \
    > "${OUTPUT_DIR}/${contract_name}-ast.json"
  
  echo -e "  ${GREEN}✓${NC} ${contract_name}-ast.json"
done

# 提取策略合约 AST
echo ""
echo "🎯 提取策略合约 AST..."
for strategy_path in artifacts/contracts/core/strategies/*.sol; do
  if [ -d "$strategy_path" ]; then
    strategy_file=$(basename "$strategy_path")
    strategy_name="${strategy_file%.sol}"
    contract_path="contracts/core/strategies/$strategy_file"
    
    # 检查是否存在于 build-info 中
    if cat "$BUILD_INFO" | jq -e ".output.sources[\"$contract_path\"]" > /dev/null 2>&1; then
      cat "$BUILD_INFO" | \
        jq ".output.sources[\"$contract_path\"].ast" \
        > "${OUTPUT_DIR}/${strategy_name}-ast.json"
      echo -e "  ${GREEN}✓${NC} ${strategy_name}-ast.json"
    fi
  fi
done

echo ""
echo -e "${GREEN}=== 完成! ===${NC}"
echo "总计: $(ls -1 "$OUTPUT_DIR"/*.json 2>/dev/null | wc -l) 个文件"
echo "位置: $OUTPUT_DIR/"

