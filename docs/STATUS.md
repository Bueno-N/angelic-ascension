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

## Rodada 3 e 4: evidência do CI
Etapa 1 (habilidades em combate): testes 62 / 6.097 verificações / 0 falhas; smoke `casts=18`. O APK com as habilidades e o modo de teste **ainda não foi gerado/validado** (o job verify ficou vermelho por falso positivo de `--check-only`, filtro corrigido na rodada seguinte; aguardando run).

## Rodada 5: CI verde (confirmado pelo usuário)
Trava de troca, automático por slot, rolagem do menu e habilidades de chefes/especiais passaram no CI. **Validação em celular ainda pendente** (dificuldade dos chefes, rolagem real, multitoque).

## Rodada 6: evidência parcial do CI + correções (rodada 7)
Log do usuário: smoke `stage=12 cleared=2 repeat=1 next=1 speed=1` (morrer→repetir, próxima fase e 2x funcionaram); abilities de chefe executadas: area_slam, charge, summon_demons, hellfire_projectiles. **Faltaram fire_bolt e life_steal**: o anjo desbloqueado matou os especiais antes de agirem (corrigido no smoke: especiais posicionados no alcance e resistentes).
Testes: 89 testes / 8.136 verificações, mas com **2 SCRIPT ERROR** (`bool("x")` no `sanitize` do save). Corrigido com conversores seguros (`SaveData.as_int/as_bool`) + teste com lixo em todos os campos. Aguardando novo run.
Obs.: "0 falhas" no resumo **não** inclui erros de script; o CI os detecta lendo o log.

## Rodada 11 — gameplay + HUD + menu novo (escrita, ainda NÃO executada no CI)

Depois de corrigir o layout do repositório (zip direto na raiz), o CI rodou. Esta rodada ainda não passou pelo CI. A maquete do layout (`docs/ui_maquete.png`) foi gerada em Python com a mesma fonte/ícones/medidas; **não é captura do jogo**.

| Item | Estado | Observação |
|---|---|---|
| Mobs aceleram com o tempo de fase (intervalo cai pela metade a cada 25 s; +1 simultâneo a cada 15 s, até +10) | ⬜ | `Balance.SPAWN_*`, `ALIVE_EXTRA_*`. **Muda a economia**: fases mais curtas = mais gemas/h. Reavaliar com o HUD "Gemas/h" |
| Mini-chefe no FIM da horda nas fases 5, 15, 25... (versão campeã, 1 habilidade, 40% da vida do chefe, ouro + 1-2 gemas, sem fragmentos) | ⬜ | `EnemiesDB.MINIS` |
| Aviso de chefe/mini-chefe (banner), arena de chefe com chamas nos 4 cantos + brilho vermelho pulsante + mais brasas | ⬜ | `fx_flame`, `Backdrop` |
| Contador de mobs (MOBS 37/100) + barra, "Próx.: Mini-chefe/Chefe na fase N (em K)" | ⬜ | |
| Vida do anjo VERDE | ⬜ | |
| Perfil: avatar (8 ícones originais) + nome editável + painel com TODOS os status | ⬜ | Toque no avatar. Nome usa o teclado do Android (LineEdit) |
| Menu novo: grade de ícones -> lista da aba com ícones, custo e botão; fonte pixel própria (com acentos) | ⬜ | `MenuModel` (lógica testada) + `UiList` |
| Multitoque no menu: andar e fazer upgrade ao mesmo tempo | ⬜ | Controles próprios por ScreenTouch. **Só o celular confirma** |
| Testes: `test_pacing_minis`, `test_profile_menu`, `test_ui_assets` (inclui: todo texto do jogo é desenhável pela fonte) | ⬜ | |
| Smoke: mini-chefes 5/15, 6+ avisos, percorre todas as abas do menu e o perfil | ⬜ | |

Riscos: nenhuma UI nova foi vista rodando; o teclado do nome (LineEdit) depende do Android; avatar/ícones são arte procedural.

## Rodada 9 — arte e animações (escrita, ainda NÃO executada no CI)

Toda a arte é **original**, gerada por código (`tools/art/*.py`), sem assets de terceiros (CC0, veja `assets/LICENSE.txt`). Prévia: `docs/art_preview.png`. A arte foi **conferida visualmente aqui** (PNGs); a integração no Godot **nunca rodou**.

