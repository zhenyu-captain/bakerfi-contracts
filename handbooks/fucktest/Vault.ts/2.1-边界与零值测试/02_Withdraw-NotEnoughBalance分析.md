# 测试用例分析：Withdraw failed not enough brETH

> **测试类型**：边界与余额验证测试（安全测试）  
> **难度等级**：★★☆☆☆（初级）  
> **测试文件**：`test/core/vault/Vault.ts:129-141`  
> **合约文件**：`contracts/core/VaultBase.sol:409-414, 476-530`

---

## 📋 测试代码

```typescript
it('Withdraw failed not enough brETH', async function () {
  const { owner, vault } = await loadFixture(deployFunction);

  // 1. 存入 10 ETH
  await vault.depositNative(owner.address, {
    value: ethers.parseUnits('10', 18),
  });

  // 2. 授权 20 brETH（超过实际持有量）
  await vault.approve(vault.getAddress(), ethers.parseUnits('20', 18));
  
  // 3. 尝试提取 20 brETH（应该失败）
  await expect(vault.redeemNative(ethers.parseUnits('20', 18))).to.be.revertedWithCustomError(
    vault,
    'NotEnoughBalanceToWithdraw',
  );
});
```

---

## 🎯 测试目标

**验证合约拒绝超额提取，确保用户只能提取其实际持有的 brETH 份额。**

### 为什么要进行余额检查？

1. **🔒 防止余额操纵** - 确保用户不能提取超过其持有量的资产
2. **💰 保护金库资产** - 防止通过溢出或授权漏洞盗取他人资产
3. **📊 维护会计一致性** - 确保 totalSupply 和实际余额匹配
4. **⚖️ 公平性保障** - 防止某些用户占用其他人的份额

---

## 🔍 合约实现分析

### 1. `redeemNative` 函数（入口函数）

**位置**：`contracts/core/VaultBase.sol:409-414`

```solidity
function redeemNative(
  uint256 shares
)
  external
  override
  nonReentrant              // ① 防重入
  whenNotPaused             // ② 检查暂停状态
  onlyWhiteListed           // ③ 白名单检查
  returns (uint256 assets)
{
  if (_asset() != wETHA()) revert InvalidAsset();  // ④ 资产类型验证
  assets = _redeemInternal(shares, msg.sender, msg.sender, true);  // ⑤ 调用内部赎回逻辑
}
```

---

### 2. `_redeemInternal` 函数（核心逻辑）

**位置**：`contracts/core/VaultBase.sol:476-530`

```solidity
function _redeemInternal(
  uint256 shares,
  address receiver,
  address holder,
  bool shouldRedeemETH
) private returns (uint256 retAmount) {
  
  // ⭐ Step 1: 零值检查
  if (shares == 0) revert InvalidAmount();
  
  // ⭐ Step 2: 接收者验证
  if (receiver == address(0)) revert InvalidReceiver();
  
  // ⭐⭐⭐ Step 3: 余额检查（测试重点！）
  if (balanceOf(holder) < shares) revert NotEnoughBalanceToWithdraw();

  // Step 4: 如果不是持有者本人赎回，需要检查授权并转移份额
  if (msg.sender != holder) {
    if (allowance(holder, msg.sender) < shares) revert NoAllowance();
    transferFrom(holder, msg.sender, shares);
  }

  // Step 5: 计算可提取的资产数量
  uint256 withdrawAmount = (shares * totalAssets()) / totalSupply();
  if (withdrawAmount == 0) revert NoAssetsToWithdraw();

  // Step 6: 从策略中撤回资产
  uint256 amount = _undeploy(withdrawAmount);
  uint256 fee = 0;
  uint256 remainingShares = totalSupply() - shares;

  // Step 7: 确保最小份额余额（防止比率扭曲）
  if (remainingShares < _MINIMUM_SHARE_BALANCE && remainingShares != 0) {
    revert InvalidShareBalance();
  }

  // Step 8: 销毁份额
  _burn(msg.sender, shares);

  // Step 9: 计算并处理提取费用
  if (getWithdrawalFee() != 0 && getFeeReceiver() != address(0)) {
    fee = amount.mulDivUp(getWithdrawalFee(), PERCENTAGE_PRECISION);
    
    if (shouldRedeemETH && _asset() == wETHA()) {
      unwrapETH(amount);
      payable(receiver).sendValue(amount - fee);
      payable(getFeeReceiver()).sendValue(fee);
    } else {
      IERC20Upgradeable(_asset()).transfer(receiver, amount - fee);
      IERC20Upgradeable(_asset()).transfer(getFeeReceiver(), fee);
    }
  } else {
    if (shouldRedeemETH) {
      unwrapETH(amount);
      payable(receiver).sendValue(amount);
    } else {
      IERC20Upgradeable(_asset()).transfer(receiver, amount);
    }
  }

  emit Withdraw(msg.sender, receiver, holder, amount - fee, shares);
  retAmount = amount - fee;
}
```

