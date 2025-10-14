# 测试用例分析：Deposit - 0 ETH

> **测试类型**：边界与零值测试（安全测试）  
> **难度等级**：★☆☆☆☆（入门级）  
> **测试文件**：`test/core/vault/Vault.ts:119-127`  
> **合约文件**：`contracts/core/VaultBase.sol:261-276`

---

## 📋 测试代码

```typescript
it('Deposit - 0 ETH', async function () {
  const { owner, vault } = await loadFixture(deployFunction);

  await expect(
    vault.depositNative(owner.address, {
      value: ethers.parseUnits('0', 18),  // 尝试存入 0 ETH
    }),
  ).to.be.revertedWithCustomError(vault, 'InvalidAmount');
});
```

---

## 🎯 测试目标

**验证合约拒绝零值存款，防止无效操作和潜在的攻击向量。**

### 为什么要拒绝零值存款？

1. **⛽ Gas 浪费防护** - 零值操作消耗 Gas 但无实际价值
2. **📊 会计系统保护** - 避免产生无意义的状态变化和事件日志
3. **🔒 攻击向量消除** - 防止恶意用户通过大量零值交易进行 DoS 攻击
4. **💼 业务逻辑完整性** - 确保每笔交易都有实际的经济意义

---

## 🔍 合约实现分析

### 1. `depositNative` 函数（入口函数）

**位置**：`contracts/core/VaultBase.sol:261-276`

```solidity
function depositNative(
  address receiver
)
  external
  payable
  nonReentrant                          // ① 防重入
  whenNotPaused                         // ② 检查暂停状态
  onlyReceiverWhiteListed(receiver)     // ③ 白名单检查
  returns (uint256 shares)
{
  if (msg.value == 0) revert InvalidAmount();  // ④ ⭐ 零值检查（这里！）
  if (_asset() != wETHA()) revert InvalidAsset();  // ⑤ 检查资产类型
  
  // ⑥ 包装 ETH 为 WETH
  wETHA().functionCallWithValue(abi.encodeWithSignature("deposit()"), msg.value);
  
  // ⑦ 执行内部存款逻辑
  return _depositInternal(msg.value, receiver);
}
```

---

## 🛡️ 安全检查层级

### 执行顺序（从外到内）

```
┌─────────────────────────────────────────────────────────┐
│ 1️⃣ nonReentrant          │ 防止重入攻击                │
├─────────────────────────────────────────────────────────┤
│ 2️⃣ whenNotPaused          │ 检查合约是否暂停            │
├─────────────────────────────────────────────────────────┤
│ 3️⃣ onlyReceiverWhiteListed│ 检查接收者是否在白名单      │
├─────────────────────────────────────────────────────────┤
│ 4️⃣ msg.value == 0         │ ⭐ 零值检查（测试重点）     │
├─────────────────────────────────────────────────────────┤
│ 5️⃣ _asset() == wETHA()    │ 资产类型验证                │
├─────────────────────────────────────────────────────────┤
│ 6️⃣ ETH → WETH 转换        │ 实际的资金操作              │
├─────────────────────────────────────────────────────────┤
│ 7️⃣ _depositInternal()     │ 内部存款逻辑                │
└─────────────────────────────────────────────────────────┘
```

---

## 🔑 关键点解析

### 1. 为什么在 modifier 之后检查？

```solidity
function depositNative(address receiver)
  external
  payable
  nonReentrant              // ← 先执行
  whenNotPaused             // ← 再执行
  onlyReceiverWhiteListed   // ← 然后执行
{
  if (msg.value == 0) revert InvalidAmount();  // ← 最后执行
```

**原因**：
- **Modifier 顺序很重要**：先确保合约状态正常（未暂停）和调用者合法（白名单）
- **Gas 优化**：在进入函数体之前就过滤掉非法调用
- **安全第一**：零值检查是业务逻辑，放在函数体内更清晰

---

### 2. `InvalidAmount` 错误定义

**位置**：`contracts/core/VaultBase.sol:58`

```solidity
// Custom errors for better gas efficiency
error InvalidAmount();
error InvalidAssetsState();
error InvalidAsset();
error MaxDepositReached();
error NotEnoughBalanceToWithdraw();
error NoAssetsToWithdraw();
error NoPermissions();
error InvalidShareBalance();
error InvalidReceiver();
error NoAllowance();
```

