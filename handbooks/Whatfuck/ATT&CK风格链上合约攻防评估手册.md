# ATT&CK 风格链上合约攻防评估手册（BakerFi 项目）

本文将传统 ATT&CK 的战术-技术-程序（TTP）思路裁剪到链上智能合约场景，为渗透/护网背景的同学提供一份“能跑、能断言、能归档”的攻防评估手册。

## 一、目标与范围
- 目标：评估 BakerFi 多策略金库系统在链上常见攻防战术下的鲁棒性，复现关键 PoC 并形成证据链。
- 范围：`contracts/core/*`、`contracts/oracles/*`、`contracts/proxy/*`、`contracts/mocks/*` 与对应 `test/*`、`scripts/*`。
- 不在范围：跨链桥、MEV 套利、主网真实经济操纵（本文仅做本地或测试网复现）。
- 基本假设：代码按当前 `package.json` 依赖版本运行；测试网络为 Hardhat/Ganache。

## 二、资产与信任边界
- 资产对象：金库资产（`Vault`）、策略资金（`MultiStrategy`→各 DEX/借贷）、预言机价格（`oracles/*`）。
- 角色与权限：`GovernableOwnable` 管理员/拥有者、`VaultRegistry` 注册管理、升级代理 `BakerFiProxy` 管理域。
- 外部依赖：DEX 路由、借贷池（AAVE/Mock）、价格源（Pyth/Chainlink/Mock）。
- 关键存储：金库额度/费率（`VaultSettings.sol`）、策略参数（LTV、回路数）、代理实现地址与存储布局。

## 三、战术矩阵（链上裁剪）
- 初始访问（Initial Access）
  - 公共函数入口滥用与参数越界：`VaultRouter.sol`、`MultiCommand.sol`
  - 批量命令聚合误用：命令序列拼接与越权操作
- 执行（Execution）
  - 可重入（Reentrancy）与外部回调：`Vault.sol`、策略 `withdraw()/redeem()` 路径
  - 闪电贷组合操作：`core/flashloan/*` 与 `test/core/BalancerFlashLoan.ts`
- 持久化（Persistence）
  - 升级持久化：`proxy/BakerFiProxy.sol` 实现替换与布局变更
  - 参数持久化：`VaultSettings.sol`、策略阈值被恶意或误配置
- 权限提升（Privilege Escalation）
  - 角色夺取与权限链缺陷：`GovernableOwnable.sol`、`VaultRegistry.sol`
  - 未校验跨合约授权链：路由→策略→外部协议
- 规避防护（Defense Evasion）
  - 预言机操纵/异常：`oracles/*`、`mocks/OracleMock.sol`、`PythMock.sol`
  - 滑点/手续费隐藏在聚合交换：路由批处理
- 发现（Discovery）
  - 存储结构探测：`EmptySlot.sol`、文档 `doc/storage-compatibility.md`
  - 合约关系探测：`Vault`→`MultiStrategy`→外部协议资金流
- 横向移动（Lateral Movement）
  - 路由→策略链路迁移：`VaultRouter` 进入不同策略模块
- 采集与外泄（Collection/Exfiltration）
  - 资产提取：绕过限制条件的 `withdraw()`/`skim()`
  - 费用抽取异常：管理费/绩效费路径偏离
- 影响（Impact）
  - 资金耗尽、价格锚定失效、服务拒绝（DoS）

## 四、技术项卡片模板（每项一页，便于落地）
- 标识与名称：如 `SC-T1001 可重入（Reentrancy）`
- 战术：执行（Execution）
- 攻击前置：存在外部调用且状态写入前后缺防护/校验不严
- 可能受影响模块：文件与函数路径（例如 `contracts/core/Vault.sol::withdraw`）
- PoC 入口：`contracts/mocks/*` 与对应 `test/*` 用例；脚本或命令清单
- 期望检测/断言：余额不负数、权限校验严格、事件序列正确、不可再次重入
- 缓解建议：`checks-effects-interactions`、`ReentrancyGuard`、限制外部回调、参数白名单
- 证据链：测试输出、调用栈、事件日志、覆盖率与静态分析片段

示例卡片（可重入）：
- 受影响模块：`contracts/core/Vault.sol`、策略 `withdraw()` 路径
- PoC 参考：`contracts/mocks/BorrowerAttacker.sol`、`test/hooks/UseTokenActions.test.ts`
- 断言要点：交易回滚原因符合预期；在回调链中不可重复进入可变状态
- 修复要点：重入防护/先更新后交互；最小化外部调用窗口

## 五、项目模块映射与 PoC 提示
- 路由/批处理（初始访问/横向移动）：
  - 代码：`contracts/core/VaultRouter.sol`、`MultiCommand.sol`
  - 演练：`contracts/mocks/VaultRouterMock.sol`、`test/core/vault/*`（若存在）
- 预言机（规避防护）：
  - 代码：`contracts/oracles/*`、`contracts/mocks/OracleMock.sol`、`PythMock.sol`
  - 演练：`test/oracles/*`、`test/pyth/*`