---

## 🛡️ 安全检查层级

### 执行顺序（从外到内）

```
┌──────────────────────────────────────────────────────────────┐
│ redeemNative() - 入口函数                                     │
├──────────────────────────────────────────────────────────────┤
│ 1️⃣ nonReentrant          │ 防止重入攻击                      │
│ 2️⃣ whenNotPaused          │ 检查合约是否暂停                  │
│ 3️⃣ onlyWhiteListed        │ 检查调用者是否在白名单            │
│ 4️⃣ _asset() == wETHA()    │ 资产类型验证                      │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ _redeemInternal() - 内部逻辑                                  │
├──────────────────────────────────────────────────────────────┤
│ 1️⃣ shares == 0            │ 零值检查                          │
│ 2️⃣ receiver == address(0) │ 接收者验证                        │
│ 3️⃣ balanceOf < shares     │ ⭐⭐⭐ 余额检查（测试重点）       │
│ 4️⃣ allowance check        │ 授权检查（代理赎回）              │
│ 5️⃣ withdrawAmount == 0    │ 可提取数量检查                    │
│ 6️⃣ _undeploy()            │ 从策略撤回资产                    │
│ 7️⃣ remainingShares check  │ 最小份额检查                      │
│ 8️⃣ _burn()                │ 销毁份额                          │
│ 9️⃣ 费用计算与转账         │ 处理提取费和资产转移              │
└──────────────────────────────────────────────────────────────┘
```

---

## 🔑 关键点解析

### 1. 余额检查 vs 授权检查

这是一个非常重要的安全概念：

```solidity
// ❌ 常见误解：有授权就能提取
approve(vault, 20 ETH)  // 授权 20 ETH
// ↑ 这只是允许合约操作你的代币

// ✅ 正确理解：必须同时满足
balanceOf(user) >= 20 ETH   // 实际持有 >= 20 ETH
allowance(user, vault) >= 20 ETH  // 授权额度 >= 20 ETH
```

**测试场景**：
- 用户存入 10 ETH → 获得约 9.96 brETH
- 用户授权 20 brETH → ✅ 授权成功
- 用户尝试提取 20 brETH → ❌ 余额不足，交易回滚

---

### 2. `NotEnoughBalanceToWithdraw` 错误定义

**位置**：`contracts/core/VaultBase.sol:62`

```solidity
// Custom errors for better gas efficiency
error InvalidAmount();
error InvalidAssetsState();
error InvalidAsset();
error MaxDepositReached();
error NotEnoughBalanceToWithdraw();  // ⭐ 这个错误！
error NoAssetsToWithdraw();
error NoPermissions();
error InvalidShareBalance();
error InvalidReceiver();
error NoAllowance();
```

**错误名称语义分析**：

