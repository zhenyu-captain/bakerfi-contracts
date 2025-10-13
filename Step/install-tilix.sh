#!/bin/bash

# Tilix 安装和配置脚本
# 安装 Tilix 终端模拟器并设置黑色背景

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "Tilix 终端模拟器安装和配置脚本"
echo "=========================================="
echo ""

# 检查是否已安装
if command -v tilix &> /dev/null; then
    CURRENT_VERSION=$(tilix --version | grep -oP '\d+\.\d+\.\d+' | head -n 1)
    echo -e "${GREEN}✓${NC} Tilix 已安装 (版本: $CURRENT_VERSION)"
    TILIX_INSTALLED=true
else
    TILIX_INSTALLED=false
    echo -e "${BLUE}开始安装 Tilix...${NC}"
    echo ""
fi

# 检测系统类型
OS_TYPE=""
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_TYPE=$ID
fi

# 安装 tilix
install_tilix() {
    case "$OS_TYPE" in
        ubuntu|debian)
            echo -e "${YELLOW}检测到 Debian/Ubuntu 系统${NC}"
            echo "使用 apt-get 安装..."
            sudo apt-get update
            sudo apt-get install -y tilix
            ;;
            
        fedora|rhel|centos)
            echo -e "${YELLOW}检测到 Fedora/RHEL/CentOS 系统${NC}"
            echo "使用 dnf/yum 安装..."
            if command -v dnf &> /dev/null; then
                sudo dnf install -y tilix
            else
                sudo yum install -y tilix
            fi
            ;;
            
        arch|manjaro)
            echo -e "${YELLOW}检测到 Arch/Manjaro 系统${NC}"
            echo "使用 pacman 安装..."
            sudo pacman -S --noconfirm tilix
            ;;
            
        *)
            echo -e "${RED}未识别的系统${NC}"
            echo "请手动安装 Tilix："
            echo "  Ubuntu/Debian: sudo apt-get install tilix"
            echo "  Fedora: sudo dnf install tilix"
            echo "  Arch: sudo pacman -S tilix"
            return 1
            ;;
    esac
}

# 执行安装（如果需要）
if [ "$TILIX_INSTALLED" = false ]; then
    if install_tilix; then
        echo ""
        echo -e "${GREEN}✓ Tilix 安装成功！${NC}"
        echo ""
        
        # 验证安装
        if command -v tilix &> /dev/null; then
            VERSION=$(tilix --version | grep -oP '\d+\.\d+\.\d+' | head -n 1)
            echo -e "${GREEN}已安装版本: $VERSION${NC}"
        fi
    else
        echo ""
        echo -e "${RED}✗ 安装失败${NC}"
        exit 1
    fi
fi

