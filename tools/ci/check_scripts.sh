#!/usr/bin/env bash
# --check-only em cada .gd. Limitação conhecida do Godot 4.5: nesse modo os AUTOLOADS não são
# resolvidos ("Identifier not found: Events"). Falhas cujo ÚNICO erro é esse são tratadas como
# falso positivo e validadas de verdade pelo smoke_run.sh (que carrega o jogo com os autoloads).
set -uo pipefail
mkdir -p build
: > build/check_scripts.log
AUTOLOADS=$(awk '/^\[autoload\]/{f=1;next} /^\[/{f=0} f&&/=/{split($0,a,"="); print a[1]}' project.godot | paste -sd'|')
fail=0; total=0; skipped=0
while IFS= read -r f; do
  total=$((total+1))
  out=$(godot --headless --path . --check-only --script "res://${f#./}" 2>&1); rc=$?
  echo "=== $f (rc=$rc)" >> build/check_scripts.log
  echo "$out" >> build/check_scripts.log
  if [ $rc -ne 0 ] || echo "$out" | grep -q "SCRIPT ERROR\|Parse Error"; then
    all=$(echo "$out" | grep -c "SCRIPT ERROR")
    auto=$(echo "$out" | grep -cE "SCRIPT ERROR: Compile Error: Identifier not found: (${AUTOLOADS})\$")
    # Em cascata: script A usa classe B que usa um autoload -> o Godot também emite uma linha
    # "Compile Error:" vazia para A. Isso só é tolerado quando há ao menos 1 erro de autoload.
    bare=$(echo "$out" | grep -cE "SCRIPT ERROR: Compile Error: *\$")
    # Godot 4.5: a cascata vem como "Compile Error: Failed to compile depended scripts." (mesmo falso positivo).
    casc=$(echo "$out" | grep -cE "SCRIPT ERROR: Compile Error: Failed to compile depended scripts")
    if [ "$auto" -gt 0 ] && [ "$all" -eq $((auto + bare + casc)) ]; then
      echo "AUTOLOAD (falso positivo, validado no smoke): $f"; skipped=$((skipped+1))
    else
      echo "FALHOU: $f"; echo "$out" | head -20; fail=$((fail+1))
    fi
  fi
done < <(find . -name '*.gd' -not -path './.godot/*' | sort)
echo "scripts: $total | falhas reais: $fail | puladas por autoload: $skipped"
[ $fail -eq 0 ]
