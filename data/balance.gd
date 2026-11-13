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

# --- Escala de inimigos por fase ---
const ENEMY_HP_GROWTH := 1.12
const ENEMY_DMG_GROWTH := 1.09
const ENEMY_GOLD_GROWTH := 1.10
# Ritmo: a fase é longa porque os inimigos chegam em fluxo (SPAWN_INTERVAL) e o nº simultâneo é limitado.
# Tempo mínimo de uma fase ~= ENEMY_COUNT * SPAWN_INTERVAL (fase 1: ~100 s). Alvo: ~32 fases/h no início.
const ENEMY_COUNT_BASE := 100
const ENEMY_COUNT_PER_STAGE := 0.5
const ENEMY_COUNT_MAX := 180
const BOSS_HP_MULT := 30.0
const BOSS_DMG_MULT := 3.0
const BOSS_GOLD_MULT := 25.0
const SPAWN_INTERVAL := 1.0
const ALIVE_BASE := 4                 # inimigos simultâneos na fase 1
const ALIVE_PER_STAGE := 0.5
const ALIVE_MAX := 30
const SPECIAL_SPAWN_CHANCE := 0.1

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
    "speed":        {"name": "Velocidade",         "base": 220.0, "per_level": 4.0,  "base_cost": 20.0, "cost_growth": 1.20},
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
