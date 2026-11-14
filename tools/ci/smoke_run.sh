#!/usr/bin/env bash
# Executa o jogo real (cena principal + autoloads) por 1800 frames fixos (30 s simulados).
set -uo pipefail
mkdir -p build
godot --headless --path . --fixed-fps 60 -- --smoke 2>&1 | tee build/smoke.log
rc=${PIPESTATUS[0]}
if grep -q "SCRIPT ERROR\|Failed to load script" build/smoke.log; then echo "Erros de script no smoke run"; exit 1; fi
if ! grep -q "SMOKE_RESULT" build/smoke.log; then echo "Smoke run não terminou (sem SMOKE_RESULT)"; exit 1; fi
gold=$(grep -o "gold=[0-9]*" build/smoke.log | head -1 | cut -d= -f2)
if [ "${gold:-0}" -le 0 ]; then echo "Nenhum inimigo morreu em 30s (ouro=0): combate/spawn não funcionou"; exit 1; fi
cleared=$(grep -o "cleared=[0-9]*" build/smoke.log | head -1 | cut -d= -f2)
if [ "${cleared:-0}" -lt 1 ]; then echo "Nenhuma fase foi limpa no smoke (limpeza de fase/spawn com problema)"; exit 1; fi
kinds=$(grep -o "kinds=[a-z_,]*" build/smoke.log | head -1 | cut -d= -f2)
for k in area_slam charge summon_demons hellfire_projectiles fire_bolt life_steal; do
  case ",$kinds," in *",$k,"*) ;; *) echo "Habilidade inimiga NÃO executada no smoke: $k (executadas: ${kinds:-nenhuma})"; exit 1;; esac
done
casts=$(grep -o "casts=[0-9]*" build/smoke.log | head -1 | cut -d= -f2)
if [ "${casts:-0}" -lt 10 ]; then echo "Habilidades não foram executadas (casts=${casts:-0}, esperado >= 10)"; exit 1; fi
for k in repeat next speed fx; do
  v=$(grep -o " $k=[0-9]" build/smoke.log | head -1 | cut -d= -f2)
  if [ "${v:-0}" != "1" ]; then echo "Verificação '$k' falhou no smoke (valor=${v:-ausente}): modo repetir / próxima fase / velocidade 2x"; exit 1; fi
done
exit $rc
