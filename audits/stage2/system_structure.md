# 系统结构事实（阶段2）

说明：本文件用于记录模块边界、依赖关系与持币/可升级属性，供阶段3映射与证据聚合引用。

## 模块清单（示例，按需增补）
- vault：持币=是，可升级=是，外部依赖=router/strategies
- router：持币=否，可升级=否，外部依赖=vault/strategies
- strategies：持币=是，可升级=因实现，外部依赖=外部协议
- proxy：持币=否，可升级=是，外部依赖=admin/implementation
- oracles：持币=否，可升级=因实现，外部依赖=链上预言机

## 依赖关系与外部接口
- 描述与图谱路径：audits/stage2/graphs/*.dot|*.png（可选）