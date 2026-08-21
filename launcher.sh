#!/bin/bash
# Hermes.app 启动器 — 打开/复用专用 Terminal 窗口，运行对话菜单
# 点击时若启动器窗口被最小化/隐藏/置后，将其恢复并提到最前
RES_DIR="$(cd "$(dirname "$0")/../Resources" && pwd)"
MENU="$RES_DIR/hermes-menu.sh"

if pgrep -f "hermes-menu.sh" >/dev/null 2>&1; then
  # 菜单已在运行 → 恢复并前置启动器窗口
  # 按窗口名含 "hermes-menu.sh" 精确匹配：普通终端里跑 hermes 的窗口不会误中
  osascript <<APPLESCRIPT 2>/dev/null || true
tell application "Terminal"
	activate
	repeat with w in windows
		if name of w contains "hermes-menu.sh" then
			try
				set miniaturized of w to false
			end try
			try
				set visible of w to true
			end try
			try
				set index of w to 1
			end try
		end if
	end repeat
end tell
APPLESCRIPT
else
  if ! osascript <<APPLESCRIPT
tell application "Terminal"
	activate
	do script "bash '$MENU'"
end tell
APPLESCRIPT
  then
    osascript -e 'display alert "无法控制 Terminal" message "请在 系统设置 → 隐私与安全性 → 自动化 中允许 Hermes 控制 Terminal。"' 2>/dev/null || true
  fi
fi
