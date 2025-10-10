# 阶段2总览索引表（模块×产物×状态）

目的：集中展示每个模块的 Facts / Assertions / Evidence 路径与完成度，供阶段3与人工复核使用。

示例表：

| Module | LATER | SWC | SCSVS | Facts | Assertions | Evidence | Status |
|--------|-------|-----|-------|-------|------------|----------|--------|
| vault  | A     | 107 | Asset-Accounting | audits/stage2/vault/facts.md | audits/stage2/vault/assertions.md | audits/stage2/vault/evidence/ | ✅ Done |
| router | R     | 128 | Atomicity        | audits/stage2/router/facts.md | audits/stage2/router/assertions.md | audits/stage2/router/evidence/ | ✅ Done |
| proxy  | R     | 112 | Upgrade-Safety   | audits/stage2/proxy/facts.md  | audits/stage2/proxy/assertions.md  | audits/stage2/proxy/evidence/  | 🕓 Pending |
| oracle | E     | 116 | Oracle-Freshness | audits/stage2/oracle/facts.md | audits/stage2/oracle/assertions.md | audits/stage2/oracle/evidence/ | 🕓 Pending |

维护建议：
- 为每模块创建占位目录与文件：`audits/stage2/{module}/facts.md`, `assertions.md`, `index.md`, `evidence/`。
- 记录完成状态（Done/Pending）与关键证据链接，保持时效。