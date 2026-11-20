#!/usr/bin/env bash
# Instala o Android Build Template no workspace do CI (equivale a "Projeto > Instalar modelo de build Android" no editor).
# Necessário porque os presets usam build Gradle (gradle_build/use_gradle_build=true: AdMob e Google Play Billing),
# e a pasta android/ NÃO vai para o repositório (~1 GB com o cache do Gradle; ver .gitignore).
# Requer: export templates já instalados (tools/ci/setup_templates.sh).
set -euo pipefail
V="${GODOT_VERSION:-4.5}"
CH="${GODOT_CHANNEL:-stable}"
TPL="$HOME/.local/share/godot/export_templates/${V}.${CH}/android_source.zip"
test -f "$TPL" || { echo "ERRO: $TPL não existe (rode tools/ci/setup_templates.sh antes)"; exit 1; }
rm -rf android/build
mkdir -p android/build
unzip -q -o "$TPL" -d android/build
echo "${V}.${CH}" > android/.build_version
touch android/build/.gdignore
chmod +x android/build/gradlew 2>/dev/null || true
echo "Android Build Template ${V}.${CH} instalado em android/build"
