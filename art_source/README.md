# Arte original (fora do jogo)

Esta pasta tem `.gdignore`: o Godot NÃO importa nem exporta nada daqui (não pesa no APK).

| Arquivo | O que é | Uso |
|---|---|---|
| `fire_props_sheet.png` | Folha de tochas, braseiros, pilares, lanternas, fogueiras, fumaça e efeitos de fogo (com transparência) | Recortada em `assets/env/` (brazier, torch_wall, torch_pillar, lantern, ground_fire_0..4) |
| `angel_sheet.jpg` | Arte ANTERIOR do anjo (11 poses, fundo branco) | **Sem uso** (substituída pela v2) |
| `angel_v2_b.webp` | Anjo v2: parado (7), ataque de raio, Power Surge e voo, fundo branco | Recortada em `assets/angel/`: `idle_0..6`, `fly_1..4` (andando), `atk_charge/release/follow`, `comet`, `orb`, `surge_0..3` (transformação da Morte do Inferno) e `swirl` (redemoinho ao transformar). Âncora = centro do rosto (`AngelSprite.ANCHORS`), mão em `AngelSprite.HANDS`. `surge_3..4` também no golpe da Morte do Inferno. **Sem uso:** esfera pequena e pouso do voo |
| `angel_v2_2wings.webp` | Anjo v2 com só **2 asas** (mesmas linhas + raio desenhado, pairar e golpes de espada) | Recortada em `assets/angel/*_2w.png` (mesmos nomes + `_2w`; âncoras em `AngelSprite.ANCHORS_2W`). Usada até a asa nível 6; a partir do 7 o jogo troca para as 4 asas. O "acompanhar" do ataque usa `atk_charge_2w`. **Sem uso:** raios desenhados, pairar/pouso e a sequência de espada |
| `angel_power_2wings.jpg`, `angel_power_4wings.jpg` | Forma de poder da Morte do Inferno (parado, voo, golpe), 2 e 4 asas. **Fundo xadrez desenhado** (removido no recorte) | Recortadas em `assets/angel/power_idle_0..4`, `power_fly_0..4`, `power_atk_1..4` (+ `_2w`). Desenhadas maiores: `AngelSprite.POWER_SCALE` = 0,7. O 1º quadro do golpe (igual ao parado) não é usado |
| `hell_projectile_sheet.webp` | Projétil da Morte do Inferno (6 quadros, fundo branco): esfera com penas, estrela, 3 quadros do projétil, desfazendo | Recortada em `assets/angel/hp_charge`, `hp_burst`, `hp_bolt_0..2`, `hp_fade` (usados por `AngelShot.hell_shot`). A prévia animada que veio junto não é usada |
| `spear_frames.zip` | Lança Celestial: 6 quadros 832x832 com transparência (surgir, carregar, disparar, voar, impacto, desfazer) | Recortados (só o vazio) em `assets/skills/celestial_lance/frame_1..6.png`; pontos de referência em `LanceFx.PIVOTS` |
| `baal/` (6 folhas, fundo transparente) | Baal: andar, preparar/correr a investida, pancada em área, golpe corpo a corpo (`baal_melee`, o 3º quadro não é usado), morte | Recortadas (metade da resolução, tamanho igualado entre as folhas) em `assets/bosses/baal/*.png`, todas num quadro 380x232 com os pés no mesmo ponto; animações em `BossArt.SHEETS`. O 1º quadro da morte foi espelhado (olhava para o outro lado). O avanço da folha de investida (3º quadro) não é usado |
| `mordath/` (6 folhas, fundo transparente) | Mordath: flutuar, conjurar/lançar, invocar, morte, portal de invocação, bola de fogo | Corpo em `assets/bosses/mordath/*.png` (quadro 218x285, pés/barra da capa alinhados; animações em `BossArt.SHEETS`; o 1º quadro do andar foi espelhado, olhava para trás). Efeitos em `assets/bosses/mordath/fx/` (`BossFx`). **Sem uso:** os 3 últimos quadros do portal e os 2 últimos da invocação (pedido do usuário); o leque e a bola desenhados nos quadros de lançar foram cortados (as bolas de verdade saem da mão) |
| `ignarr/` (7 folhas, fundo transparente) | Ignarr: andar, golpe, sopro, rugido dos meteoros, morte, efeito do sopro, meteoro | Corpo em `assets/bosses/ignarr/*.png` (quadro 588x340, patas alinhadas; andar e sopro espelhados porque olhavam para a esquerda; o fogo desenhado na boca foi cortado, o sopro é um efeito à parte). Efeitos em `assets/bosses/ignarr/fx/`. **Sem uso:** 1º e 5º quadros da folha de ataque (de frente/fora de escala) |
| `azazel/` (8 folhas, fundo transparente) | Azazel: voo, arremesso, orbes de almas, sumir/surgir (passo sombrio), morte, efeito do orbe, portal de sombra | Corpo em `assets/bosses/azazel/*.png` (quadro 320x300; asas vizinhas e orbes soltos removidos no recorte). Efeitos em `assets/bosses/azazel/fx/`. O voo usa os quadros escolhidos pelo usuário (mistura de originais e espelhados: 1,3,4 espelhados, 4 e 5 originais, 2 espelhado, nessa ordem). Orbe: `azazel_orb2_fx.webp` (quadros 1,2,3,7,8 -> `fx/soul_*`); `azazel_orb_fx.webp` ficou sem uso. **Sem uso:** 1º–3º quadros da folha de arremesso, quadros 4–6 do orbe novo |
| `lucifer/` (13 folhas, fundo transparente) | Lucifer: andar, golpe de espada, invocar (espada erguida), nova (braços abertos), raio (aponta), tempestade (espada com as duas mãos), colheita (flutuando), morte; efeitos: alma, explosão, raio, anel de fogo, portal | Corpo em `assets/bosses/lucifer/*.png` (quadro 376x370, pés alinhados); efeitos em `assets/bosses/lucifer/fx/`. **Sem uso:** 1º e 6º quadros do golpe (iguais ao parado), 2º e 3º quadros da alma (o voo usa os quadros com rastro) |
| `angel_v2_c.webp`, `angel_v2_ultra.webp` | Mesmas poses redesenhadas (asas iguais); a `ultra` tem a fase Ultra-Power com céu/chão desenhados atrás | Guardadas. As da `ultra` com cenário não dão para recortar sem refazer o fundo |
| `mobs_sheet.webp` | Mobs (gosma, guerreiro de escudo, espectro, golem de lava, diabinho, demônio roxo, aranha) e 4 anjos | Recortada em `assets/mobs/` (dados em `MobArt.SHEETS`). **Sem uso por enquanto:** aranha e os 4 anjos |
| `world_props_sheet.png` | Objetos do **mundo aberto** (portal, arcos, muralhas, estandartes, ilhas flutuantes, chão de lava) | **Guardada para depois.** Atenção: o fundo xadrez está DESENHADO na imagem (não é transparência de verdade); antes de usar, precisa remover o xadrez ou pedir a folha com fundo transparente |

