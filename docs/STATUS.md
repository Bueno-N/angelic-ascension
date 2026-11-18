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


## Rodada 15 — animação de morte, aviso de fase, menu "Fases" (300 andares, dificuldade a cada 50) e projeção de ganhos (⬜ escrita, **nunca executada no CI**)

| Item | Estado | Observação |
|---|---|---|
| Morte: jogo congela, anjo cai com penas, "VOCÊ CAIU"; **toque na tela** volta à fase anterior | ⬜ | `death_overlay.gd`; toques ficam travados 1,2 s; anima em tempo real (ignora o 2x) |
| Aviso "FASE N" + dificuldade ao entrar numa fase (também ao voltar/escolher) | ⬜ | Dourado; em fase de chefe o aviso de chefe (vermelho) aparece em seguida |
| Aba **Fases** no menu: 300 andares em 6 dificuldades de 50 (Fácil, Normal, Difícil, Pesadelo, Infernal, Abismal) | ⬜ | Abre rolando até a fase atual; **IR** só em fases já alcançadas; escolher uma abaixo do recorde fica **repetindo** nela |
| Dificuldade muda a cada 50: vida, dano e ganhos dos inimigos multiplicados por degrau | ⬜ | **Valores são palpite** (`Balance.TIER_*`): vida x1/1,5/2,5/4/6,5/10, dano x1/1,25/1,6/2,1/2,8/3,8, ganhos x1/1,25/1,6/2/2,5/3,2. Muda o equilíbrio: precisa de playtest |
| Projeção por fase: mobs, ouro e gemas médios por vitória (+ fragmentos nos chefes) | ⬜ | `StageLogic.projection`: média teórica com as chances de drop atuais, **não é medição** |
| Limite de 300 andares (progressão, saves e debug) | ⬜ | No 300 (chefe) só repete; save com fase maior é limitado a 300 |
| Grade do menu agora com 3 colunas (cabem 6-7 abas) | ⬜ | |
| Ícone novo `stages` | ✅ visto (PNG) | |
| Testes `test_stages.gd`; smoke com `death=` e `goto=` | ⬜ | |


## Rodada 16 — mapa das fases (botão FASES abaixo de MENU) (⬜ escrita, **nunca executada no CI**)

Substitui a lista de fases dentro do menu (rodada 15): a aba "Fases" saiu do menu; o resto da rodada 15 (morte, aviso de fase, dificuldades, projeção) continua.

| Item | Estado | Observação |
|---|---|---|
| Botão **FASES** logo abaixo do botão MENU; abre o mapa em tela cheia | ⬜ | `map_panel.gd`, `map_logic.gd`; o menu desceu para não cobrir o botão |
| Mapa: caminho sinuoso com bolinhas, "Fase N" em cima de cada uma, até a fase 300; rola arrastando (com inércia) | ⬜ | Chips de dificuldade no topo pulam para cada degrau |
| Fundo mais vermelho a cada dificuldade (Fácil azul-noite ... Abismal vermelho vivo) | ⬜ | Cores em `MapLogic.TIER_BG` (palpite visual; ver no celular) |
| Chefes com ícone de caveira (e nó maior); mini-chefes com espada | ⬜ | Ícone novo `skull` ✅ visto (PNG) |
| Tocar numa fase mostra dificuldade e projeção de ganhos; **IR PARA A FASE** só em fases já alcançadas | ⬜ | Escolher uma abaixo do recorde fica repetindo nela |
| O mapa **pausa** o jogo enquanto aberto (tela cheia) | ⬜ | Decisão minha; o menu continua sem pausar |
| Testes de mapa em `test_stages.gd`; smoke com `map=` | ⬜ | |


## Rodada 17 — crateras no mapa, ícones de habilidades, preços, trilha sonora e efeitos sonoros (⬜ escrita, **nunca executada no CI**)