| 错误名 | 触发条件 | 含义 |
|--------|---------|------|
| `NotEnoughBalanceToWithdraw` | `balanceOf(holder) < shares` | 用户持有的份额不足 |
| `NoAssetsToWithdraw` | `withdrawAmount == 0` | 计算出的可提取资产为零 |
| `NoAllowance` | `allowance(holder, sender) < shares` | 授权额度不足（代理赎回时） |

---

### 3. 测试断言解析

```typescript
// Step 1: 存入 10 ETH
await vault.depositNative(owner.address, {
  value: ethers.parseUnits('10', 18),  // 10 ETH
});
// 结果：获得约 9961040768967475200 Wei 的 brETH (≈ 9.96 brETH)

// Step 2: 授权 20 brETH
await vault.approve(vault.getAddress(), ethers.parseUnits('20', 18));
// 授权成功！但这不意味着可以提取 20 brETH

// Step 3: 尝试提取 20 brETH
await expect(
  vault.redeemNative(ethers.parseUnits('20', 18))  // 20 brETH
).to.be.revertedWithCustomError(vault, 'NotEnoughBalanceToWithdraw');
// ❌ 余额检查失败：balanceOf(owner) = 9.96 brETH < 20 brETH
```

**执行流程**：

1. `redeemNative(20 brETH)` 被调用
2. 通过 modifier 检查（nonReentrant, whenNotPaused, onlyWhiteListed）
3. 进入 `_redeemInternal(20 brETH, owner, owner, true)`
4. 执行到 `if (balanceOf(owner) < 20 brETH)` → **条件为真**
5. 🔴 `revert NotEnoughBalanceToWithdraw()`
6. ✅ 测试断言 `.to.be.revertedWithCustomError(vault, 'NotEnoughBalanceToWithdraw')` 通过

---

## 🧪 实验：手动复现

### 步骤 1: 运行单个测试

```bash
npx hardhat test test/core/vault/Vault.ts --grep "Withdraw failed not enough brETH"
```

**预期输出**：
```
  BakerFi Vault
    ✔ Withdraw failed not enough brETH (948ms)

  1 passing (953ms)
```

### 步骤 2: 修改测试（观察边界情况）

尝试提取**刚好等于余额**的 brETH：

```typescript
it('Withdraw exactly balance - should succeed', async function () {
  const { owner, vault } = await loadFixture(deployFunction);

  await vault.depositNative(owner.address, {
    value: ethers.parseUnits('10', 18),
  });

  const balance = await vault.balanceOf(owner.address);  // 获取实际余额
  console.log(`User balance: ${balance}`);  // ≈ 9961040768967475200

  await vault.approve(vault.getAddress(), balance);
  await expect(vault.redeemNative(balance)).to.not.be.reverted;  // ✅ 应该成功
});
```

### 步骤 3: 边界值测试

```typescript
it('Withdraw balance + 1 Wei - should fail', async function () {
  const { owner, vault } = await loadFixture(deployFunction);

  await vault.depositNative(owner.address, {
    value: ethers.parseUnits('10', 18),
  });

  const balance = await vault.balanceOf(owner.address);
  
  await vault.approve(vault.getAddress(), balance + 1n);  // 授权多 1 Wei
  
  // 尝试提取比余额多 1 Wei
  await expect(vault.redeemNative(balance + 1n))
    .to.be.revertedWithCustomError(vault, 'NotEnoughBalanceToWithdraw');  // ❌ 应该失败
});
```

---

## 🔬 更深入的理解

### 对比：ERC-20 的 `transfer` vs ERC-4626 的 `redeem`

#### ERC-20 Transfer

```solidity
function transfer(address to, uint256 amount) external returns (bool) {
  require(balanceOf[msg.sender] >= amount, "Insufficient balance");
  balanceOf[msg.sender] -= amount;
  balanceOf[to] += amount;
  return true;
}
```

#### ERC-4626 Redeem

