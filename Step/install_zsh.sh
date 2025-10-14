#!/bin/bash

# ZSH和历史命令插件自动安装脚本
# 支持Ubuntu/Debian、Fedora/RHEL/CentOS、Arch Linux

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检测操作系统
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    elif [ -f /etc/redhat-release ]; then
        OS="rhel"
    else
        print_error "无法检测操作系统类型"
        exit 1
    fi
    print_info "检测到操作系统: $OS"
}

# 安装zsh
install_zsh() {
    if command -v zsh &> /dev/null; then
        print_warning "zsh已经安装，跳过安装步骤"
        return 0
    fi

    print_info "开始安装zsh..."
    
    case $OS in
        ubuntu|debian|linuxmint)
            sudo apt-get update
            sudo apt-get install -y zsh git curl
            ;;
        fedora|rhel|centos)
            sudo dnf install -y zsh git curl || sudo yum install -y zsh git curl
            ;;
        arch|manjaro)
            sudo pacman -Sy --noconfirm zsh git curl
            ;;
        *)
            print_error "不支持的操作系统: $OS"
            exit 1
            ;;
    esac
    
    print_info "zsh安装完成"
}

# 安装Oh My Zsh
install_oh_my_zsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        print_warning "Oh My Zsh已经安装，跳过安装步骤"
        return 0
    fi

    print_info "开始安装Oh My Zsh..."
    
    # 使用非交互式安装
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    
    print_info "Oh My Zsh安装完成"
}

# 安装zsh-autosuggestions插件（自动建议）
install_autosuggestions() {
    local plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
    
    if [ -d "$plugin_dir" ]; then
        print_warning "zsh-autosuggestions已经安装，跳过安装步骤"
        return 0
    fi

    print_info "开始安装zsh-autosuggestions插件..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$plugin_dir"
    print_info "zsh-autosuggestions安装完成"
}

# 安装zsh-syntax-highlighting插件（语法高亮）
install_syntax_highlighting() {
    local plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
    
    if [ -d "$plugin_dir" ]; then
        print_warning "zsh-syntax-highlighting已经安装，跳过安装步骤"
        return 0
    fi

    print_info "开始安装zsh-syntax-highlighting插件..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugin_dir"
    print_info "zsh-syntax-highlighting安装完成"
}

# 安装zsh-history-substring-search插件（历史搜索）
install_history_substring_search() {
    local plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-history-substring-search"
    
    if [ -d "$plugin_dir" ]; then
        print_warning "zsh-history-substring-search已经安装，跳过安装步骤"
        return 0
    fi

    print_info "开始安装zsh-history-substring-search插件..."
    git clone https://github.com/zsh-users/zsh-history-substring-search "$plugin_dir"
    print_info "zsh-history-substring-search安装完成"
}

# 配置.zshrc文件
configure_zshrc() {
    print_info "配置.zshrc文件..."
    
    local zshrc="$HOME/.zshrc"
    
    # 备份原有配置
    if [ -f "$zshrc" ]; then
        cp "$zshrc" "$zshrc.backup.$(date +%Y%m%d%H%M%S)"
        print_info "已备份原有.zshrc文件"
    fi

    # 启用插件
    if [ -f "$zshrc" ]; then
        # 检查是否已经配置了插件
        if grep -q "plugins=(git" "$zshrc"; then
            # 替换插件列表
            sed -i 's/^plugins=(.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search)/' "$zshrc"
        else
            # 添加插件列表
            echo "plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search)" >> "$zshrc"
        fi
    fi

    # 添加历史命令配置
    cat >> "$zshrc" << 'EOF'

# 历史命令配置
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_ALL_DUPS  # 忽略重复命令
setopt HIST_FIND_NO_DUPS     # 搜索时忽略重复
setopt HIST_REDUCE_BLANKS    # 删除多余空格
setopt INC_APPEND_HISTORY    # 立即追加到历史文件
setopt SHARE_HISTORY         # 在会话间共享历史

# 历史搜索快捷键配置
bindkey '^[[A' history-substring-search-up      # 上箭头
bindkey '^[[B' history-substring-search-down    # 下箭头
bindkey '^P' history-substring-search-up        # Ctrl+P
bindkey '^N' history-substring-search-down      # Ctrl+N

# autosuggestions配置
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
EOF

    print_info ".zshrc配置完成"
}

