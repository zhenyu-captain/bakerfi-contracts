#!/bin/bash

# BakerFi Contracts 清理脚本
# 清理所有不需要提交到 git 的本地生成文件

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "BakerFi 项目清理脚本"
echo "=========================================="
echo ""

# 检查是否在项目根目录
if [ ! -f "package.json" ] || [ ! -f "hardhat.config.ts" ]; then
    echo -e "${RED}❌ 错误: 请在项目根目录运行此脚本${NC}"
    exit 1
fi

# 显示将要清理的内容
echo -e "${YELLOW}此脚本将清理以下内容:${NC}"
echo "  • node_modules/ (npm 依赖)"
echo "  • artifacts/, cache/ (Hardhat 编译产物)"
echo "  • typechain/, typechain-types/ (TypeChain 类型)"
echo "  • coverage/ (测试覆盖率报告)"
echo "  • *.log (所有日志文件)"
echo "  • PROJECT_VERIFICATION_REPORT.md (验证报告)"
echo "  • 其他临时文件和构建产物"
echo ""
echo -e "${GREEN}保留的内容:${NC}"
echo "  ✅ .env (环境配置)"
echo "  ✅ 所有源代码文件 (contracts/, scripts/, test/)"
echo "  ✅ src/types/ (TypeChain 生成的类型)"
echo "  ✅ audits/stage2/evidence/ (审计证据)"
echo ""

# 计算当前项目大小
BEFORE_SIZE=$(du -sh . 2>/dev/null | cut -f1)
echo "当前项目大小: $BEFORE_SIZE"
echo ""

# 统计信息
CLEANED_COUNT=0
FAILED_COUNT=0

# 清理函数（改进版，不会因错误中断）
clean_item() {
    local path=$1
    local description=$2
    
    if [ -e "$path" ]; then
        # 计算大小（如果是目录）
        if [ -d "$path" ]; then
            local size=$(du -sh "$path" 2>/dev/null | cut -f1)
            echo -e "${YELLOW}正在删除:${NC} $description ($size)"
        else
            echo -e "${YELLOW}正在删除:${NC} $description"
        fi
        
        # 尝试删除
        if rm -rf "$path" 2>/dev/null; then
            ((CLEANED_COUNT++))
            echo -e "${GREEN}✓ 已删除${NC}"
        else
            ((FAILED_COUNT++))
            echo -e "${RED}✗ 删除失败${NC}"
        fi
    else
        echo -e "${BLUE}跳过:${NC} $description (不存在)"
    fi
}

# 清理多个匹配的文件
clean_pattern() {
    local pattern=$1
    local description=$2
    
    if ls $pattern 1> /dev/null 2>&1; then
        echo -e "${YELLOW}正在删除:${NC} $description"
        if rm -f $pattern 2>/dev/null; then
            ((CLEANED_COUNT++))
            echo -e "${GREEN}✓ 已删除${NC}"
        else
            ((FAILED_COUNT++))
            echo -e "${RED}✗ 删除失败${NC}"
        fi
    fi
}

echo -e "${BLUE}开始清理...${NC}"
echo ""

# ============================================
# 1. Node.js 依赖
# ============================================
echo "=== [1/10] Node.js 依赖 ==="
clean_item "node_modules" "node_modules/ (npm 依赖包)"
echo ""

# ============================================
# 2. Hardhat 编译产物
# ============================================
echo "=== [2/10] Hardhat 编译产物 ==="
clean_item "artifacts" "artifacts/ (编译产物)"
clean_item "cache" "cache/ (Hardhat 缓存)"
clean_item ".storage-layouts" ".storage-layouts/ (存储布局)"
echo ""

# ============================================
# 3. TypeScript 类型生成
# ============================================
echo "=== [3/10] TypeScript 类型生成 ==="
echo -e "${YELLOW}⚠️  注意: src/types 包含 TypeChain 生成的类型，已保留${NC}"
echo -e "${BLUE}保留:${NC} src/types/ (可通过 npx hardhat compile 重新生成)"
clean_item "typechain" "typechain/ (TypeChain 类型)"
clean_item "typechain-types" "typechain-types/ (TypeChain 类型)"
clean_item "dist" "dist/ (编译输出)"
echo ""

# ============================================
# 4. 测试覆盖率报告
# ============================================
echo "=== [4/10] 测试覆盖率报告 ==="
clean_item "coverage" "coverage/ (覆盖率报告)"
clean_item "coverage.json" "coverage.json (覆盖率数据)"
clean_item ".coverage_artifacts" ".coverage_artifacts/ (覆盖率临时文件)"
clean_item ".coverage_cache" ".coverage_cache/ (覆盖率缓存)"
echo ""

# ============================================
# 5. 日志文件
# ============================================
echo "=== [5/10] 日志和报告文件 ==="
clean_item "setup.log" "setup.log (安装日志)"
clean_item "PROJECT_VERIFICATION_REPORT.md" "PROJECT_VERIFICATION_REPORT.md (验证报告)"
clean_pattern "*.log" "所有 *.log 文件"
echo ""

# ============================================
# 6. 环境配置文件（谨慎删除）
# ============================================
echo "=== [6/10] 环境配置文件 ==="
echo -e "${YELLOW}⚠️  注意: .env 文件包含敏感配置，已保留${NC}"

if [ -f ".env" ]; then
    echo -e "${BLUE}保留:${NC} .env (环境变量配置)"
fi

clean_item ".env-versions" ".env-versions (版本记录)"
clean_item "activate-env.sh" "activate-env.sh (环境激活脚本)"
echo ""

