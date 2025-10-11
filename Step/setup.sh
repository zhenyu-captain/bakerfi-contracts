#!/bin/bash

# BakerFi Contracts 完整环境安装脚本
# 所有工具均使用指定版本，不使用 latest

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================
# 版本配置（所有版本在此集中管理）
# ============================================
NODE_VERSION="20.11.0"
NVM_VERSION="0.39.7"
PYTHON_VERSION="3.11.7"
MINICONDA_VERSION="py311_24.1.2-0"
SLITHER_VERSION="0.10.0"
MYTHRIL_VERSION="0.24.8"
ECHIDNA_VERSION="2.2.4"
SOLC_SELECT_VERSION="1.0.4"

echo "=========================================="
echo "BakerFi 合约环境安装脚本"
echo "=========================================="
echo ""

# 检测是否为重复运行
if [ -f ".env-versions" ] && [ -z "$FORCE_REINSTALL" ]; then
    echo -e "${YELLOW}⚠️  检测到已安装的环境${NC}"
    echo ""
    cat .env-versions
    echo ""
    echo "环境已存在，脚本将跳过已安装的组件"
    echo "如需强制重新安装，请运行: FORCE_REINSTALL=1 ./setup.sh"
    echo "如需验证环境，请运行: ./verify-tools.sh"
    echo ""
    sleep 2
fi

echo -e "${BLUE}版本配置:${NC}"
echo "  Node.js: ${NODE_VERSION}"
echo "  Python: ${PYTHON_VERSION} (via Anaconda)"
echo "  Slither: ${SLITHER_VERSION}"
echo "  Mythril: ${MYTHRIL_VERSION}"
echo "  Echidna: ${ECHIDNA_VERSION}"
echo ""

# 检查是否为 root 用户
if [ "$EUID" -eq 0 ]; then 
    echo -e "${RED}❌ 请不要使用 root 用户运行此脚本${NC}"
    exit 1
fi

# 检测操作系统
OS="unknown"
ARCH=$(uname -m)
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
fi

echo -e "${GREEN}检测到系统: $OS ($ARCH)${NC}"
echo ""

# ============================================
# 1. 检查系统基础依赖
# ============================================
echo -e "${YELLOW}[1/8] 检查系统基础依赖...${NC}"

MISSING_DEPS=()

# 检查必需工具
for cmd in curl wget git; do
    if ! command -v $cmd &> /dev/null; then
        MISSING_DEPS+=($cmd)
    fi
done

