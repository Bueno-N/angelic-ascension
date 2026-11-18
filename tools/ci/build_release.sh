#!/usr/bin/env bash
# Gera o APK de RELEASE assinado com a SUA chave (variáveis GODOT_ANDROID_KEYSTORE_RELEASE_*).
# Desliga o modo de teste, roda testes + smoke com essa configuração e confere a assinatura.
set -uo pipefail
: "${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:?defina o caminho do keystore}"
: "${GODOT_ANDROID_KEYSTORE_RELEASE_USER:?defina o alias da chave}"
: "${GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD:?defina a senha}"
VERSION_NAME="${VERSION_NAME:-1.0.0}"
VERSION_CODE="${VERSION_CODE:-1}"
mkdir -p build

# 1) modo de teste DESLIGADO no código (além de OS.is_debug_build() ser falso em release)
sed -i 's/^const DEBUG_TOOLS := .*/const DEBUG_TOOLS := false/' data/balance.gd
grep -q '^const DEBUG_TOOLS := false' data/balance.gd || { echo "Falha ao desligar DEBUG_TOOLS"; exit 1; }

# 2) versão do app
sed -i "s/^version\/code=.*/version\/code=${VERSION_CODE}/; s/^version\/name=.*/version\/name=\"${VERSION_NAME}\"/" export_presets.cfg

# 3) importar, testar e rodar o smoke COM a configuração de release
bash tools/ci/import_project.sh || exit 1
bash tools/ci/run_tests.sh || exit 1
bash tools/ci/smoke_run.sh || exit 1

# 4) exportar
APK="build/AngelicAscension-release.apk"
rm -f "$APK"
godot --headless --path . --export-release "Android Release" "$APK" 2>&1 | tee build/export_release.log
[ -s "$APK" ] || { echo "APK de release não foi gerado"; exit 1; }
unzip -tq "$APK" || { echo "APK corrompido"; exit 1; }

# 5) a assinatura NÃO pode ser a de debug
APKSIGNER="${ANDROID_SDK_ROOT:-/usr/local/lib/android/sdk}/build-tools/35.0.1/apksigner"
"$APKSIGNER" verify --print-certs "$APK" 2>&1 | tee build/apk_certs.txt
if grep -qi "CN=Android Debug" build/apk_certs.txt; then echo "ERRO: APK assinado com a chave de debug"; exit 1; fi
if ! grep -qi "certificate" build/apk_certs.txt; then echo "ERRO: não foi possível ler a assinatura"; exit 1; fi
ls -l "$APK"
