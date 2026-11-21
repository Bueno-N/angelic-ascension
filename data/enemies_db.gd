class_name EnemiesDB
extends RefCounted
## Mobs e chefes. Valores base (fase 1); a escala por fase vem de StageLogic/Balance.

const TYPES := [
    {"id": "demon_common", "sprite": "imp", "name": "Demônio Comum", "kind": "common", "special": false, "unlock_stage": 1,
     "hp": 20.0, "dmg": 5.0, "speed": 70.0, "gold": 2.0, "color": "#b32626", "radius": 14.0},
    {"id": "demon_warrior", "sprite": "warrior", "name": "Demônio Guerreiro", "kind": "warrior", "special": false, "unlock_stage": 3,
     "hp": 45.0, "dmg": 9.0, "speed": 60.0, "gold": 4.0, "color": "#8a1c1c", "radius": 17.0},
    {"id": "shadow_creature", "sprite": "shadow", "name": "Criatura Sombria", "kind": "shadow", "special": false, "unlock_stage": 6,
     "hp": 30.0, "dmg": 8.0, "speed": 95.0, "gold": 5.0, "color": "#3b2a5c", "radius": 13.0},
    {"id": "infernal_beast", "sprite": "hound", "name": "Fera Infernal", "kind": "beast", "special": false, "unlock_stage": 10,
     "hp": 90.0, "dmg": 14.0, "speed": 80.0, "gold": 8.0, "color": "#c2561a", "radius": 20.0},
    # Especiais: habilidade própria ainda NÃO implementada em runtime (campo "ability" reservado).
    {"id": "hex_caster", "sprite": "caster", "name": "Conjurador Profano", "kind": "special", "special": true, "unlock_stage": 5,
     "hp": 40.0, "dmg": 12.0, "speed": 55.0, "gold": 15.0, "color": "#7a2fb0", "radius": 16.0, "ability": "fire_bolt"},
    {"id": "soul_leech", "sprite": "leech", "name": "Sanguessuga de Almas", "kind": "special", "special": true, "unlock_stage": 12,
     "hp": 70.0, "dmg": 15.0, "speed": 75.0, "gold": 25.0, "color": "#2fb08a", "radius": 16.0, "ability": "life_steal"},
]

const SPRITE_SCALE := 2.0   # os sprites são pixel art: escala inteira mantém os pixels nítidos
const BOSS_BASE := {"hp": 20.0, "dmg": 5.0, "speed": 55.0, "gold": 2.0, "radius": 42.0}

# Cada chefe tem exatamente 2 habilidades, e NENHUMA é repetida entre chefes (cada um tem as suas).
const BOSSES := [
    {"id": "baal", "sprite": "boss_baal", "name": "Baal, o Devorador", "color": "#7a0f0f", "abilities": ["area_slam", "charge"]},
    {"id": "mordath", "sprite": "boss_mordath", "name": "Mordath, Senhor das Sombras", "color": "#2a1a4a", "abilities": ["summon_demons", "hellfire_projectiles"],
     "basic": "ranged_orb"},   # golpe básico À DISTÂNCIA (1 bola de fogo, mesma arte dos projéteis infernais)
    {"id": "ignarr", "sprite": "boss_ignarr", "name": "Ignarr, Fera Infernal", "color": "#a8410f", "abilities": ["meteor_rain", "flame_breath"]},
    {"id": "azazel", "sprite": "boss_azazel", "name": "Azazel, Arauto do Abismo", "color": "#4a0f3a", "abilities": ["shadow_step", "soul_orbs"]},
]

