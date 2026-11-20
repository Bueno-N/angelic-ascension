#!/usr/bin/env bash
# Instala o plugin AdMob (Poing Studios) NO WORKSPACE DO CI e prepara o export Android com Gradle. Não altera o repositório:
# só o workflow "AdMob (APK com anúncios)" roda isto. Requer: Godot já instalado, templates instalados, rede.
# Passos (da documentação oficial do plugin): addon em res://addons/admob -> habilitar o plugin -> Android Build Template -> exportar com Gradle.
# NUNCA foi executado por quem escreveu (sem rede no ambiente de desenvolvimento): a 1ª execução no CI pode pedir ajustes.
set -euo pipefail
TAG="${ADMOB_PLUGIN_TAG:-v5.1.0}"
V="${GODOT_VERSION:-4.5}"
CH="${GODOT_CHANNEL:-stable}"
API="https://api.github.com/repos/poingstudios/godot-admob-plugin/releases/tags/${TAG}"
mkdir -p build/admob
curl -fsSL ${GITHUB_TOKEN:+-H "Authorization: Bearer $GITHUB_TOKEN"} "$API" -o build/admob/release.json
python3 - <<'PY'
import json
r = json.load(open("build/admob/release.json"))
names = [a["name"] for a in r["assets"]]
print("Assets do release %s: %d" % (r["tag_name"], len(names)))
for n in names: print("  ", n)
addon = [a for a in r["assets"] if a["name"].startswith("poing-godot-admob-v") and a["name"].endswith(".zip")]
if not addon:
    raise SystemExit("ERRO: nenhum asset 'poing-godot-admob-v*.zip' neste release (veja a lista acima e ajuste ADMOB_PLUGIN_TAG)")
open("build/admob/addon_url.txt", "w").write(addon[0]["browser_download_url"])
PY
URL=$(cat build/admob/addon_url.txt)
echo "Baixando $URL"
curl -fsSL -o build/admob/addon.zip "$URL"
unzip -q -o build/admob/addon.zip -d .
CFG=$(find addons -maxdepth 3 -name plugin.cfg -path '*admob*' | head -1)
if [ -z "$CFG" ]; then echo "ERRO: plugin.cfg do AdMob não encontrado após extrair (estrutura do zip mudou?)"; find . -maxdepth 3 -name '*.cfg' | head; exit 1; fi
echo "plugin.cfg: $CFG"

# habilita o plugin no project.godot (como Project Settings > Plugins)
python3 - "$CFG" <<'PY'
import re, sys
cfg = "res://" + sys.argv[1].lstrip("./")
s = open("project.godot").read()
if cfg in s:
    print("plugin já habilitado")
elif "[editor_plugins]" in s:
    s = re.sub(r"(\[editor_plugins\]\s*\n\s*enabled=PackedStringArray\()", r'\1"%s", ' % cfg, s, count=1)
    open("project.godot", "w").write(s)
else:
    s += '\n[editor_plugins]\n\nenabled=PackedStringArray("%s")\n' % cfg
    open("project.godot", "w").write(s)
print("habilitado:", cfg)
PY

# Android Build Template (equivale a Project > Install Android Build Template)
bash tools/ci/setup_build_template.sh

# export com Gradle apenas neste workspace
python3 - <<'PY'
s = open("export_presets.cfg").read()
s = s.replace("gradle_build/use_gradle_build=false", "gradle_build/use_gradle_build=true")
open("export_presets.cfg", "w").write(s)
print("use_gradle_build=true (presets Android Debug e Release, só neste workspace)")
PY
grep -n "use_gradle_build" export_presets.cfg
echo "OK. App ID: o plugin lê Project Settings > Admob > General (Android). Sem ele o app fecha ao abrir; ver docs/ADMOB.md."
