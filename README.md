# Angelic Ascension

Jogo 2D de fantasia sombria (Godot 4.3, GDScript, 100% gratuito/open source). Alvo: **Android**, landscape.

## Estrutura
```
data/        balance.gd (TUDO configurável), skills_db, equipment_db, wings_db, enemies_db
autoload/    events, save_manager, game_state
scripts/logic/    lógica pura e testável (stats, fases, drops, loja, save, slots, modelo de economia)
scripts/runtime/  jogo (player, inimigos, fases, HUD, menus, joystick, main)
tests/       suíte headless (run_tests.gd)   tools/   relatório de economia + scripts de CI
docs/STATUS.md    registro do que foi/ não foi verificado
```

## Rodando local
```bash
godot --headless --path . --import
godot --headless --path . --script res://tests/run_tests.gd        # testes
godot --headless --path . --script res://tools/economy_report.gd   # projeção de economia
```

## CI (GitHub Actions) — `.github/workflows/build.yml`
1. **verify**: instala Godot 4.3 → importa → `--check-only` em todos os `.gd` → testes → relatório de economia.
2. **build-android** (só se verify passar): JDK 17, SDK Android, templates, keystore debug → exporta APK → artefato `AngelicAscension-debug-apk`.

Logs sempre são enviados como artefatos (`logs-verify`, `logs-build-android`). Se algo falhar, baixe o log e traga para correção.

## Publicando no GitHub
```bash
git init && git add . && git commit -m "Angelic Ascension: base + CI"
git branch -M main
git remote add origin https://github.com/SEU_USUARIO/angelic-ascension.git
git push -u origin main
```
Depois abra a aba **Actions** do repositório.

## Notas
- APK de **debug** (assinado com keystore de debug). Versão final/release exige keystore próprio (guardado em *secrets*); ainda não configurado.
- Versão do Godot fixada em 4.3 via `GODOT_VERSION` no workflow.
