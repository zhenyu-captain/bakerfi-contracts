# BakerFi 环境设置指南
./Step/setup.sh
./Step/activate-env.sh
./Step/verify-tools.sh
./Step/verify-project.sh
./clear.sh


## 📋 脚本说明

本项目包含五个核心脚本，所有脚本都**支持重复运行**（幂等性）：

| 脚本 | 功能 | 幂等性 | 使用频率 |
|------|------|--------|----------|
| `setup.sh` | 安装完整开发和审计环境 | ✅ 完全幂等 | 初次安装 / 环境损坏时 |
| `activate-env.sh` | 激活开发环境 | ✅ 可无限次运行 | 每次打开新终端 |
| `verify-tools.sh` | 验证所有工具是否正常工作 | ✅ 只读检查 | 任何时候验证环境 |
| `verify-project.sh` | **完整项目功能验证** | ✅ 可重复运行 | **开始审计前 / 验证项目** |
| `clear.sh` | 清理本地生成的文件 | ✅ 安全清理 | 提交代码前 / 重置环境 |

## 🚀 快速开始

### 1. 初次安装（全新系统）

```bash
# 进入项目目录
cd /home/mi/bakerfi-contracts

# 运行安装脚本
./setup.sh

# 安装完成后，激活环境
source ./activate-env.sh

# 验证所有工具
./verify-tools.sh
```

### 2. VirtualBox 还原后重新安装

**方案 A: 直接重新运行（推荐）**
```bash
cd /home/mi/bakerfi-contracts

# 直接运行，脚本会跳过已安装的组件
./setup.sh

# 激活环境
source ./activate-env.sh

# 验证环境
./verify-tools.sh
```

**方案 B: 强制完全重新安装**
```bash
cd /home/mi/bakerfi-contracts

# 使用 FORCE_REINSTALL 环境变量
FORCE_REINSTALL=1 ./setup.sh

source ./activate-env.sh
./verify-tools.sh
```

### 3. 日常使用

每次打开新终端时：
```bash
cd /home/mi/bakerfi-contracts
source ./activate-env.sh
```

然后就可以使用所有工具了！

## 🔧 脚本详细说明

### setup.sh - 安装脚本

**功能：**
- 检查系统基础依赖（curl, wget, git）
- 安装 Node.js 20.11.0 (via nvm)
- 安装 Python 3.11.7 (via Miniconda)
- 安装项目 npm 依赖
- 安装审计工具：Slither, Mythril, Echidna, Surya
- 创建环境激活脚本和配置文件

**幂等性保证：**
- ✅ 检查 nvm 是否已安装
- ✅ 检查 Node.js 版本是否存在
- ✅ 检查 Miniconda 是否已安装
- ✅ 检查 conda 环境是否存在
- ✅ 检查 Echidna 是否已安装
- ✅ 检查 .env 文件是否存在

**重复运行行为：**
- 已安装的组件会被跳过
- Python/npm 包会被更新到指定版本
- 配置文件不会覆盖已存在的 .env
- activate-env.sh 会被更新（确保最新）

**安装位置：**
```
~/.nvm/                      # nvm
~/.nvm/versions/node/20.11.0 # Node.js
~/miniconda3/                # Miniconda
~/miniconda3/envs/bakerfi/   # Python 环境
~/.local/bin/                # Echidna
./node_modules/              # npm 依赖
./activate-env.sh            # 激活脚本
./.env                       # 环境配置
./.env-versions              # 版本记录
```

### activate-env.sh - 环境激活脚本

**功能：**
- 添加 ~/.local/bin 到 PATH
- 激活 nvm
- 激活 conda 环境 bakerfi

**使用方法：**
```bash
source ./activate-env.sh
```

**注意：**
- 必须使用 `source` 或 `.` 命令
- 每次打开新终端都需要运行
- 可以无限次重复运行

### verify-tools.sh - 验证脚本

**功能：**
检查以下工具是否正常工作：
- Node.js, npm
- Python
- Slither
- Echidna
- Mythril
- Surya
- solc-select
- Hardhat

**使用方法：**
```bash
./verify-tools.sh
```

**输出示例：**
```
==========================================
BakerFi 工具验证
==========================================

=== 核心工具 ===
✓ Node.js v20.11.0
✓ npm 10.2.4
✓ Python 3.11.7

=== 审计工具 ===
✓ Slither 0.10.0
✓ Echidna 2.2.4
✓ Mythril v0.24.8
✓ Surya
✓ solc-select & solc Version: 0.8.24

=== Hardhat 检查 ===
✓ Hardhat

==========================================
结果: 9 通过 / 0 失败
==========================================

🎉 所有工具都已正确安装！
```

## 📦 已安装工具版本

| 工具 | 版本 | 说明 |
|------|------|------|
| Node.js | 20.11.0 | JavaScript 运行时 |
| npm | 10.2.4 | 包管理器 |
| Python | 3.11.7 | Python 解释器 |
| Slither | 0.10.0 | 静态分析工具 |
| Mythril | 0.24.8 | 符号执行工具（可选） |
| Echidna | 2.2.4 | 模糊测试工具（可选） |
| Surya | 0.4.11 | 可视化工具（可选） |
| solc | 0.8.24 | Solidity 编译器 |

