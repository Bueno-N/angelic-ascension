class_name SaveData
extends RefCounted
## Estado persistente + serialização + validação/migração.

const VERSION := 1

static func default_state() -> Dictionary:
    var ups := {}
    for a in Balance.ATTRIBUTE_ORDER:
        ups[a] = 0
    var owned := {}
    var equipped := {}
    for c in EquipmentDB.CATEGORIES:
        owned[c] = []
        equipped[c] = 0
    return {
        "version": VERSION, "gold": 0, "gems": 0, "shards": 0,
        "stage": 1, "max_stage": 1,
        "upgrades": ups, "owned_equipment": owned, "equipped": equipped,
        "wings_level": 0, "glow_tier": 0,
        "skills_owned": [], "skills_equipped": [],
        "settings": {"auto_skills": true},
    }

static func to_json(state: Dictionary) -> String:
    return JSON.stringify(state)

## Parse silencioso (JSON.parse_string imprime ERROR no log em entrada inválida).
static func parse_dict(text: String) -> Variant:
    var j := JSON.new()
    if j.parse(text) != OK:
        return null
    return j.data

## Nunca falha: JSON inválido/ausente devolve o estado padrão.
static func from_json(text: String) -> Dictionary:
    var parsed = parse_dict(text)
    if not (parsed is Dictionary):
        return default_state()
    return sanitize(parsed)

static func sanitize(raw: Dictionary) -> Dictionary:
    var s := default_state()
    for key in ["gold", "gems", "shards"]:
        if raw.has(key) and (raw[key] is int or raw[key] is float):
            s[key] = maxi(0, int(raw[key]))
    if raw.has("stage") and (raw["stage"] is int or raw["stage"] is float):
        s["stage"] = maxi(1, int(raw["stage"]))
    s["max_stage"] = maxi(int(s["stage"]), 1)
    if raw.has("max_stage") and (raw["max_stage"] is int or raw["max_stage"] is float):
        s["max_stage"] = maxi(int(s["stage"]), int(raw["max_stage"]))

    if raw.get("upgrades") is Dictionary:
        for a in Balance.ATTRIBUTE_ORDER:
            if raw["upgrades"].has(a):
                s["upgrades"][a] = maxi(0, int(raw["upgrades"][a]))

    if raw.get("owned_equipment") is Dictionary:
        for c in EquipmentDB.CATEGORIES:
            var arr = raw["owned_equipment"].get(c, [])
            if arr is Array:
                for t in arr:
                    var ti: int = int(t)
                    if ti >= 1 and ti <= EquipmentDB.TIER_COUNT and not s["owned_equipment"][c].has(ti):
                        s["owned_equipment"][c].append(ti)
    if raw.get("equipped") is Dictionary:
        for c in EquipmentDB.CATEGORIES:
            var t: int = int(raw["equipped"].get(c, 0))
            if t == 0 or s["owned_equipment"][c].has(t):
                s["equipped"][c] = t

    s["wings_level"] = clampi(int(raw.get("wings_level", 0)), 0, WingsDB.MAX_LEVEL)
    s["glow_tier"] = clampi(int(raw.get("glow_tier", 0)), 0, WingsDB.GLOW.size())

    var valid_ids := SkillsDB.ids()
    if raw.get("skills_owned") is Array:
        for id in raw["skills_owned"]:
            if valid_ids.has(id) and not s["skills_owned"].has(id):
                s["skills_owned"].append(id)
    if raw.get("skills_equipped") is Array:
        for id in raw["skills_equipped"]:
            if s["skills_owned"].has(id) and not s["skills_equipped"].has(id) \
                    and s["skills_equipped"].size() < SkillsDB.MAX_EQUIPPED:
                s["skills_equipped"].append(id)

    if raw.get("settings") is Dictionary:
        s["settings"]["auto_skills"] = bool(raw["settings"].get("auto_skills", true))
    return s
