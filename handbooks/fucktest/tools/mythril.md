| 模块                                    | 作用             | 输出文件                      | 格式         | 内容结构                                   | 用途                        |
| ------------------------------------- | -------------- | ------------------------- | ---------- | -------------------------------------- | ------------------------- |
| 🧠 1️⃣ 符号执行引擎<br>(Symbolic Execution) | 穷举路径、生成符号状态机   | `mythril-traces.json`     | JSON       | 路径树 + 状态变量变化 + 路径条件                    | 后续 SMT 求解、路径分析            |
| ⚙️ 2️⃣ 约束求解<br>(SMT Solving)          | 求解每条路径的可行输入    | `mythril-constraints.log` | TXT / JSON | 每个路径对应的求解输入参数（sender, value, calldata） | 提取可执行 POC                 |
| 🛡️ 3️⃣ 检测器系统<br>(Detectors)          | 匹配漏洞规则（SWC 标准） | `mythril-results.json`    | JSON       | 漏洞数组，每项含函数名、SWC ID、严重等级、描述             | 审计报告的主干来源                 |
| 🔄 4️⃣ 路径与交易模拟器<br>(Tx Simulator)     | 将可行路径转换为交易序列   | `mythril-poc.json`        | JSON       | 每条路径对应的 `tx_sequence`（函数调用 + 输入参数）     | 生成 Hardhat / Foundry 测试用例 |
| 📄 5️⃣ 报告层<br>(Reporting Layer)       | 汇总结果、生成人类可读版本  | `mythril-report.md`       | Markdown   | 按漏洞类型分组的报告 + 函数位置 + SWC 标准引用           | 直接用于审计报告附件                |



