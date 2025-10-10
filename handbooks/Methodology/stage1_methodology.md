# 阶段1 方法论模板（System Understanding & Assumptions）

目的：抽象并标准化系统认知与假设的表达，不含路径与命令；为阶段2验证与阶段3聚合提供语义基线。

核心维度（四维 → LATER 对齐）：
- Structure（结构）→ LATER:L：模块、边界、角色、状态变量、事件；
- Authority（权限）→ LATER:A：管理员、升级、路由/策略授权、Proxy 管理；
- Value（价值流）→ LATER:A（资产会计）/R（运行时过程）：总资产/份额/价格、存取款/赎回、再平衡；
- Invariant（不变量）→ LATER:R/A/T/E：守恒、单调、事件一致、升级安全、预言机新鲜度与单位。

Stage1 输出结构（Schema）：
- system_overview：模块表、角色表、边界描述；
- accounting_principles：总资产/总份额/价格定义与单位；
- value_flow：入口/出口/批处理/再平衡的语义；
- trust_and_authority：权限与信任的边界（不含路径与命令）；
- conceptual_invariants：语义级不变量声明（数值与阈值在阶段2具体化）。

验收要求：
- 仅包含“做什么、语义与结构”，不包含任何项目路径或命令；
- 为阶段2的 Facts/Assertions/Evidence 提供明确的语义来源；
- 可被不同项目复用，无需修改模板内容。