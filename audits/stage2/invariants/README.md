# 不变量模板与填写指南（阶段2 → 阶段3可迁移）

目的：统一不变式语义与证据产出，让阶段2的断言可直接用于阶段3聚合与 Echidna Harness。

模板字段：
- ID：`BF-{module}-s2-{later}-invariant-{index}`
- Module：模块名（vault/router/proxy/oracle/...）
- LATER：`A/T/L/E/R`（选择最贴近的维度）
- Title：不变式标题（简短）
- Statement：语义化陈述（中文+英文可选）
- Expression：半结构表达（统一语法），例如：`assert(totalAssets >= sum(strategyAssets))`
- Preconditions：前置条件（初始化、角色、余额等）
- Actions：操作序列（deposit/withdraw/rebalance/...）
- Expected：期望关系（守恒/单调/原子性/新鲜度/槽位不变等）
- Evidence：产出路径与命令（test/coverage/static/log）
- Mapping：标准编号（SWC/SCSVS/DASP）

示例：
```
ID: BF-vault-s2-A-invariant-001
Module: vault
LATER: A
Title: 资产守恒不变式
Statement: 对任意序列 deposit/withdraw/rebalance，系统总资产非负且守恒。
Preconditions: 初始化完成；发行份额非负；策略余额可读。
Actions: deposit(user, amount); rebalance(); withdraw(user, amount)
Expected: totalAssets >= 0 且 deltaAssets == deltaShares * pricePerShare
Evidence:
  - Test: npx hardhat test test/core/vault/*
  - Coverage: coverage/index.html 行区间 <links>
  - RunLog: audits/stage2/evidence/vault/invariant_001.log
Mapping: SWC-107; SCSVS-Asset-Accounting
```

填写约定：
- 所有不变式以独立条目记录（一个 ID 一个文件或表项）。
- 优先从 Hardhat 断言开始；如具备 Echidna，补充 Harness 与配置路径。
- 证据路径必须可复验（附命令）。

语法约定（Expression）：
- 使用 `assert(<boolean>)` 或关系表达式，例如：`assert(pricePerShare >= 0)`；
- 允许定义辅助函数名（如 `sum(strategyAssets)`）但需在 Facts 中说明其含义；
- 涉及浮点或精度时，给出容差：`assert(abs(delta) <= epsilon)`，并在 Evidence 中注明单位与 epsilon。