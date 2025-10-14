# Slither 静态分析工具集

完整的 Slither 分析工具，包含检测器、图表生成和 ABI/AST 提取。

---

## 📁 目录结构

```
slither_analysis/
├── abi/              # 合约 ABI (31个)
├── ast/              # 抽象语法树 (33个)
├── detectors/        # 安全检测结果
│   ├── full-scan-*.json      # 完整检测JSON
│   ├── high-severity-*.json  # 高危问题
│   ├── medium-severity-*.json # 中危问题
│   ├── summary-*.md          # 可读报告
│   └── latest.json           # 最新结果链接
├── reports/          # Slither Printers 输出
│   ├── contract-summary-*.txt
│   ├── function-summary-*.txt
│   ├── data-dependency-*.txt
│   └── slithir-*.txt
├── graphs/           # 可视化图表
│   ├── call-graph-*.dot/png
│   ├── inheritance-*.dot/png
│   └── *.dot 文件
└── 工具脚本
    ├── run-detectors.sh  # 运行所有检测器
    ├── run-printers.sh   # 生成图表和报告
    ├── extract-abi.sh    # 提取 ABI
    ├── extract-ast.sh    # 提取 AST
    └── check.sh          # 完整性检查
```

---

## 🚀 快速使用

### 1. 运行安全检测 (--detect all)

```bash
./run-detectors.sh
```

**输出：**
- `detectors/full-scan-TIMESTAMP.json` - 完整检测结果
- `detectors/high-severity-TIMESTAMP.json` - 高危问题
- `detectors/medium-severity-TIMESTAMP.json` - 中危问题
- `detectors/low-severity-TIMESTAMP.json` - 低危问题
- `detectors/summary-TIMESTAMP.md` - 可读报告

**查看结果：**
```bash
# 查看摘要报告
cat detectors/latest-report.md

# 查看高危问题
jq . detectors/high-severity-*.json

# 统计问题数量
jq -s 'length' detectors/high-severity-*.json
```

---

### 2. 生成分析图表

```bash
./run-printers.sh
```

**输出：**
- **合约摘要**: `reports/contract-summary-*.txt`
- **函数摘要**: `reports/function-summary-*.txt`  
- **调用图**: `graphs/call-graph-*.dot` (可视化)
- **继承图**: `graphs/inheritance-*.dot` (可视化)
- **数据依赖**: `reports/data-dependency-*.txt`
- **SlithIR**: `reports/slithir-*.txt` (控制流)

**查看图表：**
```bash
# 如果安装了 graphviz
dot -Tpng graphs/latest-call-graph.dot -o call-graph.png
open call-graph.png

# 在线查看 dot 文件
# 访问 https://dreampuf.github.io/GraphvizOnline/
```

---

### 3. 提取 ABI/AST

```bash
# 提取 ABI
./extract-abi.sh

# 提取 AST
./extract-ast.sh

# 检查完整性
./check.sh
```

---

## 📊 检测器优先级

| 优先级 | 检测器 | 说明 | 严重性 |
|-------|--------|------|--------|
| 🔴 1 | `reentrancy-eth` | 以太坊重入攻击 | High |
| 🔴 2 | `controlled-delegatecall` | 可控 delegatecall | High |
| 🔴 3 | `unprotected-upgrade` | 未保护升级 | High |
| 🔴 4 | `suicidal` | 自毁函数 | High |
| 🟡 5 | `unchecked-transfer` | 未检查转账 | Medium |
| 🟡 6 | `tx-origin` | tx.origin 认证 | Medium |
| 🟢 7 | `costly-loop` | 昂贵循环 | Optimization |

---

## 🔍 结果分析

### 查看特定类型问题

```bash
# 重入攻击
jq '.results.detectors[] | select(.check=="reentrancy-eth")' \
  detectors/latest.json

# 升级安全问题
jq '.results.detectors[] | select(.check=="unprotected-upgrade")' \
  detectors/latest.json

# 所有高危问题的检测器名称
jq '.results.detectors[] | select(.impact=="High") | .check' \
  detectors/latest.json | sort -u
```

### 按合约过滤

