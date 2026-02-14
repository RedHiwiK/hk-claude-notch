#!/bin/bash
# ClaudeNotch - 打包为 .app bundle + DMG
# 用法: ./scripts/build-dmg.sh [version]
# 例如: ./scripts/build-dmg.sh 0.1.0
set -e

VERSION="${1:-0.1.0}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/.build/release"
APP_NAME="ClaudeNotch"
APP_BUNDLE="$PROJECT_DIR/.build/${APP_NAME}.app"
DMG_DIR="$PROJECT_DIR/.build/dmg"
DMG_OUTPUT="$PROJECT_DIR/.build/${APP_NAME}.dmg"

echo "📌 Version: $VERSION"

echo "🔨 Building release binary..."
cd "$PROJECT_DIR"
swift build --configuration release

echo "📦 Creating .app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources/hooks"

# 复制图标
if [ -f "$PROJECT_DIR/Resources/AppIcon.icns" ]; then
  cp "$PROJECT_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

# 复制可执行文件
cp "$BUILD_DIR/ClaudeNotch" "$APP_BUNDLE/Contents/MacOS/ClaudeNotch"

# 复制 hooks 脚本到 .app 内
for script in _common.sh session-start.sh pre-tool-use.sh post-tool-use.sh stop.sh session-end.sh notification.sh; do
  if [ -f "$PROJECT_DIR/hooks/$script" ]; then
    cp "$PROJECT_DIR/hooks/$script" "$APP_BUNDLE/Contents/Resources/hooks/$script"
    chmod +x "$APP_BUNDLE/Contents/Resources/hooks/$script"
  fi
done

# 复制安装脚本
cp "$PROJECT_DIR/hooks/install.sh" "$APP_BUNDLE/Contents/Resources/install-hooks.sh"
chmod +x "$APP_BUNDLE/Contents/Resources/install-hooks.sh"

# 生成 Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>ClaudeNotch</string>
    <key>CFBundleIdentifier</key>
    <string>com.claudenotch.app</string>
    <key>CFBundleName</key>
    <string>ClaudeNotch</string>
    <key>CFBundleDisplayName</key>
    <string>ClaudeNotch</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>ClaudeNotch needs AppleScript access to interact with iTerm2 for session management.</string>
</dict>
</plist>
PLIST

# 生成 PkgInfo
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

echo "✅ App bundle created: $APP_BUNDLE"

# 打包 DMG
echo "💿 Creating DMG..."
rm -rf "$DMG_DIR" "$DMG_OUTPUT"
mkdir -p "$DMG_DIR"

# 复制 .app 到 DMG 临时目录
cp -R "$APP_BUNDLE" "$DMG_DIR/"

# 创建 Applications 快捷方式
ln -s /Applications "$DMG_DIR/Applications"

# 创建 DMG
hdiutil create \
  -volname "ClaudeNotch" \
  -srcfolder "$DMG_DIR" \
  -ov \
  -format UDZO \
  "$DMG_OUTPUT"

rm -rf "$DMG_DIR"

echo ""
echo "✅ DMG created: $DMG_OUTPUT"
echo "   Size: $(du -h "$DMG_OUTPUT" | cut -f1)"
echo ""
echo "📋 Next steps for users after installing the .app:"
echo "   1. Drag ClaudeNotch.app to /Applications"
echo "   2. Run: /Applications/ClaudeNotch.app/Contents/Resources/install-hooks.sh"
echo "   3. Open ClaudeNotch from Applications"
echo "   4. Restart Claude Code sessions to activate hooks"
