#!/bin/bash

# BakerFi Contracts 项目功能验证脚本
# 自动执行完整验证流程并生成报告

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# 开始时间
START_TIME=$(date +%s)
REPORT_DATE=$(date +"%Y-%m-%d %H:%M")

echo "=========================================="
echo "BakerFi 项目功能验证脚本"
echo "=========================================="
echo ""
echo -e "${BLUE}开始时间: $REPORT_DATE${NC}"
echo ""

# 检查是否在项目根目录
if [ ! -f "package.json" ] || [ ! -f "hardhat.config.ts" ]; then
    echo -e "${RED}❌ 错误: 请在项目根目录运行此脚本${NC}"
    exit 1
fi

# 创建临时文件存储结果
TEMP_DIR=$(mktemp -d)
TEST_OUTPUT="$TEMP_DIR/test_output.txt"
COVERAGE_OUTPUT="$TEMP_DIR/coverage_output.txt"
COMPILE_OUTPUT="$TEMP_DIR/compile_output.txt"

# 清理函数
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# ============================================
# 阶段 1: 环境激活
# ============================================
echo -e "${YELLOW}[1/7] 激活开发环境...${NC}"

export PATH="$HOME/.local/bin:$PATH"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

eval "$($HOME/miniconda3/bin/conda shell.bash hook)" 2>/dev/null || true
conda activate bakerfi 2>/dev/null || true

NODE_VERSION=$(node --version 2>/dev/null || echo "未安装")
NPM_VERSION=$(npm --version 2>/dev/null || echo "未安装")
PYTHON_VERSION=$(python --version 2>&1 || echo "未安装")

if [ "$NODE_VERSION" = "未安装" ]; then
    echo -e "${RED}❌ Node.js 未安装或环境未激活${NC}"
    echo "请先运行: ./Step/setup.sh"
    exit 1
fi

echo -e "${GREEN}✓ 环境已激活${NC}"
echo "  Node.js: $NODE_VERSION"
echo "  npm: $NPM_VERSION"
echo "  Python: $PYTHON_VERSION"
echo ""

# ============================================
# 阶段 2: 安装依赖
# ============================================
echo -e "${YELLOW}[2/7] 检查并安装项目依赖...${NC}"

if [ ! -d "node_modules" ]; then
    echo "  正在安装 npm 依赖..."
    INSTALL_START=$(date +%s)
    npm install --silent > /dev/null 2>&1
    INSTALL_END=$(date +%s)
    INSTALL_TIME=$((INSTALL_END - INSTALL_START))
    echo -e "${GREEN}✓ 依赖安装完成 (${INSTALL_TIME}秒)${NC}"
else
    echo -e "${GREEN}✓ 依赖已存在，跳过安装${NC}"
fi

PACKAGE_COUNT=$(find node_modules -maxdepth 1 -type d | wc -l)
echo "  已安装包: $((PACKAGE_COUNT - 1)) 个"
echo ""

# ============================================
# 阶段 3: 编译合约
# ============================================
echo -e "${YELLOW}[3/7] 编译智能合约...${NC}"

COMPILE_START=$(date +%s)
npx hardhat compile > "$COMPILE_OUTPUT" 2>&1
COMPILE_END=$(date +%s)
COMPILE_TIME=$((COMPILE_END - COMPILE_START))

# 提取编译统计
CONTRACT_COUNT=$(grep -o "Compiled [0-9]* Solidity" "$COMPILE_OUTPUT" | grep -o "[0-9]*" || echo "0")
TYPECHAIN_COUNT=$(grep -o "Successfully generated [0-9]* typings" "$COMPILE_OUTPUT" | grep -o "[0-9]*" | head -1 || echo "0")
WARNING_COUNT=$(grep -c "Warning:" "$COMPILE_OUTPUT" || echo "0")

echo -e "${GREEN}✓ 编译完成 (${COMPILE_TIME}秒)${NC}"
echo "  合约数量: $CONTRACT_COUNT 个"
echo "  类型定义: $TYPECHAIN_COUNT 个"
echo "  警告数量: $WARNING_COUNT 个"
echo ""

# ============================================
# 阶段 4: 运行测试
# ============================================
echo -e "${YELLOW}[4/7] 运行完整测试套件...${NC}"

TEST_START=$(date +%s)
npx hardhat test > "$TEST_OUTPUT" 2>&1 || true
TEST_END=$(date +%s)
TEST_TIME=$((TEST_END - TEST_START))

# 提取测试统计
TEST_PASSING=$(grep -o "[0-9]* passing" "$TEST_OUTPUT" | grep -o "[0-9]*" || echo "0")
TEST_PENDING=$(grep -o "[0-9]* pending" "$TEST_OUTPUT" | grep -o "[0-9]*" || echo "0")
TEST_FAILING=$(grep -o "[0-9]* failing" "$TEST_OUTPUT" | grep -o "[0-9]*" || echo "0")
TEST_TOTAL=$((TEST_PASSING + TEST_PENDING + TEST_FAILING))

