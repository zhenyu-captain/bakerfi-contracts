#!/bin/bash
# Mythril 符号执行分析（基于 Slither 数据）

set +e  # 允许错误继续执行

# 清理函数（Ctrl+C 时调用）
cleanup() {
    echo ""
    echo -e "${YELLOW}⚠ 分析被中断${NC}"
    echo "清理临时文件..."
    rm -f "${OUTPUT_DIR}"/temp-*.bin
    rm -f "${OUTPUT_DIR}"/temp-*.json
    rm -f "${OUTPUT_DIR}"/*.tmp
    echo "已保存的结果可在 ${OUTPUT_DIR} 查看"
    exit 130
}

# 捕获中断信号
trap cleanup SIGINT SIGTERM

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== BakerFi Mythril 符号执行分析工具 ===${NC}\n"

# 切换到项目根目录
cd "$(dirname "$0")/../../.."
PROJECT_ROOT=$(pwd)
OUTPUT_DIR="handbooks/fucktest/mythril_analysis/symbolic-execution"

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 检查 myth 是否安装
if ! command -v myth &> /dev/null; then
    echo -e "${RED}✗ Mythril 未安装${NC}"
    echo "请安装: pip install mythril"
    exit 1
fi

echo -e "${GREEN}✓ Mythril 已安装: $(myth version 2>&1 | grep -v Warning | head -1)${NC}"
echo "📁 输出目录: $OUTPUT_DIR"
echo ""

# 检查 Slither 分析结果
SLITHER_DIR="handbooks/fucktest/slither_analysis"
echo -e "${BLUE}📊 读取 Slither 分析数据...${NC}"

# 1. 检测器结果
DETECTOR_FILE=$(ls -t "$SLITHER_DIR/detectors/"full-scan-*.json 2>/dev/null | head -1)
if [ -f "$DETECTOR_FILE" ]; then
    HIGH_COUNT=$(jq '[.results.detectors[] | select(.impact=="High")] | length' "$DETECTOR_FILE" 2>/dev/null || echo 0)
    MEDIUM_COUNT=$(jq '[.results.detectors[] | select(.impact=="Medium")] | length' "$DETECTOR_FILE" 2>/dev/null || echo 0)
    echo -e "${GREEN}✓ Detectors: ${HIGH_COUNT} 个高危, ${MEDIUM_COUNT} 个中危${NC}"
else
    echo -e "${YELLOW}⚠ 未找到检测结果（建议先运行 slither_analysis/extract-detectors.sh）${NC}"
    HIGH_COUNT=0
    MEDIUM_COUNT=0
fi

# 2. ABI 数据
ABI_COUNT=$(find "$SLITHER_DIR/abi" -name "*.json" 2>/dev/null | wc -l)
echo -e "${GREEN}✓ ABI: ${ABI_COUNT} 个合约${NC}"

# 3. Contract Summary
CONTRACT_SUMMARY=$(ls -t "$SLITHER_DIR/contract-summary/"*.txt 2>/dev/null | head -1)
if [ -f "$CONTRACT_SUMMARY" ]; then
    CONTRACT_COUNT=$(grep -c "^+ Contract" "$CONTRACT_SUMMARY" 2>/dev/null || echo 0)
    echo -e "${GREEN}✓ Contract Summary: ${CONTRACT_COUNT} 个合约${NC}"
fi

echo ""

# 显示分析模式
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "${YELLOW}选择分析模式:${NC}"
echo ""
echo -e "  ${GREEN}[5]${NC} 高危自动分析 ⭐ ${YELLOW}(推荐)${NC} - 基于 Slither 高危问题"
echo -e "      分析范围: 有高危问题的合约（Slither 检测到 ${HIGH_COUNT} 个高危问题）"
echo -e "      推荐超时: 900秒 (15分钟)"
echo ""
echo -e "  ${GREEN}[2]${NC} 标准扫描 - 审计主力"
echo -e "      分析范围: 核心合约 (Vault, VaultBase, StrategyLeverage)"
echo -e "      推荐超时: 900秒 (15分钟)"
echo ""
echo -e "  ${GREEN}[3]${NC} 深度扫描 - 核心模块验证"
echo -e "      分析范围: 手动指定单个合约"
echo -e "      推荐超时: 3600秒 (60分钟)"
echo ""
echo -e "  ${GREEN}[4]${NC} 单合约分析 - 问题复现"
echo -e "      分析范围: 手动指定，生成 JSON + Markdown"
echo -e "      推荐超时: 900秒 (15分钟)"
echo ""
echo -e "  ${GREEN}[1]${NC} 快速扫描 - CI/CD 集成"
echo -e "      分析范围: 核心合约 (同标准扫描)"
echo -e "      推荐超时: 300秒 (5分钟)"
echo ""
echo -e "${BLUE}输入格式:${NC} ${GREEN}模式-超时秒数${NC} 或 ${GREEN}模式${NC}"
echo -e "  示例: ${GREEN}5-120${NC} (模式5, 120秒超时)"
echo -e "        ${GREEN}2-600${NC} (模式2, 600秒/10分钟超时)"  
echo -e "        ${GREEN}5${NC} (模式5, 使用推荐的900秒)"
echo ""
read -p "请输入: " INPUT

# 解析输入: 模式-超时 或 模式
if [[ "$INPUT" == *-* ]]; then
    MODE="${INPUT%%-*}"      # 提取 "-" 前面的部分
    USER_TIMEOUT="${INPUT##*-}"  # 提取 "-" 后面的部分
else
    MODE="$INPUT"
    USER_TIMEOUT=""
fi

case $MODE in
    1)
        DEFAULT_TIMEOUT=300
        MODE_NAME="quick"
        TARGET_TYPE="batch"
        ;;
    2)
        DEFAULT_TIMEOUT=900
        MODE_NAME="standard"
        TARGET_TYPE="batch"
        ;;
    3)
        DEFAULT_TIMEOUT=3600
        MODE_NAME="deep"
        TARGET_TYPE="single"
        echo ""
        echo "可用的核心合约:"
        ls contracts/core/*.sol 2>/dev/null | head -10
        echo ""
        read -p "请输入合约路径: " CONTRACT_FILE
        ;;
    4)
        DEFAULT_TIMEOUT=900
        MODE_NAME="single"
        TARGET_TYPE="single-full"
        echo ""
        echo "可用的核心合约:"
        ls contracts/core/*.sol 2>/dev/null | head -10
        echo ""
        read -p "请输入合约路径: " CONTRACT_FILE
        ;;
    5)
        DEFAULT_TIMEOUT=900
        MODE_NAME="slither-high"
        TARGET_TYPE="slither-based"
        ;;
    *)
        echo -e "${RED}无效选择${NC}"
        exit 1
        ;;
esac

# 应用用户自定义超时或使用默认值
if [ -n "$USER_TIMEOUT" ]; then
    # 验证是否为数字
    if [[ "$USER_TIMEOUT" =~ ^[0-9]+$ ]] && [ "$USER_TIMEOUT" -gt 0 ]; then
        TIMEOUT=$USER_TIMEOUT
        echo -e "${GREEN}✓ 使用自定义超时: ${TIMEOUT} 秒 ($(($TIMEOUT/60))分钟)${NC}"
    else
        echo -e "${RED}✗ 无效的超时时间: $USER_TIMEOUT${NC}"
        echo "使用推荐超时: $DEFAULT_TIMEOUT 秒"
        TIMEOUT=$DEFAULT_TIMEOUT
    fi
else
    TIMEOUT=$DEFAULT_TIMEOUT
    echo -e "${GREEN}✓ 使用推荐超时: ${TIMEOUT} 秒 ($(($TIMEOUT/60))分钟)${NC}"
fi

# 显示选择的模式信息
echo ""
case $MODE in
    1) echo -e "${GREEN}✓ 模式 [1]: 快速扫描${NC}" ;;
    2) echo -e "${GREEN}✓ 模式 [2]: 标准扫描${NC}" ;;
    3) echo -e "${GREEN}✓ 模式 [3]: 深度扫描 - $CONTRACT_FILE${NC}" ;;
    4) echo -e "${GREEN}✓ 模式 [4]: 单合约分析 - $CONTRACT_FILE${NC}" ;;
    5) 
        echo -e "${GREEN}✓ 模式 [5]: 高危自动分析${NC}"
        if [ "$HIGH_COUNT" -gt 0 ] && [ -f "$DETECTOR_FILE" ]; then
            echo ""
            echo "从 Slither 提取高危合约..."
            mapfile -t HIGH_CONTRACTS < <(jq -r '.results.detectors[] | select(.impact=="High") | .elements[0].source_mapping.filename_short' "$DETECTOR_FILE" 2>/dev/null | sort -u)
            echo -e "${GREEN}找到 ${#HIGH_CONTRACTS[@]} 个高危合约:${NC}"
            for contract in "${HIGH_CONTRACTS[@]}"; do
                echo "  - $contract"
            done
        else
            echo -e "${RED}✗ 未找到高危问题，无法使用此模式${NC}"
            exit 1
        fi
        ;;
esac

echo ""
echo -e "${YELLOW}🔍 开始符号执行分析...${NC}"
echo ""

# ============================================
# 执行分析
# ============================================

if [ "$TARGET_TYPE" = "slither-based" ]; then
    # 模式 5: 基于 Slither 高危问题
    OUTPUT_DIR_RESULTS="${OUTPUT_DIR}/results-mode5-${TIMESTAMP}"
    OUTPUT_FILE="${OUTPUT_DIR_RESULTS}/summary.json"
    
    # 创建结果目录
    mkdir -p "$OUTPUT_DIR_RESULTS"
    
    cat > "$OUTPUT_FILE" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "mode": "slither-high",
  "timeout": $TIMEOUT,
  "slither_data": {
    "detector_file": "$(basename "$DETECTOR_FILE")",
    "high_count": $HIGH_COUNT,
    "medium_count": $MEDIUM_COUNT,
    "contracts_count": ${#HIGH_CONTRACTS[@]}
  },
  "contracts": []
}
EOF
    
    # 分析每个高危合约
    TOTAL_CONTRACTS=${#HIGH_CONTRACTS[@]}
    CURRENT=0
    
    echo -e "${BLUE}准备分析 ${TOTAL_CONTRACTS} 个合约...${NC}"
    
    for contract in "${HIGH_CONTRACTS[@]}"; do
        CURRENT=$((CURRENT + 1))
        echo ""
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}进度: ${CURRENT}/${TOTAL_CONTRACTS}${NC}"
        
        if [ -f "$contract" ]; then
            CONTRACT_NAME=$(basename "$contract" .sol)
            echo "  📝 分析: $contract"
            
            # 使用 Hardhat artifacts（已编译的字节码）
            ARTIFACT_PATH="artifacts/${contract}/${CONTRACT_NAME}.json"
            
            if [ -f "$ARTIFACT_PATH" ]; then
                echo "    ↳ 使用 Hardhat artifact: ${CONTRACT_NAME}.json"
                
                # 从 artifact 提取 bytecode
                BYTECODE=$(jq -r '.deployedBytecode' "$ARTIFACT_PATH" 2>/dev/null)
                
                if [ "$BYTECODE" != "null" ] && [ -n "$BYTECODE" ]; then
                    # 创建临时 bytecode 文件
                    echo "$BYTECODE" > "${OUTPUT_DIR}/temp-${CONTRACT_NAME}.bin"
                    
                    # 每个合约的结果单独保存
                    CONTRACT_RESULT="${OUTPUT_DIR_RESULTS}/${CONTRACT_NAME}.json"
                    
                    echo "    ↳ 运行符号执行（强制超时: ${TIMEOUT}秒）..."
                    START_TIME=$(date +%s)
                    
                    # 使用 timeout 命令强制限制执行时间
                    timeout ${TIMEOUT}s myth analyze -f "${OUTPUT_DIR}/temp-${CONTRACT_NAME}.bin" \
                        --execution-timeout $TIMEOUT \
                        -o json \
                        2>&1 | grep -v "Warning" | grep "^{" > "$CONTRACT_RESULT" || echo '{"success": false, "error": "Analysis timeout or failed", "issues": []}' > "$CONTRACT_RESULT"
                    
                    END_TIME=$(date +%s)
                    ELAPSED=$((END_TIME - START_TIME))
                    
                    # 清理临时文件
                    rm -f "${OUTPUT_DIR}/temp-${CONTRACT_NAME}.bin"
                    
                    # 立即保存结果到主文件（增量更新）
                    if [ -f "$CONTRACT_RESULT" ] && [ -s "$CONTRACT_RESULT" ]; then
                        ISSUE_COUNT=$(jq '.issues | length' "$CONTRACT_RESULT" 2>/dev/null || echo 0)
                        echo -e "    ${GREEN}✓${NC} 完成 (${ELAPSED}秒) - 发现 ${ISSUE_COUNT} 个问题"
                        echo "    ↳ 已保存: ${CONTRACT_NAME}.json"
                        
                        # 更新主 JSON 文件
                        jq --arg contract "$contract" \
                           --arg contract_name "$CONTRACT_NAME" \
                           --arg result_file "${CONTRACT_NAME}.json" \
                           --slurpfile analysis "$CONTRACT_RESULT" \
                           '.contracts += [{"contract": $contract, "contract_name": $contract_name, "result_file": $result_file, "analysis": $analysis[0]}]' \
                           "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"
                    else
                        echo "    ✗ 分析失败"
                    fi
                else
                    echo "    ✗ 无法提取 bytecode"
                fi
            else
                echo "    ⚠ 未找到 artifact，请先编译: npx hardhat compile"
            fi
        else
            echo "  ⚠ 文件不存在: $contract"
        fi
    done
    
    echo ""
    echo -e "${GREEN}✓ 高危合约分析完成${NC}"
    
    # 清理所有临时文件
    rm -f "${OUTPUT_DIR}"/temp-*.bin
    rm -f "${OUTPUT_DIR}"/temp-*.json
    rm -f "${OUTPUT_FILE}".tmp

elif [ "$TARGET_TYPE" = "single-full" ]; then
    # 模式 4: 单合约，生成 JSON + Markdown
    if [ -z "$CONTRACT_FILE" ] || [ ! -f "$CONTRACT_FILE" ]; then
        echo -e "${RED}✗ 合约文件不存在${NC}"
        exit 1
    fi
    
    CONTRACT_NAME=$(basename "$CONTRACT_FILE" .sol)
    OUTPUT_DIR_RESULTS="${OUTPUT_DIR}/results-mode4-${TIMESTAMP}"
    mkdir -p "$OUTPUT_DIR_RESULTS"
    
    OUTPUT_JSON="${OUTPUT_DIR_RESULTS}/${CONTRACT_NAME}.json"
    OUTPUT_MD="${OUTPUT_DIR_RESULTS}/${CONTRACT_NAME}.md"
    
    echo "  📝 分析: $CONTRACT_FILE"
    echo ""
    
    # 使用 Hardhat artifacts（已编译的字节码）
    ARTIFACT_PATH="artifacts/${CONTRACT_FILE}/${CONTRACT_NAME}.json"
    
    if [ -f "$ARTIFACT_PATH" ]; then
        echo "    ↳ 使用 Hardhat artifact: ${CONTRACT_NAME}.json"
        
        # 从 artifact 提取 bytecode
        BYTECODE=$(jq -r '.deployedBytecode' "$ARTIFACT_PATH" 2>/dev/null)
        
        if [ "$BYTECODE" != "null" ] && [ -n "$BYTECODE" ]; then
            # 创建临时 bytecode 文件
            echo "$BYTECODE" > "${OUTPUT_DIR}/temp-${CONTRACT_NAME}.bin"
            
            # 生成 JSON 报告
            echo "    ↳ 生成 JSON 报告（强制超时: ${TIMEOUT}秒）..."
            START_TIME=$(date +%s)
            
            timeout ${TIMEOUT}s myth analyze -f "${OUTPUT_DIR}/temp-${CONTRACT_NAME}.bin" \
                --execution-timeout $TIMEOUT \
                -o json \
                2>&1 | grep -v "Warning" | grep "^{" > "$OUTPUT_JSON" || echo '{"success": false, "error": "Analysis timeout or failed", "issues": []}' > "$OUTPUT_JSON"
            
            END_TIME=$(date +%s)
            ELAPSED_JSON=$((END_TIME - START_TIME))
            
            # 生成 Markdown 报告
            echo "    ↳ 生成 Markdown 报告（强制超时: ${TIMEOUT}秒）..."
            START_TIME=$(date +%s)
            
            timeout ${TIMEOUT}s myth analyze -f "${OUTPUT_DIR}/temp-${CONTRACT_NAME}.bin" \
                --execution-timeout $TIMEOUT \
                -o markdown \
                > "$OUTPUT_MD" 2>&1 || echo "# Analysis Timeout" > "$OUTPUT_MD"
            
            END_TIME=$(date +%s)
            ELAPSED_MD=$((END_TIME - START_TIME))
            
            # 清理临时文件
            rm -f "${OUTPUT_DIR}/temp-${CONTRACT_NAME}.bin"
            
            if [ -f "$OUTPUT_JSON" ] && [ -s "$OUTPUT_JSON" ]; then
                ISSUE_COUNT=$(jq '.issues | length' "$OUTPUT_JSON" 2>/dev/null || echo 0)
                echo -e "    ${GREEN}✓${NC} JSON 完成 (${ELAPSED_JSON}秒) - 发现 ${ISSUE_COUNT} 个问题"
                echo -e "    ${GREEN}✓${NC} Markdown 完成 (${ELAPSED_MD}秒)"
            fi
        else
            echo -e "    ${RED}✗ 无法提取 bytecode${NC}"
            echo '{"success": false, "error": "Cannot extract bytecode from artifact", "issues": []}' > "$OUTPUT_JSON"
            echo "# Error: Cannot extract bytecode from artifact" > "$OUTPUT_MD"
        fi
    else
        echo -e "    ${RED}✗ 未找到 artifact，请先编译: npx hardhat compile${NC}"
        echo '{"success": false, "error": "Artifact not found. Please run: npx hardhat compile", "issues": []}' > "$OUTPUT_JSON"
        echo "# Error: Artifact not found\n\nPlease run: \`npx hardhat compile\`" > "$OUTPUT_MD"
    fi
    
    echo -e "${GREEN}✓ 单合约分析完成${NC}"
    echo "  JSON: $(basename "$OUTPUT_JSON")"
    echo "  MD:   $(basename "$OUTPUT_MD")"

elif [ "$TARGET_TYPE" = "single" ]; then
    # 模式 3: 深度扫描单个合约
    if [ -z "$CONTRACT_FILE" ] || [ ! -f "$CONTRACT_FILE" ]; then
        echo -e "${RED}✗ 合约文件不存在${NC}"
        exit 1
    fi
    
    CONTRACT_NAME=$(basename "$CONTRACT_FILE" .sol)
    OUTPUT_DIR_RESULTS="${OUTPUT_DIR}/results-mode3-${TIMESTAMP}"
    mkdir -p "$OUTPUT_DIR_RESULTS"
    
    OUTPUT_JSON="${OUTPUT_DIR_RESULTS}/${CONTRACT_NAME}-deep.json"
    
    echo "  📝 深度分析: $CONTRACT_FILE"
    echo "  （强制超时: ${TIMEOUT}秒）"
    echo ""
    
    # 使用 Hardhat artifacts（已编译的字节码）
    ARTIFACT_PATH="artifacts/${CONTRACT_FILE}/${CONTRACT_NAME}.json"
    
    if [ -f "$ARTIFACT_PATH" ]; then
        echo "    ↳ 使用 Hardhat artifact: ${CONTRACT_NAME}.json"
        
        # 从 artifact 提取 bytecode
        BYTECODE=$(jq -r '.deployedBytecode' "$ARTIFACT_PATH" 2>/dev/null)
        
        if [ "$BYTECODE" != "null" ] && [ -n "$BYTECODE" ]; then
            # 创建临时 bytecode 文件
            echo "$BYTECODE" > "${OUTPUT_DIR}/temp-${CONTRACT_NAME}.bin"
            
            echo "    ↳ 运行符号执行（强制超时: ${TIMEOUT}秒）..."
            START_TIME=$(date +%s)
            
            # 使用 timeout 命令强制限制执行时间
            timeout ${TIMEOUT}s myth analyze -f "${OUTPUT_DIR}/temp-${CONTRACT_NAME}.bin" \
                --execution-timeout $TIMEOUT \
                -o json \
                2>&1 | grep -v "Warning" | grep "^{" > "$OUTPUT_JSON" || echo '{"success": false, "error": "Analysis timeout or failed", "issues": []}' > "$OUTPUT_JSON"
            
            END_TIME=$(date +%s)
            ELAPSED=$((END_TIME - START_TIME))
            
            # 清理临时文件
            rm -f "${OUTPUT_DIR}/temp-${CONTRACT_NAME}.bin"
            
            if [ -f "$OUTPUT_JSON" ] && [ -s "$OUTPUT_JSON" ]; then
                ISSUE_COUNT=$(jq '.issues | length' "$OUTPUT_JSON" 2>/dev/null || echo 0)
                echo -e "    ${GREEN}✓${NC} 完成 (${ELAPSED}秒) - 发现 ${ISSUE_COUNT} 个问题"
            fi
        else
            echo -e "    ${RED}✗ 无法提取 bytecode${NC}"
            echo '{"success": false, "error": "Cannot extract bytecode from artifact", "issues": []}' > "$OUTPUT_JSON"
        fi
    else
        echo -e "    ${RED}✗ 未找到 artifact，请先编译: npx hardhat compile${NC}"
        echo '{"success": false, "error": "Artifact not found. Please run: npx hardhat compile", "issues": []}' > "$OUTPUT_JSON"
    fi
    
    echo -e "${GREEN}✓ 深度扫描完成${NC}"
    echo "  JSON: $(basename "$OUTPUT_JSON")"

elif [ "$TARGET_TYPE" = "batch" ]; then
    # 模式 1/2: 批量分析核心合约
    OUTPUT_DIR_RESULTS="${OUTPUT_DIR}/results-mode${MODE}-${TIMESTAMP}"
    OUTPUT_FILE="${OUTPUT_DIR_RESULTS}/summary.json"
    
    # 创建结果目录
    mkdir -p "$OUTPUT_DIR_RESULTS"
    
    # 从 Slither ABI 目录自动获取所有核心合约
    echo "从 Slither ABI 数据获取核心合约列表..."
    
    ABI_DIR="$SLITHER_DIR/abi"
    CORE_CONTRACTS=()
    
    # 遍历 ABI 目录，映射到源文件
    for abi_file in "$ABI_DIR"/*.json; do
        if [ -f "$abi_file" ]; then
            CONTRACT_NAME=$(basename "$abi_file" .json)
            
            # 查找对应的源文件（优先 contracts/core/）
            if [ -f "contracts/core/${CONTRACT_NAME}.sol" ]; then
                CORE_CONTRACTS+=("contracts/core/${CONTRACT_NAME}.sol")
            elif [ -f "contracts/core/strategies/${CONTRACT_NAME}.sol" ]; then
                CORE_CONTRACTS+=("contracts/core/strategies/${CONTRACT_NAME}.sol")
            elif [ -f "contracts/core/flashloan/${CONTRACT_NAME}.sol" ]; then
                CORE_CONTRACTS+=("contracts/core/flashloan/${CONTRACT_NAME}.sol")
            fi
        fi
    done
    
    echo -e "${GREEN}✓ 从 Slither ABI 找到 ${#CORE_CONTRACTS[@]} 个核心合约${NC}"
    
    if [ ${#CORE_CONTRACTS[@]} -eq 0 ]; then
        echo -e "${RED}✗ 未找到核心合约${NC}"
        exit 1
    fi
    
    echo "将分析以下合约:"
    for contract in "${CORE_CONTRACTS[@]}"; do
        echo "  - $contract"
    done
    echo ""
    
    cat > "$OUTPUT_FILE" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "mode": "$MODE_NAME",
  "timeout": $TIMEOUT,
  "slither_data": {
    "abi_count": $ABI_COUNT,
    "detector_high": $HIGH_COUNT,
    "detector_medium": $MEDIUM_COUNT
  },
  "contracts_count": ${#CORE_CONTRACTS[@]},
  "contracts": []
}
EOF
    
    # 分析每个合约
    TOTAL_CONTRACTS=${#CORE_CONTRACTS[@]}
    CURRENT=0
    
    for contract in "${CORE_CONTRACTS[@]}"; do
        CURRENT=$((CURRENT + 1))
        echo ""
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}进度: ${CURRENT}/${TOTAL_CONTRACTS}${NC}"
        if [ -f "$contract" ]; then
            CONTRACT_NAME=$(basename "$contract" .sol)
            echo "  📝 分析: $contract"
            
            # 使用 Hardhat artifacts（已编译的字节码）
            ARTIFACT_PATH="artifacts/${contract}/${CONTRACT_NAME}.json"
            
            if [ -f "$ARTIFACT_PATH" ]; then
                echo "    ↳ 使用 Hardhat artifact"
                
                BYTECODE=$(jq -r '.deployedBytecode' "$ARTIFACT_PATH" 2>/dev/null)
                
                if [ "$BYTECODE" != "null" ] && [ -n "$BYTECODE" ]; then
                    echo "$BYTECODE" > "${OUTPUT_DIR}/temp-${CONTRACT_NAME}.bin"
                    
                    # 每个合约的结果单独保存
                    CONTRACT_RESULT="${OUTPUT_DIR_RESULTS}/${CONTRACT_NAME}.json"
                    
                    echo "    ↳ 运行符号执行（强制超时: ${TIMEOUT}秒）..."
                    START_TIME=$(date +%s)
                    
                    timeout ${TIMEOUT}s myth analyze -f "${OUTPUT_DIR}/temp-${CONTRACT_NAME}.bin" \
                        --execution-timeout $TIMEOUT \
                        -o json \
                        2>&1 | grep -v "Warning" | grep "^{" > "$CONTRACT_RESULT" || echo '{"success": false, "error": "Analysis timeout or failed", "issues": []}' > "$CONTRACT_RESULT"
                    
                    END_TIME=$(date +%s)
                    ELAPSED=$((END_TIME - START_TIME))
                    
                    rm -f "${OUTPUT_DIR}/temp-${CONTRACT_NAME}.bin"
                    
                    # 立即保存结果
                    if [ -f "$CONTRACT_RESULT" ] && [ -s "$CONTRACT_RESULT" ]; then
                        ISSUE_COUNT=$(jq '.issues | length' "$CONTRACT_RESULT" 2>/dev/null || echo 0)
                        echo -e "    ${GREEN}✓${NC} 完成 (${ELAPSED}秒) - 发现 ${ISSUE_COUNT} 个问题"
                        echo "    ↳ 已保存: ${CONTRACT_NAME}.json"
                        
                        # 更新主 JSON 文件
                        jq --arg contract "$contract" \
                           --arg contract_name "$CONTRACT_NAME" \
                           --arg result_file "${CONTRACT_NAME}.json" \
                           --slurpfile analysis "$CONTRACT_RESULT" \
                           '.contracts += [{"contract": $contract, "contract_name": $contract_name, "result_file": $result_file, "analysis": $analysis[0]}]' \
                           "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"
                    else
                        echo "    ✗ 分析失败"
                    fi
                fi
            else
                echo "    ⚠ 未找到 artifact，跳过"
            fi
        fi
    done
    
    echo ""
    echo -e "${GREEN}✓ 批量分析完成${NC}"
    
    # 清理所有临时文件
    rm -f "${OUTPUT_DIR}"/temp-*.bin
    rm -f "${OUTPUT_DIR}"/temp-*.json
    rm -f "${OUTPUT_FILE}".tmp
fi

# ============================================
# 显示结果
# ============================================
echo ""
echo -e "${GREEN}=== 完成! ===${NC}"
echo "结果目录: ${OUTPUT_DIR_RESULTS}"
echo ""

# 统计
if [ -d "$OUTPUT_DIR_RESULTS" ]; then
    json_count=$(find "$OUTPUT_DIR_RESULTS" -name "*.json" 2>/dev/null | wc -l)
    md_count=$(find "$OUTPUT_DIR_RESULTS" -name "*.md" 2>/dev/null | wc -l)
    
    echo "生成的文件:"
    ls -1 "$OUTPUT_DIR_RESULTS"/ | sed 's/^/  /'
    echo ""
    
    echo "统计信息:"
    echo "  JSON 文件: ${json_count} 个"
    echo "  Markdown 文件: ${md_count} 个"
    echo ""
    
    echo "查看报告:"
    if [ -f "${OUTPUT_DIR_RESULTS}/summary.json" ]; then
        echo "  # 查看汇总"
        echo "  cat ${OUTPUT_DIR_RESULTS}/summary.json | jq ."
        echo ""
        echo "  # 查看所有问题"
        echo "  jq '.contracts[].analysis.issues' ${OUTPUT_DIR_RESULTS}/summary.json"
        echo ""
        echo "  # 查看单个合约"
        echo "  cat ${OUTPUT_DIR_RESULTS}/ContractName.json | jq ."
    else
        echo "  cat ${OUTPUT_DIR_RESULTS}/*.json | jq ."
        if [ "$md_count" -gt 0 ]; then
            echo "  cat ${OUTPUT_DIR_RESULTS}/*.md | less"
        fi
    fi
fi
echo ""

# 显示 Slither 数据利用情况
echo -e "${BLUE}📊 Slither 数据利用情况:${NC}"
if [ "$TARGET_TYPE" = "slither-based" ]; then
    echo "  ✅ 分析目标: 从 Slither detectors 自动选择（高危合约）"
    echo "  ✅ 上下文: 包含 Slither 统计数据"
elif [ "$TARGET_TYPE" = "batch" ]; then
    echo "  ✅ 分析目标: 从 Slither ABI 自动获取（所有核心合约）"
    echo "  ✅ 上下文: 包含 Slither 统计数据"
else
    echo "  ⚠️  分析目标: 手动指定"
    echo "  ✅ 上下文: 包含 Slither 统计数据"
fi
echo ""
