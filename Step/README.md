# BakerFi 项目脚本工具集

本目录包含所有用于搭建环境、验证项目和清理的自动化脚本。

## 🚀 快速开始（3 步）

```bash
# 1. 安装环境
./Step/setup.sh

# 2. 验证项目（自动生成报告）
./Step/verify-project.sh

# 3. 查看报告
cat PROJECT_VERIFICATION_REPORT.md
```

就这么简单！✅

---

## 📋 脚本列表

| 脚本 | 功能 | 使用频率 |
|------|------|----------|
| ⭐ **verify-project.sh** | **一键验证项目功能** | **开始审计前必运行** |
| `setup.sh` | 安装完整环境 | 初次安装 |
| `activate-env.sh` | 激活环境 | 每次打开新终端 |
| `verify-tools.sh` | 快速验证工具 | 环境检查 |
| `install-glow.sh` | 安装 Glow（Markdown渲染器） | 可选安装 |
| `install-tilix.sh` | 安装并配置 Tilix 终端 | 可选安装 |
| `clear.sh` | 清理生成文件 | 提交代码前 |

---

## ⭐ 重点：verify-project.sh

**这是最重要的脚本！** 用于验证项目功能并生成完整报告。

### 功能
```
✅ 激活环境
✅ 安装依赖
✅ 编译合约（208个）
✅ 运行测试（331个）
✅ 生成覆盖率
✅ 检查POC
✅ 生成报告（Markdown）
```

### 使用
```bash
./Step/verify-project.sh
```

### 输出
- ✅ `PROJECT_VERIFICATION_REPORT.md` - 完整报告
- ✅ `coverage/` - 覆盖率报告
- ✅ 终端彩色输出

### 时间
约 8-10 分钟

---

## 📝 详细文档

查看完整文档：[SETUP_GUIDE.md](./SETUP_GUIDE.md)

---

## 🔄 典型工作流

### 场景 1: 首次使用
```bash
# 1. 安装环境
./Step/setup.sh

# 2. 验证项目
./Step/verify-project.sh

# 3. 开始审计
# 查看 PROJECT_VERIFICATION_REPORT.md
```

### 场景 2: VirtualBox 还原后
```bash
# 1. 验证环境和项目（自动检测并安装）
./Step/verify-project.sh

# 2. 如环境有问题，重新安装
./Step/setup.sh
```

### 场景 3: 日常使用
```bash
# 每次打开新终端
source ./Step/activate-env.sh

# 编译和测试
npx hardhat compile
npx hardhat test
```

### 场景 4: 代码更新后
```bash
# 重新验证项目
./Step/verify-project.sh

# 对比新旧报告
diff PROJECT_VERIFICATION_REPORT.md PROJECT_VERIFICATION_REPORT.md.bak
```

### 场景 5: 提交代码前
```bash
# 清理生成文件
./clear.sh

# 验证清理结果
git status
```

---

## 📊 脚本功能对比

| 功能 | setup.sh | verify-project.sh | verify-tools.sh | clear.sh |
|------|----------|-------------------|-----------------|----------|
| 安装工具 | ✅ | ❌ | ❌ | ❌ |
| 检查环境 | ✅ | ✅ | ✅ | ❌ |
| 安装依赖 | ❌ | ✅ | ❌ | ❌ |
| 编译合约 | ❌ | ✅ | ❌ | ❌ |
| 运行测试 | ❌ | ✅ | ❌ | ❌ |
| 生成覆盖率 | ❌ | ✅ | ❌ | ❌ |
| 生成报告 | ❌ | ✅ | ❌ | ❌ |
| 清理文件 | ❌ | ❌ | ❌ | ✅ |
| 执行时间 | ~5分钟 | ~8分钟 | <1分钟 | <1分钟 |

---

## ⚙️ 环境要求

- **操作系统**: Linux (Ubuntu/Debian 推荐)
- **必需工具**: curl, wget, git
- **磁盘空间**: ~2GB
- **网络**: 需要互联网连接

