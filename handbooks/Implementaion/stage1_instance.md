# 阶段1 实例落地（BakerFi）

system_overview：
- Modules：Vault, VaultRouter, VaultRegistry, MultiStrategy, MultiCommand, BakerFiProxy, Oracles(Pyth/Chainlink), Libraries(Math/Rebase/Curve/UniV2/V3)。
- Roles：Admin/Owner、Router、Strategy、User、Oracle Feeds、External Protocols(Aave/Curve/Balancer/Lido/Uniswap)。
- Boundaries：`contracts/core/*`, `contracts/proxy/*`, `contracts/oracles/*`, `contracts/libraries/*`；测试位于 `test/*`。

accounting_principles：
- 总资产/总份额/价格：`totalAssets`, `totalShares`, `pricePerShare`（单位：token decimals）。

value_flow：
- 入口/出口：存款、赎回；再平衡与批处理由 Router/Strategy 驱动；
- 关键事件：Deposit/Withdraw/Rebalance/Upgrade。

trust_and_authority：
- 管理与升级：Proxy Admin/Owner；
- 路由与策略授权：Router 入口、Strategy 白名单；
- 预言机与外部依赖：Pyth/Chainlink、Aave/Curve/Balancer/Lido/Uniswap。

conceptual_invariants（语义级）：
- 资产守恒、`pricePerShare` 非负且单调（费后语义）、事件与状态一致、升级安全、预言机新鲜度与单位一致。