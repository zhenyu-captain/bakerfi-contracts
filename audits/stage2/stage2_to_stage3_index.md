# 阶段2 → 阶段3 索引（人工维护）

目的：将阶段2的产出（Facts/Assertions/Evidence/Mapping）与阶段3的卡片/聚合项建立稳定链接，避免信息丢失。

结构建议：
- 列表项以统一 ID 为主键（`BF-{module}-{stage}-{later}-{topic}-{index}`）。
- 每项包含证据路径、标准编号、阶段3卡片编号（若已生成）。

示例：

```
- ID: BF-vault-s2-A-asset-001
  Module: vault
  LATER: A
  Stage3Card: CARD-VAULT-A-001
  Evidence:
    - Test: audits/stage2/evidence/vault/asset_001.log
    - Static: audits/stage2/slither/vault.json
    - Coverage: coverage/index.html#L100-L180
  Mapping:
    - Standard: SWC-107; SCSVS-Asset-Accounting
```

维护约定：
- 索引文件按模块分段或按 ID 排序均可，但需保持 ID 唯一与路径有效。
- 当阶段3生成卡片后，将 `Stage3Card` 补录；若卡片拆分或合并，记录说明。