**为什么使用 Custom Error？**

| 传统 `require` | Custom Error |
|---------------|--------------|
| `require(msg.value > 0, "Invalid amount")` | `if (msg.value == 0) revert InvalidAmount();` |
| Gas: ~50,000 | Gas: ~24,000 |
| 返回字符串 | 返回 4-byte selector |
| ❌ 更贵 | ✅ 更便宜 |

**Gas 节省 ≈ 50%** 🎉

---

### 3. 测试断言解析

```typescript
await expect(
  vault.depositNative(owner.address, {
    value: ethers.parseUnits('0', 18),  // 0.000000000000000000 ETH
  }),
).to.be.revertedWithCustomError(vault, 'InvalidAmount');
```

**逐步分解**：

1. `ethers.parseUnits('0', 18)` → 转换为 Wei（1 ETH = 10^18 Wei）
2. `value: 0` → 传入的 `msg.value = 0`
3. `vault.depositNative(owner.address, { value: 0 })` → 调用存款函数
4. 合约执行到 `if (msg.value == 0) revert InvalidAmount();` → 🔴 回滚
5. `.to.be.revertedWithCustomError(vault, 'InvalidAmount')` → ✅ 测试通过

---

## 🧪 实验：手动复现

### 步骤 1: 运行单个测试

```bash
npx hardhat test test/core/vault/Vault.ts --grep "Deposit - 0 ETH"
```

**预期输出**：
```
  BakerFi Vault
    ✔ Deposit - 0 ETH (972ms)

  1 passing (979ms)
```

### 步骤 2: 修改测试（观察失败）

尝试修改测试，期望成功（这应该失败）：

```typescript
it('Deposit - 0 ETH', async function () {
  const { owner, vault } = await loadFixture(deployFunction);

  // 期望成功（错误的期望）
  await expect(
    vault.depositNative(owner.address, {
      value: ethers.parseUnits('0', 18),
    }),
  ).to.not.be.reverted;  // ← 错误的断言
});
```

**结果**：测试会失败，因为合约确实会 revert。

---

## 🔬 更深入的理解

### 对比：其他存款函数的零值检查

#### `deposit()` - ERC-20 存款

**位置**：`contracts/core/VaultBase.sol:284-298`

```solidity
function deposit(
  uint256 assets,
  address receiver
)
  external
  override
  nonReentrant
  whenNotPaused
  onlyReceiverWhiteListed(receiver)
  returns (uint256 shares)
{
  if (assets == 0) revert InvalidAmount();  // ⭐ 同样的零值检查
  IERC20Upgradeable(_asset()).safeTransferFrom(msg.sender, address(this), assets);
  return _depositInternal(assets, receiver);
}
```

#### `mint()` - 铸造指定份额

**位置**：`contracts/core/VaultBase.sol:220-237`

```solidity
function mint(
  uint256 shares,
  address receiver
)
  external
  override
  nonReentrant
  whenNotPaused
  onlyReceiverWhiteListed(receiver)
  returns (uint256 assets)
{
  if (shares == 0) revert InvalidAmount();  // ⭐ 检查份额是否为零
  assets = this.convertToAssets(shares);
  IERC20Upgradeable(_asset()).safeTransferFrom(msg.sender, address(this), assets);
  _depositInternal(assets, receiver);
}
```

**一致性**：所有存款入口都有零值检查！ ✅

---

## 📊 攻击场景分析

### 假设：如果没有零值检查会怎样？

#### 场景 1: Gas DoS 攻击

```solidity
// 攻击者脚本
for (let i = 0; i < 10000; i++) {
  await vault.depositNative(attacker.address, { value: 0 });
}
```

**后果**：
- 💸 消耗大量 Gas 但没有经济成本
- 📈 污染事件日志
- 🐌 拖慢链上监听器
- 💥 可能触发前端错误

#### 场景 2: 会计系统污染

```solidity
// 没有零值检查的情况下
depositNative(user, { value: 0 })
→ emit Deposit(user, user, 0, 0)  // 无意义的事件
→ totalAssets 不变
→ totalSupply 不变（可能）
→ 但交易记录增加 ❌
```

#### 场景 3: 前端展示问题

```javascript
// 前端展示交易历史
transactions.forEach(tx => {
  console.log(`${tx.user} deposited ${tx.amount} ETH`);
  // 输出: "0xABC... deposited 0 ETH" ← 垃圾信息
});
```