# 配置 Tilix（无论是否刚安装）
if command -v tilix &> /dev/null; then
    
    echo ""
    echo -e "${BLUE}配置 Tilix 黑色背景主题...${NC}"
    
    # 检查 dconf 是否可用
    if ! command -v dconf &> /dev/null; then
        echo -e "${YELLOW}⚠${NC}  dconf 未安装，尝试安装..."
        sudo apt-get install -y dconf-cli 2>/dev/null || sudo apt-get install -y dconf-tools 2>/dev/null || true
    fi
    
    # 获取默认配置文件 UUID
    # Tilix 使用 dconf 存储配置
    TILIX_SCHEMA="com.gexperts.Tilix"
    
    # 检查是否有现有的配置文件
    if command -v dconf &> /dev/null; then
        # 首先需要先启动一次 tilix 让它创建默认配置
        echo -e "${BLUE}检查 Tilix 配置...${NC}"
        
        # 检查是否有配置
        PROFILE_CHECK=$(dconf read /com/gexperts/Tilix/profileIDs 2>/dev/null)
        
        if [ -z "$PROFILE_CHECK" ]; then
            echo -e "${YELLOW}⚠${NC}  首次运行，需要初始化 Tilix 配置..."
            echo -e "${YELLOW}⚠${NC}  启动 Tilix 创建默认配置（将在 3 秒后自动关闭）..."
            
            # 启动 tilix 并在后台运行，等待它创建配置
            tilix &
            TILIX_PID=$!
            sleep 3
            kill $TILIX_PID 2>/dev/null || true
            sleep 1
            
            echo -e "${GREEN}✓${NC} 配置已初始化"
        fi
        
        # 获取默认配置文件 ID
        DEFAULT_PROFILE=$(dconf read /com/gexperts/Tilix/profileIDs 2>/dev/null | tr -d "[]'" | sed 's/,.*//g' | tr -d ' ')
        
        if [ -z "$DEFAULT_PROFILE" ]; then
            # 如果仍然没有配置文件，创建一个新的
            DEFAULT_PROFILE=$(uuidgen)
            echo -e "${YELLOW}⚠${NC}  创建新的配置文件: $DEFAULT_PROFILE"
            dconf write /com/gexperts/Tilix/profileIDs "['$DEFAULT_PROFILE']"
            dconf write /com/gexperts/Tilix/profiles/$DEFAULT_PROFILE/visible-name "'Default'"
        else
            echo -e "${GREEN}✓${NC} 找到现有配置文件: $DEFAULT_PROFILE"
        fi
        
        PROFILE_PATH="/com/gexperts/Tilix/profiles/$DEFAULT_PROFILE"
        
        # 设置黑色背景和白色前景
        echo -e "${BLUE}设置颜色方案...${NC}"
        
        # 使用自定义颜色（黑色背景）- 注意格式
        dconf write ${PROFILE_PATH}/use-theme-colors false
        dconf write ${PROFILE_PATH}/background-color "'rgb(0,0,0)'"
        dconf write ${PROFILE_PATH}/foreground-color "'rgb(255,255,255)'"
        
        # 设置背景透明度（100 表示完全不透明）
        dconf write ${PROFILE_PATH}/background-transparency-percent 100
        
        # 使用系统字体
        dconf write ${PROFILE_PATH}/use-system-font true
        
        # 设置光标颜色
        dconf write ${PROFILE_PATH}/cursor-colors-set false
        
        # 禁用终端响铃
        dconf write ${PROFILE_PATH}/terminal-bell "'none'"
        
        # 设置滚动
        dconf write ${PROFILE_PATH}/scrollback-unlimited false
        dconf write ${PROFILE_PATH}/scrollback-lines 10000
        
        # 显示滚动条
        dconf write ${PROFILE_PATH}/show-scrollbar true
        
        # 验证配置
        BG_COLOR=$(dconf read ${PROFILE_PATH}/background-color 2>/dev/null)
        FG_COLOR=$(dconf read ${PROFILE_PATH}/foreground-color 2>/dev/null)
        
        echo -e "${GREEN}✓${NC} 已设置黑色背景: $BG_COLOR"
        echo -e "${GREEN}✓${NC} 已设置白色文字: $FG_COLOR"
        echo -e "${GREEN}✓${NC} 配置已应用到配置文件: $DEFAULT_PROFILE"
        
    else
        echo -e "${RED}✗${NC} 无法配置 Tilix，dconf 不可用"
        echo ""
        echo "你可以手动在 Tilix 中配置："
        echo "  1. 打开 Tilix"
        echo "  2. 点击菜单 -> Preferences"
        echo "  3. 选择 Profiles 标签"
        echo "  4. 选择默认配置文件"
        echo "  5. 在 Colors 选项卡中："
        echo "     - 取消勾选 'Use colors from system theme'"
        echo "     - 设置背景色为黑色 (#000000)"
        echo "     - 设置前景色为白色 (#FFFFFF)"
    fi
    
    # 在 zshrc 和 bashrc 中添加别名
    echo ""
    echo -e "${BLUE}添加 Shell 别名...${NC}"
    
    if [ -f "$HOME/.zshrc" ]; then
        if ! grep -q "alias tilix=" "$HOME/.zshrc" 2>/dev/null; then
            cat >> "$HOME/.zshrc" << 'EOF'

