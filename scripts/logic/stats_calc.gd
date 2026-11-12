class_name StatsCalc
extends RefCounted
## Fonte única dos atributos finais:
##   final = (base + nivel * por_nivel) * (1 + bônus_asas + bônus_equipamento[atributo])
## Os bônus percentuais são ADITIVOS entre si e multiplicam o valor base+gold (nunca em cascata).

static func upgrade_value(attr: String, level: int) -> float:
    var d: Dictionary = Balance.ATTRIBUTES[attr]
    return float(d["base"]) + float(d["per_level"]) * float(level)

static func upgrade_cost(attr: String, level: int) -> int:
    var d: Dictionary = Balance.ATTRIBUTES[attr]
    return int(ceil(float(d["base_cost"]) * pow(float(d["cost_growth"]), float(level))))

static func compute(state: Dictionary) -> Dictionary:
    var wings: float = WingsDB.bonus_for_level(int(state.get("wings_level", 0)))
    var eq: Dictionary = EquipmentDB.bonuses_for(state.get("equipped", {}))
    var ups: Dictionary = state.get("upgrades", {})
    var out := {}
    for attr in Balance.ATTRIBUTE_ORDER:
        var lvl: int = int(ups.get(attr, 0))
        var pct: float = wings + float(eq.get(attr, 0.0))
        out[attr] = upgrade_value(attr, lvl) * (1.0 + pct)
    out["skill_power_mult"] = 1.0 + WingsDB.glow_bonus(int(state.get("glow_tier", 0)))
    return out

static func regen_amount(max_hp: float, delta: float) -> float:
    return max_hp * Balance.HP_REGEN_PCT_PER_SEC * delta

static func stage_clear_heal(max_hp: float) -> float:
    return max_hp * Balance.STAGE_CLEAR_HEAL_PCT

static func damage_after_armor(raw: float, armor: float) -> float:
    return raw * Balance.ARMOR_K / (Balance.ARMOR_K + maxf(0.0, armor))