```solidity
function redeem(uint256 shares, address receiver, address holder) 
  external returns (uint256 assets) 
{
  require(balanceOf[holder] >= shares, "Insufficient shares");  // ⭐ 类似检查
  
  // 但多了更多逻辑：
  // 1. 授权检查（如果 msg.sender != holder）
  // 2. 份额 → 资产转换
  // 3. 策略撤回
  // 4. 费用计算
  // 5. 销毁份额
  // 6. 转移资产
}
```

**区别**：
- ERC-20：简单的余额转移
- ERC-4626：涉及策略、份额转换、费用等复杂逻辑

---

### 为什么需要三层检查？

```solidity
// 1️⃣ 份额余额检查
if (balanceOf(holder) < shares) revert NotEnoughBalanceToWithdraw();

// 2️⃣ 授权检查（代理赎回时）
if (msg.sender != holder) {
  if (allowance(holder, msg.sender) < shares) revert NoAllowance();
}

// 3️⃣ 资产数量检查
uint256 withdrawAmount = (shares * totalAssets()) / totalSupply();
if (withdrawAmount == 0) revert NoAssetsToWithdraw();
```

**场景说明**：

| 场景 | 余额检查 | 授权检查 | 资产检查 | 结果 |
|------|---------|---------|---------|------|
| 用户提取超过持有量 | ❌ 失败 | - | - | `NotEnoughBalanceToWithdraw` |
| 代理未授权 | ✅ 通过 | ❌ 失败 | - | `NoAllowance` |
| 金库资产为零 | ✅ 通过 | ✅ 通过 | ❌ 失败 | `NoAssetsToWithdraw` |
| 正常提取 | ✅ 通过 | ✅ 通过 | ✅ 通过 | ✅ 成功 |

---

## 📊 攻击场景分析

### 假设：如果没有余额检查会怎样？

#### 场景 1: 整数下溢攻击（Solidity 0.8 之前）

```solidity
// ❌ 没有余额检查（Solidity < 0.8）
function redeem(uint256 shares) external {
  balanceOf[msg.sender] -= shares;  // 如果 shares > balanceOf 会下溢
  // 下溢后 balanceOf 变成一个巨大的数字！
}
```

**Solidity 0.8+** 自动防止溢出，但仍需显式检查：

```solidity
// ✅ Solidity 0.8+ 会自动 revert（但错误信息不友好）
balanceOf[msg.sender] -= shares;  // 如果 shares > balanceOf → Panic(0x11)

// ✅ 更好的做法：显式检查
if (balanceOf[msg.sender] < shares) revert NotEnoughBalanceToWithdraw();
```

#### 场景 2: 授权滥用攻击

```solidity
// 假设没有余额检查，只有授权检查
function redeem(uint256 shares, address holder) external {
  require(allowance[holder][msg.sender] >= shares);  // 只检查授权
  // 没有检查余额！
  
  allowance[holder][msg.sender] -= shares;
  balanceOf[holder] -= shares;  // ← Solidity 0.8 会 panic，但错误不明确
  // ...
}
```

**攻击步骤**：
1. Alice 有 10 brETH，授权 Bob 20 brETH
2. Bob 尝试提取 20 brETH
3. 没有余额检查 → 直接执行 `balanceOf[Alice] -= 20`
4. Solidity 0.8 会 panic，但攻击者可能找到绕过方法

#### 场景 3: 前端展示不一致

```javascript
// 前端逻辑
const allowance = await vault.allowance(user, spender);
const balance = await vault.balanceOf(user);

// ❌ 前端只检查授权
if (allowance >= amount) {
  await vault.redeem(amount);  // 可能因余额不足失败
}

// ✅ 正确的前端逻辑
if (balance >= amount && allowance >= amount) {
  await vault.redeem(amount);
}
```

---

## ✅ 测试验证点

