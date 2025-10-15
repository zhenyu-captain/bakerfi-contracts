#!/bin/bash
# 检查分析文件的完整性和正确性

# 不使用 set -e，因为我们需要捕获所有错误
set +e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  BakerFi 分析文件完整性检查              ║${NC}"
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
# 1. 检查目录结构
# ============================================
echo -e "${YELLOW}📁 检查目录结构...${NC}"

if [ -d "handbooks/fucktest/slither_analysis/abi" ]; then
    check_pass "ABI 目录存在"
else
    check_fail "ABI 目录不存在"
fi

if [ -d "handbooks/fucktest/slither_analysis/ast" ]; then
    check_pass "AST 目录存在"
else
    check_fail "AST 目录不存在"
fi

if [ -d "handbooks/fucktest/slither_analysis/detectors" ]; then
    check_pass "Detectors 目录存在"
else
    check_warn "Detectors 目录不存在（需要运行 extract-detectors.sh）"
fi

if [ -d "handbooks/fucktest/slither_analysis/contract-summary" ]; then
    check_pass "Contract-summary 目录存在"
else
    check_warn "Contract-summary 目录不存在（需要运行 extract-contract-summary.sh）"
fi

if [ -d "handbooks/fucktest/slither_analysis/function-summary" ]; then
    check_pass "Function-summary 目录存在"
else
    check_warn "Function-summary 目录不存在（需要运行 extract-function-summary.sh）"
fi

if [ -d "handbooks/fucktest/slither_analysis/call-graph" ]; then
    check_pass "Call-graph 目录存在"
else
    check_warn "Call-graph 目录不存在（需要运行 extract-call-graph.sh）"
fi

if [ -d "handbooks/fucktest/slither_analysis/data-dependency" ]; then
    check_pass "Data-dependency 目录存在"
else
    check_warn "Data-dependency 目录不存在（需要运行 extract-data-dependency.sh）"
fi

if [ -d "handbooks/fucktest/slither_analysis/slithir" ]; then
    check_pass "SlithIR 目录存在"
else
    check_warn "SlithIR 目录不存在（需要运行 extract-slithir.sh）"
fi

echo ""

# ============================================
# 2. 检查 artifacts 是否已编译
# ============================================
echo -e "${YELLOW}🔨 检查编译产物...${NC}"

if [ -d "artifacts/contracts" ]; then
    check_pass "artifacts 目录存在"
else
    check_fail "artifacts 目录不存在，请先运行: npx hardhat compile"
    exit 1
fi