---

## ✅ 测试验证点

| 验证项 | 状态 | 说明 |
|--------|------|------|
| 零值检查存在 | ✅ | `if (msg.value == 0) revert` |
| 使用 Custom Error | ✅ | `revert InvalidAmount()` |
| 检查位置正确 | ✅ | 在 modifier 之后，业务逻辑之前 |
| 错误信息清晰 | ✅ | `InvalidAmount` 易于理解 |
| 测试覆盖完整 | ✅ | 单独的测试用例 |

---

## 🎓 知识点总结

### 1. 零值保护模式

```solidity
// ❌ 不推荐：使用 require
require(amount > 0, "Amount must be greater than zero");

// ✅ 推荐：使用 custom error
if (amount == 0) revert InvalidAmount();
```

**原因**：Gas 效率高，代码更清晰。

### 2. 边界值测试的重要性

边界值（Boundary Values）是软件测试中最容易出错的地方：

- **零值**：0
- **最小值**：1 Wei
- **最大值**：type(uint256).max
- **刚好超限**：maxDeposit + 1

**这个测试覆盖了"零值"这个边界！**

### 3. Solidity 0.8+ 的 Custom Error 特性

自 Solidity 0.8.4 起，Custom Error 成为标准：

```solidity
// 定义
error InvalidAmount();
error InsufficientBalance(uint256 requested, uint256 available);

// 使用
if (amount == 0) revert InvalidAmount();
if (balance < amount) revert InsufficientBalance(amount, balance);
```

**优势**：
- 💰 节省 Gas（约 50%）
- 📝 代码更清晰
- 🔍 可以携带参数

---

## 🔧 实用工具验证

### 1. 使用 Slither 检测

```bash
slither contracts/core/VaultBase.sol --detect missing-zero-check
```

**Slither 应该不会报告问题**，因为零值检查已存在。

### 2. 使用 Echidna 模糊测试

```yaml
# echidna.yaml
testMode: assertion
testLimit: 50000
deployer: "0x30000"
sender: ["0x10000", "0x20000", "0x30000"]
```

```solidity
// EchidnaTest.sol
function echidna_deposit_nonzero() public returns (bool) {
  try vault.depositNative{value: 0}(address(this)) {
    return false;  // 应该 revert，如果成功则测试失败
  } catch {
    return true;   // 正确地 revert 了
  }
}
```

### 3. 使用 Mythril 符号执行

```bash
myth analyze contracts/core/VaultBase.sol --execution-timeout 60
```

---

## 📝 练习题

### 练习 1: 修改测试

尝试测试 **1 Wei** 的存款（最小非零值）：

```typescript
it('Deposit - 1 Wei', async function () {
  const { owner, vault } = await loadFixture(deployFunction);
  
  // 你的代码
  // 提示：1 Wei 应该能通过零值检查，但可能在其他地方失败
});
```

### 练习 2: 对比其他函数

找到 `deposit()` 函数的零值测试（提示：行号 ~920）：

```typescript
it('Deposit Failed - Zero Deposit', async function () {
  // 找到并分析这个测试
});
```

### 练习 3: 编写 PoC

编写一个攻击脚本，尝试在没有零值保护的合约上执行 DoS：

```javascript
// poc.js
async function gasDoS(vault, attacker) {
  const txs = [];
  for (let i = 0; i < 100; i++) {
    txs.push(vault.depositNative(attacker, { value: 0 }));
  }
  await Promise.all(txs);
}
```

---

## 🎯 下一步学习

按照学习顺序，下一个测试是：

**✅ 已完成**：2.1-01 Deposit - 0 ETH（零值保护）  
**➡️ 下一个**：2.1-02 Withdraw failed not enough brETH（余额不足保护）

---

## 📚 参考资料

- [Solidity Custom Errors](https://docs.soliditylang.org/en/latest/contracts.html#errors)
- [ERC-4626 标准](https://eips.ethereum.org/EIPS/eip-4626)
- [OpenZeppelin ReentrancyGuard](https://docs.openzeppelin.com/contracts/4.x/api/security#ReentrancyGuard)
- [SWC-123: Requirement Violation](https://swcregistry.io/docs/SWC-123)

---

**作者**：BakerFi Security Learning Team  
**日期**：2025-10-13  
**状态**：✅ 完成分析

