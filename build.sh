#!/bin/zsh
# Builds the native macOS app from src/main.swift and Snake.html, then installs it into /Applications.
set -e
cd "$(dirname "$0")"

APP_NAME="Super Snake"                 # shown in the menu bar, Dock and Finder
BUNDLE_ID="local.supersnake.game"     # saved settings, high scores and achievements are kept per bundle id

APP="$APP_NAME.app"
EXEC="${APP_NAME// /}"
BUILD="build"
rm -rf "$APP" "$BUILD"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$BUILD/Snake.iconset"

# App binary
swiftc -O src/main.swift -o "$APP/Contents/MacOS/$EXEC" -framework Cocoa -framework WebKit

# Game
cp Snake.html "$APP/Contents/Resources/Snake.html"

# Icon
swiftc -O src/icon.swift -o "$BUILD/makeicon" -framework Cocoa
"$BUILD/makeicon" "$BUILD/icon_1024.png"
for s in 16 32 128 256 512; do
  sips -z $s $s "$BUILD/icon_1024.png" --out "$BUILD/Snake.iconset/icon_${s}x${s}.png" >/dev/null
  d=$((s * 2))
  sips -z $d $d "$BUILD/icon_1024.png" --out "$BUILD/Snake.iconset/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$BUILD/Snake.iconset" -o "$APP/Contents/Resources/Snake.icns"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>$APP_NAME</string>
  <key>CFBundleDisplayName</key><string>$APP_NAME</string>
  <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
  <key>CFBundleExecutable</key><string>$EXEC</string>
  <key>CFBundleIconFile</key><string>Snake</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>12.0</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.arcade-games</string>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

# Ad-hoc sign so macOS will run it locally
codesign --force --deep --sign - "$APP"
rm -rf "$BUILD"

# Install into /Applications, replacing any previous version
osascript -e "tell application \"$APP_NAME\" to quit" 2>/dev/null || true
rm -rf "/Applications/$APP"
mv "$APP" "/Applications/$APP"
touch "/Applications/$APP"
echo "Installed /Applications/$APP"