| 验证项 | 状态 | 说明 |
|--------|------|------|
| 余额检查存在 | ✅ | `if (balanceOf(holder) < shares)` |
| 使用 Custom Error | ✅ | `revert NotEnoughBalanceToWithdraw()` |
| 检查位置正确 | ✅ | 在授权检查之前（更早失败） |
| 错误信息清晰 | ✅ | `NotEnoughBalanceToWithdraw` 明确表达语义 |
| 测试覆盖完整 | ✅ | 测试了超额提取（2倍余额） |
| Gas 效率 | ✅ | Custom Error 比 require 节省约 50% Gas |

---

## 🎓 知识点总结

### 1. 授权 ≠ 余额

```solidity
// ❌ 错误理解
approve(vault, 100 ETH)  // 授权 100 ETH
→ 可以提取 100 ETH？  // NO！

// ✅ 正确理解
balanceOf(user) = 50 ETH      // 实际持有 50 ETH
allowance(user, vault) = 100 ETH  // 授权 100 ETH
→ 只能提取 min(50, 100) = 50 ETH
```

**关键概念**：
- **授权 (allowance)**：允许别人操作你的代币
- **余额 (balance)**：你实际拥有的代币数量
- **两者必须同时满足** 才能成功转移

---

### 2. ERC-4626 的三层防护

```solidity
// Layer 1: 份额余额检查
if (balanceOf(holder) < shares) revert;

// Layer 2: 授权检查（代理赎回）
if (msg.sender != holder && allowance < shares) revert;

// Layer 3: 实际资产检查
if (withdrawAmount == 0) revert;
```

**为什么需要三层？**
- **Layer 1**：防止用户提取超过持有量
- **Layer 2**：防止未授权的代理提取
- **Layer 3**：防止金库资产不足的情况

---

### 3. 边界值测试的关键

边界值（Boundary Values）是最容易出错的地方：

| 边界值 | 测试场景 | 预期结果 |
|--------|---------|---------|
| 0 shares | 提取 0 brETH | `InvalidAmount` |
| balance | 提取刚好等于余额 | ✅ 成功 |
| balance + 1 | 提取比余额多 1 Wei | `NotEnoughBalanceToWithdraw` |
| balance × 2 | 提取两倍余额（本测试） | `NotEnoughBalanceToWithdraw` |
| type(uint256).max | 提取最大值 | `NotEnoughBalanceToWithdraw` |

**这个测试覆盖了"超额提取（2倍）"这个边界！**

---

### 4. 实际份额计算

从测试第65-85行可知，存入 10 ETH 的实际份额计算：

```javascript
// 存入 10 ETH
depositAmount = 10 ETH = 10,000,000,000,000,000,000 Wei

// 获得的 brETH
shares = 9,961,040,768,967,475,200 Wei ≈ 9.96 brETH

// 计算公式（第一次存款）
shares = depositAmount - flashLoanFee - strategyFee
```

**为什么不是 1:1？**
- 策略部署时有 flash loan 费用
- 策略执行时有滑点损失
- 初始存款的固定成本

---

## 🔧 实用工具验证

### 1. 使用 Hardhat Console 交互测试

```javascript
// 启动 Hardhat console
npx hardhat console --network hardhat

// 部署合约
const Vault = await ethers.getContractFactory("Vault");
const vault = await Vault.deploy(...);

// 存入 10 ETH
await vault.depositNative(owner.address, { value: ethers.parseEther("10") });

// 查看余额
const balance = await vault.balanceOf(owner.address);
console.log("Balance:", balance.toString());  // 9961040768967475200

// 授权
await vault.approve(vault.address, ethers.parseEther("20"));

// 尝试提取（应该失败）
try {
  await vault.redeemNative(ethers.parseEther("20"));
} catch (error) {
  console.log("Error:", error.message);  // 包含 NotEnoughBalanceToWithdraw
}
```

---

### 2. 使用 Slither 检测余额检查

```bash
slither contracts/core/VaultBase.sol --detect unchecked-transfer
```