if [ -f "artifacts/build-info/"*.json ]; then
    BUILD_INFO=$(ls -t artifacts/build-info/*.json 2>/dev/null | head -1)
    check_pass "build-info 文件存在: $(basename $BUILD_INFO)"
else
    check_fail "build-info 不存在，请先运行: npx hardhat compile"
    exit 1
fi

echo ""

# ============================================
# 3. 检查 ABI 文件
# ============================================
echo -e "${YELLOW}📦 检查 ABI 文件...${NC}"

# 定义应该存在的核心合约
EXPECTED_CORE_CONTRACTS=(
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

ABI_DIR="handbooks/fucktest/slither_analysis/abi"
abi_count=0
abi_missing=0

# 检查核心合约
for contract in "${EXPECTED_CORE_CONTRACTS[@]}"; do
    if [ -f "$ABI_DIR/${contract}.json" ]; then
        # 验证 JSON 格式
        if jq empty "$ABI_DIR/${contract}.json" 2>/dev/null; then
            # 检查是否有 ABI 字段
            if jq -e '.abi' "$ABI_DIR/${contract}.json" >/dev/null 2>&1; then
                func_count=$(jq '.abi[] | select(.type=="function")' "$ABI_DIR/${contract}.json" | jq -s 'length')
                check_pass "${contract}.json (${func_count} 函数)"
                ((abi_count++))
            else
                check_fail "${contract}.json 缺少 ABI 字段"
            fi
        else
            check_fail "${contract}.json JSON 格式错误"
        fi
    else
        check_fail "${contract}.json 不存在"
        ((abi_missing++))
    fi
done

# 统计策略合约
STRATEGY_DIR="artifacts/contracts/core/strategies"
if [ -d "$STRATEGY_DIR" ]; then
    expected_strategy_count=$(find "$STRATEGY_DIR" -name "*.json" ! -name "*.dbg.json" | wc -l)
    actual_strategy_count=$(find "$ABI_DIR" -name "Strategy*.json" | wc -l)
    
    if [ "$actual_strategy_count" -eq "$expected_strategy_count" ]; then
        check_pass "策略合约: ${actual_strategy_count}/${expected_strategy_count}"
    else
        check_warn "策略合约: ${actual_strategy_count}/${expected_strategy_count} (可能有遗漏)"
    fi
fi

# 统计 Oracle 合约
ORACLE_DIR="artifacts/contracts/oracles"
if [ -d "$ORACLE_DIR" ]; then
    expected_oracle_count=$(find "$ORACLE_DIR" -name "*.json" ! -name "*.dbg.json" | wc -l)
    actual_oracle_count=$(find "$ABI_DIR" -name "*Oracle*.json" | wc -l)
    
    if [ "$actual_oracle_count" -eq "$expected_oracle_count" ]; then
        check_pass "Oracle 合约: ${actual_oracle_count}/${expected_oracle_count}"
    else
        check_warn "Oracle 合约: ${actual_oracle_count}/${expected_oracle_count} (可能有遗漏)"
    fi
fi

echo ""

# ============================================
# 4. 检查 AST 文件
# ============================================
echo -e "${YELLOW}🌳 检查 AST 文件...${NC}"

AST_DIR="handbooks/fucktest/slither_analysis/ast"
ast_count=0
ast_missing=0

# 检查核心合约 AST
for contract in "${EXPECTED_CORE_CONTRACTS[@]}"; do
    ast_file="$AST_DIR/${contract}-ast.json"
    full_file="$AST_DIR/${contract}-full.json"
    
    if [ -f "$ast_file" ]; then
        # 验证 JSON 格式
        if jq empty "$ast_file" 2>/dev/null; then
            # 检查是否有 nodeType 字段（AST 特征）
            if jq -e '.nodeType' "$ast_file" >/dev/null 2>&1; then
                node_type=$(jq -r '.nodeType' "$ast_file")
                check_pass "${contract}-ast.json (nodeType: ${node_type})"
                ((ast_count++))
            else
                check_fail "${contract}-ast.json 不是有效的 AST"
            fi
        else
            check_fail "${contract}-ast.json JSON 格式错误"
        fi
    else
        check_fail "${contract}-ast.json 不存在"
        ((ast_missing++))
    fi
done

# 统计策略 AST
actual_strategy_ast=$(find "$AST_DIR" -name "Strategy*-ast.json" | wc -l)
if [ "$actual_strategy_ast" -gt 0 ]; then
    check_pass "策略合约 AST: ${actual_strategy_ast} 个"
else
    check_warn "未找到策略合约 AST"
fi

echo ""

# ============================================
# 5. 数据完整性检查
# ============================================
echo -e "${YELLOW}🔍 数据完整性检查...${NC}"

# 检查 ABI 文件大小
for contract in "${EXPECTED_CORE_CONTRACTS[@]}"; do
    abi_file="$ABI_DIR/${contract}.json"
    if [ -f "$abi_file" ]; then
        size=$(stat -f%z "$abi_file" 2>/dev/null || stat -c%s "$abi_file" 2>/dev/null)
        if [ "$size" -lt 100 ]; then
            check_fail "${contract}.json 文件太小 (${size} bytes)"
        else
            check_pass "${contract}.json 大小正常 ($(numfmt --to=iec-i --suffix=B $size 2>/dev/null || echo ${size}B))"
        fi
    fi
done

echo ""

# ============================================
# 6. 对比源文件检查
# ============================================
echo -e "${YELLOW}📊 对比源文件检查...${NC}"

# 检查是否有源文件但没有对应的 ABI
for sol_file in contracts/core/*.sol; do
    if [ -f "$sol_file" ]; then
        contract_name=$(basename "$sol_file" .sol)
        # 跳过一些不需要 ABI 的文件
        if [[ "$contract_name" != "Constants" ]] && [[ "$contract_name" != "EmptySlot" ]]; then
            if [ ! -f "$ABI_DIR/${contract_name}.json" ]; then
                check_warn "源文件 ${contract_name}.sol 存在，但没有对应的 ABI"
            fi
        fi
    fi
done

echo ""

# ============================================
# 7. 总结
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
echo "  ABI 文件: $(find "$ABI_DIR" -name "*.json" 2>/dev/null | wc -l) 个"
echo "  AST 文件: $(find "$AST_DIR" -name "*.json" 2>/dev/null | wc -l) 个"
echo "  Detectors: $(find handbooks/fucktest/slither_analysis/detectors -name "*.json" 2>/dev/null | wc -l) 个"
echo "  Contract-summary: $(find handbooks/fucktest/slither_analysis/contract-summary -name "*.txt" 2>/dev/null | wc -l) 个"
echo "  Function-summary: $(find handbooks/fucktest/slither_analysis/function-summary -name "*.txt" 2>/dev/null | wc -l) 个"
echo "  Call-graph: $(find handbooks/fucktest/slither_analysis/call-graph -name "*.dot" 2>/dev/null | wc -l) 个"
echo "  Data-dependency: $(find handbooks/fucktest/slither_analysis/data-dependency -name "*.txt" 2>/dev/null | wc -l) 个"
echo "  SlithIR: $(find handbooks/fucktest/slither_analysis/slithir -name "*.txt" 2>/dev/null | wc -l) 个"
echo "  总大小: $(du -sh handbooks/fucktest/slither_analysis 2>/dev/null | cut -f1)"
echo ""

# ============================================
# 8. 建议
# ============================================
if [ $total_errors -gt 0 ]; then
    echo -e "${RED}❌ 发现 ${total_errors} 个错误${NC}"
    echo ""
    echo -e "${YELLOW}💡 建议操作:${NC}"
    
    if [ $abi_missing -gt 0 ]; then
        echo "  1. 重新提取 ABI: ./extract-abi.sh"
    fi
    
    if [ $ast_missing -gt 0 ]; then
        echo "  2. 重新提取 AST: ./extract-ast.sh"
    fi
    
    echo "  3. 如果问题持续，请先编译: npx hardhat compile"
    echo ""
    exit 1
elif [ $total_warnings -gt 0 ]; then
    echo -e "${YELLOW}⚠ 有 ${total_warnings} 个警告，但可以继续${NC}"
    echo ""
    exit 0
else
    echo -e "${GREEN}✅ 所有检查通过！分析文件完整且正确${NC}"
    echo ""
    exit 0
fi

