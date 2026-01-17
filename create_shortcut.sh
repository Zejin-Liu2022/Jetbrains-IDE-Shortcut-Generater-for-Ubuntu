#!/bin/bash

# ==========================================
#  Ubuntu JetBrains 快捷方式生成器 (Binary优先版)
# ==========================================

# 定义颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}==============================================${NC}"
echo -e "${BLUE}    Ubuntu 快捷方式助手 (优先使用二进制执行文件)    ${NC}"
echo -e "${BLUE}==============================================${NC}"

# --- 1. 获取基础路径 ---
while true; do
    echo -e "${YELLOW}请输入 IDE 的 bin 目录路径 或 .sh 脚本路径:${NC}"
    read -e -p "> " INPUT_PATH
    
    # 去除引号
    INPUT_PATH=$(echo "$INPUT_PATH" | tr -d "'\"")

    SCRIPT_FILE=""
    
    if [ -d "$INPUT_PATH" ]; then
        # 如果是目录，先找到 .sh 脚本作为“锚点”
        SCRIPT_FILE=$(find "$INPUT_PATH" -maxdepth 1 -name "*.sh" | head -n 1)
        if [ -z "$SCRIPT_FILE" ]; then
            echo -e "${RED}错误：在该目录下未找到 .sh 脚本用于定位，请重试。${NC}"
            continue
        fi
    elif [ -f "$INPUT_PATH" ]; then
        SCRIPT_FILE="$INPUT_PATH"
    else
        echo -e "${RED}错误：路径不存在。${NC}"
        continue
    fi
    
    echo -e "${GREEN}已定位基础脚本: $SCRIPT_FILE${NC}"
    break
done

# --- 2. 智能切换为二进制文件 ---
BIN_DIR=$(dirname "$SCRIPT_FILE")
BASE_NAME=$(basename "$SCRIPT_FILE" .sh) # 例如 pycharm.sh -> pycharm

# 尝试寻找同名的二进制文件 (无后缀 或 64后缀)
# 优先级: name > name64 > name.sh
CANDIDATE_BIN_1="$BIN_DIR/$BASE_NAME"
CANDIDATE_BIN_2="$BIN_DIR/${BASE_NAME}64"

TARGET_EXEC=""

if [ -f "$CANDIDATE_BIN_1" ]; then
    TARGET_EXEC="$CANDIDATE_BIN_1"
    echo -e "${CYAN}策略生效：已找到原生二进制文件 -> $(basename "$TARGET_EXEC")${NC}"
elif [ -f "$CANDIDATE_BIN_2" ]; then
    TARGET_EXEC="$CANDIDATE_BIN_2"
    echo -e "${CYAN}策略生效：已找到 64位 二进制文件 -> $(basename "$TARGET_EXEC")${NC}"
else
    TARGET_EXEC="$SCRIPT_FILE"
    echo -e "${YELLOW}未找到同名二进制文件，回退使用 .sh 脚本 -> $(basename "$TARGET_EXEC")${NC}"
fi

# --- 3. 获取名称 ---
echo -e "\n${YELLOW}请输入快捷方式名称 (例如: PyCharm Professional):${NC}"
read -p "> " APP_NAME
[ -z "$APP_NAME" ] && APP_NAME="JetBrains IDE"

# --- 4. 自动寻找图标 ---
echo -e "\n${YELLOW}正在寻找图标...${NC}"
# 优先找 svg，其次 png
ICON_PATH=$(find "$BIN_DIR" -maxdepth 1 -name "*.svg" -o -name "*.png" | head -n 1)
if [ -z "$ICON_PATH" ]; then
    # 向上找一级
    ICON_PATH=$(find "$BIN_DIR/.." -maxdepth 2 -name "*.svg" -o -name "*.png" | head -n 1)
fi

if [ -n "$ICON_PATH" ]; then
    echo -e "${GREEN}已找到图标: $ICON_PATH${NC}"
else
    echo -e "${RED}未找到图标，请输入图标路径:${NC}"
    read -e -p "> " ICON_PATH
    ICON_PATH=$(echo "$ICON_PATH" | tr -d "'\"")
    [ -z "$ICON_PATH" ] && ICON_PATH="utilities-terminal"
fi

# --- 5. 权限检查 (SUDO) ---
if [ ! -x "$TARGET_EXEC" ]; then
    echo -e "\n${RED}检测到目标文件没有执行权限: $TARGET_EXEC${NC}"
    echo -e "正在申请 sudo 权限进行修复..."
    sudo chmod +x "$TARGET_EXEC"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}权限已修复。${NC}"
    else
        echo -e "${RED}权限修复失败，请手动检查。${NC}"
    fi
fi

# --- 6. 生成 .desktop ---
if command -v xdg-user-dir > /dev/null; then
    DESKTOP_DIR=$(xdg-user-dir DESKTOP)
else
    DESKTOP_DIR="$HOME/Desktop"
fi

OUTPUT_FILE="$DESKTOP_DIR/$APP_NAME.desktop"

cat > "$OUTPUT_FILE" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$APP_NAME
Icon=$ICON_PATH
Exec="$TARGET_EXEC" %f
Comment=$APP_NAME
Categories=Development;IDE;
Terminal=false
StartupWMClass=jetbrains-$(basename "$BASE_NAME")
EOF

chmod +x "$OUTPUT_FILE"

# --- 7. 完成 ---
echo -e "${GREEN}==============================================${NC}"
echo -e "${GREEN}快捷方式已创建: $OUTPUT_FILE${NC}"
echo -e "${GREEN}指向目标: $TARGET_EXEC${NC}"
echo -e "${GREEN}==============================================${NC}"
echo -e "${YELLOW}注意：首次点击若无反应，请右键图标选择【允许运行】(Allow Launching)。${NC}"
echo -e "如果你想让它出现在应用菜单里，请运行以下命令："
echo -e "   cp \"$OUTPUT_FILE\" ~/.local/share/applications/"
