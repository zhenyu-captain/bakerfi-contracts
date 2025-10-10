# 信任假设表（Authority vs Trust 边界）

目的：明确外部依赖与信任来源，记录验证方法与后备方案，供阶段3的 Threats & Trust 聚合使用。

字段定义（表格或列表均可）：
- ID：`BF-{module}-s2-T-trust-{index}`
- Module：模块名（vault/router/proxy/oracle/...）
- TrustSource：信任来源（管理员、预言机、外部协议等）
- Verification：验证方式（链上校验、签名验证、手动抽样等）
- Fallback：后备方案（数据降级、暂停、切源、回滚）
- Evidence：命令与路径（测试、日志、配置）
- Mapping：标准编号（如 SCSVS-Trust-Management）

示例：
```
ID: BF-oracle-s2-T-trust-001
Module: oracle
TrustSource: Chainlink price feed
Verification: compare against on-chain feed; check freshness <= threshold
Fallback: switch to Pyth; pause price-dependent operations
Evidence:
  - Test: npx hardhat test test/oracles/*
  - Config: echidna.yaml freshness threshold
Mapping: SCSVS-Oracle-Freshness; SWC-116
```