#!/usr/bin/env bash
# Prepara SDK Android, keystore de debug e Editor Settings do Godot. Requer JAVA_HOME (JDK 17).
set -uo pipefail
V="${GODOT_VERSION:-4.3}"
SDK="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-/usr/local/lib/android/sdk}}"
SDKM="$SDK/cmdline-tools/latest/bin/sdkmanager"
if [ ! -x "$SDKM" ]; then echo "sdkmanager não encontrado em $SDKM"; exit 1; fi
yes | "$SDKM" --licenses > /dev/null 2>&1 || true
"$SDKM" "platform-tools" "build-tools;34.0.0" "platforms;android-34" || exit 1

KS="$HOME/debug.keystore"
if [ ! -f "$KS" ]; then
  "$JAVA_HOME/bin/keytool" -genkeypair -v -keystore "$KS" -storepass android -alias androiddebugkey \
    -keypass android -keyalg RSA -keysize 2048 -validity 10000 \
    -dname "CN=Android Debug,O=Android,C=US" || exit 1
fi

mkdir -p "$HOME/.config/godot"
cat > "$HOME/.config/godot/editor_settings-${V}.tres" <<SETTINGS
[gd_resource type="EditorSettings" format=3]

[resource]
export/android/android_sdk_path = "${SDK}"
export/android/java_sdk_path = "${JAVA_HOME}"
export/android/debug_keystore = "${KS}"
export/android/debug_keystore_user = "androiddebugkey"
export/android/debug_keystore_pass = "android"
SETTINGS
echo "Android configurado: SDK=$SDK JAVA_HOME=$JAVA_HOME"