O fundo da arena (`assets/env/arena_bg.png`) veio da imagem enviada pelo usuário, em resolução original (1672x941).

## Mapas (imagem única por mapa)

- `maps/map_gate.webp`, `map_forge.webp`, `map_graveyard.webp` -> `assets/env/maps/gate.png`, `forge.png`, `graveyard.png` (2000x1125).
- Contorno andável e objetos bloqueados em `data/arena_maps.gd` (pixels da imagem); a lava é tirada automaticamente pela cor.
- Uso: portão e cemitério alternam a cada 10 fases; forja nas fases de chefe e no boss semanal (`ArenaMaps.for_stage`).
- `tile_*.webp` (tentativa anterior com tiles) ficaram sem uso.
- `lava_portal_sheet.webp` (12 quadros, fundo branco) -> `assets/env/portal/portal_00..11.png` (144 px): portal de lava de onde os mobs nascem (`LavaPortal`).

## Habilidades

- `skills/rain_of_light.webp` (com transparência) -> `assets/skills/rain_of_light/` (fall_0..3, flash, impact_0..4; reduzidos a 60%).
- `skills/holy_shield.webp` (4x4, com transparência) -> `assets/skills/holy_shield/shield_00..15` (00-05 ativação, 06-11 escudo em laço, 12-15 quebra).
- `skills/swords_of_paradise.webp` (12 quadros) -> `assets/skills/swords_of_paradise/sword_00..11` (00-02 surgem, 03-08 laço, 09-11 somem; `OrbitSwords`).
- `skills/divine_judgment.webp` (14 quadros) -> `assets/skills/divine_judgment/judgment_00..13` (00-03 selo, 04-09 raio com o topo esmaecido, 10-13 dissipar).
- `skills/wings_of_redemption.png` (7) + `skills/wings_ring.png` (5) -> `assets/skills/wings_of_redemption/wings_0..6`, `ring_0..4`.
- `skills/army_of_archangels.webp` (16, 125 px) -> `assets/skills/army_of_archangels/angel_00..15` (00-03 surgir, 04-07 parado, 08-11 golpe, 12-15 sumir; `ArchangelAlly`).
- `skills/fury_burst.png` (7) + `fury_aura.png` (6) -> `assets/skills/celestial_fury/burst_0..6`, `aura_0..5`.
- `skills/apocalypse_seal.png` (7), `apocalypse_pillar.png` (5), `apocalypse_blast.png` (6) -> `assets/skills/holy_apocalypse/seal_*`, `pillar_*`, `blast_*`.
- `skills/hell_burst.webp` (9, 222 px) -> `assets/skills/death_of_hell/burst_0..8` (explosão de ativação da MORTE DO INFERNO).
- Código: `scripts/runtime/skill_fx.gd`.
