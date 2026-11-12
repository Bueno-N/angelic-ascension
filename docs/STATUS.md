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

## Alterações da rodada 2 (escritas, ainda NÃO executadas no CI)

| Item | Estado | Observação |
|---|---|---|
| Regeneração de vida (1,5%/s da vida máx.) + cura de 30% ao limpar fase | ⬜ | `Balance.HP_REGEN_PCT_PER_SEC`, `STAGE_CLEAR_HEAL_PCT`; testes em `test_stats.gd` |
| Novo ritmo: ~100 inimigos/fase em fluxo (1/s), simultâneos 4→30 | ⬜ | Fase 1 ≥ ~100 s (limite de spawn). **Nunca medido em jogo real** |
| BOSS_GEM_GROWTH 1.12 → 1.10; MODEL_STAGES_PER_HOUR 30 → 32 | ⬜ | Projeção (Python): 1ª habilidade ~1,5 h, suprema ~103 dias a 3 h/dia. Gemas/h inicial no modelo: **~75** (≈35% vem dos drops de mobs). Acima da referência de 15–25: foi o pedido de "um pouco mais elevado", mas é ~3x, não ~2x |
| Menus: Atributos, Equipamentos, Asas+Brilho, Habilidades | ⬜ | Compra/equipar/remover funcionam via lógica já testada; layout/rolagem por toque **não validados** |
| `UiLogic` (estados, metas, bônus totais, formatação) + 8 testes | ⬜ | `tests/test_ui_logic.gd` |
| HUD de calibração: "Última fase: X s \| Gemas/h (sessão)" | ⬜ | Serve para medir o ritmo real no celular |
| Smoke run: agora exige avançar de fase (fase 1 com 3 inimigos só no modo --smoke) | ⬜ | Exercita limpeza de fase + cura |

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
| 9 As 10 habilidades | dados + lógica de slots + menu de compra/equipar ⬜ | **Sem efeitos, animações, botões nem auto-cast em combate** |
| 10 Polimento | não iniciado | |

## Validação manual obrigatória (nenhum CI substitui)

👤 APK instala e abre num celular real · orientação landscape · joystick responde ao toque · FPS em aparelho intermediário · consumo de bateria/memória · save persiste após fechar o app e matar o processo · legibilidade da HUD (notch/safe area não tratado) · sensação de balanceamento · visual/arte.

## Parâmetros que dependem de decisão/calibração

- Preços de equipamentos e brilho: **placeholders** (design não definiu).
- `BOSS_GEM_GROWTH = 1.12`: escolhido pela projeção; o ritmo real depende da dificuldade (HP dos inimigos cresce exponencialmente; atributos de ouro crescem de forma polinomial — existirá um "muro" de fase que o modelo não captura).
- Dano extra do Julgamento Divino em chefes: +50% (sugestão).
- Preços das habilidades: mantidos como no design original.