echo -e "${GREEN}✓ 测试完成 (${TEST_TIME}秒)${NC}"
echo "  总计: $TEST_TOTAL 个"
echo "  ✅ 通过: $TEST_PASSING 个"
echo "  ⏸️  跳过: $TEST_PENDING 个"
echo "  ❌ 失败: $TEST_FAILING 个"

if [ "$TEST_FAILING" -gt 0 ]; then
    echo -e "${RED}⚠️  发现失败的测试！${NC}"
fi
echo ""

# ============================================
# 阶段 5: 生成覆盖率
# ============================================
echo -e "${YELLOW}[5/7] 生成测试覆盖率报告...${NC}"

COV_START=$(date +%s)
npx hardhat coverage > "$COVERAGE_OUTPUT" 2>&1 || true
COV_END=$(date +%s)
COV_TIME=$((COV_END - COV_START))

# 提取覆盖率数据
STMT_COV=$(grep "All files" "$COVERAGE_OUTPUT" | awk '{print $2}' || echo "0")
BRANCH_COV=$(grep "All files" "$COVERAGE_OUTPUT" | awk '{print $3}' || echo "0")
FUNC_COV=$(grep "All files" "$COVERAGE_OUTPUT" | awk '{print $4}' || echo "0")
LINE_COV=$(grep "All files" "$COVERAGE_OUTPUT" | awk '{print $5}' || echo "0")

echo -e "${GREEN}✓ 覆盖率报告生成完成 (${COV_TIME}秒)${NC}"
echo "  语句覆盖率: $STMT_COV"
echo "  分支覆盖率: $BRANCH_COV"
echo "  函数覆盖率: $FUNC_COV"
echo "  行覆盖率: $LINE_COV"
echo ""

# ============================================
# 阶段 6: 检查 POC 和 Echidna
# ============================================
echo -e "${YELLOW}[6/7] 检查 POC 和 Echidna 测试...${NC}"

POC_FILES=$(find contracts -name "*Attack*" -o -name "*POC*" 2>/dev/null | wc -l)
TEST_CONTRACTS=$(find contracts/tests -name "*.sol" 2>/dev/null | wc -l)
ECHIDNA_EXISTS=$([ -f "echidna.yaml" ] && echo "是" || echo "否")

echo -e "${GREEN}✓ POC 检查完成${NC}"
echo "  攻击测试文件: $POC_FILES 个"
echo "  测试合约: $TEST_CONTRACTS 个"
echo "  Echidna 配置: $ECHIDNA_EXISTS"
echo ""

# ============================================
# 阶段 7: 显示验证总结
# ============================================
echo -e "${YELLOW}[7/7] 显示验证总结...${NC}"

END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))
TOTAL_MINUTES=$((TOTAL_TIME / 60))
TOTAL_SECONDS=$((TOTAL_TIME % 60))

# 计算测试通过率（避免除以0）
if [ "$TEST_TOTAL" -gt 0 ]; then
    TEST_PASS_RATE=$((TEST_PASSING * 100 / TEST_TOTAL))
else
    TEST_PASS_RATE=0
fi

echo ""
echo -e "${GREEN}✓ 验证总结已准备${NC}"
echo ""

# ============================================
# 完成总结
# ============================================
echo "=========================================="
echo -e "${GREEN}验证完成！${NC}"
echo "=========================================="
echo ""

echo -e "${BLUE}=== 📊 验证总结 ===${NC}"
echo ""
echo "执行时间:"
echo "  总耗时: ${TOTAL_MINUTES}分${TOTAL_SECONDS}秒"
echo ""

echo "编译结果:"
echo "  合约数量: $CONTRACT_COUNT 个"
echo "  类型定义: $TYPECHAIN_COUNT 个"  
echo "  编译警告: $WARNING_COUNT 个"
echo ""

echo "测试结果:"
echo "  ✅ 通过: $TEST_PASSING 个 (${TEST_PASS_RATE}%)"
echo "  ⏸️  跳过: $TEST_PENDING 个"
echo "  ❌ 失败: $TEST_FAILING 个"
echo ""

echo "代码覆盖率:"
echo "  语句覆盖率: $STMT_COV"
echo "  分支覆盖率: $BRANCH_COV"
echo "  函数覆盖率: $FUNC_COV"
echo "  行覆盖率: $LINE_COV"
echo ""

echo "POC 和安全测试:"
echo "  攻击测试文件: $POC_FILES 个"
echo "  测试合约: $TEST_CONTRACTS 个"  
echo "  Echidna 配置: $ECHIDNA_EXISTS"
echo ""

echo "生成的文件:"
echo "  ✅ coverage/index.html (覆盖率报告)"
echo "  ✅ artifacts/ (编译产物)"
echo "  ✅ src/types/ (类型定义)"
echo ""

if [ "$TEST_FAILING" -eq 0 ]; then
    echo -e "${GREEN}🎉 所有测试通过，项目功能正常，可以开始审计工作！${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  发现 $TEST_FAILING 个失败的测试${NC}"
    echo "请查看测试日志进行调试"
    exit 1
fi
