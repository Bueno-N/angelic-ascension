class_name Balance
extends RefCounted
## FONTE ÚNICA DE BALANCEAMENTO. Altere valores aqui; nada é duplicado em outros arquivos.

# --- Drops de gemas (valores de referência do design) ---
const GEM_CHANCE_COMMON := 0.005      # 0,5% de 1 gema
const GEM_CHANCE_SPECIAL := 0.02      # 2% de 1..3 gemas
const GEM_SPECIAL_MIN := 1
const GEM_SPECIAL_MAX := 3

# --- Chefes (opção C: recompensa de gemas cresce com a fase) ---
const BOSS_EVERY := 10
const BOSS_GEM_MIN := 10              # no 1º chefe (fase 10)
const BOSS_GEM_MAX := 20
const BOSS_GEM_GROWTH := 1.10         # multiplicador por índice de chefe (PARÂMETRO A CALIBRAR)
const BOSS_SHARDS_BASE := 1           # fragmentos de asa por chefe
const BOSS_SHARDS_BONUS_EVERY := 10   # +1 fragmento a cada N chefes

# --- Andares (fases) e dificuldade: 300 andares; a cada 50 muda a dificuldade ---
# (vida/dano dos inimigos e ganhos multiplicados por degrau; valores são PRIMEIRO PALPITE, sem playtest)
const MAX_STAGE := 300
const TIER_SIZE := 50
const TIER_NAMES := ["Fácil", "Normal", "Difícil", "Pesadelo", "Infernal", "Abismal"]
const TIER_HP_MULT := [1.0, 1.5, 2.5, 4.0, 6.5, 10.0]
const TIER_DMG_MULT := [1.0, 1.15, 1.35, 1.6, 1.9, 2.2]
const TIER_REWARD_MULT := [1.0, 1.25, 1.6, 2.0, 2.5, 3.2]   # ouro dos inimigos e gemas de chefe

# --- Escala de inimigos por fase ---
# REBALANCEADO (rodada 19): crescimento POLINOMIAL (fase^expoente), não exponencial. O poder do anjo cresce ~linearmente com a fase
# (o ouro sobe 10%/fase e o custo do nível 15%), então vida/dano exponenciais viravam um muro já perto da fase 40.
# Vida do mob comum (base 20): fase 55 ~740, 100 ~1.200, 300 ~19.000 (com o degrau). PALPITE por modelo, sem playtest.
const ENEMY_HP_POWER := 0.8
const ENEMY_DMG_POWER := 0.7
const ENEMY_GOLD_GROWTH := 1.10
# Ritmo: a fase é longa porque os inimigos chegam em fluxo (SPAWN_INTERVAL) e o nº simultâneo é limitado.
# Mobs por fase: começa em 50 e sobe +5 a cada 5 fases (fases 1-5: 50, 6-10: 55, 11-15: 60...).
# A horda acelera dentro da fase (SPAWN_ACCEL_SECONDS), então o tempo real é menor que contagem x SPAWN_INTERVAL.
const ENEMY_COUNT_BASE := 50
const ENEMY_COUNT_STEP := 5           # mobs a mais a cada degrau
const ENEMY_COUNT_STEP_EVERY := 5     # tamanho do degrau, em fases
const ENEMY_COUNT_MAX := 180          # teto (atingido na fase 131); aumente aqui se quiser que o aumento continue
const BOSS_HP_MULT := 30.0
const BOSS_DMG_MULT := 3.0
const BOSS_GOLD_MULT := 25.0
const SPAWN_INTERVAL := 1.0
const ALIVE_BASE := 4                 # inimigos simultâneos na fase 1
const ALIVE_PER_STAGE := 0.5
const ALIVE_MAX := 30
const SPECIAL_SPAWN_CHANCE := 0.1

# --- Desempenho e bateria ---
const MAX_FPS := 60                  # evita gastar bateria em telas de 90/120 Hz
const AUTO_CHECK_INTERVAL := 0.2     # auto-cast avaliado 5x por segundo (não a cada frame)
const FX_CAP_NORMAL := 80            # máx. de efeitos/partículas simultâneos
const FX_CAP_LOW := 20               # idem no modo "Efeitos: Baixo"
const UI_REDRAW_INTERVAL := 0.05     # a barra de habilidades redesenha a 20 fps

# --- Ritmo DENTRO da fase: os mobs chegam cada vez mais rápido com o passar do tempo ---
const SPAWN_MIN_INTERVAL := 0.25      # intervalo mínimo entre mobs (s)
const SPAWN_ACCEL_SECONDS := 25.0     # o intervalo cai pela metade a cada ~25 s de fase
const ALIVE_EXTRA_EVERY := 15.0       # +1 inimigo simultâneo a cada 15 s de fase
const ALIVE_EXTRA_MAX := 10