# LUCIFER: chefe único semanal, FORA da lista BOSSES (que tem 2 habilidades por chefe). Números em Balance.WEEKLY_*.
const LUCIFER := {"id": "lucifer", "sprite": "boss_lucifer", "name": "Lucifer, o Caído", "color": "#0c0412",
    "abilities": ["summon_boss", "hell_nova", "abyss_beam", "inferno_storm", "soul_harvest"]}   # summon_boss primeiro: tem prioridade e sai a cada ~20 s

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
    # --- Ignarr (chefe 3): fogo ---
    "meteor_rain": {"name": "Chuva de meteoros", "cooldown": 11.0, "telegraph": 1.4, "min_range": 0.0, "max_range": 99999.0,
        "count": 5, "radius": 75.0, "scatter": 230.0, "dmg_mult": 1.6},
    "flame_breath": {"name": "Sopro flamejante", "cooldown": 6.0, "telegraph": 0.9, "min_range": 0.0, "max_range": 360.0,
        "range": 380.0, "half_angle_deg": 35.0, "dmg_mult": 1.7},
    # --- Azazel (chefe 4): abismo ---
    "shadow_step": {"name": "Passo sombrio", "cooldown": 10.0, "telegraph": 1.0, "min_range": 200.0, "max_range": 99999.0,
        "land_offset": 100.0, "radius": 130.0, "dmg_mult": 1.6},
    "soul_orbs": {"name": "Orbes de almas", "cooldown": 9.0, "telegraph": 0.9, "min_range": 0.0, "max_range": 900.0,
        "count": 4, "speed": 170.0, "homing": 1.4, "life": 5.0, "dmg_mult": 0.9, "hit_radius": 16.0},
    # --- Lucifer (chefe semanal): as 4 mais fortes + invocação de chefe a cada 20 s ---
    "hell_nova": {"name": "Nova infernal", "cooldown": 9.0, "telegraph": 1.3, "min_range": 0.0, "max_range": 360.0,
        "inner": 110.0, "radius": 340.0, "dmg_mult": 2.0},
    "abyss_beam": {"name": "Raio do abismo", "cooldown": 8.0, "telegraph": 1.1, "min_range": 0.0, "max_range": 900.0,
        "length": 1100.0, "width": 70.0, "dmg_mult": 2.4},
    "inferno_storm": {"name": "Tempestade infernal", "cooldown": 12.0, "telegraph": 1.5, "min_range": 0.0, "max_range": 99999.0,
        "count": 9, "radius": 80.0, "scatter": 360.0, "dmg_mult": 2.0},
    "soul_harvest": {"name": "Colheita de almas", "cooldown": 10.0, "telegraph": 1.0, "min_range": 0.0, "max_range": 99999.0,
        "count": 12, "speed": 200.0, "homing": 1.8, "life": 6.0, "dmg_mult": 1.0, "hit_radius": 16.0},
    "summon_boss": {"name": "Invocar chefe", "cooldown": 20.0, "telegraph": 1.0, "min_range": 0.0, "max_range": 99999.0,
        "count": 1},
    "fire_bolt": {"name": "Bola de fogo", "cooldown": 3.5, "telegraph": 0.4, "min_range": 0.0, "max_range": 420.0,
        "speed": 300.0, "dmg_mult": 1.0, "hit_radius": 12.0},
    "life_steal": {"name": "Drenar vida", "cooldown": 4.0, "telegraph": 0.5, "min_range": 0.0, "max_range": 200.0,
        "dmg_mult": 0.8, "heal_pct": 0.5},
}

# Golpe básico à distância de alguns chefes (no lugar do corpo a corpo): mantém `hold` de distância e,
# a cada `cooldown` s com o anjo a até `range`, dispara 1 projétil. dmg_mult multiplica o dano do chefe.
const BASIC_ATTACKS := {
    "ranged_orb": {"range": 420.0, "hold": 300.0, "cooldown": 1.3, "speed": 280.0, "dmg_mult": 1.0, "hit_radius": 14.0},
}

# Mini-chefes: versão "campeã" (maior, mais forte) de um demônio comum, com 1 habilidade. Ciclam a cada 10 fases.
const MINIS := [
    {"id": "mini_warrior", "name": "Capitão Infernal", "type": "demon_warrior", "abilities": ["area_slam"]},
    {"id": "mini_hound", "name": "Cérbero das Cinzas", "type": "infernal_beast", "abilities": ["charge"]},
    {"id": "mini_caster", "name": "Bruxo Profano", "type": "hex_caster", "abilities": ["hellfire_projectiles"]},
]

static func type_by_id(id: String) -> Dictionary:
    for t in TYPES:
        if t["id"] == id:
            return t
    return {}

static func mini_for(stage: int) -> Dictionary:
    var idx: int = floori(float(stage - Balance.MINI_OFFSET) / float(Balance.BOSS_EVERY))
    return MINIS[posmod(idx, MINIS.size())]

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
    if stage >= Balance.MAX_STAGE:
        return LUCIFER     # o último chefe do jogo (fase 300) é o Lucifer
    var idx: int = maxi(1, floori(float(stage) / float(Balance.BOSS_EVERY)))
    return BOSSES[(idx - 1) % BOSSES.size()]