## ⚠️ 常见问题

### Q1: 还原 VirtualBox 快照后需要做什么？

**A:** 直接运行三个脚本即可：
```bash
cd /home/mi/bakerfi-contracts
./setup.sh                    # 会自动检测并跳过已安装组件
source ./activate-env.sh      # 激活环境
./verify-tools.sh             # 验证环境
```

### Q2: 如何完全重新安装？

**A:** 有两种方法：

方法 1: 使用环境变量
```bash
FORCE_REINSTALL=1 ./setup.sh
```

方法 2: 删除标记文件后重新安装
```bash
rm .env-versions
./setup.sh
```

### Q3: 脚本运行失败了怎么办？

**A:** 
1. 查看日志文件 `setup.log`
2. 运行 `./verify-tools.sh` 查看哪些工具有问题
3. 重新运行 `./setup.sh`（脚本会跳过已成功安装的部分）

### Q4: 可以在不同的终端同时使用吗？

**A:** 可以！每个终端都需要运行：
```bash
source ./activate-env.sh
```

### Q5: 环境变量在哪里配置？

**A:** 编辑 `.env` 文件（已自动创建）：
```bash
nano .env
```

## 🎯 下一步

环境安装完成后，可以开始审计工作：

```bash
# 1. 编译合约
npx hardhat compile

# 2. 运行测试
npx hardhat test

# 3. 生成覆盖率报告
npx hardhat coverage

# 4. 运行静态分析
slither . --config-file slither.config.json

# 5. 运行模糊测试（可选）
echidna . --config echidna.yaml
```

## 📝 脚本维护

所有脚本的版本配置集中在 `setup.sh` 的开头：

```bash
NODE_VERSION="20.11.0"
PYTHON_VERSION="3.11.7"
SLITHER_VERSION="0.10.0"
MYTHRIL_VERSION="0.24.8"
ECHIDNA_VERSION="2.2.4"
```

如需更新工具版本，只需修改这些变量后重新运行 `./setup.sh` 即可。

## 🔍 重要文件说明

| 文件 | 说明 | 是否可删除 |
|------|------|-----------|
| `setup.sh` | 安装脚本 | ❌ 核心文件 |
| `activate-env.sh` | 激活脚本（自动生成） | ⚠️ 会被重新生成 |
| `verify-tools.sh` | 验证脚本 | ❌ 推荐保留 |
| `.env` | 环境变量配置 | ⚠️ 不会被覆盖 |
| `.env-versions` | 版本记录 | ⚠️ 会被更新 |
| `setup.log` | 安装日志 | ✅ 可删除 |

---

### verify-project.sh - 项目功能验证脚本 ⭐

**功能：**
自动化执行完整的项目功能验证流程，并生成详细报告。这是**最重要的审计准备脚本**！

**执行流程：**
1. ✅ 激活开发环境（Node.js + Python）
2. ✅ 检查并安装项目依赖
3. ✅ 编译所有智能合约
4. ✅ 运行完整测试套件
5. ✅ 生成代码覆盖率报告
6. ✅ 检查 POC 和 Echidna 配置
7. ✅ 生成完整的验证报告 Markdown

**使用方法：**
```bash
cd /home/mi/bakerfi-contracts
./Step/verify-project.sh
```

**执行时间：** 约 8-10 分钟

**生成的文件：**
- ✅ `PROJECT_VERIFICATION_REPORT.md` - 完整验证报告（~400行）
- ✅ `coverage/` - HTML 覆盖率报告
- ✅ `artifacts/` - 编译产物
- ✅ `src/types/` - TypeScript 类型定义

**报告内容包括：**
| 章节 | 内容 |
|------|------|
| 📋 执行摘要 | 项目状态、测试通过率、覆盖率 |
| 🎯 任务完成情况 | 7 个验证任务的详细状态 |
| 🔧 环境配置 | 工具版本信息 |
| 📊 编译结果 | 合约数量、类型定义、警告 |
| ✅ 测试结果 | 通过/失败/跳过统计 |
| 📈 代码覆盖率 | 语句/分支/函数/行覆盖率 |
| 🔍 POC 和安全测试 | 攻击测试、Echidna 配置 |
| 🎯 项目质量评估 | A-F 等级评分 |
| 🚀 下一步建议 | 审计工作指引 |
| 📊 执行统计 | 时间统计 |

