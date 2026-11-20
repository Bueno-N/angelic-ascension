# Arte original (fora do jogo)

Esta pasta tem `.gdignore`: o Godot NÃO importa nem exporta nada daqui (não pesa no APK).

| Arquivo | O que é | Uso |
|---|---|---|
| `fire_props_sheet.png` | Folha de tochas, braseiros, pilares, lanternas, fogueiras, fumaça e efeitos de fogo (com transparência) | Recortada em `assets/env/` (brazier, torch_wall, torch_pillar, lantern, ground_fire_0..4) |
| `angel_sheet.jpg` | Arte ANTERIOR do anjo (11 poses, fundo branco) | **Sem uso** (substituída pela v2). Só o raio `hell_beam.png` (ataque da Morte do Inferno) continua vindo dela |
| `angel_v2_b.webp` | Anjo v2: parado (7), ataque de raio, Power Surge e voo, fundo branco | Recortada em `assets/angel/`: `idle_0..6`, `fly_1..4` (andando), `atk_charge/release/follow`, `comet`, `orb`, `surge_0..3` (transformação da Morte do Inferno), `power` (forma de poder) e `swirl` (redemoinho ao transformar). Âncora = centro do rosto (`AngelSprite.ANCHORS`), mão em `AngelSprite.HANDS`. `surge_3..4` também no golpe da Morte do Inferno. **Sem uso:** esfera pequena e pouso do voo |
| `angel_v2_2wings.webp` | Anjo v2 com só **2 asas** (mesmas linhas + raio desenhado, pairar e golpes de espada) | Recortada em `assets/angel/*_2w.png` (mesmos nomes + `_2w`; âncoras em `AngelSprite.ANCHORS_2W`). Usada até a asa nível 6; a partir do 7 o jogo troca para as 4 asas. O "acompanhar" do ataque usa `atk_charge_2w`. **Sem uso:** raios desenhados, pairar/pouso e a sequência de espada |
| `angel_v2_c.webp`, `angel_v2_ultra.webp` | Mesmas poses redesenhadas (asas iguais); a `ultra` tem a fase Ultra-Power com céu/chão desenhados atrás | Guardadas. As da `ultra` com cenário não dão para recortar sem refazer o fundo |
| `mobs_sheet.webp` | Mobs (gosma, guerreiro de escudo, espectro, golem de lava, diabinho, demônio roxo, aranha) e 4 anjos | Recortada em `assets/mobs/` (dados em `MobArt.SHEETS`). **Sem uso por enquanto:** aranha e os 4 anjos |
| `world_props_sheet.png` | Objetos do **mundo aberto** (portal, arcos, muralhas, estandartes, ilhas flutuantes, chão de lava) | **Guardada para depois.** Atenção: o fundo xadrez está DESENHADO na imagem (não é transparência de verdade); antes de usar, precisa remover o xadrez ou pedir a folha com fundo transparente |

O fundo da arena (`assets/env/arena_bg.png`) veio da imagem enviada pelo usuário, em resolução original (1672x941).
