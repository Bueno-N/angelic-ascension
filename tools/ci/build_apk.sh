#!/usr/bin/env bash
# Exporta o APK de debug e valida que o arquivo existe e é um zip íntegro.
set -uo pipefail
mkdir -p build
APK="build/AngelicAscension-debug.apk"
rm -f "$APK"
godot --headless --path . --export-debug "Android Debug" "$APK" 2>&1 | tee build/export.log
if [ ! -s "$APK" ]; then echo "APK não foi gerado"; exit 1; fi
unzip -tq "$APK" || { echo "APK corrompido"; exit 1; }
ls -l "$APK"
unzip -l "$APK" | grep -E "AndroidManifest.xml|classes.dex|lib/arm64-v8a" | head
