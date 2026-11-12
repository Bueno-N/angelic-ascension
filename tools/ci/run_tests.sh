#!/usr/bin/env bash
# Roda a suíte headless. Falha se o runner retornar != 0 OU se houver SCRIPT ERROR no log
# (erros de runtime em GDScript não derrubam o exit code por si só).
set -uo pipefail
mkdir -p build
godot --headless --path . --script res://tests/run_tests.gd 2>&1 | tee build/test.log
rc=${PIPESTATUS[0]}
if grep -q "SCRIPT ERROR\|Failed to load script" build/test.log; then
  echo "Erros de script detectados no log de testes"; exit 1
fi
if ! grep -q "RESUMO DOS TESTES" build/test.log; then
  echo "Runner não chegou ao resumo (crash antes de terminar)"; exit 1
fi
exit $rc