| Item | Estado | Observação |
|---|---|---|
| Fundo do mapa com **crateras** (tile 320x160 sem emendas, 2x, com paralaxe), por cima das cores de dificuldade | ✅ visto (PNG) / ⬜ no jogo | `tools/art/scenery.py` → `assets/sprites/map_craters.png`; desenho em `map_panel.gd` |
| **Ícones** das 10 habilidades (lança, escudo, chuva, espadas, raio, asas, exército, fúria, apocalipse, morte do inferno) na barra de habilidades e no menu | ✅ visto (PNG) / ⬜ no jogo | `ui.py`; nomes `sk_<id>` no atlas `ui_icons.png`; a sigla (LC, ES...) deixou de ser desenhada |
| **Preços das habilidades ~1/3 menores**: 70 / 350 / 1.300 / 5.000 / 13.500 / 34.000 / 82.000 / 200.000 / 500.000 / 1.300.000 gemas | ⬜ | Calculados com o modelo `EconomyModel` AGORA com o teto de 300 fases (depois da 300 o ganho é só repetir a última). Modelo: 1ª em ~1 h, suprema em ~435 h (~145 dias a 3 h/dia). **É modelo, não medição** |
| Modelo de economia respeita as 300 fases (`farming`) | ⬜ | Antes ele supunha fases infinitas e subestimava o tempo das habilidades caras |
| **4 trilhas** (`music_1/2/3` por par de dificuldades + `music_boss` nas fases de chefe), laço de 16 compassos | ⬜ gerada, **nunca ouvida por mim** | `tools/audio/music.py`; 25-42 s cada, OGG mono 32 kHz, ~1,1 MB no total |
| **46 efeitos**: ataque, dano no anjo, morte, 10 habilidades, mobs (ataque e morte por tipo), tiro e drenar, 8 habilidades de chefe/mini-chefe, rugido, alerta, fim de chefe, UI | ⬜ gerados, **nunca ouvidos por mim** | `tools/audio/sfx.py`; WAV mono 22 kHz, ~2 MB. Timbre e volume relativo são palpite: ajuste `AudioLogic.GAIN_DB` ouvindo no celular |
| Opções de som: **Música liga/desliga**, **volume da música**, **volume dos efeitos sonoros** (0 = só música), além do volume geral | ⬜ | Valem para o aparelho (`settings.json`), também no menu inicial |
| Limitador de efeitos (intervalo mínimo por som, 16 vozes com prioridade) | ⬜ | Evita 50 mobs virarem ruído: habilidades e chefes nunca são cortados |
| `AudioHub` (autoload) com troca suave de trilha e música também no menu inicial | ⬜ | `autoload/audio_hub.gd` |
| Testes `test_audio.gd` (arquivos x manifesto, trilha por fase, limitador, opções, barramentos); smoke com `aud=` | ⬜ | Smoke toca TODOS os efeitos e músicas e confere que carregam |

Pendências que só o aparelho resolve: soar bem? volume relativo música x efeitos? o 2x de velocidade não muda o tom (conferir); consumo de bateria com música.

## Rodada 18 — Boss Semanal (Lucifer) e ranking mundial (⬜ escrita, **nunca executada no CI**; online **nunca testado contra servidor**)

| Item | Estado | Observação |
|---|---|---|
| Botão **BOSS SEMANAL** (ícone do Lucifer) logo abaixo de FASES; **travado até concluir a fase 50** (recorde > 50); o painel do menu desceu para não cobri-lo | ⬜ | `hud.gd`; `UiButton` aceita texto em 2 linhas |
| **Lucifer** (chefe único, fora da lista de 4 chefes de fase): sprite 64x64 original (`tools/art/enemies.py`), 4 habilidades exclusivas — Nova infernal (rosca: segura colado nele ou longe), Raio do abismo, Tempestade infernal (9 meteoros), Colheita de almas (12 orbes teleguiados) — + **invoca 1 chefe a cada 20 s** (até 4 vivos; aparência Baal/Mordath/Ignarr/Azazel, vida e dano do chefe do andar 290) | ⬜ | `enemies_db.gd`, `enemy.gd`; 5 sons novos (`tools/audio/sfx.py`) |
| Potência: vida **8x** e dano **1,2x** do chefe da fase 300 (`Balance.WEEKLY_*`) | ⬜ **palpite** | "Mais difícil que a última fase": só o playtest diz se a escala está certa |
| Luta de **2 min**; fim: "O SEU TEMPO ACABOU" (ou "LUCIFER DERROTADO!" / "VOCE CAIU") e volta à partida normal (anjo curado); a fase fica congelada e mapa/próxima fase travados durante a luta | ⬜ | `stage_manager.gd` (modo semanal), `main.gd` |
| **4 entradas por semana** (semana = segunda 00:00 UTC), gastas ao entrar | ⬜ | `weekly_boss.gd`, salvas em `state["weekly"]`; online o servidor conta as entradas |
| **Pontuação** = dano ao Lucifer (+ até 25% se matar, pelo tempo que sobrar); vale o melhor da semana | ⬜ | |
| **Ranking mundial** + **prêmios por posição** (1º = 600 gemas + 25 fragmentos ... participação = 10 gemas), resgate na semana seguinte | ⬜ escrito / ❌ **não testado em servidor** | `online_client.gd`, `weekly_panel.gd`, `docs/weekly_ranking.sql`, `docs/ONLINE.md`. **Precisa de um projeto Supabase e de URL + chave em `data/online_config.gd`; sem isso roda OFFLINE** |
| Testes `test_weekly.gd` (semana UTC, desbloqueio, 4 entradas, prêmios, pontuação, save, parse da resposta do servidor, habilidades, textos na fonte); smoke com `wk=` e as 5 habilidades novas | ⬜ | Rede (`OnlineClient`) **sem teste automatizado** |

