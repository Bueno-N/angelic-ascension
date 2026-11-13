class_name SkillsDB
extends RefCounted
## As 10 habilidades. Todos os números (dano, duração, cura, raios, contagens) ficam aqui.

const MAX_EQUIPPED := 3
const DEFAULT_COOLDOWN := 8.0
const ULTIMATE_COOLDOWN := 60.0
const ABSORB_CAP := 0.9        # o escudo nunca passa de 90% (o brilho escala, mas não torna invulnerável)
const EQUIP_DELAY := 2.0       # recarga inicial de uma habilidade recém-equipada (evita trocar em combate para burlar recarga)

const ABBR := {
    "celestial_lance": "LC", "holy_shield": "ES", "rain_of_light": "CL", "swords_of_paradise": "EP",
    "divine_judgment": "JD", "wings_of_redemption": "AR", "army_of_archangels": "EA",
    "celestial_fury": "FC", "holy_apocalypse": "AS", "death_of_hell": "MI",
}

# damage_pct: multiplicador do ataque atual (1.5 = 150%).
const SKILLS := [
    {"id": "celestial_lance", "name": "Lança Celestial", "rarity": "Comum", "price": 100,
     "damage_pct": 1.5, "duration": 0.0, "cooldown": 8.0, "effects": {},
     "desc": "Lança de luz contra o inimigo mais próximo."},
    {"id": "holy_shield", "name": "Escudo Sagrado", "rarity": "Incomum", "price": 500,
     "damage_pct": 2.5, "duration": 3.0, "cooldown": 8.0, "effects": {"damage_absorb": 0.40, "radius": 170.0},
     "desc": "Explosão ao ativar; absorve 40% do dano por 3s."},
    {"id": "rain_of_light", "name": "Chuva de Luz", "rarity": "Rara", "price": 2000,
     "damage_pct": 4.0, "duration": 0.0, "cooldown": 8.0,
     "effects": {"area": true, "projectiles": 8, "radius": 80.0, "spread_time": 0.8},
     "desc": "Projéteis celestiais caem sobre uma área (400% por projétil)."},
    {"id": "swords_of_paradise", "name": "Espadas do Paraíso", "rarity": "Épica", "price": 7500,
     "damage_pct": 6.0, "duration": 4.0, "cooldown": 8.0,
     "effects": {"orbiting": true, "swords": 3, "orbit_radius": 90.0, "hit_radius": 40.0, "tick": 0.5},
     "desc": "Espadas giram ao redor do anjo por 4s (600% por acerto)."},
    {"id": "divine_judgment", "name": "Julgamento Divino", "rarity": "Épica", "price": 20000,
     "damage_pct": 10.0, "duration": 0.0, "cooldown": 8.0, "effects": {"boss_bonus": 0.5},
     "desc": "Raio sobre o inimigo mais forte; +50% de dano em chefes (valor sugerido, ajustável)."},
    {"id": "wings_of_redemption", "name": "Asas da Redenção", "rarity": "Lendária", "price": 50000,
     "damage_pct": 15.0, "duration": 0.0, "cooldown": 8.0,
     "effects": {"heal_pct": 0.15, "area": true, "radius": 280.0},
     "desc": "Onda de energia em volta; cura 15% da vida máxima."},
    {"id": "army_of_archangels", "name": "Exército dos Arcanjos", "rarity": "Lendária", "price": 120000,
     "damage_pct": 20.0, "duration": 5.0, "cooldown": 8.0, "effects": {"summons": 3, "ally_tick": 2.0},
     "desc": "3 guerreiros celestiais lutam por 5s (2000% por golpe de cada um)."},
    {"id": "celestial_fury", "name": "Fúria Celestial", "rarity": "Mítica", "price": 300000,
     "damage_pct": 30.0, "duration": 5.0, "cooldown": 8.0,
     "effects": {"damage_mult": 1.0, "attack_speed_mult": 0.5, "speed_mult": 0.3, "radius": 240.0},
     "desc": "Explosão inicial; +100% dano, +50% vel. ataque, +30% vel. mov. por 5s."},
    {"id": "holy_apocalypse", "name": "Apocalipse Sagrado", "rarity": "Divina", "price": 750000,
     "damage_pct": 50.0, "duration": 0.0, "cooldown": 8.0,
     "effects": {"area": true, "no_execute": true, "boss_max_hp_pct_cap": 0.25},
     "desc": "Explosão em todo o campo; chefes sofrem no máx. 25% da vida por uso (sem execução)."},
    {"id": "death_of_hell", "name": "A MORTE DO INFERNO", "rarity": "Suprema", "price": 2000000,
     "damage_pct": 150.0, "duration": 10.0, "cooldown": 60.0,
     "effects": {"area": true, "heal_pct": 0.50, "all_stats_mult": 1.0},
     "desc": "Forma celestial definitiva: dano massivo, cura 50%, +100% em atributos de combate por 10s."},
]

static func ids() -> Array:
    var out: Array = []
    for s in SKILLS:
        out.append(s["id"])
    return out

static func get_skill(id: String) -> Dictionary:
    for s in SKILLS:
        if s["id"] == id:
            return s
    return {}

static func abbr(id: String) -> String:
    return str(ABBR.get(id, "?"))

## Dano base da habilidade. glow_mult = 1 + bônus do brilho das asas.
static func damage(id: String, attack: float, glow_mult: float, vs_boss: bool = false) -> float:
    var s := get_skill(id)
    if s.is_empty():
        return 0.0
    var d: float = attack * float(s["damage_pct"]) * glow_mult
    if vs_boss and s["effects"].has("boss_bonus"):
        d *= 1.0 + float(s["effects"]["boss_bonus"])
    return d

## Garante que habilidades "sem execução" nunca tirem mais que X% da vida máxima do chefe por uso.
static func boss_capped_damage(id: String, dmg: float, boss_max_hp: float) -> float:
    var s := get_skill(id)
    if s.is_empty() or not s["effects"].has("boss_max_hp_pct_cap"):
        return dmg
    return minf(dmg, boss_max_hp * float(s["effects"]["boss_max_hp_pct_cap"]))

## O brilho das asas também escala cura e proteção (limitada por ABSORB_CAP).
static func scaled_heal_pct(id: String, glow_mult: float) -> float:
    return float(get_skill(id).get("effects", {}).get("heal_pct", 0.0)) * glow_mult

static func scaled_absorb(id: String, glow_mult: float) -> float:
    var a: float = float(get_skill(id).get("effects", {}).get("damage_absorb", 0.0)) * glow_mult
    return minf(ABSORB_CAP, a)

## Modificadores de buff por atributo ("all" = todos os atributos de combate, exceto vida máxima).
static func buff_mods(id: String, glow_mult: float) -> Dictionary:
    var e: Dictionary = get_skill(id).get("effects", {})
    var m := {}
    if e.has("damage_mult"):
        m["attack"] = float(e["damage_mult"]) * glow_mult
    if e.has("attack_speed_mult"):
        m["attack_speed"] = float(e["attack_speed_mult"]) * glow_mult
    if e.has("speed_mult"):
        m["speed"] = float(e["speed_mult"]) * glow_mult
    if e.has("all_stats_mult"):
        m["all"] = float(e["all_stats_mult"]) * glow_mult
    return m
