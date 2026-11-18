# Angelic Ascension

Jogo 2D de fantasia sombria (Godot 4.5, GDScript, 100% gratuito/open source). Alvo: **Android**, landscape.

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
1. **verify**: instala Godot 4.5 → importa → `--check-only` em todos os `.gd` → testes → relatório de economia.
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
- Versão do Godot fixada em 4.5 via `GODOT_VERSION` no workflow.

## Modo de teste
O menu ganha a aba **Teste** (dar ouro/gemas/fragmentos, pular de fase, curar, zerar recargas, desbloquear tudo, resetar progresso)
e o HUD mostra `[TESTE]`. Isso existe só quando `Balance.DEBUG_TOOLS = true` **e** o build é de debug (`OS.is_debug_build()`).
**Antes do APK final:** coloque `DEBUG_TOOLS := false` em `data/balance.gd` (e exporte em release). Há um teste que verifica a coerência da flag.

## Versão final (release)
Veja `docs/RELEASE.md`: chave de assinatura própria em secrets + workflow manual "Gerar APK de release".

## Arte (original, CC0)
Toda a arte pixel art é gerada por código em `tools/art/` (sem assets de terceiros). Para regenerar: `python3 tools/art/generate.py`
(gera `assets/sprites/*.png`, `data/sprite_manifest.gd` e `docs/art_preview.png`). Para mudar um sprite, edite o gerador e rode de novo.

## Como atualizar o repositório com um novo zip
Extraia o zip **direto na raiz do repositório** (os arquivos `project.godot`, `data/`, `scripts/`, `.github/` devem ficar na raiz,
sem subpasta). Se aparecer uma pasta `angelic_ascension/` dentro do repositório, apague-a. O CI verifica isso (`tools/ci/check_layout.sh`).

## Interface (toque próprio, multitoque)
Todos os botões/menus são controles próprios (`UiButton`, `UiList`) que usam `InputEventScreenTouch/Drag`, então o joystick e o menu
funcionam ao mesmo tempo. Fonte pixel e ícones são originais (`tools/art/ui.py`). Todo texto exibido deve usar só caracteres de
`SpriteManifest.FONT_CHARS` (há teste que verifica isso). Maquete do layout: `docs/ui_maquete.png`.
