# 阶段2 方法论模板（Verification & Evidence）

目的：标准化验证活动与证据归档的结构，不含任何具体命令或路径。

核心模型：
- Facts：源代码/接口/边界的客观事实（来源自阶段1语义与仓库结构）。
- Assertions：可验证的断言（单位、容差、覆盖范围、事件一致性等）。
- Evidence：验证产物的归档（测试日志、覆盖率、静态分析、图谱、运行时记录）。

统一编号：
- `BF-{module}-s2-{later}-{topic}-{index}` 作为唯一主键，贯穿阶段2与阶段3。

Evidence 类型与建议归档名：
- Tests：`BF-*-test.log`
- Coverage：`BF-*-coverage.json|lcov`
- Static：`BF-*-slither.json`
- Graphs：`BF-*-graph.dot|png`
- Invariants：`BF-*-invariant.log`
- Runtime：`BF-*-runtime.log`

表格模板（不含具体路径）：
- Columns：`BF ID | Module | LATER | Facts | Assertions | Evidence Types | Status | Notes`

验收要求：
- 断言需明确单位与容差；覆盖阈值建议线可注明；
- 对静态分析告警需给出“误报/可接受”说明的策略字段；
- 不写具体命令，只描述“执行单元测试/静态分析/导出图谱并归档”。