Limites conhecidos do online (detalhes em `docs/ONLINE.md`): pontuação enviada pelo aparelho (dá para trapacear), sem login (id anônimo por instalação), plano grátis do Supabase pode pausar por inatividade, política de privacidade necessária na Play Store (nome do perfil vai ao servidor).
Pendências que só o aparelho resolve: o Lucifer é legível/justo na tela? 2 min é suficiente? prêmios equilibrados com a economia? sons novos soam bem?

## Rodada 19 — rebalanceamento dos mobs e menu em tela cheia (⬜ escrita, **nunca executada no CI**)

| Item | Estado | Observação |
|---|---|---|
| Vida/dano dos mobs **polinomiais** (`fase^0,8` e `fase^0,7`) em vez de x1,12 / x1,09 por fase | ⬜ palpite por modelo | Modelo: o poder do anjo cresce ~linear com a fase (ouro +10%/fase, custo +15%/nível); o crescimento exponencial dos mobs virava muro por volta da fase 40 (fase 55: vida 13,6 mil; fase 300: 1e17). Agora mob comum (base 20): fase 55 ~740, 300 ~19 mil |
| Degraus de dano mais suaves: x1 / 1,15 / 1,35 / 1,6 / 1,9 / 2,2 (vida igual: até x10) | ⬜ | Lucifer: dano 1,2x do chefe da fase 300 |
| Menu ocupa a tela (menos a coluna MENU/FASES/BOSS), por cima da fase; asas/equipamentos: prévia do anjo à esquerda e lista larga à direita | ⬜ | Precisa ver no celular |

Atenção: com a progressão mais fácil o ritmo real de fases/hora vai subir; o modelo de economia (gemas) precisa de recalibração com playtest.

## Rodada 20 — Lucifer como chefe final, semanal mais forte, velocidade limitada (⬜ escrita, **nunca executada no CI**)

| Item | Estado | Observação |
|---|---|---|
| **Lucifer é o chefe da fase 300** (último do jogo): vida e dano x1,3 sobre a fórmula de chefe (`Balance.LUCIFER_STAGE_MULT`), maior que os outros chefes; invoca chefes com 50% do andar 290 | ⬜ palpite | `EnemiesDB.boss_for(300)`, `StageLogic.boss_hp/dmg`; recompensas normais de chefe (gemas/ouro) |
| **Semanal mais forte**: vida 6x e dano 1,6x do chefe da fase 300 (já com o x1,3: ~7,8x e ~2x); **invocações = chefe do andar 290 inteiro** (vida e dano) | ⬜ palpite | `Balance.WEEKLY_*` |
| **Velocidade de movimento limitada a 50 melhorias** (máx. 420 sem bônus); a linha mostra MÁXIMO; o save é limitado a 50 | ⬜ | `max_level` em `Balance.ATTRIBUTES`; outros atributos sem teto |
| Testes: `test_weekly.gd` (Lucifer na fase 300, invocações no andar 290, teto da velocidade) | ⬜ | |

## Rodada 21 — migração para o Godot 4.5 (preparação para o AdMob) (⬜ escrita, **nunca executada no CI**)

| Item | Estado | Observação |
|---|---|---|
| `GODOT_VERSION` 4.3 → **4.5** (build.yml, release.yml, scripts `tools/ci/setup_*.sh`), `project.godot` features "4.5" | ⬜ | Download de `4.5-stable` e templates `4.5.stable` |
| Android SDK do CI: build-tools **35.0.1** e plataforma **android-35** (exigência do Godot 4.5); `apksigner` do release aponta para 35.0.1 | ⬜ | `setup_android.sh`, `build_release.sh` |
| Código do jogo **não foi alterado**; pode haver avisos/erros novos do 4.5 no parse (avisos viram erro neste projeto) | ❌ desconhecido | Cole o log do CI e eu corrijo |
| AdMob | ⬜ **não instalado** | Próximo passo: Android Build Template + build com Gradle + classe `Ads` |