| Item | Estado | Observação |
|---|---|---|
| 31 folhas de sprites (anjo em camadas, 6 demônios, 4 chefes, 8 efeitos, aliado, espada, tocha, chão) | ✅ arte gerada/inspecionada · ⬜ no jogo | `assets/sprites/*.png` + `data/sprite_manifest.gd` (gerado; .json não entra no APK) |
| Anjo REDESENHADO (rodada 10): arcanjo encapuzado de armadura branca/azul/dourada, 72x64 (era 48x48), espada sempre empunhada, asas de penas lavanda com placas douradas | ⬜ | Design **original** inspirado no estilo da referência enviada (não é cópia). Armadura de tier alto fica dourada |
| Anjo animado: idle / attack / cast, asas em 4 estágios, equipamentos tingidos por tier, piscada ao levar dano | ⬜ | Camadas alinhadas por tabela de poses; sincronia entre camadas só se confirma rodando |
| Aura: anel rúnico giratório, pulsa a cada tick, intensidade pelo nível de Aura, muda com Fúria/Morte do Inferno | ⬜ | |
| Ataque: animação de golpe + arco de luz + faíscas no alvo | ⬜ | |
| Skills: explosões, pilares de luz, escudo, espadas de luz orbitando, aliados animados | ⬜ | `SkillCaster` + `SpriteFx` |
| Monstros e chefes animados (andar + conjurar), sombra no chão, piscada branca ao levar dano | ⬜ | Fase de aviso mostra a pose "cast" |
| Cenário: chão de pedra com lava + tochas animadas + brasas | ⬜ | |
| Testes `test_sprites.gd` (manifesto, dimensões dos PNGs, animações, camadas, SpriteFrames) | ⬜ | |
| Smoke: instancia todos os demônios e os 4 chefes | ⬜ | |

Riscos conhecidos: FPS com ~8 AnimatedSprite2D no anjo + dezenas de inimigos (só o celular mede; "Efeitos: Baixo" ajuda); alinhamento fino das camadas do anjo; escala 2x fixa dos sprites.

## Rodada 8 (escrita, ainda NÃO executada no CI)

| Item | Estado | Observação |
|---|---|---|
| Etapa 5: menos redesenhos (inimigos, anjo, barra de habilidades a 20 fps), auto-cast 5x/s, teto de efeitos, FPS máx. 60 | ⬜ | **Sem medição de FPS/bateria**: são otimizações por inspeção do código. O ganho real só o celular mostra |
| Botão "Efeitos: Alto/Baixo" (sem brasas, faíscas e explosões; só chefes explodem) | ⬜ | Salvo no progresso; smoke exige `fx=1` |
| Etapa 6 (preparação): preset "Android Release", `release.yml`, `build_release.sh`, `docs/RELEASE.md` | ⬜ **nunca executado** | Precisa da sua chave (secrets). Valida assinatura com `apksigner`; desliga `DEBUG_TOOLS`; roda testes e smoke antes |
| Testes: `test_performance.gd` | ⬜ | |

## Rodada 6 (escrita)

| Item | Estado | Observação |
|---|---|---|
| Morrer volta 1 fase e **repete** ela até tocar em "Próxima fase" (modo repetir) | ⬜ | Botão no HUD (canto superior esquerdo). Só pula até uma fase **já alcançada** (`stage < max_stage`), para não furar chefes |
| Automático ON/OFF **por slot, em cima do ícone**; aba Auto e "todas de uma vez" removidas do menu | ⬜ | Regra do automático aparece na descrição de cada habilidade (aba Habilid.) |
| Botão "Velocidade 1x/2x" (salvo no progresso) | ⬜ | **Interpretação minha:** `Engine.time_scale = 2` (tudo: anjo, mobs, recargas). Não é só os mobs |
| Etapa 3 — cenário sombrio (gradiente, lava, vinheta, brasas) com paleta a cada 10 fases | ⬜ | Chefe = tom avermelhado |
| Etapa 3 — anjo evolui com equipamentos (espada, armadura, botas, luvas por tier) + prévia na aba Equip. | ⬜ | Cores/tamanhos por tier em `AngelDraw` |
| Etapa 3 — partículas: morte dos inimigos, faíscas do brilho das asas | ⬜ | Limite de 60 efeitos simultâneos |
| Etapa 3 — demônios por tipo (escudo, cauda sombria, espinhos, coroa do chefe) | ⬜ | Arte provisória feita em código |
| Etapa 3 — área segura (notch) no HUD | ⬜ | Só em aparelho móvel; **nunca testado em aparelho com notch** |
| Smoke estendido: morte→repetir, próxima fase, toggle 2x, todos os visuais com `unlock_all` | ⬜ | `repeat=1 next=1 speed=1` exigidos |
| Testes: `test_progress_controls.gd` | ⬜ | |

