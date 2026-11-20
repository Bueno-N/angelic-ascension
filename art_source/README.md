# Arte original (fora do jogo)

Esta pasta tem `.gdignore`: o Godot NÃO importa nem exporta nada daqui (não pesa no APK).

| Arquivo | O que é | Uso |
|---|---|---|
| `fire_props_sheet.png` | Folha de tochas, braseiros, pilares, lanternas, fogueiras, fumaça e efeitos de fogo (com transparência) | Recortada em `assets/env/` (brazier, torch_wall, torch_pillar, lantern, ground_fire_0..4) |
| `angel_sheet.jpg` | Arte do anjo (11 poses, fundo branco) | Recortada em `assets/angel/` com fundo removido; âncoras (peito) em `AngelSprite.ANCHORS`. Poses `hell_*` só com a habilidade A MORTE DO INFERNO; `folded` (asas fechadas) guardada sem uso |
| `world_props_sheet.png` | Objetos do **mundo aberto** (portal, arcos, muralhas, estandartes, ilhas flutuantes, chão de lava) | **Guardada para depois.** Atenção: o fundo xadrez está DESENHADO na imagem (não é transparência de verdade); antes de usar, precisa remover o xadrez ou pedir a folha com fundo transparente |

O fundo da arena (`assets/env/arena_bg.png`) veio da imagem enviada pelo usuário, em resolução original (1672x941).
