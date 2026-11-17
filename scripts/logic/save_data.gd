class_name SaveData
extends RefCounted
## Estado persistente + serialização + validação/migração.

const VERSION := 1

## Conversores SEGUROS para dados vindos de disco (bool("x") / int({}) abortam o script em GDScript).
static func as_int(v, default: int = 0) -> int:
    if v is int:
        return v
    if v is float:
        return int(v)
    if v is String and v.is_valid_int():
        return v.to_int()
    return default

static func as_bool(v, default: bool = false) -> bool:
    if v is bool:
        return v
    if v is int or v is float:
        return v != 0
    return default

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
        "settings": {"auto_slots": [true, true, true], "speed_2x": false, "low_fx": false, "volume": OptionsLogic.DEFAULT_VOLUME,
        "music_on": true, "music_vol": OptionsLogic.DEFAULT_MUSIC_VOL, "sfx_vol": OptionsLogic.DEFAULT_SFX_VOL},
        "profile": {"name": ProfileLogic.DEFAULT_NAME, "avatar": 0},
        "weekly": WeeklyBoss.default_weekly(),
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
            s[key] = maxi(0, as_int(raw[key]))
    if raw.has("stage") and (raw["stage"] is int or raw["stage"] is float):
        s["stage"] = clampi(as_int(raw["stage"], 1), 1, Balance.MAX_STAGE)
    s["max_stage"] = maxi(int(s["stage"]), 1)
    if raw.has("max_stage") and (raw["max_stage"] is int or raw["max_stage"] is float):
        s["max_stage"] = clampi(maxi(int(s["stage"]), as_int(raw["max_stage"], 1)), 1, Balance.MAX_STAGE)

    if raw.get("upgrades") is Dictionary:
        for a in Balance.ATTRIBUTE_ORDER:
            if raw["upgrades"].has(a):
                s["upgrades"][a] = clampi(as_int(raw["upgrades"][a]), 0, StatsCalc.max_level(a))

    if raw.get("owned_equipment") is Dictionary:
        for c in EquipmentDB.CATEGORIES:
            var arr = raw["owned_equipment"].get(c, [])
            if arr is Array:
                for t in arr:
                    var ti: int = as_int(t)
                    if ti >= 1 and ti <= EquipmentDB.TIER_COUNT and not s["owned_equipment"][c].has(ti):
                        s["owned_equipment"][c].append(ti)
    if raw.get("equipped") is Dictionary:
        for c in EquipmentDB.CATEGORIES:
            var t: int = as_int(raw["equipped"].get(c, 0))
            if t == 0 or s["owned_equipment"][c].has(t):
                s["equipped"][c] = t

    s["wings_level"] = clampi(as_int(raw.get("wings_level", 0)), 0, WingsDB.MAX_LEVEL)
    s["glow_tier"] = clampi(as_int(raw.get("glow_tier", 0)), 0, WingsDB.GLOW.size())

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

    s["weekly"] = WeeklyBoss.sanitize(raw.get("weekly"))

    if raw.get("profile") is Dictionary:
        var rp: Dictionary = raw["profile"]
        s["profile"]["name"] = ProfileLogic.clean_name(rp.get("name", ProfileLogic.DEFAULT_NAME))
        s["profile"]["avatar"] = clampi(as_int(rp.get("avatar", 0)), 0, ProfileLogic.AVATAR_COUNT - 1)

    if raw.get("settings") is Dictionary:
        var rs: Dictionary = raw["settings"]
        s["settings"]["speed_2x"] = as_bool(rs.get("speed_2x", false), false)
        s["settings"]["low_fx"] = as_bool(rs.get("low_fx", false), false)
        s["settings"]["volume"] = clampi(as_int(rs.get("volume", OptionsLogic.DEFAULT_VOLUME), OptionsLogic.DEFAULT_VOLUME), 0, 100)
        s["settings"]["music_on"] = as_bool(rs.get("music_on", true), true)
        s["settings"]["music_vol"] = clampi(as_int(rs.get("music_vol", OptionsLogic.DEFAULT_MUSIC_VOL), OptionsLogic.DEFAULT_MUSIC_VOL), 0, 100)
        s["settings"]["sfx_vol"] = clampi(as_int(rs.get("sfx_vol", OptionsLogic.DEFAULT_SFX_VOL), OptionsLogic.DEFAULT_SFX_VOL), 0, 100)
        if rs.get("auto_slots") is Array:
            var src: Array = rs["auto_slots"]
            var arr2: Array = []
            for k in range(SkillsDB.MAX_EQUIPPED):
                arr2.append(as_bool(src[k], true) if k < src.size() else true)
            s["settings"]["auto_slots"] = arr2
        elif rs.has("auto_skills"):
            var v: bool = as_bool(rs["auto_skills"], true)
            s["settings"]["auto_slots"] = [v, v, v]
    return s