- 升级与代理（持久化/权限提升）：
  - 代码：`contracts/proxy/BakerFiProxy.sol`
  - 文档：`doc/proxy/*`、`doc/storage-compatibility.md`
  - 演练：`test/proxy/*`
- 闪电贷与策略执行（执行/影响）：
  - 代码：`contracts/core/flashloan/*`、`contracts/core/strategies/*`
  - 演练：`test/core/BalancerFlashLoan.ts`、`test/hooks/Leverage.ts`
- 费用与取款（采集/外泄）：
  - 代码：`VaultSettings.sol`、`Vault.sol`
  - 演练：`test/hooks/UseTokenActions.test.ts`

## 六、演练与复现流程（命令可直接跑）
- 环境准备（Windows/PowerShell）：
  - 安装依赖：`npm ci`
  - 编译合约：`npx hardhat compile`
- 单场景 PoC：
  - 运行指定测试：`npx hardhat test -- test/core/BalancerFlashLoan.ts`
  - 运行某目录：`npx hardhat test -- test/oracles`
- 覆盖率与 Gas：
  - 覆盖率：`npm run test:coverage`（或 `npx hardhat coverage`）
  - Gas 报告：`npm run test:gas`（或 `REPORT_GAS=true npx hardhat test`）
- 静态分析与性质测试：
  - Slither：`npm run slither`（`slither --config-file ./slither.config.json .`）
  - Echidna（如需）：`echidna . --config echidna.yaml --contract <ContractName>`
- 本地部署复现：
  - 启动 Ganache（可选）：`npm run ganache:dev`
  - 本地部署：`npm run deploy:local` 或 `npx hardhat run --network localhost scripts/deploy-dev.ts`
  - 交互/验证：使用 `scripts/tasks/*` 的 Hardhat 任务（如设置费率、读取策略参数）

## 七、检测与响应（如何观察与写断言）
- 观察点：
  - 事件与日志：是否按顺序触发（Deposit/Withdraw/StrategyMove/OracleUpdate 等）
  - 余额与份额：用户/金库/策略余额不负数、份额计算正确
  - 回滚原因：`require/revert` 原因匹配，避免静默失败
  - 价格新鲜度与边界：时间戳、偏差阈值、回退行为
- 断言模板：
  - 安全性质：权限不可绕过；异常价格下交易拒绝；升级后存储兼容
  - 负面测试：越权参数/极端输入触发回滚且有明确原因
  - 不变量：资金守恒、费用上界、策略参数上下界
- 响应建议：
  - 立即措施：冻结异常参数、关闭路由批处理入口、回滚到安全版本
  - 中期措施：增加校验与断言、完善事件与监控、补充日志与追踪工具

## 八、缓解与修复建议（策略/代码/配置）
- 策略侧：限制批处理命令集、对外部协议交互设置保护阈值与白名单
- 代码侧：引入防重入、严格参数校验、显式错误原因、统一计价与四舍五入规则
- 配置侧：预言机聚合与新鲜度限制、升级前后布局比对与选择器校验、费率阈值防误设

## 九、验收与严重性分级
- 严重性分级：
  - 高：可能导致资金损失或跨模块影响（如可重入、升级不兼容导致锁死/外泄）
  - 中：配置/参数与路由误用导致风险升高（如 LTV 过高、滑点阈值过宽）
  - 低：观察到但难以被利用的边缘行为（日志/事件不一致、信息泄露）
- 验收标准：
  - PoC 不可复现或断言全部通过
  - 覆盖率达到阈值（自定，如行覆盖 ≥80%）
  - 静态分析无高危项（Slither/Echidna）
  - 本地部署与交互脚本运行无异常

## 十、归档与版本固定（复现友好）
- 固定版本：记录 Node/NPM/Hardhat/OS 版本与依赖锁（`package-lock.json`）
- 保存工件：`coverage/`、Gas 输出、`slither.report.*`、`echidna.*`、部署与任务执行日志
- 命令清单：保留本文命令与输出（建议 Markdown/JSON）
- `.env.example`：如需网络/API 密钥，提供最小示例并避免泄露

## 附录：命令-目的-产出清单（示例）
- `npm ci`：安装依赖 → 产出：`node_modules/`
- `npx hardhat compile`：编译合约 → 产出：`artifacts/`、`cache/`
- `npx hardhat test -- test/core/BalancerFlashLoan.ts`：单场景 PoC → 产出：测试日志与断言结果
- `npm run test:coverage`：覆盖率 → 产出：`coverage/` 报告
- `npm run test:gas`：Gas 报告 → 产出：Gas 统计片段（控制台或文件）
- `npm run slither`：静态分析 → 产出：静态报告（按配置）
- `npm run ganache:dev` → `npm run deploy:local`：本地网络与部署 → 产出：部署地址与事件日志
- `npx hardhat --network localhost run scripts/deploy-dev.ts`：在 localhost 部署 → 产出：部署日志与合约地址

——
建议用本手册把每个关注的技术项写成“卡片”，并关联到仓库的具体代码、测试与脚本入口；按“能跑、能断言、能归档”的标准完成一次最小可复现实验，即可形成审计证据链。