**输出示例：**
```
==========================================
BakerFi 项目功能验证脚本
==========================================

开始时间: 2025-10-11 21:00

[1/7] 激活开发环境...
✓ 环境已激活
  Node.js: v20.11.0
  npm: 10.2.4
  Python: Python 3.11.7

[2/7] 检查并安装项目依赖...
✓ 依赖已存在，跳过安装
  已安装包: 1280 个

[3/7] 编译智能合约...
✓ 编译完成 (15秒)
  合约数量: 208 个
  类型定义: 542 个
  警告数量: 3 个

[4/7] 运行完整测试套件...
✓ 测试完成 (15秒)
  总计: 369 个
  ✅ 通过: 331 个
  ⏸️  跳过: 38 个
  ❌ 失败: 0 个

[5/7] 生成测试覆盖率报告...
✓ 覆盖率报告生成完成 (120秒)
  语句覆盖率: 76.07
  分支覆盖率: 56.54
  函数覆盖率: 66.20
  行覆盖率: 74.45

[6/7] 检查 POC 和 Echidna 测试...
✓ POC 检查完成
  攻击测试文件: 1 个
  测试合约: 3 个
  Echidna 配置: 是

[7/7] 生成验证报告...
✓ 验证报告已生成: PROJECT_VERIFICATION_REPORT.md

==========================================
验证完成！
==========================================

执行摘要:
  总耗时: 8分30秒
  测试通过: 331/369
  覆盖率: 76.07

生成的文件:
  ✅ PROJECT_VERIFICATION_REPORT.md
  ✅ coverage/index.html

🎉 所有测试通过，可以开始审计工作！
```

**使用场景：**
1. **开始审计前** - 验证项目功能完整性
2. **代码更新后** - 确保没有破坏现有功能
3. **环境验证** - 确认开发环境正确配置
4. **定期检查** - 持续集成/质量保证

**优势：**
- ✅ **自动化** - 一键完成所有验证步骤
- ✅ **标准化** - 每次执行相同流程，结果可对比
- ✅ **详细报告** - Markdown 格式，易于阅读和分享
- ✅ **时间统计** - 记录每个步骤的执行时间
- ✅ **错误处理** - 即使某步失败也会继续执行
- ✅ **版本记录** - 记录所有工具版本信息

**退出状态：**
- `0` - 所有测试通过
- `1` - 存在失败的测试

**注意事项：**
- 脚本会自动激活环境，无需手动运行 `activate-env.sh`
- 如果依赖未安装，会自动执行 `npm install`
- 生成的报告会覆盖之前的报告
- 建议在 VirtualBox 快照前运行一次验证

**与其他脚本的关系：**
```
setup.sh          → 安装环境
  ↓
verify-project.sh → 验证项目功能（自动激活环境）
  ↓
审计工作开始       → 使用生成的报告
```

---

### clear.sh - 清理脚本

**功能：**
清理所有不需要提交到 git 的本地生成文件，包括：
- npm 依赖包 (`node_modules/`)
- Hardhat 编译产物 (`artifacts/`, `cache/`)
- TypeScript 类型生成 (`src/types/`, `typechain/`)
- 测试覆盖率报告 (`coverage/`)
- 日志文件 (`*.log`)
- 静态分析报告
- 临时文件

**使用场景：**
1. 提交代码到 git 前清理
2. 重置开发环境
3. 释放磁盘空间
4. 排查编译缓存问题

**使用方法：**
```bash
cd /home/mi/bakerfi-contracts
./Step/clear.sh
```

**清理内容详细列表：**

| 类别 | 清理项 | 说明 |
|------|--------|------|
| **Node.js** | `node_modules/` | npm 依赖包 |
| **Hardhat** | `artifacts/`, `cache/`, `.storage-layouts/` | 编译产物和缓存 |
| **TypeScript** | `src/types/`, `typechain/`, `dist/` | 类型生成和编译输出 |
| **测试** | `coverage/`, `coverage.json` | 覆盖率报告 |
| **日志** | `*.log`, `setup.log` | 所有日志文件 |
| **审计** | `slither-report.*`, `mythril-report.*` | 静态分析报告 |
| **临时** | `.tmp/`, `.DS_Store` | 临时文件和系统文件 |
| **其他** | `deployments/`, `.openzeppelin/` | 部署记录 |

**保留的文件：**
- ✅ `.env` - 保留（包含敏感配置）
- ✅ `.vscode/`, `.idea/` - 保留（IDE 配置）
- ✅ `audits/stage2/evidence/` - 保留（审计证据）
- ✅ 所有源代码文件

**清理后的操作：**
```bash
# 1. 重新安装依赖
npm install

# 2. 重新编译合约
npx hardhat compile

# 3. 如果清理了环境脚本
./Step/setup.sh
source ./Step/activate-env.sh
```

**安全提示：**
- ✅ 脚本会检查项目目录（必须包含 `package.json` 和 `hardhat.config.ts`）
- ✅ 不会删除源代码和配置文件
- ✅ 保留 `.env` 文件避免丢失敏感信息
- ✅ 显示清理统计和 git 状态

**示例输出：**
```
==========================================
BakerFi 项目清理脚本
==========================================

开始清理...

=== [1/10] Node.js 依赖 ===
正在删除: node_modules/ (npm 依赖包) (450M)
✓ 已删除

=== [2/10] Hardhat 编译产物 ===
正在删除: artifacts/ (编译产物) (12M)
✓ 已删除
正在删除: cache/ (Hardhat 缓存) (3M)
✓ 已删除

...

==========================================
清理完成！
==========================================

清理统计:
  已删除项目: 15 个

=== Git 状态检查 ===
✓ 没有未追踪的文件
```

---

**总结：所有脚本都支持重复运行，VirtualBox 还原后可以直接重新执行！** 🎉