## Rodada 4 — Modo de teste (escrito)

| Item | Estado | Observação |
|---|---|---|
| Aba "Teste" (ouro, gemas, fragmentos, fase, cura, recargas, desbloquear tudo, reset) | ⬜ | `DebugTools` + testes |
| Desligamento no APK final | ⬜ | `Balance.DEBUG_TOOLS` + `OS.is_debug_build()`. **Lembrar de pôr false antes da versão final** |

## Implementado (código escrito) × planejado

| Etapa do plano | Código | Observação |
|---|---|---|
| 0 Infra | executado no CI | Run anterior verde |
| 1 Movimento/joystick | executado no CI (smoke) | Toque real não validado |
| 2 Combate (ataque auto + aura) | executado no CI (smoke) | Arte provisória |
| 3 Fases/ondas/escala | executado no CI (smoke); ritmo novo ⬜ | |
| 4 Ouro + upgrades | executado no CI; menu novo ⬜ | |
| 5 Chefes + fragmentos | escrito (rodada 5) ⬜ | 2 habilidades por chefe com telegraph; especiais com habilidade própria |
| 6 Gemas e drops | lógica testada no CI | |
| 7 Equipamentos | lógica testada + menu ⬜ | Preços placeholders |
| 8 Asas e brilho | lógica testada + menu ⬜ | Prévia das asas no menu |
| 9 As 10 habilidades | menu executado no CI; efeitos em combate ⬜ (rodada 3) | Efeitos desenhados por código (anéis, raios, espadas, aliados) |
| 10 Polimento | rodada 6 ⬜ (visuais por código; **sem arte final**) | |

## Validação manual obrigatória (nenhum CI substitui)

👤 APK instala e abre num celular real · orientação landscape · joystick responde ao toque · FPS em aparelho intermediário · consumo de bateria/memória · save persiste após fechar o app e matar o processo · legibilidade da HUD (notch/safe area não tratado) · sensação de balanceamento · visual/arte.

## Parâmetros que dependem de decisão/calibração

- Preços de equipamentos e brilho: **placeholders** (design não definiu).
- `BOSS_GEM_GROWTH = 1.12`: escolhido pela projeção; o ritmo real depende da dificuldade (HP dos inimigos cresce exponencialmente; atributos de ouro crescem de forma polinomial — existirá um "muro" de fase que o modelo não captura).
- Dano extra do Julgamento Divino em chefes: +50% (sugestão).
- Preços das habilidades: mantidos como no design original.


## Rodada 12 — aba Opções, novo layout do HUD e pausa (⬜ escrita, **nunca executada no CI**)

A rodada 11 passou no CI (confirmado pelo usuário; logs não anexados aqui). Esta rodada ainda não passou por nenhum CI nem foi vista num celular.

| Item | Estado | Observação |
|---|---|---|
| Aba **Opções** no menu (ícone de engrenagem): Efeitos Alto/Baixo e Volume do jogo (passos de 10%) | ⬜ | `options_logic.gd`, `menu_model.gd`; volume salvo em `settings.volume` e aplicado ao barramento Master (ainda não há áudio no jogo) |
| Botão MENU no canto superior direito | ⬜ | Habilidades passaram para o canto inferior direito |
| Ouro/gemas/fragmentos embaixo do cartão do anjo | ⬜ | |
| Velocidade 2x e Próxima fase ao lado do cartão da vida | ⬜ | Botão "Efeitos" saiu do HUD (agora na aba Opções) |
| Só o **perfil** (ícone do jogador) aberto = jogo em **pausa**; o menu NÃO pausa | ⬜ | `get_tree().paused`; o perfil continua ativo; joystick é solto ao pausar. Menu mantém o multitoque (andar enquanto faz upgrades) |
| Novos testes `test_options.gd`; smoke com `pause=` e `opt=` | ⬜ | Smoke despausa logo após checar (a cena precisa contar frames) |
| Ícones novos `gear` e `speaker` | ✅ visto (PNG) | Só conferidos visualmente; arte gerada por `tools/art/ui.py` |

