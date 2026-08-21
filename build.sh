#!/bin/bash
# Hermes Launcher 一键构建脚本
# 用法: ./build.sh
# 功能: 从源码构建 Hermes.app，输出到 build/Hermes.app

set -euo pipefail

# 颜色
GREEN=$'\033[0;32m'; RED=$'\033[0;31m'; NC=$'\033[0m'

ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD="$ROOT/build"

echo -e "${GREEN}═══ Hermes Launcher 构建 ═══${NC}"

# 检查源码
for f in hermes-menu.sh launcher.sh; do
  if [ ! -f "$ROOT/$f" ]; then
    echo -e "${RED}错误: 缺少 $f${NC}"
    exit 1
  fi
done

# 清理旧构建
if [ -d "$BUILD" ]; then
  echo "清理旧构建..."
  rm -rf "$BUILD"
fi

# 创建 App 结构
echo "创建 App 结构..."
mkdir -p "$BUILD/Hermes.app/Contents/MacOS"
mkdir -p "$BUILD/Hermes.app/Contents/Resources"

# 复制脚本
echo "复制并执行权限脚本..."
cp "$ROOT/hermes-menu.sh" "$BUILD/Hermes.app/Contents/Resources/hermes-menu.sh"
cp "$ROOT/launcher.sh" "$BUILD/Hermes.app/Contents/MacOS/Hermes"
chmod +x "$BUILD/Hermes.app/Contents/MacOS/Hermes"
chmod +x "$BUILD/Hermes.app/Contents/Resources/hermes-menu.sh"

# 复制图标（如果在根目录有 AppIcon.icns）
if [ -f "$ROOT/AppIcon.icns" ]; then
  echo "复制图标..."
  cp "$ROOT/AppIcon.icns" "$BUILD/Hermes.app/Contents/Resources/AppIcon.icns"
fi

# 生成 Info.plist
echo "生成 Info.plist..."
cat > "$BUILD/Hermes.app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Hermes</string>
    <key>CFBundleDisplayName</key><string>Hermes</string>
    <key>CFBundleIdentifier</key><string>com.hermes.launcher</string>
    <key>CFBundleVersion</key><string>1.0</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleExecutable</key><string>Hermes</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>LSMinimumSystemVersion</key><string>12.0</string>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

# 签名（可选，本地使用跳过）
if codesign --force --deep -s - "$BUILD/Hermes.app" >/dev/null 2>&1; then
  echo -e "${GREEN}✓ 已签名（ad-hoc）${NC}"
else
  echo -e "${GREEN}✓ 构建完成（未签名）${NC}"
fi

echo
echo -e "${GREEN}═══ 构建成功 ═══${NC}"
echo "App 位于: $BUILD/Hermes.app"
echo "安装: cp -R \"$BUILD/Hermes.app\" /Applications/"