# 在.bashrc中添加自动启动zsh的配置
add_zsh_to_bashrc() {
    local bashrc="$HOME/.bashrc"
    
    if [ ! -f "$bashrc" ]; then
        print_warning ".bashrc文件不存在，跳过此步骤"
        return 0
    fi
    
    # 检查是否已经添加了自动启动zsh的配置
    if grep -q "exec zsh" "$bashrc" || grep -q "# Auto-start zsh" "$bashrc"; then
        print_warning ".bashrc中已经配置了zsh自动启动"
        return 0
    fi
    
    print_info "在.bashrc中添加自动启动zsh的配置..."
    
    # 备份.bashrc
    cp "$bashrc" "$bashrc.backup.$(date +%Y%m%d%H%M%S)"
    
    # 添加自动启动zsh的代码
    cat >> "$bashrc" << 'EOF'

# Auto-start zsh
if [ -t 1 ] && [ -n "$BASH_VERSION" ] && command -v zsh &> /dev/null; then
    export SHELL=$(which zsh)
    exec zsh
fi
EOF
    
    print_info ".bashrc配置完成"
}

# 设置zsh为默认shell（需要注销重新登录才生效）
set_default_shell() {
    if [ "$SHELL" = "$(which zsh)" ]; then
        print_warning "zsh已经是默认shell"
        return 0
    fi

    print_info "设置zsh为默认shell（需要注销重新登录）..."
    
    # 检查zsh是否在/etc/shells中
    if ! grep -q "$(which zsh)" /etc/shells; then
        print_info "将zsh添加到/etc/shells..."
        echo "$(which zsh)" | sudo tee -a /etc/shells
    fi
    
    # 更改默认shell
    chsh -s "$(which zsh)"
    
    print_info "默认shell已通过chsh设置为zsh"
}

# 主函数
main() {
    echo "======================================"
    echo "  ZSH和历史命令插件自动安装脚本"
    echo "======================================"
    echo ""

    detect_os
    install_zsh
    install_oh_my_zsh
    install_autosuggestions
    install_syntax_highlighting
    install_history_substring_search
    configure_zshrc
    
    echo ""
    echo "选择zsh启动方式："
    echo "  1) 在.bashrc中自动启动zsh（推荐，立即生效）"
    echo "  2) 通过chsh设置为默认shell（需要注销重新登录）"
    echo "  3) 两者都设置（最完整）"
    echo "  4) 跳过，手动启动"
    echo ""
    read -p "请选择 [1-4]: " -n 1 -r
    echo ""
    
    case $REPLY in
        1)
            add_zsh_to_bashrc
            ;;
        2)
            set_default_shell
            ;;
        3)
            add_zsh_to_bashrc
            set_default_shell
            ;;
        4)
            print_info "已跳过自动配置"
            ;;
        *)
            print_warning "无效选择，已跳过自动配置"
            ;;
    esac

    echo ""
    print_info "================================================"
    print_info "所有安装和配置已完成！"
    print_info "================================================"
    echo ""
    print_info "已安装的插件："
    print_info "  1. zsh-autosuggestions - 根据历史自动建议命令"
    print_info "  2. zsh-syntax-highlighting - 命令语法高亮"
    print_info "  3. zsh-history-substring-search - 历史命令搜索"
    echo ""
    print_info "快捷键说明："
    print_info "  - 上/下箭头或Ctrl+P/N：搜索历史命令"
    print_info "  - 右箭头或End：接受自动建议"
    print_info "  - Ctrl+R：反向搜索历史"
    echo ""
    
    if [[ $REPLY == "1" ]] || [[ $REPLY == "3" ]]; then
        echo ""
        print_info "配置已写入.bashrc，现在启动zsh..."
        print_info "如果要立即生效，请执行以下命令之一："
        print_info "  source ~/.bashrc   # 重新加载.bashrc（会自动启动zsh）"
        print_info "  exec zsh           # 直接启动zsh"
        echo ""
        read -p "是否现在启动zsh？(y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "正在启动zsh..."
            exec zsh
        fi
    else
        print_info "运行以下命令启动zsh："
        print_info "  zsh                # 手动启动zsh"
        print_info "  source ~/.bashrc   # 如果已配置.bashrc自动启动"
    fi
}

# 运行主函数
main


