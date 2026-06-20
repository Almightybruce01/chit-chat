#!/bin/sh
# Writes GoogleSignIn-Info.plist with CFBundleURLTypes from GoogleService-Info.plist.
set -e
GS="${SRCROOT}/Chit Chat Social/GoogleService-Info.plist"
OUT="${SRCROOT}/Chit Chat Social/GoogleSignIn-Info.plist"
if [ ! -f "$GS" ]; then
  echo "warning: GoogleService-Info.plist missing — Google OAuth return URL not configured."
  cat > "$OUT" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict/>
</plist>
PLIST
  exit 0
fi
REVERSED=$(/usr/libexec/PlistBuddy -c "Print :REVERSED_CLIENT_ID" "$GS")
cat > "$OUT" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>${REVERSED}</string>
			</array>
		</dict>
	</array>
</dict>
</plist>
PLIST
echo "Google Sign-In URL scheme: ${REVERSED}"
