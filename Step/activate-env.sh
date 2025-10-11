#!/bin/bash
# BakerFi 环境激活脚本
# 使用方法: source ./activate-env.sh

# 添加本地 bin 到 PATH
export PATH="$HOME/.local/bin:$PATH"

# 激活 nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# 激活 conda 环境
eval "$($HOME/miniconda3/bin/conda shell.bash hook)"
conda activate bakerfi

echo "✓ BakerFi 开发环境已激活"
echo "  Node.js: $(node --version)"
echo "  Python: $(python --version 2>&1)"
