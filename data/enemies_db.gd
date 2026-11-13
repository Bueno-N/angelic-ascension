class_name EnemiesDB
extends RefCounted
## Mobs e chefes. Valores base (fase 1); a escala por fase vem de StageLogic/Balance.

const TYPES := [
    {"id": "demon_common", "name": "Demônio Comum", "kind": "common", "special": false, "unlock_stage": 1,
     "hp": 20.0, "dmg": 5.0, "speed": 70.0, "gold": 2.0, "color": "#b32626", "radius": 14.0},
    {"id": "demon_warrior", "name": "Demônio Guerreiro", "kind": "warrior", "special": false, "unlock_stage": 3,
     "hp": 45.0, "dmg": 9.0, "speed": 60.0, "gold": 4.0, "color": "#8a1c1c", "radius": 17.0},
    {"id": "shadow_creature", "name": "Criatura Sombria", "kind": "shadow", "special": false, "unlock_stage": 6,
     "hp": 30.0, "dmg": 8.0, "speed": 95.0, "gold": 5.0, "color": "#3b2a5c", "radius": 13.0},
    {"id": "infernal_beast", "name": "Fera Infernal", "kind": "beast", "special": false, "unlock_stage": 10,
     "hp": 90.0, "dmg": 14.0, "speed": 80.0, "gold": 8.0, "color": "#c2561a", "radius": 20.0},
    # Especiais: habilidade própria ainda NÃO implementada em runtime (campo "ability" reservado).
    {"id": "hex_caster", "name": "Conjurador Profano", "kind": "special", "special": true, "unlock_stage": 5,
     "hp": 40.0, "dmg": 12.0, "speed": 55.0, "gold": 15.0, "color": "#7a2fb0", "radius": 16.0, "ability": "fire_bolt"},
    {"id": "soul_leech", "name": "Sanguessuga de Almas", "kind": "special", "special": true, "unlock_stage": 12,
     "hp": 70.0, "dmg": 15.0, "speed": 75.0, "gold": 25.0, "color": "#2fb08a", "radius": 16.0, "ability": "life_steal"},
]

const BOSS_BASE := {"hp": 20.0, "dmg": 5.0, "speed": 55.0, "gold": 2.0, "radius": 42.0}

# Cada chefe tem exatamente 2 habilidades (implementação em runtime: etapa futura).
const BOSSES := [
    {"id": "baal", "name": "Baal, o Devorador", "color": "#7a0f0f", "abilities": ["area_slam", "charge"]},
    {"id": "mordath", "name": "Mordath, Senhor das Sombras", "color": "#2a1a4a", "abilities": ["summon_demons", "hellfire_projectiles"]},
    {"id": "ignarr", "name": "Ignarr, Fera Infernal", "color": "#a8410f", "abilities": ["charge", "area_slam"]},
    {"id": "azazel", "name": "Azazel, Arauto do Abismo", "color": "#4a0f3a", "abilities": ["hellfire_projectiles", "summon_demons"]},
]

# Habilidades de chefes e inimigos especiais (todos os números aqui).
# telegraph = segundos de AVISO VISUAL antes do golpe; dmg_mult multiplica o dano do inimigo (já escalado pela fase).
# min_range/max_range = distância ao anjo em que a habilidade pode começar.
const ABILITY_INITIAL_FRACTION := 0.5   # recarga inicial = 50% da recarga cheia
const MAX_SUMMONS_ALIVE := 8
const ABILITIES := {
    "area_slam": {"name": "Pancada em área", "cooldown": 7.0, "telegraph": 1.0, "min_range": 0.0, "max_range": 260.0,
        "radius": 150.0, "dmg_mult": 1.5},
    "charge": {"name": "Investida", "cooldown": 9.0, "telegraph": 1.0, "min_range": 140.0, "max_range": 700.0,
        "speed": 700.0, "duration": 0.6, "width": 40.0, "dmg_mult": 1.3},
    "summon_demons": {"name": "Invocação de demônios", "cooldown": 14.0, "telegraph": 0.8, "min_range": 0.0, "max_range": 99999.0,
        "count": 3},
    "hellfire_projectiles": {"name": "Projéteis infernais", "cooldown": 8.0, "telegraph": 0.8, "min_range": 0.0, "max_range": 800.0,
        "count": 5, "speed": 260.0, "spread_deg": 60.0, "dmg_mult": 0.6, "hit_radius": 14.0},
    "fire_bolt": {"name": "Bola de fogo", "cooldown": 3.5, "telegraph": 0.4, "min_range": 0.0, "max_range": 420.0,
        "speed": 300.0, "dmg_mult": 1.0, "hit_radius": 12.0},
    "life_steal": {"name": "Drenar vida", "cooldown": 4.0, "telegraph": 0.5, "min_range": 0.0, "max_range": 200.0,
        "dmg_mult": 0.8, "heal_pct": 0.5},
}

## Sorteia só tipos NÃO especiais (usado por invocações).
static func pick_normal(stage: int, rng: RandomNumberGenerator) -> Dictionary:
    var normals: Array = []
    for t in available_types(stage):
        if not t["special"]:
            normals.append(t)
    return normals[rng.randi_range(0, normals.size() - 1)]

static func available_types(stage: int) -> Array:
    var out: Array = []
    for t in TYPES:
        if int(t["unlock_stage"]) <= stage:
            out.append(t)
    return out

static func pick_type(stage: int, rng: RandomNumberGenerator) -> Dictionary:
    var avail := available_types(stage)
    var specials: Array = []
    var normals: Array = []
    for t in avail:
        if t["special"]:
            specials.append(t)
        else:
            normals.append(t)
    if not specials.is_empty() and rng.randf() < Balance.SPECIAL_SPAWN_CHANCE:
        return specials[rng.randi_range(0, specials.size() - 1)]
    return normals[rng.randi_range(0, normals.size() - 1)]

static func boss_for(stage: int) -> Dictionary:
    var idx: int = maxi(1, floori(float(stage) / float(Balance.BOSS_EVERY)))
    return BOSSES[(idx - 1) % BOSSES.size()]