**Slither 应该不会报告问题**，因为余额检查已存在。

---

### 3. 使用 Echidna 模糊测试

```solidity
// EchidnaVaultTest.sol
contract EchidnaVaultTest {
  Vault vault;
  
  function echidna_cannot_withdraw_more_than_balance() public returns (bool) {
    uint256 balance = vault.balanceOf(address(this));
    
    try vault.redeemNative(balance + 1) {
      return false;  // 应该 revert，如果成功则测试失败
    } catch {
      return true;   // 正确地 revert 了
    }
  }
}
```

---

### 4. 使用 Foundry 的 Invariant Testing

```solidity
// test/invariants/VaultInvariants.t.sol
contract VaultInvariants is Test {
  function invariant_totalSupply_equals_sum_of_balances() public {
    uint256 totalSupply = vault.totalSupply();
    uint256 sumOfBalances = 0;
    
    for (uint i = 0; i < users.length; i++) {
      sumOfBalances += vault.balanceOf(users[i]);
    }
    
    assertEq(totalSupply, sumOfBalances, "Total supply mismatch");
  }
}
```

---

## 📝 练习题

### 练习 1: 测试精确边界

编写测试，提取**刚好等于余额**的 brETH：

```typescript
it('Withdraw exact balance - should succeed', async function () {
  const { owner, vault } = await loadFixture(deployFunction);
  
  // 你的代码：
  // 1. 存入一定数量的 ETH
  // 2. 获取实际 brETH 余额
  // 3. 授权并提取刚好等于余额的数量
  // 4. 验证提取成功
});
```

<details>
<summary>💡 参考答案</summary>

```typescript
it('Withdraw exact balance - should succeed', async function () {
  const { owner, vault } = await loadFixture(deployFunction);
  
  // 存入 10 ETH
  await vault.depositNative(owner.address, {
    value: ethers.parseUnits('10', 18),
  });
  
  // 获取实际余额
  const balance = await vault.balanceOf(owner.address);
  console.log(`Balance: ${balance}`);  // 9961040768967475200
  
  // 授权
  await vault.approve(vault.getAddress(), balance);
  
  // 提取全部余额
  await expect(vault.redeemNative(balance))
    .to.emit(vault, 'Withdraw')
    .to.not.be.reverted;
  
  // 验证余额为零
  expect(await vault.balanceOf(owner.address)).to.equal(0);
});
```
</details>

---

### 练习 2: 测试授权不足场景

编写测试，验证授权不足时的错误（代理赎回场景）：

```typescript
it('Withdraw with insufficient allowance - should fail', async function () {
  const { owner, vault, otherAccount } = await loadFixture(deployFunction);
  
  // 你的代码：
  // 1. owner 存入 10 ETH
  // 2. owner 授权 otherAccount 5 brETH
  // 3. otherAccount 尝试提取 10 brETH（超过授权）
  // 4. 验证抛出 NoAllowance 错误
});
```

<details>
<summary>💡 参考答案</summary>

```typescript
it('Withdraw with insufficient allowance - should fail', async function () {
  const { owner, vault, otherAccount } = await loadFixture(deployFunction);
  
  // owner 存入 10 ETH
  await vault.depositNative(owner.address, {
    value: ethers.parseUnits('10', 18),
  });
  
  const balance = await vault.balanceOf(owner.address);
  
  // owner 授权 otherAccount 5 brETH
  await vault.approve(otherAccount.address, ethers.parseUnits('5', 18));
  
  // otherAccount 尝试代理赎回 10 brETH（超过授权）
  await expect(
    vault.connect(otherAccount).redeem(balance, otherAccount.address, owner.address)
  ).to.be.revertedWithCustomError(vault, 'NoAllowance');
});
```
</details>

---

### 练习 3: 编写攻击 PoC

模拟一个攻击者尝试通过授权漏洞提取超额资产：

