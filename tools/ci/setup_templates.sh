#!/usr/bin/env bash
# Instala os export templates do Godot (necessários para gerar o APK).
set -euo pipefail
V="${GODOT_VERSION:-4.3}"
CH="${GODOT_CHANNEL:-stable}"
DEST="$HOME/.local/share/godot/export_templates/${V}.${CH}"
if [ -f "$DEST/android_debug.apk" ]; then echo "templates já instalados"; exit 0; fi
mkdir -p "$DEST" /tmp/tpl
curl -fsSL -o /tmp/tpl/templates.tpz "https://github.com/godotengine/godot/releases/download/${V}-${CH}/Godot_v${V}-${CH}_export_templates.tpz"
unzip -q -o /tmp/tpl/templates.tpz -d /tmp/tpl
cp -r /tmp/tpl/templates/* "$DEST/"
ls "$DEST" | head -30
test -f "$DEST/android_debug.apk"
