#!/usr/bin/env bash
# Importa recursos e gera o cache de classes globais (class_name). Log em build/import.log.
set -uo pipefail
mkdir -p build
godot --headless --path . --import 2>&1 | tee build/import.log
echo "import exit code: ${PIPESTATUS[0]} (o Godot 4.5 às vezes retorna != 0 mesmo importando; a validação real são as próximas etapas)"
test -f .godot/global_script_class_cache.cfg && echo "cache de classes globais: OK" || { echo "cache de classes globais AUSENTE"; exit 1; }
