# 阶段3 方法论模板（Aggregation & Reporting）

目的：按统一结构聚合阶段2产物，生成问题卡片与报告映射，不含项目路径与命令。

聚合模型：
- 三元映射：`LATER × Standard(SWC/SCSVS/DASP) × Tool`
- 卡片字段：`BF ID | Layer | Standard | Risk | Evidence Types | Verdict | Rationale`
- 入口：以阶段2的 BF ID 作为主键进行聚合，不新增主键体系。

验收要求：
- 仅定义聚合字段与输出结构；
- 不新增目录结构；
- 支持跨项目横向对比与复用。