# ============================================
# 7. 静态分析报告
# ============================================
echo "=== [7/10] 静态分析报告 ==="
clean_item "slither-report.json" "slither-report.json"
clean_item "slither-report.txt" "slither-report.txt"
clean_item "slither-report.md" "slither-report.md"
clean_item "mythril-report.json" "mythril-report.json"
clean_item "mythril-report.txt" "mythril-report.txt"
clean_item "echidna-corpus" "echidna-corpus/ (Echidna 语料库)"

if [ -d "audits/stage2/evidence" ]; then
    echo -e "${BLUE}保留:${NC} audits/stage2/evidence/ (审计证据)"
fi
echo ""

# ============================================
# 8. 临时文件
# ============================================
echo "=== [8/10] 临时文件 ==="
clean_item ".tmp" ".tmp/"
clean_item "tmp" "tmp/"
clean_item ".temp" ".temp/"
clean_item ".DS_Store" ".DS_Store"

# 递归删除所有 .DS_Store
if find . -name ".DS_Store" -type f 2>/dev/null | grep -q .; then
    echo -e "${YELLOW}正在删除:${NC} 所有 .DS_Store 文件"
    find . -name ".DS_Store" -type f -delete 2>/dev/null && echo -e "${GREEN}✓ 已删除${NC}"
fi
echo ""

# ============================================
# 9. 编辑器和 IDE 配置（可选）
# ============================================
echo "=== [9/10] 编辑器/IDE 配置文件 ==="
echo -e "${BLUE}保留:${NC} .vscode/, .idea/ 等 IDE 配置"
echo -e "${BLUE}提示:${NC} 如需删除，请手动运行: rm -rf .vscode .idea"
echo ""

# ============================================
# 10. Hardhat 和其他构建产物
# ============================================
echo "=== [10/10] 其他构建产物 ==="
clean_item "deployments" "deployments/ (部署记录)"
clean_item ".openzeppelin" ".openzeppelin/ (OpenZeppelin 升级记录)"
clean_item "broadcast" "broadcast/ (Foundry 广播记录)"
clean_item ".tenderly" ".tenderly/ (Tenderly 配置)"

# 清理 npm 包文件
clean_pattern "*.tgz" "*.tgz (npm 打包文件)"
echo ""

# ============================================
# 完成统计
# ============================================
echo "=========================================="
echo -e "${GREEN}清理完成！${NC}"
echo "=========================================="
echo ""
echo "清理统计:"
echo "  ✓ 成功删除: $CLEANED_COUNT 个"
if [ $FAILED_COUNT -gt 0 ]; then
    echo "  ✗ 删除失败: $FAILED_COUNT 个"
fi
echo ""

# 显示剩余未追踪的文件
echo "=== Git 状态检查 ==="
if git rev-parse --git-dir > /dev/null 2>&1; then
    UNTRACKED=$(git status --short 2>/dev/null | grep "^??" | wc -l)
    MODIFIED=$(git status --short 2>/dev/null | grep "^ M" | wc -l)
    
    if [ $UNTRACKED -gt 0 ] || [ $MODIFIED -gt 0 ]; then
        echo -e "${YELLOW}当前状态:${NC}"
        [ $UNTRACKED -gt 0 ] && echo "  未追踪的文件: $UNTRACKED 个"
        [ $MODIFIED -gt 0 ] && echo "  已修改的文件: $MODIFIED 个"
        echo ""
        git status --short 2>/dev/null | head -10
        echo ""
        echo -e "查看详情: ${GREEN}git status${NC}"
    else
        echo -e "${GREEN}✓ 工作目录干净${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  不是 git 仓库，跳过检查${NC}"
fi
echo ""

# ============================================
# 后续操作提示
# ============================================
echo "=== 下一步操作 ==="
echo "清理完成后，你可以选择："
echo ""
echo "方案 A: 完整重新验证（推荐）"
echo -e "   ${GREEN}./Step/verify-project.sh${NC}"
echo -e "   ${BLUE}# 会自动安装依赖、编译、测试、生成覆盖率${NC}"
echo ""
echo "方案 B: 手动逐步执行"
echo -e "   ${GREEN}npm install${NC}              # 1. 安装依赖"
echo -e "   ${GREEN}npx hardhat compile${NC}      # 2. 编译合约"
echo -e "   ${GREEN}npx hardhat test${NC}         # 3. 运行测试"
echo -e "   ${GREEN}npx hardhat coverage${NC}     # 4. 生成覆盖率"
echo ""
echo "方案 C: 重新设置环境（如果清理了环境文件）"
echo -e "   ${GREEN}./Step/setup.sh${NC}"
echo -e "   ${GREEN}source ./Step/activate-env.sh${NC}"
echo ""

# ============================================
# 显示磁盘空间
# ============================================
echo "=== 磁盘空间 ==="
AFTER_SIZE=$(du -sh . 2>/dev/null | cut -f1)
echo "  清理前: $BEFORE_SIZE"
echo "  清理后: $AFTER_SIZE"
echo ""

echo -e "${GREEN}✓ 清理脚本执行完毕${NC}"
echo ""

# ============================================
# 快速重新验证提示
# ============================================
if [ "$CLEANED_COUNT" -gt 0 ]; then
    echo -e "${BLUE}💡 提示: 现在可以重新验证项目${NC}"
    echo ""
    echo "运行完整验证（推荐）："
    echo -e "  ${GREEN}./Step/verify-project.sh${NC}"
    echo ""
    echo "或者单独运行："
    echo -e "  ${GREEN}npm install && npx hardhat compile && npx hardhat test${NC}"
    echo ""
fi
