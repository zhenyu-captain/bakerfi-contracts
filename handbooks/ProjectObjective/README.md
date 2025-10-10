# 人工目标
## 前置
* 了解项目的背景：项目的关键词表，关键词的意思，关键词在项目中的实际作用，在PrepareDocument保存为json
* 了解项目的实际情况：项目的目录，目录的作用，文件，文件的作用，包含所有的目录和文件，在PrepareDocument保存为json
## 目标
* 产出高中低级别的POC，子目标1是现有的POC确定，子目标2新的POC挖掘和验证，它由工具验证维度（执行落地）得出，依赖行业标准维度以及层次更高一级的宏观维度。
## 路径
* 阶段1，阶段2，阶段3的文档，并尽 量使路径文档 成为标准化可复用的
## 检查
* OpensourceTools文件内的工具是否可以被用，用在哪个工作。设计是输入keywords然后download到项目的readme.ad



# Project Objective
## 抽象的多目标逻辑版本和实现任务流程

**目标与范围**
- 提供可移植的方法论与执行规范，覆盖阶段1/2/3，统一命名与证据归档。
- 四维到 LATER 映射：Structure→`L`；Value→`A`；Authority/Trust→`T/E`；Runtime/Batch/Upgrade→`R`。

**阶段1（系统认知与假设）**
- 输出要求：
  - 系统概览与模块清单、资产与会计口径、角色与权限、价值流视图。
  - 概念不变量、攻击面与风险概览（SWC/SCSVS 种子）。
  - 验证输入准备、目录与路径对照、命名与映射、边界与不做事项、快速起步命令。
- 验收标准：
  - 文档与仓库结构一致；不新增工具或产物；作为阶段2语义源可直接引用。

**阶段2（方法论 + 框架模板 + 实例映射）**
- 目录与产物（模板）：
  - 事实：`audits/stage2/system_structure.md`
  - 映射：`audits/stage2/standard_mapping.csv`
  - 统一入口：`audits/stage2/run_test.md`
  - 证据：`audits/stage2/evidence/*`
  - 可选：`audits/stage2/slither/`、`audits/stage2/graphs/`、`audits/stage2/invariants/`、`audits/stage2/gas/`、`audits/stage2/findings/`
- 工具与命令：
  - 必选：`npx hardhat test`、`npx hardhat coverage`、`slither . --config-file slither.config.json`
  - 可选：`surya graph`、`myth analyze`、`echidna-test . --config echidna.yaml`
- 通用检查清单：
  - 枚举结构、走查权限、验证资金流、校验批处理、检查预言机、审核升级。
- 统一命名与编号：
  - BF ID：`BF-{module}-s2-{later}-{topic}-{index}`（与阶段3主键兼容）。
- 统一验收标准：
  - 四维各至少一条可复验产物（含命令与路径）。
  - 关键路径测试通过并具备覆盖率证据；权限矩阵导出审阅；不变量以测试断言或 Harness 形式存在并归档。
  - 产物具统一编号，可被阶段3聚合。

**阶段3（宏观维度与标准/工具/报告落地）**
- LATER 宏观维度与行业标准映射（SWC/SCSVS/DASP/OWASP）。
- 工具验证维度：静态分析、测试与覆盖、不变量/符号、性能与 DoS 观测。
- 报告与修复验证：字段统一、复现与证据、修复与二次验证、聚合输出。
- 三元映射规则：每个发现绑定 1 个 LATER 层面 + 1 个标准编号 + 1 组工具证据（命令与文件）。
- 问题卡片模板与编号规则：`BF-{module}-{layer}-{std}-{index}`；状态 `open|mitigated|validated`。
- 最小命令清单：`slither`、`surya graph`、`npx hardhat test`、`npx hardhat coverage`、`echidna-test`、`myth analyze`（按需）。

**统一命名与编号（方法论层）**
- 维度枚举：`structure | authority | value | invariant | oracle | upgrade | batch`（与 LATER 对齐）。
- 通用 ID 模板：`{project?}-{module?}-{dimension}-{topic}-{index}`。
- 要求：阶段2/3 ID 稳定可聚合；证据命名统一前缀使用 BF ID。

## 项目实例的多目标逻辑版本和实现任务流程

**仓库与模块**
- 仓库：`bakerfi-contracts`
- 模块：`vault`、`router`、`multiStrategy`、`multiCommand`、`oracles`、`proxy`、`libraries`
- 参考图：`doc/architecture.png`

**阶段1（引用语义源）**
- 文档源：`handbooks/Default/不成熟的想法-阶段1.md`
- 执行要点：
  - 不新增产物；以该文档作为阶段2的 Facts/Assertions/Evidence 的语义源。
  - 明确资产与会计口径、角色与权限、价值流与概念不变量；准备最小行动命令。

**阶段2（实例落地与归档）**
- 索引与信任来源：
  - 总览索引：`audits/stage2/stage2_index.md`（模块产物路径与状态）。
  - 信任来源：`audits/stage2/trust_sources.md`（外部依赖与假设清单，分 Authority vs Trust）。
- 最小执行：
  - `npx hardhat test`；`npx hardhat coverage`；`slither . --config-file slither.config.json`
  - 为 `vault/proxy/oracles` 各登记至少 1–2 条 BF 条目（如资产守恒/初始化幂等/新鲜度精度）。
  - 证据归档到 `audits/stage2/evidence/*`，并在条目内注明复验命令与路径。
- BF 统一编号：
  - `BF-{module}-s2-{later}-{topic}-{index}`，示例：`BF-vault-s2-A-asset-001`
- 验收清单：
  - `stage2_index.md` 至少包含 `vault/proxy/oracles` 三条记录，含命令与证据路径。
  - 至少三条 BF ID 登记 Facts/Assertions/Evidence 与复验命令。
  - 完成一次 Slither 扫描并记录重要警示与误报说明。

**阶段3（聚合与报告）**
- 三元映射表：在阶段3生成问题卡片并聚合 LATER × 标准 × 证据。
- 产出与交付：
  - 标准映射清单、工具产出归档、运营与升级证据链。
  - 验收：每个发现至少 1 个复现命令 + 1 组证据 + 标准标签；修复后二次验证状态更新为 `validated`。

**路径与命令（实例）**
- 测试：`npx hardhat test`
- 覆盖率：`npx hardhat coverage`
- 静态分析：`slither . --config-file slither.config.json`
- 图谱（可选）：`surya graph contracts/core/Vault.sol --output audits/stage2/graphs/vault.dot`
- 不变量（可选）：`echidna-test . --config echidna.yaml`

**证据归档约定（实例）**
- 证据目录：`audits/stage2/evidence/{module}/`（日志/JSON/截图）。
- 静态分析：`audits/stage2/slither/{module}.json`
- 覆盖率：`coverage/`（保留默认路径）。
- 命名规范：统一使用 BF ID 前缀，如：`BF-vault-s2-A-asset-001-test.log`。

**不做事项（约束）**
- 阶段1不新增工具/目录；参数阈值在阶段2具体化。
- 若可选工具未安装（Surya/Mythril/Echidna），可跳过不阻塞阶段2验收。