安装会自动配置：
- Node.js 20.11.0 (via nvm)
- Python 3.11.7 (via Miniconda)
- Slither, Echidna, Mythril, Surya

---

## 🎯 脚本选择指南

**我应该运行哪个脚本？**

```
全新系统？
  → setup.sh

要验证项目？
  → verify-project.sh ⭐（推荐！）

打开新终端？
  → source ./Step/activate-env.sh

检查工具是否正常？
  → verify-tools.sh

代码改动了？
  → verify-project.sh

要提交代码？
  → clear.sh
```

---

## 📁 生成的文件

### 由 setup.sh 生成
```
~/.nvm/              # Node.js
~/miniconda3/        # Python 环境
~/.local/bin/        # Echidna
activate-env.sh      # 激活脚本
.env                 # 环境配置
.env-versions        # 版本记录
```

### 由 verify-project.sh 生成
```
PROJECT_VERIFICATION_REPORT.md  # ⭐ 主要报告
coverage/                       # HTML 覆盖率
artifacts/                      # 编译产物
cache/                          # Hardhat 缓存
src/types/                      # TypeScript 类型
```

---

## 📖 可选工具

### Glow - Markdown 渲染器

为了更方便地在终端中查看文档，我们提供了 Glow 安装脚本：

```bash
# 安装 Glow
./Step/install-glow.sh

# 使用 Glow 查看文档（自动适应终端宽度）
glow README.md
glow Step/SETUP_GUIDE.md
glow PROJECT_VERIFICATION_REPORT.md
```

**特性**：
- ✅ 自动适应终端宽度
- ✅ 彩色语法高亮
- ✅ 分页浏览大文件
- ✅ 支持代码块渲染
- ✅ 安装后立即可用

### Tilix - 现代化终端模拟器

强大的平铺式终端，支持分屏和多标签：

```bash
# 安装并配置 Tilix（黑色背景）
./Step/install-tilix.sh

# 启动 Tilix
tilix
```

**特性**：
- ✅ 自动配置黑色背景主题
- ✅ 平铺式终端布局
- ✅ 拖放重新排列终端
- ✅ 同步输入到多个终端
- ✅ 现代化 UI 界面
- ✅ Shell 命令别名（tl, tlx）

---

## 💡 提示

1. **第一次使用**建议先运行 `setup.sh`，再运行 `verify-project.sh`
2. **verify-project.sh** 会自动激活环境，无需手动运行 `activate-env.sh`
3. **报告会被覆盖**，如需保留旧报告请备份
4. **所有脚本都支持重复运行**，不会破坏环境
5. **VirtualBox 还原后**可直接运行 `verify-project.sh`
6. **建议安装 Glow** 以获得更好的文档阅读体验
7. **建议安装 Tilix** 作为主要终端（支持分屏、黑色主题）

---

## ❓ 常见问题

**Q: verify-project.sh 和 setup.sh 的区别？**  
A: setup.sh 安装工具，verify-project.sh 验证项目功能并生成报告。

**Q: 每次都要运行 verify-project.sh 吗？**  
A: 不需要。只在开始审计前、代码更新后或环境验证时运行。

**Q: 报告在哪里？**  
A: `PROJECT_VERIFICATION_REPORT.md` 在项目根目录。

**Q: 如何只运行测试而不生成报告？**  
A: 使用 `npx hardhat test`

**Q: 脚本运行失败怎么办？**  
A: 查看终端输出的错误信息，或重新运行 `setup.sh`

---

## 📞 技术支持

- 📖 完整文档：[SETUP_GUIDE.md](./SETUP_GUIDE.md)
- 🐛 问题报告：检查脚本执行日志
- 💬 Telegram: @bakerfi

---

**版本**: v1.0  
**最后更新**: 2025-10-11  
**维护者**: BakerFi Team