# Tilix 快捷命令
alias tl='tilix'
alias tlx='tilix'

EOF
            echo -e "${GREEN}✓${NC} 已添加别名到 ~/.zshrc"
        fi
    fi
    
    if [ -f "$HOME/.bashrc" ]; then
        if ! grep -q "alias tilix=" "$HOME/.bashrc" 2>/dev/null; then
            cat >> "$HOME/.bashrc" << 'EOF'

# Tilix 快捷命令
alias tl='tilix'
alias tlx='tilix'

EOF
            echo -e "${GREEN}✓${NC} 已添加别名到 ~/.bashrc"
        fi
    fi
    
    echo ""
    echo -e "${GREEN}✓ 配置完成！${NC}"
    echo ""
    echo "=========================================="
    echo "Tilix 特性："
    echo "=========================================="
    echo ""
    echo -e "${BLUE}核心功能：${NC}"
    echo "  • 平铺式终端布局"
    echo "  • 支持多个窗口和会话"
    echo "  • 拖放重新排列终端"
    echo "  • 同步输入到多个终端"
    echo "  • 自定义配色方案"
    echo "  • 支持终端通知"
    echo ""
    echo -e "${BLUE}常用快捷键：${NC}"
    echo -e "  ${GREEN}Ctrl+Alt+T${NC}         打开新的 Tilix 窗口"
    echo -e "  ${GREEN}Ctrl+Shift+D${NC}       垂直分割终端"
    echo -e "  ${GREEN}Ctrl+Shift+R${NC}       水平分割终端"
    echo -e "  ${GREEN}Ctrl+Shift+W${NC}       关闭当前终端"
    echo -e "  ${GREEN}Alt+方向键${NC}         在分割的终端间切换"
    echo -e "  ${GREEN}Ctrl+Shift+T${NC}       新建标签页"
    echo -e "  ${GREEN}Ctrl+PageUp/Down${NC}   切换标签页"
    echo ""
    echo -e "${BLUE}Shell 别名：${NC}"
    echo -e "  ${GREEN}tl${NC}  或  ${GREEN}tlx${NC}       启动 Tilix"
    echo ""
    echo "=========================================="
    echo ""
    
    echo -e "${YELLOW}⚡ 让配置生效：${NC}"
    echo ""
    echo "1. 重新启动 Tilix（如果已打开）"
    echo -e "   ${BLUE}killall tilix && tilix${NC}"
    echo ""
    echo "2. 或者直接启动 Tilix："
    echo -e "   ${BLUE}tilix${NC}"
    echo ""
    
    # 检测当前使用的 shell
    CURRENT_SHELL=$(basename "$SHELL")
    if [ "$CURRENT_SHELL" = "zsh" ]; then
        echo "3. 重新加载 shell 配置（使用别名）："
        echo -e "   ${BLUE}source ~/.zshrc${NC}"
    elif [ "$CURRENT_SHELL" = "bash" ]; then
        echo "3. 重新加载 shell 配置（使用别名）："
        echo -e "   ${BLUE}source ~/.bashrc${NC}"
    fi
    
    echo ""
    echo "=========================================="
    echo ""
    
    # 提供快速测试
    echo -e "${YELLOW}是否现在启动 Tilix? (y/n)${NC}"
    read -r -n 1 response
    echo ""
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${GREEN}启动 Tilix...${NC}"
        echo ""
        # 在后台启动 Tilix
        tilix &
        sleep 1
        echo -e "${GREEN}✓${NC} Tilix 已启动（黑色背景已配置）"
    fi
    
else
    echo ""
    echo -e "${RED}✗ Tilix 未安装${NC}"
    echo ""
    echo "请先安装 Tilix 或检查 PATH 配置"
    exit 1
fi

echo ""
echo -e "${GREEN}=========================================="
echo "安装和配置完成！"
echo "==========================================${NC}"
echo ""

