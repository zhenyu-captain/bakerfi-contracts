# BakerFi Vault 的 98 个测试用例
* 1013 ✅ 完成 npx hardhat test test/core/vault/Vault.ts --grep "Deposit - 0 ETH"，属于安全覆盖测试。
* 1014 ✅ 完成 npx hardhat test test/core/vault/Vault.ts --grep "Withdraw failed not enough brETH"，属于安全覆盖测试。

### 参考流程
1. 📖 阅读测试代码（5-10分钟）
   ├─ 理解测试意图
   ├─ 找到关键断言
   └─ 识别测试类型
2. 🔍 定位合约代码（10-15分钟）
   ├─ 找到被测试的函数
   ├─ 追踪调用链
   └─ 理解实现逻辑
3. ▶️ 运行单个测试（2-3分钟）
   └─ npx hardhat test --grep "测试名称"
4. 🧪 修改测试实验（10-20分钟）
   ├─ 改变输入值
   ├─ 观察失败原因
   └─ 验证边界条件
5. 🔧 工具验证（可选，10-15分钟）
   ├─ Slither 静态分析
   ├─ Echidna 模糊测试
   └─ Mythril 符号执行
6. 📝 编写总结（15-30分钟）
   ├─ 测试目标
   ├─ 实现原理
   ├─ 安全威胁
   └─ 最佳实践

---

## 🔧 常用命令
```bash
# 运行所有 Vault 测试
npx hardhat test test/core/vault/Vault.ts

# 运行单个测试
npx hardhat test test/core/vault/Vault.ts --grep "Deposit - 0 ETH"

# 运行当前模块（2.1）
npx hardhat test test/core/vault/Vault.ts --grep "0 ETH|not enough|Zero|10 Wei|minimum"

# 带覆盖率
npx hardhat coverage --testfiles "test/core/vault/Vault.ts"

# 带 Gas 报告
REPORT_GAS=true npx hardhat test test/core/vault/Vault.ts
```

### 代码分析
```bash
# Slither 静态分析
slither contracts/core/VaultBase.sol

# 查找零值检查
grep -n "== 0) revert" contracts/core/VaultBase.sol

# 查找所有错误定义
grep -n "^  error" contracts/core/VaultBase.sol
```