Pontos de atenção para o celular: posição da barra do chefe (agora entre os botões e o MENU), largura do painel de recursos com números grandes, e se os controles pausados realmente ignoram toque (há guardas extras no código). `docs/ui_maquete.png` **não** foi atualizada para o novo layout.


## Rodada 13 — menu inicial, 2 jogos salvos, nome obrigatório e barra de mobs no topo (⬜ escrita, **nunca executada no CI**)

A rodada 12 (aba Opções, novo layout, pausa só com o perfil) foi confirmada como funcionando pelo usuário (sem logs do CI aqui).

| Item | Estado | Observação |
|---|---|---|
| Menu inicial (`scenes/title.tscn`, `title_screen.gd`): INICIAR JOGO, CONFIGURAÇÕES, SAIR | ⬜ | Agora é a cena principal do projeto; o jogo (`main.tscn`) só abre depois de escolher |
| INICIAR JOGO -> NOVO JOGO ou CARREGAR JOGO, **máx. 2 espaços** por conta | ⬜ | `SlotStore` (`user://save_1.json`, `save_2.json`); apagar e sobrescrever pedem 2º toque |
| Novo jogo exige **nome** (1+ caracteres desenháveis, até 14) | ⬜ | O botão COMEÇAR fica desabilitado sem nome; o nome continua editável no perfil |
| Save único antigo (`save.json`) vira o espaço 1 | ⬜ | `SlotStore.migrate_legacy` (teste em `test_slots.gd`) |
| Configurações (volume/efeitos) valem para todos os jogos | ⬜ | `user://settings.json`; também editáveis dentro do jogo (aba Opções) |
| Aba Opções: "Menu inicial" (salva e volta; permite trocar de jogo) | ⬜ | |
| Barra de **progresso de mobs** no meio do topo, contador dentro | ⬜ | Saiu do cartão do anjo; botões VEL./PRÓX. FASE desceram p/ y=52; barra do chefe foi p/ a direita deles |
| Testes `test_slots.gd`; smoke com `title=` | ⬜ | O smoke percorre as telas do menu inicial e entra no jogo sem gravar nada (espaço 0) |

Pontos de atenção para o celular: teclado virtual cobrindo o botão COMEÇAR (Enter/OK do teclado também confirma), legibilidade/tamanho dos botões do menu inicial, e se voltar ao menu inicial e iniciar outro jogo funciona repetidamente. `docs/ui_maquete.png` continua **sem** refletir o layout novo.


## Rodada 14 — 50 mobs (+5 a cada 5 fases) e habilidades próprias dos chefes 3 e 4 (⬜ escrita, **nunca executada no CI**)

| Item | Estado | Observação |
|---|---|---|
| Mobs por fase: 50 nas fases 1-5, +5 a cada 5 fases (55, 60...) | ⬜ | `StageLogic.enemy_count`; teto `ENEMY_COUNT_MAX = 180` (fase 131). **Muda a economia**: antes eram 100 na fase 1; gemas/h e ritmo precisam de nova medição |
| Mobs ficam mais fortes com a fase | ✅ já existia (lógica testada em rodadas anteriores) | Vida x1,12, dano x1,09 e ouro x1,10 por fase (`Balance.ENEMY_*_GROWTH`); teste novo confere o crescimento |
| Ignarr (fase 30): **Chuva de meteoros** + **Sopro flamejante** | ⬜ | Antes copiava Baal (investida + pancada) |
| Azazel (fase 40): **Passo sombrio** + **Orbes de almas** (teleguiados) | ⬜ | Antes copiava Mordath (projéteis + invocação) |
| Teste de que nenhuma habilidade se repete entre chefes; smoke exige as 4 novas | ⬜ | O smoke ficou mais longo (~4940 frames): 600 frames por chefe |

Números das habilidades novas (dano, raios, recargas) são **primeiro palpite**, sem playtest: ajuste em `EnemiesDB.ABILITIES`.
