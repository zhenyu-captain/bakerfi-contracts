# 2.1 边界与零值测试 (Boundary & Zero Value Tests)

> **难度等级**：★☆☆☆☆（入门级）  
> **学习目标**：熟悉 `require` / `revert` 断言与输入校验机制  
> **测试总数**：8 个

---

## 📚 模块概述

这是安全测试的第一站，也是最基础的防护层。边界与零值测试确保合约拒绝所有无效的输入值，防止：

- ⛽ Gas 浪费
- 📊 会计系统污染
- 🔒 DoS 攻击向量
- 💼 业务逻辑错误

---

## 📋 测试清单

| # | 测试用例 | 状态 | 难度 | 关键词 |
|---|---------|------|------|--------|
| ✅ 1 | [Deposit - 0 ETH](./01_Deposit-0-ETH分析.md) | 已完成 | ★☆☆ | 零值保护 |
| ⬜ 2 | Withdraw failed not enough brETH | 待分析 | ★☆☆ | 余额不足 |
| ⬜ 3 | Deposit Failed - Zero Deposit | 待分析 | ★☆☆ | 零值保护 |
| ⬜ 4 | Deposit Failed - Zero Receiver | 待分析 | ★★☆ | 零地址保护 |
| ⬜ 5 | Mint Failed - Zero Shares | 待分析 | ★☆☆ | 零份额保护 |
| ⬜ 6 | Mint Failed - No Receiver | 待分析 | ★★☆ | 接收者验证 |
| ⬜ 7 | Deposit 10 Wei - minimum shares | 待分析 | ★★★ | **通胀攻击防护** ⭐ |
| ⬜ 8 | Withdraw - minimum shares should fail | 待分析 | ★★☆ | 最小份额保留 |

---

## 🎯 学习路径

### 第一周：零值保护（1-3）

**目标**：理解为什么要拒绝零值输入

```
Day 1-2: ✅ Deposit - 0 ETH（原生ETH）
Day 3-4: ⬜ Withdraw failed not enough brETH（份额不足）
Day 5-6: ⬜ Deposit Failed - Zero Deposit（ERC-20）
Day 7:   总结与复习
```

**产出**：
- 理解 Custom Error vs require
- 掌握零值检查的最佳位置
- 了解 Gas 优化技巧

---

### 第二周：地址验证（4, 6）

**目标**：防止资金发送到无效地址

```
Day 1-3: ⬜ Deposit Failed - Zero Receiver
Day 4-6: ⬜ Mint Failed - No Receiver
Day 7:   编写自己的零地址检查测试
```

**产出**：
- 理解零地址（0x0）的危险性
- 掌握 receiver 参数验证
- 学习 ERC-4626 的安全要求

---

### 第三周：份额保护（5, 7, 8）⭐

**目标**：防止通胀攻击和份额耗尽

```
Day 1-2: ⬜ Mint Failed - Zero Shares
Day 3-5: ⬜ Deposit 10 Wei - minimum shares（重点！）
Day 6-7: ⬜ Withdraw - minimum shares should fail
```

**产出**：
- **深入理解通胀攻击（Inflation Attack）**
- 掌握 `_MINIMUM_SHARE_BALANCE` 的作用
- 学习 DeFi Vault 的核心安全模式

---

## 🔑 核心概念

### 1. 边界值（Boundary Values）

在测试中，边界值是最容易出错的地方：

| 类型 | 边界值 | 测试覆盖 |
|------|--------|---------|
| 零值 | 0 | ✅ 测试 1, 3, 5 |
| 最小值 | 1 Wei | ✅ 测试 7 |
| 地址零值 | address(0) | ✅ 测试 4, 6 |
| 余额临界 | balance - 1 | ✅ 测试 2 |
| 份额临界 | _MINIMUM_SHARE_BALANCE | ✅ 测试 7, 8 |

---

### 2. 零值保护模式

**标准模式**：

```solidity
function deposit(uint256 amount) external {
  // ✅ 步骤 1: 立即检查零值
  if (amount == 0) revert InvalidAmount();
  
  // ✅ 步骤 2: 其他业务逻辑
  _processDeposit(amount);
}
```

**为什么不在 modifier 中检查？**

```solidity
// ❌ 不推荐：modifier 中检查零值
modifier nonZero(uint256 amount) {
  if (amount == 0) revert InvalidAmount();
  _;
}

function deposit(uint256 amount) external nonZero(amount) {
  // ...
}
```

**原因**：
- 降低代码可读性
- modifier 应该用于通用的访问控制
- 业务逻辑检查应该在函数体内

---

### 3. Custom Error vs Require

| 特性 | `require` | Custom Error |
|------|-----------|--------------|
| Gas 成本 | ~50,000 | ~24,000 |
| 错误信息 | 字符串 | 4-byte selector |
| 参数支持 | ❌ | ✅ |
| 可读性 | 😐 | 😊 |
| Solidity 版本 | 所有版本 | 0.8.4+ |

**示例**：

```solidity
// 旧方式
require(amount > 0, "Amount must be greater than zero");

// 新方式
error InvalidAmount();
if (amount == 0) revert InvalidAmount();

// 带参数的错误
error InsufficientBalance(uint256 requested, uint256 available);
if (balance < amount) revert InsufficientBalance(amount, balance);
```

---

## 🛡️ 安全威胁分析

### 威胁 1: Gas DoS 攻击

**场景**：攻击者通过大量零值交易消耗系统资源

```javascript
// 攻击脚本
for (let i = 0; i < 10000; i++) {
  await vault.deposit(0);  // 如果没有零值检查
}
```

