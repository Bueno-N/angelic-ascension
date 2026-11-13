# Registro de status — o que foi REALMENTE verificado

Atualize esta tabela depois de cada execução do workflow. Regra: só marque ✅ com evidência (log do GitHub Actions).

Legenda: ✅ executado e passou · ❌ executado e falhou · ⬜ escrito, **nunca executado** · 👤 depende de validação manual em aparelho

## Estado atual (nenhuma execução do CI ainda)

| Item | Estado | Evidência / observação |
|---|---|---|
| Sintaxe YAML do workflow | ✅ | Validada com PyYAML no ambiente de autoria (não prova que o GitHub aceita todas as actions) |
| Sintaxe bash de `tools/ci/*.sh` | ✅ | `bash -n` no ambiente de autoria |
| Balanço de parênteses e indentação dos `.gd` | ✅ | Script estático simples. **Não é** o parser do GDScript |
| Parse real dos `.gd` (Godot 4.3) | ✅ parcial | Run 1: 24/30 OK. 6 falharam só por autoload não resolvido em `--check-only` (falso positivo); agora validados via smoke run |
| Importação do projeto + cache de classes | ✅ | Run 1 (`import.log`) |
| Testes de lógica (stats, habilidades, economia, progressão, save, drops) | ⬜ | `tests/run_tests.gd` — nunca rodou; podem existir erros de GDScript/ asserts |
| Instalação de export templates 4.3 | ⬜ | `setup_templates.sh` |
| Configuração do SDK Android + keystore debug | ⬜ | `setup_android.sh` |
| Export do APK debug | ⬜ | `build_apk.sh`; o `export_presets.cfg` foi escrito à mão (não gerado pelo editor) |
| `economy_report.gd` | ✅ | Run 1: saída idêntica ao port em Python (modelo compila e calcula igual). Continua sendo projeção, **não mede jogo real** |
| Smoke run (cena principal, 30 s) | ⬜ | `smoke_run.sh`, novo |

## Rodada 2 (regen, ritmo, menus): CI verde (confirmado pelo usuário)

Testes: 43 testes / 5.774 verificações / 0 falhas (run anterior). Smoke run sem erro de script. Ritmo e menus ainda **não validados em celular**.

## Rodada 3 — Etapa 1: habilidades em combate

**Evidência do CI (logs enviados pelo usuário):** testes 62 / 6.097 verificações / 0 falhas / 0 avisos; smoke run `stage=2 gold=36 hp=100 casts=18` (10 habilidades executadas + 8 auto-casts). O job `verify` ficou vermelho só por falso positivo de `--check-only` em cascata (autoload via SkillCaster); filtro corrigido (⬜ aguardando novo run). **O APK desta versão ainda não foi gerado** (job build-android depende do verify).

| Item | Estado | Observação |
|---|---|---|
| 10 habilidades com efeito em combate (`skill_caster.gd`) | ⬜ | Parâmetros (raios, contagens, durações) em `data/skills_db.gd` |
| Buffs temporários (`BuffState`), brilho escala cura/escudo/buffs | ⬜ | Testes em `test_skill_runtime.gd` |
| Auto-cast com regras por habilidade (`AutoCast`) + botão AUTO | ⬜ | Regras simples; precisam de teste de sensação no celular |
| 3 botões com recarga visual (`SkillBar`) | ⬜ | Layout/tamanho do toque não validados |
| Joystick multitoque (ScreenTouch/Drag) | ⬜ | `emulate_touch_from_mouse=true` para teste no desktop. **Risco: comportamento real de 2 dedos só no celular** |
| Smoke run: executa as 10 habilidades (`debug_cast_all`) + auto-cast, exige casts >= 10 | ⬜ | Cobre o código, não a sensação nem os visuais |

Decisões de design que eu tomei (revise): Apocalipse Sagrado limita dano em chefes a 25% da vida máx. por uso (garante "sem execução"); Morte do Inferno dobra ataque/armadura/velocidades/aura, mas **não** a vida máxima; Exército dos Arcanjos: 2000% por golpe, cada guerreiro golpeia a cada 2 s (ambiguidade do design); Escudo limitado a 90% de absorção mesmo com brilho alto; habilidade recém-equipada começa com 2 s de recarga.

## Rodada 4 — Modo de teste (escrito, ainda NÃO executado no CI)

| Item | Estado | Observação |
|---|---|---|
| Aba "Teste" (ouro, gemas, fragmentos, fase, cura, recargas, desbloquear tudo, reset) | ⬜ | `DebugTools` + testes em `test_debug_tools.gd` |
| Desligamento no APK final | ⬜ | `Balance.DEBUG_TOOLS` + `OS.is_debug_build()`. **Lembrar de pôr false antes da versão final** |

## Implementado (código escrito) × planejado

| Etapa do plano | Código | Observação |
|---|---|---|
| 0 Infra | executado no CI | Run anterior verde |
| 1 Movimento/joystick | executado no CI (smoke) | Toque real não validado |
| 2 Combate (ataque auto + aura) | executado no CI (smoke) | Arte provisória |
| 3 Fases/ondas/escala | executado no CI (smoke); ritmo novo ⬜ | |
| 4 Ouro + upgrades | executado no CI; menu novo ⬜ | |
| 5 Chefes + fragmentos | parcial | **As 2 habilidades de cada chefe NÃO estão implementadas** (só dados) |
| 6 Gemas e drops | lógica testada no CI | |
| 7 Equipamentos | lógica testada + menu ⬜ | Preços placeholders |
| 8 Asas e brilho | lógica testada + menu ⬜ | Prévia das asas no menu |
| 9 As 10 habilidades | menu executado no CI; efeitos em combate ⬜ (rodada 3) | Efeitos desenhados por código (anéis, raios, espadas, aliados) |
| 10 Polimento | não iniciado | |

## Validação manual obrigatória (nenhum CI substitui)

👤 APK instala e abre num celular real · orientação landscape · joystick responde ao toque · FPS em aparelho intermediário · consumo de bateria/memória · save persiste após fechar o app e matar o processo · legibilidade da HUD (notch/safe area não tratado) · sensação de balanceamento · visual/arte.

## Parâmetros que dependem de decisão/calibração

- Preços de equipamentos e brilho: **placeholders** (design não definiu).
- `BOSS_GEM_GROWTH = 1.12`: escolhido pela projeção; o ritmo real depende da dificuldade (HP dos inimigos cresce exponencialmente; atributos de ouro crescem de forma polinomial — existirá um "muro" de fase que o modelo não captura).
- Dano extra do Julgamento Divino em chefes: +50% (sugestão).
- Preços das habilidades: mantidos como no design original.
