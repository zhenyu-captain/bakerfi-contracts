#!/bin/bash

# Glow 安装脚本
# Glow 是一个终端 Markdown 渲染器，让你方便地查看 README 和文档

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "Glow Markdown 渲染器安装脚本"
echo "=========================================="
echo ""

# 检查是否已安装
if command -v glow &> /dev/null; then
    CURRENT_VERSION=$(glow --version | grep -oP '\d+\.\d+\.\d+' | head -n 1)
    echo -e "${GREEN}✓${NC} Glow 已安装 (版本: $CURRENT_VERSION)"
    GLOW_INSTALLED=true
else
    GLOW_INSTALLED=false
    echo -e "${BLUE}开始安装 Glow...${NC}"
    echo ""
fi

# 检测系统类型
OS_TYPE=""
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_TYPE=$ID
fi

# 根据不同的系统使用不同的安装方法
install_glow() {
    case "$OS_TYPE" in
        ubuntu|debian)
            echo -e "${YELLOW}检测到 Debian/Ubuntu 系统${NC}"
            echo "使用 apt 安装..."
            
            # 添加 glow 仓库
            if ! grep -q "charm.sh" /etc/apt/sources.list.d/charm.list 2>/dev/null; then
                echo "添加 Charm 仓库..."
                sudo mkdir -p /etc/apt/keyrings
                curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
                echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
                sudo apt update
            fi
            
            sudo apt install -y glow
            ;;
            
        fedora|rhel|centos)
            echo -e "${YELLOW}检测到 Fedora/RHEL/CentOS 系统${NC}"
            echo "使用 yum/dnf 安装..."
            
            echo '[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key' | sudo tee /etc/yum.repos.d/charm.repo
            
            if command -v dnf &> /dev/null; then
                sudo dnf install -y glow
            else
                sudo yum install -y glow
            fi
            ;;
            
        arch|manjaro)
            echo -e "${YELLOW}检测到 Arch/Manjaro 系统${NC}"
            echo "使用 pacman 安装..."
            sudo pacman -S --noconfirm glow
            ;;
            
        *)
            # 如果无法识别系统，尝试直接下载二进制文件
            echo -e "${YELLOW}未识别的系统，使用通用安装方法${NC}"
            echo "下载预编译二进制文件..."
            
            # 检测架构
            ARCH=$(uname -m)
            case "$ARCH" in
                x86_64)
                    ARCH="x86_64"
                    ;;
                aarch64|arm64)
                    ARCH="arm64"
                    ;;
                armv7l)
                    ARCH="armv7"
                    ;;
                *)
                    echo -e "${RED}不支持的架构: $ARCH${NC}"
                    exit 1
                    ;;
            esac
            
            # 下载最新版本
            GLOW_VERSION="1.5.1"
            DOWNLOAD_URL="https://github.com/charmbracelet/glow/releases/download/v${GLOW_VERSION}/glow_${GLOW_VERSION}_linux_${ARCH}.tar.gz"
            
            echo "下载 Glow v${GLOW_VERSION} for Linux ${ARCH}..."
            TMP_DIR=$(mktemp -d)
            cd "$TMP_DIR"
            
            if ! curl -sL "$DOWNLOAD_URL" -o glow.tar.gz; then
                echo -e "${RED}下载失败${NC}"
                exit 1
            fi
            
            tar -xzf glow.tar.gz
            
            # 安装到用户目录
            mkdir -p "$HOME/.local/bin"
            mv glow "$HOME/.local/bin/"
            chmod +x "$HOME/.local/bin/glow"
            
            # 确保 ~/.local/bin 在 PATH 中
            if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
                echo ""
                echo -e "${YELLOW}提示: 需要将 ~/.local/bin 添加到 PATH${NC}"
                echo "请在 ~/.bashrc 或 ~/.zshrc 中添加："
                echo -e "${BLUE}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
                echo ""
                export PATH="$HOME/.local/bin:$PATH"
            fi
            
            cd - > /dev/null
            rm -rf "$TMP_DIR"
            ;;
    esac
}

# 执行安装（如果需要）
if [ "$GLOW_INSTALLED" = false ]; then
    if install_glow; then
        echo ""
        echo -e "${GREEN}✓ Glow 安装成功！${NC}"
        echo ""
        
        # 验证安装
        if command -v glow &> /dev/null; then
            VERSION=$(glow --version | grep -oP '\d+\.\d+\.\d+' | head -n 1)
            echo -e "${GREEN}已安装版本: $VERSION${NC}"
        fi
    else
        echo ""
        echo -e "${RED}✗ 安装失败${NC}"
        echo ""
        echo "请尝试手动安装："
        echo "  Ubuntu/Debian: sudo apt install glow"
        echo "  Fedora: sudo dnf install glow"
        echo "  Arch: sudo pacman -S glow"
        echo ""
        echo "或访问: https://github.com/charmbracelet/glow"
        exit 1
    fi