**防护**：
```solidity
if (amount == 0) revert InvalidAmount();  // ✅ 阻止攻击
```

---

### 威胁 2: 会计系统污染

**场景**：零值交易产生无意义的事件和状态变化

```solidity
// 没有保护的情况
deposit(0) 
→ emit Deposit(user, 0, 0)  // 垃圾事件
→ totalSupply 不变
→ 但 nonce 增加 ❌
```

**防护**：早期拒绝零值输入

---

### 威胁 3: 零地址资金丢失

**场景**：用户错误地将资金发送到 0x0 地址

```solidity
vault.deposit(1000, address(0));  // 资金永久丢失 ❌
```

**防护**：
```solidity
if (receiver == address(0)) revert InvalidReceiver();  // ✅
```

---

### 威胁 4: 通胀攻击（Inflation Attack）⭐

**场景**：第一个存款者操纵份额价格

```solidity
// 攻击步骤
1. Alice 存入 1 Wei，获得 1000 份额（最小份额）
2. Alice 直接转账 1000 ETH 到 Vault
3. totalAssets = 1000 ETH, totalSupply = 1000 shares
4. 份额价格 = 1 ETH/share（极高！）
5. Bob 存入 10 ETH，只能获得 10 shares ❌
```

**防护**：
```solidity
uint256 private constant _MINIMUM_SHARE_BALANCE = 1000;

if (total.base == 0 && shares < _MINIMUM_SHARE_BALANCE) {
  revert InvalidShareBalance();  // ✅ 防止攻击
}
```

**详细分析见测试 #7** ⭐

---

## 📊 测试统计

### 覆盖的错误类型

| 错误类型 | 测试数量 | 占比 |
|---------|---------|------|
| `InvalidAmount` | 3 | 37.5% |
| `InvalidReceiver` | 2 | 25.0% |
| `NotEnoughBalanceToWithdraw` | 1 | 12.5% |
| `InvalidShareBalance` | 2 | 25.0% |

### 覆盖的函数

| 函数 | 测试数量 |
|------|---------|
| `depositNative()` | 2 |
| `deposit()` | 1 |
| `mint()` | 2 |
| `withdraw()` | 1 |
| `redeem()` | 2 |

---

## 🔧 实践任务

### 任务 1: 运行所有测试

```bash
# 只运行边界值测试
npx hardhat test test/core/vault/Vault.ts --grep "0 ETH|not enough|Zero|10 Wei|minimum"
```

### 任务 2: 代码审查

在 `VaultBase.sol` 中找到所有的零值检查：

```bash
grep -n "== 0) revert" contracts/core/VaultBase.sol
```

### 任务 3: 编写测试

为 `redeemNative()` 函数编写一个零份额测试：

```typescript
it('Redeem Native - 0 Shares', async function () {
  // 你的代码
});
```

### 任务 4: 工具验证

使用 Slither 检测缺失的零值检查：

```bash
slither contracts/core/VaultBase.sol --detect missing-zero-check
```

---

## 💡 最佳实践

### ✅ Do's

```solidity
// 1. 使用 Custom Error
error InvalidAmount();
if (amount == 0) revert InvalidAmount();

// 2. 早期返回
function deposit(uint256 amount) external {
  if (amount == 0) revert InvalidAmount();  // 立即检查
  // ... 其他逻辑
}

// 3. 检查接收者地址
if (receiver == address(0)) revert InvalidReceiver();

// 4. 防止通胀攻击
if (total.base == 0 && shares < _MINIMUM_SHARE_BALANCE) {
  revert InvalidShareBalance();
}
```

### ❌ Don'ts

```solidity
// 1. 不要使用 require 字符串（Gas 浪费）
require(amount > 0, "Invalid amount");  // ❌

// 2. 不要跳过零地址检查
function mint(address receiver) external {
  _mint(receiver, shares);  // ❌ 没检查 receiver
}

// 3. 不要允许零值存款
function deposit(uint256 amount) external {
  _deposit(amount);  // ❌ 没检查 amount
}
```

---

## 📚 延伸阅读

### 必读文章
- [The Dao Hack Explained](https://www.gemini.com/cryptopedia/the-dao-hack-makerdao) - 理解重入攻击
- [ERC-4626 Inflation Attack](https://ethereum-magicians.org/t/address-eip-4626-inflation-attacks-with-virtual-shares-and-assets/12677) - **必读！**
- [Solidity Custom Errors](https://docs.soliditylang.org/en/latest/contracts.html#errors)

### 推荐视频
- [Smart Contract Security 101](https://www.youtube.com/watch?v=P8LXLoTUJ5g)
- [Understanding Vault Economics](https://www.youtube.com/watch?v=I4hTqT3pLHI)

### 工具文档
- [Slither Detectors](https://github.com/crytic/slither/wiki/Detector-Documentation)
- [Echidna Tutorial](https://secure-contracts.com/program-analysis/echidna/index.html)

---

## 🎯 模块完成标准

完成以下任务后，可以进入下一模块：

- [ ] 完成所有 8 个测试的分析文档
- [ ] 运行所有测试并理解每个断言
- [ ] 阅读所有相关的合约源码
- [ ] 使用至少一个工具验证（Slither/Echidna）
- [ ] 编写至少 1 个自己的测试用例
- [ ] 能够解释通胀攻击的原理和防护

---

## ➡️ 下一模块

完成本模块后，进入：

**2.2 暂停状态安全测试** (难度 ★☆☆☆☆)

---

**更新日期**：2025-10-13  
**进度**：1/8 完成 (12.5%)  
**状态**：🟢 进行中

