#!/bin/bash

# BakerFi 工具验证脚本
# 快速检查所有已安装的工具是否正常工作

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "=========================================="
echo "BakerFi 工具验证"
echo "=========================================="
echo ""

# 确保 PATH 包含所有必要目录
export PATH="$HOME/.local/bin:$PATH"

# 激活 nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 2>/dev/null

# 激活 conda 环境
if [ -d "$HOME/miniconda3" ]; then
    eval "$($HOME/miniconda3/bin/conda shell.bash hook)" 2>/dev/null
    conda activate bakerfi 2>/dev/null || true
fi

PASS=0
FAIL=0

check_tool() {
    local name=$1
    local cmd=$2
    
    if eval "$cmd" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $name"
        ((PASS++))
        return 0
    else
        echo -e "${RED}✗${NC} $name"
        ((FAIL++))
        return 1
    fi
}

echo "=== 核心工具 ==="
check_tool "Node.js $(node --version 2>/dev/null)" "node --version"
check_tool "npm $(npm --version 2>/dev/null)" "npm --version"
check_tool "Python $(python --version 2>&1 | cut -d' ' -f2)" "python --version"
echo ""

echo "=== 审计工具 ==="

# Slither - 使用 pip show 获取版本（更可靠）
SLITHER_VER=$(pip show slither-analyzer 2>/dev/null | grep "^Version:" | cut -d' ' -f2 || echo "未知")
check_tool "Slither $SLITHER_VER" "pip show slither-analyzer"

# Echidna
ECHIDNA_VER=$(echidna --version 2>&1 | grep -oP '\d+\.\d+\.\d+' || echo "未知")
check_tool "Echidna $ECHIDNA_VER" "echidna --version"

# Mythril
MYTH_VER=$(pip show mythril 2>/dev/null | grep "^Version:" | cut -d' ' -f2 || echo "未知")
check_tool "Mythril v$MYTH_VER" "pip show mythril"

# Surya
check_tool "Surya" "surya --version"

# solc
SOLC_VER=$(solc --version 2>&1 | grep -oP 'Version: \d+\.\d+\.\d+' | head -n 1 || echo "未知")
check_tool "solc $SOLC_VER" "solc --version"
echo ""

echo "=== Hardhat 检查 ==="
check_tool "Hardhat" "npx hardhat --version"
echo ""

echo "=========================================="
echo -e "结果: ${GREEN}$PASS 通过${NC} / ${RED}$FAIL 失败${NC}"
echo "=========================================="
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}🎉 所有工具都已正确安装！${NC}"
    echo ""
    echo "可以开始工作了："
    echo -e "  ${GREEN}./Step/verify-project.sh${NC}  # 一键验证项目"
    echo "  或单独运行："
    echo -e "  ${GREEN}npx hardhat compile${NC}        # 编译合约"
    echo -e "  ${GREEN}npx hardhat test${NC}           # 运行测试"
    echo ""
    exit 0
else
    echo -e "${RED}❌ 有 $FAIL 个工具未能正常工作${NC}"
    echo ""
    echo "请检查安装日志: setup.log"
    echo -e "或重新运行: ${GREEN}./Step/setup.sh${NC}"
    echo ""
    exit 1
fi