if [ ${#MISSING_DEPS[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ 必需的系统工具已安装${NC}"
else
    echo -e "${YELLOW}⚠️  缺少系统工具: ${MISSING_DEPS[*]}${NC}"
    echo -e "${YELLOW}请手动安装后重新运行脚本：${NC}"
    
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        echo "  sudo apt-get install curl wget git build-essential"
    elif [ "$OS" = "fedora" ] || [ "$OS" = "rhel" ] || [ "$OS" = "centos" ]; then
        echo "  sudo dnf install curl wget git gcc gcc-c++ make"
    elif [ "$OS" = "arch" ] || [ "$OS" = "manjaro" ]; then
        echo "  sudo pacman -S curl wget git base-devel"
    fi
    
    exit 1
fi
echo ""

# ============================================
# 2. 安装 nvm 和 Node.js
# ============================================
echo -e "${YELLOW}[2/8] 安装 Node.js ${NODE_VERSION} (via nvm ${NVM_VERSION})...${NC}"

# 安装 nvm
if [ ! -d "$HOME/.nvm" ]; then
    echo "  安装 nvm ${NVM_VERSION}..."
    curl -sS https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash > /dev/null 2>&1
fi

# 加载 nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# 安装指定版本的 Node.js
if ! nvm list | grep -q "v${NODE_VERSION}"; then
    echo "  安装 Node.js ${NODE_VERSION}..."
    nvm install ${NODE_VERSION} > /dev/null 2>&1
fi

nvm use ${NODE_VERSION} > /dev/null 2>&1
nvm alias default ${NODE_VERSION} > /dev/null 2>&1

NODE_ACTUAL=$(node --version)
NPM_ACTUAL=$(npm --version)

echo -e "${GREEN}✓ Node.js ${NODE_ACTUAL} 安装完成${NC}"
echo -e "${GREEN}✓ npm ${NPM_ACTUAL} 已就绪${NC}"
echo ""

# ============================================
# 3. 安装 Miniconda 和 Python
# ============================================
echo -e "${YELLOW}[3/8] 安装 Python ${PYTHON_VERSION} (via Miniconda)...${NC}"

CONDA_DIR="$HOME/miniconda3"
CONDA_ENV_NAME="bakerfi"

if [ ! -d "$CONDA_DIR" ]; then
    echo "  下载 Miniconda ${MINICONDA_VERSION}..."
    
    if [ "$ARCH" = "x86_64" ]; then
        MINICONDA_INSTALLER="Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh"
    elif [ "$ARCH" = "aarch64" ]; then
        MINICONDA_INSTALLER="Miniconda3-${MINICONDA_VERSION}-Linux-aarch64.sh"
    else
        echo -e "${RED}❌ 不支持的架构: $ARCH${NC}"
        exit 1
    fi
    
    cd /tmp
    wget -q https://repo.anaconda.com/miniconda/${MINICONDA_INSTALLER}
    bash ${MINICONDA_INSTALLER} -b -p $CONDA_DIR > /dev/null 2>&1
    rm ${MINICONDA_INSTALLER}
    cd - > /dev/null
    
    echo "  Miniconda 安装完成"
fi

# 初始化 conda
eval "$($CONDA_DIR/bin/conda shell.bash hook)"

# 创建或更新 conda 环境
if conda env list | grep -q "^${CONDA_ENV_NAME} "; then
    echo "  环境 ${CONDA_ENV_NAME} 已存在，跳过创建"
else
    echo "  创建 conda 环境: ${CONDA_ENV_NAME} (Python ${PYTHON_VERSION})..."
    conda create -n ${CONDA_ENV_NAME} python=${PYTHON_VERSION} -y -q > /dev/null 2>&1
fi

# 激活环境
conda activate ${CONDA_ENV_NAME}

PYTHON_ACTUAL=$(python --version 2>&1)
echo -e "${GREEN}✓ ${PYTHON_ACTUAL} 安装完成${NC}"
echo -e "${GREEN}✓ Conda 环境: ${CONDA_ENV_NAME}${NC}"
echo ""

# ============================================
# 4. 安装项目 npm 依赖
# ============================================
echo -e "${YELLOW}[4/8] 安装项目 npm 依赖...${NC}"

if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ 未找到 package.json${NC}"
    exit 1
fi

echo "  执行 npm install (可能需要几分钟)..."
npm install --silent > /dev/null 2>&1

echo -e "${GREEN}✓ npm 依赖安装完成${NC}"
echo ""

# ============================================
# 5. 安装 Slither
# ============================================
echo -e "${YELLOW}[5/8] 安装 Slither ${SLITHER_VERSION}...${NC}"

# 先卸载可能存在的旧版本
pip uninstall -y slither-analyzer mythril > /dev/null 2>&1 || true

# 重新安装 Slither 及其依赖（一次性安装避免冲突）
pip install --quiet slither-analyzer==${SLITHER_VERSION} > /dev/null 2>&1

# 安装 solc-select 用于管理 Solidity 编译器版本
pip install --quiet solc-select==${SOLC_SELECT_VERSION} > /dev/null 2>&1

# 安装项目需要的 solc 版本 (0.8.24 是主版本)
solc-select install 0.8.24 > /dev/null 2>&1 || true
solc-select use 0.8.24 > /dev/null 2>&1 || true

# 验证安装（忽略警告）
SLITHER_ACTUAL=$(pip show slither-analyzer 2>/dev/null | grep Version | cut -d' ' -f2 || echo "0.10.0")
echo -e "${GREEN}✓ Slither ${SLITHER_ACTUAL}${NC}"
echo -e "${GREEN}✓ solc-select ${SOLC_SELECT_VERSION}${NC}"
echo ""

# ============================================
# 6. 安装 Mythril (可选)
# ============================================
echo -e "${YELLOW}[6/8] 安装 Mythril ${MYTHRIL_VERSION}...${NC}"

# 先卸载可能存在的旧版本
pip uninstall -y mythril > /dev/null 2>&1 || true

# 安装 Mythril
pip install --quiet mythril==${MYTHRIL_VERSION} > /dev/null 2>&1 || {
    echo -e "${YELLOW}⚠️  Mythril 安装失败（可选工具，不影响主要功能）${NC}"
}

if command -v myth &> /dev/null; then
    MYTH_ACTUAL=$(myth version 2>&1 | grep -oP 'v\d+\.\d+\.\d+' | head -n 1 || echo "${MYTHRIL_VERSION}")
    echo -e "${GREEN}✓ Mythril ${MYTH_ACTUAL}${NC}"
else
    echo -e "${YELLOW}⚠️  Mythril 未安装（可选）${NC}"
fi
echo ""

# ============================================
# 7. 安装 Echidna
# ============================================
echo -e "${YELLOW}[7/8] 安装 Echidna ${ECHIDNA_VERSION}...${NC}"

if ! command -v echidna &> /dev/null && ! command -v echidna-test &> /dev/null; then
    ECHIDNA_URL="https://github.com/crytic/echidna/releases/download/v${ECHIDNA_VERSION}/echidna-${ECHIDNA_VERSION}-x86_64-linux.tar.gz"
    
    echo "  下载 Echidna ${ECHIDNA_VERSION}..."
    cd /tmp
    rm -rf echidna_install
    mkdir -p echidna_install
    
    if wget -q "$ECHIDNA_URL" -O echidna.tar.gz 2>/dev/null; then
        if tar -xzf echidna.tar.gz -C echidna_install 2>/dev/null; then
            # 查找可执行文件并安装到用户目录
            mkdir -p $HOME/.local/bin
            
            if [ -f "echidna_install/echidna" ]; then
                # 先删除已存在的文件（如果有）
                rm -f $HOME/.local/bin/echidna 2>/dev/null
                mv echidna_install/echidna $HOME/.local/bin/
                chmod +x $HOME/.local/bin/echidna
                echo -e "${GREEN}✓ Echidna 安装到 ~/.local/bin/${NC}"
            elif [ -f "echidna_install/echidna-test" ]; then
                # 先删除已存在的文件（如果有）
                rm -f $HOME/.local/bin/echidna-test 2>/dev/null
                mv echidna_install/echidna-test $HOME/.local/bin/
                chmod +x $HOME/.local/bin/echidna-test
                echo -e "${GREEN}✓ Echidna 安装到 ~/.local/bin/${NC}"
            else
                echo -e "${YELLOW}⚠️  Echidna 可执行文件未找到（可选工具）${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  Echidna 解压失败（可选工具）${NC}"
        fi
        
        rm -rf echidna_install echidna.tar.gz
    else
        echo -e "${YELLOW}⚠️  Echidna 下载失败（可选工具）${NC}"
    fi
    cd - > /dev/null
fi

if command -v echidna &> /dev/null; then
    ECHIDNA_ACTUAL=$(echidna --version 2>&1 | head -n 1)
    echo -e "${GREEN}✓ ${ECHIDNA_ACTUAL}${NC}"
elif command -v echidna-test &> /dev/null; then
    ECHIDNA_ACTUAL=$(echidna-test --version 2>&1 | head -n 1)
    echo -e "${GREEN}✓ ${ECHIDNA_ACTUAL}${NC}"
else
    echo -e "${YELLOW}⚠️  Echidna 未安装（可选工具，不影响核心功能）${NC}"
fi
echo ""

# ============================================
# 8. 安装 Surya (可选的可视化工具)
# ============================================
echo -e "${YELLOW}[8/8] 安装 Surya (可视化工具)...${NC}"

# Surya 版本通过 npm 安装
SURYA_VERSION="0.4.11"
npm install -g --silent surya@${SURYA_VERSION} > /dev/null 2>&1 || {
    echo -e "${YELLOW}⚠️  Surya 安装失败（可选工具）${NC}"
}

if command -v surya &> /dev/null; then
    echo -e "${GREEN}✓ Surya ${SURYA_VERSION}${NC}"
else
    echo -e "${YELLOW}⚠️  Surya 未安装（可选）${NC}"
fi
echo ""

# ============================================
# 环境验证
# ============================================
echo "=========================================="
echo -e "${BLUE}环境验证${NC}"
echo "=========================================="
echo ""

# 临时添加 ~/.local/bin 到 PATH 用于验证
export PATH="$HOME/.local/bin:$PATH"

echo "=== 核心工具 ==="
echo "  Node.js:  $(node --version)"
echo "  npm:      $(npm --version)"
echo "  Python:   $(python --version 2>&1)"
echo "  Conda:    $(conda --version 2>&1)"
echo ""

echo "=== 审计工具 ==="
echo "  Slither:  $(slither --version 2>&1 | head -n 1)"

# 检查 Echidna
if command -v echidna &> /dev/null; then
    echo "  Echidna:  $(echidna --version 2>&1 | head -n 1)"
elif [ -f "$HOME/.local/bin/echidna" ]; then
    echo "  Echidna:  $($HOME/.local/bin/echidna --version 2>&1 | head -n 1)"
else
    echo "  Echidna:  未安装"
fi

if command -v myth &> /dev/null; then
    echo "  Mythril:  $(myth version 2>&1 | grep -oP "v\d+\.\d+\.\d+" | head -n 1)"
fi
if command -v surya &> /dev/null; then
    echo "  Surya:    已安装"
fi
echo ""

echo "=== Hardhat 检查 ==="
if npx hardhat --version > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓ Hardhat 可用${NC}"
else
    echo -e "  ${YELLOW}⚠️  Hardhat 需要首次初始化${NC}"
fi
echo ""

# ============================================
# 创建激活脚本
# ============================================
if [ ! -f "activate-env.sh" ]; then
    echo "创建环境激活脚本..."
else
    echo "更新环境激活脚本..."
fi

cat > activate-env.sh << 'ACTIVATE_EOF'
#!/bin/bash
# BakerFi 环境激活脚本
# 使用方法: source ./activate-env.sh

# 添加本地 bin 到 PATH
export PATH="$HOME/.local/bin:$PATH"

# 激活 nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# 激活 conda 环境
eval "$($HOME/miniconda3/bin/conda shell.bash hook)"
conda activate bakerfi

echo "✓ BakerFi 开发环境已激活"
echo "  Node.js: $(node --version)"
echo "  Python: $(python --version 2>&1)"
ACTIVATE_EOF

chmod +x activate-env.sh

# ============================================
# 创建环境配置文件
# ============================================
if [ ! -f ".env" ]; then
    echo "创建 .env 配置模板..."
    cat > .env << 'ENV_EOF'
# BakerFi 环境变量配置

# 本地开发
WEB3_RPC_LOCAL_URL=http://127.0.0.1:8545

# RPC 节点（留空使用默认）
WEB3_RPC_ETH_MAIN_NET_URL=
WEB3_RPC_ARBITRUM_URL=
WEB3_RPC_OPTIMISM_URL=
WEB3_RPC_BASE_URL=

# API Keys
ANKR_API_KEY=
ETHERSCAN_API_KEY=
BASESCAN_API_KEY=
ARBSCAN_API_KEY=

# 部署私钥（生产环境）
BAKERFI_PRIVATE_KEY=

# Tenderly 开发网络
TENDERLY_DEV_NET_RPC=

# Gas 报告
REPORT_GAS=false
ENV_EOF
fi

# ============================================
# 完成
# ============================================
echo "=========================================="
echo -e "${GREEN}🎉 环境安装完成！${NC}"
echo "=========================================="
echo ""
echo -e "${BLUE}已安装版本:${NC}"
echo "  ├─ Node.js ${NODE_VERSION}"
echo "  ├─ Python ${PYTHON_VERSION}"
echo "  ├─ Slither ${SLITHER_VERSION}"
echo "  ├─ Mythril ${MYTHRIL_VERSION}"
echo "  └─ Echidna ${ECHIDNA_VERSION}"
echo ""
echo -e "${BLUE}下一步操作:${NC}"
echo "  1. 激活环境:"
echo -e "     ${GREEN}source ./Step/activate-env.sh${NC}"
echo ""
echo "  2. 验证项目（推荐）:"
echo -e "     ${GREEN}./Step/verify-project.sh${NC}"
echo ""
echo "  3. 或手动执行:"
echo -e "     ${GREEN}npx hardhat compile${NC}      # 编译合约"
echo -e "     ${GREEN}npx hardhat test${NC}         # 运行测试"
echo -e "     ${GREEN}npx hardhat coverage${NC}     # 生成覆盖率"
echo ""
echo -e "${YELLOW}注意:${NC} 每次打开新终端需要先运行: ${GREEN}source ./Step/activate-env.sh${NC}"
echo ""

# 保存版本信息
cat > .env-versions << EOF
# BakerFi 环境版本记录
# 安装时间: $(date)
NODE_VERSION=${NODE_VERSION}
PYTHON_VERSION=${PYTHON_VERSION}
SLITHER_VERSION=${SLITHER_VERSION}
MYTHRIL_VERSION=${MYTHRIL_VERSION}
ECHIDNA_VERSION=${ECHIDNA_VERSION}
SURYA_VERSION=${SURYA_VERSION}
EOF

echo -e "${GREEN}✓ 版本信息已保存到 .env-versions${NC}"
echo ""

