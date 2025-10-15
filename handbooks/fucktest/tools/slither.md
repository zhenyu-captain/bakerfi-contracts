# Slither 静态分析基线

已创建的提取脚本
 	脚本	输出类型	描述
1	extract-abi.sh	JSON	合约 ABI
2	extract-ast.sh	JSON	抽象语法树
3	extract-detectors.sh	JSON	安全检测结果
4	extract-contract-summary.sh	TXT	合约摘要
5	extract-function-summary.sh	TXT	函数摘要（包含复杂度）
6	extract-call-graph.sh	DOT	调用关系图
7	extract-data-dependency.sh	TXT	数据依赖图（变量流）
8	extract-slithir.sh	TXT	SlithIR 中间表示（SSA/控制流）✨


已创建的提取脚本创建的目录结构
slither_analysis/
├── abi/                    # 合约 ABI (JSON)
├── ast/                    # 抽象语法树 (JSON)
├── detectors/              # 安全检测结果 (JSON)
├── contract-summary/       # 合约摘要 (TXT)
├── function-summary/       # 函数摘要 (TXT)
├── call-graph/             # 调用关系图 (DOT)
├── data-dependency/        # 数据依赖图 (TXT)
├── slithir/                # SlithIR 中间表示 (TXT) ✨
├── extract-*.sh            # 8 个提取脚本
├── check.sh                # 完整性检查
└── README.md

**更新日期**: 2025-10-14  
**Slither 版本**: 0.10.x  
**适用于**: BakerFi 安全审计

