# 阶段2 实例落地（BakerFi）

索引（占位）：`audits/stage2/stage2_index.md`、`audits/stage2/trust_sources.md`、`audits/stage2/run_test.md`

表格：
- Columns：`BF ID | Module | LATER | Facts | Assertions | Evidence Path | Status | Notes`

初始条目（示例占位，将在执行后填充证据路径）：
- `BF-vault-s2-A-asset-001` | vault | A | Vault 会计变量定义与单位 | 资产守恒/价格非负/单调（给出 epsilon） | `audits/stage2/evidence/tests/BF-vault-s2-A-asset-001-test.log` | Pending | 
- `BF-proxy-s2-R-upgrade-001` | proxy | R | Proxy 初始化与实现槽位兼容 | `initialize()` 一次性；实现槽位未覆盖 | `audits/stage2/evidence/runtime/BF-proxy-s2-R-upgrade-001-runtime.log` | Pending |
- `BF-oracles-s2-E-freshness-001` | oracles | E | 预言机来源与单位 | 新鲜度窗口/精度换算 | `audits/stage2/evidence/tests/BF-oracles-s2-E-freshness-001-test.log` | Pending |

说明：具体命令在 `audits/stage2/run_test.md`；静态分析产物指向 `audits/stage2/slither/*.json`；图谱指向 `audits/stage2/graphs/*`。