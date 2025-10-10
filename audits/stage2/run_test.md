# 阶段2统一执行入口

本文件用于记录可复验的命令与产物路径，供阶段3调用。

## 基本命令
- 测试：`npx hardhat test`
- 覆盖率：`npx hardhat coverage`
- Gas：`npm run test:gas`（若项目集成）
- 静态分析：`slither . --config-file slither.config.json`

## 可选命令
- Surya 图谱：`surya graph contracts/core/Vault.sol --output audits/stage2/graphs/vault.dot`
- Mythril：`myth analyze contracts/proxy/BakerFiProxy.sol -o json -t 300`
- Echidna：`echidna-test . --config echidna.yaml`

## 产物路径建议
- `audits/stage2/evidence/*`：工具输出与截图（建议细分如下）
  - `audits/stage2/evidence/tests/`：测试日志与截图
  - `audits/stage2/evidence/static/`：静态分析与规则匹配输出
  - `audits/stage2/evidence/invariants/`：不变量验证日志
  - `audits/stage2/evidence/runtime/`：升级/部署/回滚运行日志
- `audits/stage2/slither/*.json`：Slither 报告
- `audits/stage2/graphs/*`：结构/调用图
- `audits/stage2/gas/*`：Gas 报告
- `audits/stage2/findings/*`：问题卡片与说明

## 证据语义标注与命名示例
- 统一 ID：`BF-{module}-s2-{later}-{topic}-{index}`，用于所有证据文件名前缀。
- 证据类型后缀：`-test.log`, `-coverage.html#Lxx`, `-slither.json`, `-graph.dot`, `-gas.md`
- 示例：
  - `BF-vault-s2-A-asset-001-test.log`
  - `BF-vault-s2-A-asset-001-slither.json`
  - `BF-proxy-s2-R-upgrade-002-test.log`
  - `BF-oracle-s2-E-freshness-001-graph.dot`
- 在 `audits/stage2/stage2_to_stage3_index.md` 中登记 ID 与具体路径，确保阶段3聚合时可直接链接。