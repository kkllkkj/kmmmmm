#!/bin/zsh
set -eu
cd "${0:A:h:h}"
swift build -c release --scratch-path /tmp/tigerpet-release
APP="$PWD/dist/小虎陪伴.app"
mkdir -p "$APP/Contents/MacOS"
cp /tmp/tigerpet-release/release/TigerPet "$APP/Contents/MacOS/TigerPet"
mkdir -p "$APP/Contents/Resources/Assets"
cp Assets/tiger-standing.png Assets/tiger-focus.png Assets/tiger-sprites.png Assets/tiger-workout.png Assets/tiger-talents.png Assets/tiger-feeding.png "$APP/Contents/Resources/Assets/"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>TigerPet</string>
<key>CFBundleIdentifier</key><string>local.tigerpet.companion</string>
<key>CFBundleName</key><string>小虎陪伴</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$APP"
printf '已生成：%s\n' "$APP"