# --- Mini-chefes (fases 5, 15, 25...): aparecem no FINAL da horda ---
const MINI_OFFSET := 5                # fase % BOSS_EVERY == 5
const MINI_SPAWN_ALIVE := 3           # surge quando restam no máx. 3 mobs vivos
const MINI_HP_FRAC := 0.4             # vida = 40% da do chefe da mesma fase
const MINI_DMG_FRAC := 0.8            # dano = 80% do dano do chefe
const MINI_GOLD_FRAC := 0.4           # ouro = 40% do ouro do chefe
const MINI_RADIUS_MULT := 1.6
const MINI_SCALE := 3.0               # escala do sprite (pixel art: inteiro)
const MINI_GEM_MIN := 1               # gemas garantidas do mini-chefe (sem fragmentos de asa)
const MINI_GEM_MAX := 2

# --- Boss semanal (LUCIFER) ---
# Liberado ao CONCLUIR a fase 50. Luta de tempo limitado; vida/dano partem do chefe da ÚLTIMA fase (valores são PALPITE, sem playtest).
const WEEKLY_UNLOCK_STAGE := 50       # precisa ter concluído esta fase (max_stage > 50)
const WEEKLY_MAX_ENTRIES := 4         # tentativas por semana (semana começa na segunda 00:00 UTC)
const WEEKLY_TIME_LIMIT := 120.0      # segundos
const WEEKLY_HP_MULT := 6.0           # x a vida do chefe da fase 300 (que já inclui o x1,3 do Lucifer): ~7,8x o chefe "comum" de lá
const WEEKLY_DMG_MULT := 1.6          # x o dano do chefe da fase 300 (já inclui o x1,3): ~2x
const WEEKLY_SUMMON_EVERY := 20.0     # Lucifer invoca 1 chefe a cada 20 s
const WEEKLY_SUMMON_STAGE := 290      # chefe invocado no semanal = chefe da fase 290 (vida e dano cheios)
const LUCIFER_STAGE_MULT := 1.3       # Lucifer como chefe da fase 300: vida e dano x1,3 sobre a fórmula normal de chefe
const LUCIFER_STAGE_SUMMON_FRAC := 0.5   # na fase 300 os chefes invocados têm 50% do chefe da fase 290
const WEEKLY_MAX_SUMMONS := 4         # chefes invocados vivos ao mesmo tempo
const WEEKLY_SPEED := 62.0
const WEEKLY_RADIUS := 56.0
const WEEKLY_SCALE := 3.0

# --- Modo acelerado (botão de velocidade no HUD) ---
const FAST_MODE_SCALE := 2.0

# --- Regeneração do anjo ---
const HP_REGEN_PCT_PER_SEC := 0.015   # % da vida máxima por segundo
const STAGE_CLEAR_HEAL_PCT := 0.30    # cura ao limpar uma fase

# --- Combate ---
const ARMOR_K := 100.0                # reduçao = K / (K + armadura)
const ATTACK_RANGE := 320.0
const AURA_RADIUS := 110.0
const AURA_TICK := 0.5

# --- Atributos comprados com GOLD (valor fixo por nível) ---
const ATTRIBUTE_ORDER := ["attack", "hp", "armor", "speed", "attack_speed", "aura"]
const ATTRIBUTES := {
    "attack":       {"name": "Ataque",             "base": 10.0,  "per_level": 2.0,  "base_cost": 10.0, "cost_growth": 1.15},
    "hp":           {"name": "Vida",               "base": 100.0, "per_level": 15.0, "base_cost": 10.0, "cost_growth": 1.15},
    "armor":        {"name": "Armadura",           "base": 0.0,   "per_level": 1.0,  "base_cost": 15.0, "cost_growth": 1.18},
    "speed":        {"name": "Velocidade",         "base": 220.0, "per_level": 4.0,  "base_cost": 20.0, "cost_growth": 1.20, "max_level": 50},   # só 50 melhorias
    "attack_speed": {"name": "Vel. de ataque",     "base": 1.0,   "per_level": 0.03, "base_cost": 25.0, "cost_growth": 1.20},
    "aura":         {"name": "Aura",               "base": 5.0,   "per_level": 1.5,  "base_cost": 12.0, "cost_growth": 1.15},
}

# --- Modo de teste (aba "Teste" no menu: dar ouro/gemas, pular fase, desbloquear tudo) ---
# Para o APK FINAL: coloque false. Mesmo com true, só funciona em builds de debug (OS.is_debug_build()).
const DEBUG_TOOLS := true

# --- Salvamento ---
const AUTOSAVE_SECONDS := 30.0

# --- Modelo de projeção de economia (APENAS ESTIMATIVA; calibrar com playtest real) ---
const MODEL_STAGES_PER_HOUR := 32.0   # fases/h na hora 1 (alvo: ~10% acima do modelo original de 30)
const MODEL_PACE_EXPONENT := 0.6      # desaceleração: fase(h) = PACE * h^EXP
const MODEL_HOURS_PER_DAY := 3.0