fi

# 配置 alias（无论是否刚安装）
if command -v glow &> /dev/null; then
    
    echo ""
    echo -e "${BLUE}配置自动宽度适配...${NC}"
    
    # 配置 alias 到 shell 配置文件
    GLOW_ALIAS="alias glow='glow --width=\$(tput cols)'"
    CONFIGURED=false
    
    # 配置 zsh
    if [ -f "$HOME/.zshrc" ]; then
        if ! grep -q "glow --width=" "$HOME/.zshrc" 2>/dev/null; then
            echo "" >> "$HOME/.zshrc"
            echo "# Glow - 自动适应终端宽度" >> "$HOME/.zshrc"
            echo "$GLOW_ALIAS" >> "$HOME/.zshrc"
            echo -e "${GREEN}✓${NC} 已添加到 ~/.zshrc"
            CONFIGURED=true
        else
            echo -e "${YELLOW}⚠${NC}  ~/.zshrc 中已存在 glow alias"
        fi
    fi
    
    # 配置 bash
    if [ -f "$HOME/.bashrc" ]; then
        if ! grep -q "glow --width=" "$HOME/.bashrc" 2>/dev/null; then
            echo "" >> "$HOME/.bashrc"
            echo "# Glow - 自动适应终端宽度" >> "$HOME/.bashrc"
            echo "$GLOW_ALIAS" >> "$HOME/.bashrc"
            echo -e "${GREEN}✓${NC} 已添加到 ~/.bashrc"
            CONFIGURED=true
        else
            echo -e "${YELLOW}⚠${NC}  ~/.bashrc 中已存在 glow alias"
        fi
    fi
    
    # 让 alias 立即生效
    if [ "$CONFIGURED" = true ]; then
        echo ""
        echo -e "${GREEN}✓ Alias 已配置成功${NC}"
        echo ""
        echo -e "${YELLOW}⚡ 让配置立即生效：${NC}"
        
        # 检测当前使用的 shell
        CURRENT_SHELL=$(basename "$SHELL")
        
        if [ "$CURRENT_SHELL" = "zsh" ] && [ -f "$HOME/.zshrc" ]; then
            echo -e "  ${BLUE}source ~/.zshrc${NC}"
            echo ""
            echo "或者重新打开终端窗口"
        elif [ "$CURRENT_SHELL" = "bash" ] && [ -f "$HOME/.bashrc" ]; then
            echo -e "  ${BLUE}source ~/.bashrc${NC}"
            echo ""
            echo "或者重新打开终端窗口"
        else
            echo -e "  ${BLUE}source ~/.zshrc${NC}  (zsh 用户)"
            echo -e "  ${BLUE}source ~/.bashrc${NC} (bash 用户)"
        fi
        
        echo ""
        echo -e "${GREEN}配置内容：${NC}"
        echo -e "  ${BLUE}alias glow='glow --width=\$(tput cols)'${NC}"
        echo ""
        echo "这将使 glow 自动适应你的终端宽度"
    fi
    
    echo ""
    echo "=========================================="
    echo "使用方法："
    echo "=========================================="
    echo ""
    echo "基本用法（自动适应宽度）："
    echo -e "  ${BLUE}glow README.md${NC}"
    echo -e "  ${BLUE}glow Step/SETUP_GUIDE.md${NC}"
    echo ""
    echo "分页模式（大文件推荐）："
    echo -e "  ${BLUE}glow -p README.md${NC}"
    echo ""
    echo "直接在终端输出（不分页）："
    echo -e "  ${BLUE}glow -s dark README.md${NC}"
    echo ""
    echo "查看所有 markdown 文件："
    echo -e "  ${BLUE}glow .${NC}"
    echo ""
    echo "更多快捷方式（可添加到 shell 配置）："
    echo -e "  ${BLUE}alias readme='glow README.md'${NC}"
    echo -e "  ${BLUE}alias guide='glow Step/SETUP_GUIDE.md'${NC}"
    echo ""
    echo "=========================================="
    echo ""
    
    # 提供一个快速测试
    if [ -f "README.md" ]; then
        echo -e "${YELLOW}是否现在查看 README.md? (y/n)${NC}"
        read -r -n 1 response
        echo ""
        if [[ "$response" =~ ^[Yy]$ ]]; then
            glow README.md
        fi
    fi
else
    echo ""
    echo -e "${RED}✗ Glow 未安装${NC}"
    echo ""
    echo "请先安装 Glow 或检查 PATH 配置"
    exit 1
fi