```bash
# 只看 Vault.sol 的问题
jq '.results.detectors[] | select(.elements[].source_mapping.filename_short | contains("Vault.sol"))' \
  detectors/latest.json
```

### 导出为 CSV

```bash
# 问题列表导出
jq -r '.results.detectors[] | [.check, .impact, .confidence, (.description | gsub("\n"; " "))] | @csv' \
  detectors/latest.json > issues.csv
```

---

## 📈 报告格式

### summary-TIMESTAMP.md 示例

```markdown
# Slither 安全检测报告

> 生成时间: 2025-10-14 23:35:00

## 📊 检测统计

| 严重性 | 数量 |
|--------|------|
| 🔴 High | 3 |
| 🟡 Medium | 15 |
| 🟢 Low | 28 |
| ℹ️ Informational | 45 |

**总计**: 91 个发现

## 🔴 高危问题

### reentrancy-eth

**影响**: High  
**置信度**: Medium

**描述**: 检测到可能的重入攻击...
```

---

## 🛠️ 高级用法

### 只运行特定检测器

```bash
slither . --detect reentrancy-eth,controlled-delegatecall \
  --json detectors/custom-scan.json
```

### 针对单个合约

```bash
slither contracts/core/Vault.sol \
  --print contract-summary \
  > reports/vault-only.txt
```

### 比较两次扫描

```bash
# 扫描当前版本
./run-detectors.sh

# 保存结果
cp detectors/latest.json detectors/before-fix.json

# 修复代码后再次扫描
./run-detectors.sh

# 对比
diff <(jq '.results.detectors[].check' detectors/before-fix.json | sort) \
     <(jq '.results.detectors[].check' detectors/latest.json | sort)
```

---

## 🎯 针对 BakerFi 的检查重点

### 1. 升级安全

```bash
# 检查存储布局
slither contracts/core/VaultBase.sol --print vars-and-auth

# 升级兼容性（如果有 V2）
slither-check-upgradeability . Vault --new-contract-name VaultV2
```

### 2. 重入风险

```bash
# 重点检查 ETH 转账函数
jq '.results.detectors[] | select(.check | contains("reentrancy"))' \
  detectors/latest.json
```

### 3. Oracle 安全

```bash
# 检查 Oracle 合约
slither contracts/oracles/ \
  --detect timestamp,weak-prng \
  > reports/oracle-security.txt
```

---

## 📚 输出文件说明

| 文件 | 内容 | 格式 |
|------|------|------|
| `full-scan-*.json` | 完整检测结果 | JSON |
| `*-severity-*.json` | 按严重性分类 | JSON |
| `summary-*.md` | 人类可读报告 | Markdown |
| `contract-summary-*.txt` | 合约结构 | Text |
| `call-graph-*.dot` | 函数调用关系 | DOT |
| `inheritance-*.dot` | 继承关系 | DOT |
| `slithir-*.txt` | 中间表示（含控制流） | Text |

---

## 🔧 依赖安装

```bash
# Slither
pip install slither-analyzer

# Graphviz (可选，用于图表可视化)
sudo apt install graphviz  # Ubuntu/Debian
brew install graphviz      # macOS

# jq (用于 JSON 处理)
sudo apt install jq
```

---

## 💡 常见问题

### Q: 检测花费时间过长？

A: 使用过滤器排除测试文件：
```bash
slither . --filter-paths "test/,node_modules/" --exclude-dependencies
```

### Q: 如何忽略特定问题？

A: 在代码中添加注释：
```solidity
// slither-disable-next-line reentrancy-eth
function withdraw() public {
    // ...
}
```

### Q: 如何生成 GitHub Actions 兼容格式？

A:
```bash
slither . --sarif results.sarif
```

---

## 🔗 相关链接

- [Slither 完整指南](../tools/slither.md)
- [检测器文档](https://github.com/crytic/slither/wiki/Detector-Documentation)
- [Printer 文档](https://github.com/crytic/slither/wiki/Printer-documentation)

---

**创建日期**: 2025-10-14  
**工具版本**: Slither 0.10.x  
**适用项目**: BakerFi Smart Contracts