```javascript
// poc.js
async function attackVault(vault, attacker, victim) {
  // 1. 获取受害者的授权
  // 2. 尝试提取超过受害者余额的资产
  // 3. 验证攻击失败
}
```

<details>
<summary>💡 参考答案</summary>

```javascript
async function attackVault(vault, attacker, victim) {
  console.log("=== Attack Simulation ===");
  
  // 受害者存入 10 ETH
  await vault.connect(victim).depositNative(victim.address, {
    value: ethers.parseEther("10")
  });
  
  const victimBalance = await vault.balanceOf(victim.address);
  console.log(`Victim balance: ${victimBalance}`);  // ~9.96 brETH
  
  // 受害者错误地授权攻击者 1000 brETH（远超余额）
  await vault.connect(victim).approve(attacker.address, ethers.parseEther("1000"));
  console.log("Victim approved 1000 brETH to attacker");
  
  // 攻击者尝试提取 1000 brETH
  try {
    await vault.connect(attacker).redeem(
      ethers.parseEther("1000"),
      attacker.address,
      victim.address
    );
    console.log("❌ ATTACK SUCCEEDED - VULNERABILITY!");
  } catch (error) {
    console.log("✅ Attack failed with:", error.message);
    // 应该包含 NotEnoughBalanceToWithdraw
  }
}
```
</details>

---

## 🎯 下一步学习

按照学习顺序，下一个测试是：

**✅ 已完成**：2.1-01 Deposit - 0 ETH（零值保护）  
**✅ 已完成**：2.1-02 Withdraw failed not enough brETH（余额不足保护）  
**➡️ 下一个**：2.1-03 Deposit Failed - Zero Deposit（ERC-20 零值存款保护）

---

## 📚 参考资料

- [ERC-4626 Tokenized Vault Standard](https://eips.ethereum.org/EIPS/eip-4626)
- [ERC-20 Token Standard](https://eips.ethereum.org/EIPS/eip-20)
- [Solidity Custom Errors](https://docs.soliditylang.org/en/latest/contracts.html#errors)
- [OpenZeppelin ERC20 Implementation](https://docs.openzeppelin.com/contracts/4.x/api/token/erc20)
- [SWC-101: Integer Overflow and Underflow](https://swcregistry.io/docs/SWC-101)
- [Checks-Effects-Interactions Pattern](https://docs.soliditylang.org/en/latest/security-considerations.html#use-the-checks-effects-interactions-pattern)

---

## 🔄 与第一个测试的对比

| 维度 | Deposit - 0 ETH | Withdraw failed not enough brETH |
|------|----------------|----------------------------------|
| **测试类型** | 零值边界测试 | 余额不足边界测试 |
| **检查位置** | 函数入口 | 内部逻辑 |
| **错误类型** | `InvalidAmount` | `NotEnoughBalanceToWithdraw` |
| **检查条件** | `msg.value == 0` | `balanceOf(holder) < shares` |
| **涉及状态** | 无状态（入口检查） | 有状态（余额查询） |
| **攻击风险** | DoS、垃圾数据 | 资产盗取、余额操纵 |
| **Gas 消耗** | 低（早期失败） | 中（需要读取余额） |

---

**作者**：BakerFi Security Learning Team  
**日期**：2025-10-14  
**状态**：✅ 完成分析  
**测试通过时间**：948ms  
**难度评估**：★★☆☆☆

---

## 💡 学习心得记录区

<details>
<summary>📝 点击展开，记录你的学习笔记</summary>

### 我学到了什么？

1. **授权和余额的区别**：

2. **ERC-4626 的安全机制**：

3. **边界值测试的重要性**：

4. **Custom Error 的优势**：

### 我的疑问？

1. 

2. 

### 下次学习计划

- [ ] 完成练习题 1-3
- [ ] 运行 Echidna 模糊测试
- [ ] 阅读 ERC-4626 标准文档
- [ ] 继续下一个测试用例

</details>

