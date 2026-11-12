class_name Shop
extends RefCounted
## Todas as compras/equipar. Opera sobre o dicionário de estado (testável sem cenas).
## GOLD: somente atributos. GEMAS: equipamentos, brilho, habilidades. FRAGMENTOS: asas.

static func upgrade_level(state: Dictionary, attr: String) -> int:
    return int(state["upgrades"].get(attr, 0))

static func buy_upgrade(state: Dictionary, attr: String) -> bool:
    if not Balance.ATTRIBUTES.has(attr):
        return false
    var lvl: int = upgrade_level(state, attr)
    var cost: int = StatsCalc.upgrade_cost(attr, lvl)
    if int(state["gold"]) < cost:
        return false
    state["gold"] = int(state["gold"]) - cost
    state["upgrades"][attr] = lvl + 1
    return true

static func buy_equipment(state: Dictionary, cat: String, tier: int) -> bool:
    var item := EquipmentDB.get_item(cat, tier)
    if item.is_empty() or state["owned_equipment"][cat].has(tier):
        return false
    var price: int = int(item["price"])
    if int(state["gems"]) < price:
        return false
    state["gems"] = int(state["gems"]) - price
    state["owned_equipment"][cat].append(tier)
    if tier > int(state["equipped"][cat]):
        state["equipped"][cat] = tier     # auto-equipa se for melhor
    return true

## tier 0 = desequipar. Só equipa o que foi comprado. Um item por categoria.
static func equip_equipment(state: Dictionary, cat: String, tier: int) -> bool:
    if not state["equipped"].has(cat):
        return false
    if tier != 0 and not state["owned_equipment"][cat].has(tier):
        return false
    state["equipped"][cat] = tier
    return true

static func evolve_wings(state: Dictionary) -> bool:
    var lvl: int = int(state["wings_level"])
    if lvl >= WingsDB.MAX_LEVEL:
        return false
    var cost: int = WingsDB.shards_for_next(lvl)
    if int(state["shards"]) < cost:
        return false
    state["shards"] = int(state["shards"]) - cost
    state["wings_level"] = lvl + 1
    return true

static func buy_glow(state: Dictionary, tier: int) -> bool:
    if tier < 1 or tier > WingsDB.GLOW.size() or tier <= int(state["glow_tier"]):
        return false
    var price: int = int(WingsDB.GLOW[tier - 1]["price"])
    if int(state["gems"]) < price:
        return false
    state["gems"] = int(state["gems"]) - price
    state["glow_tier"] = tier
    return true

static func buy_skill(state: Dictionary, id: String) -> bool:
    var s := SkillsDB.get_skill(id)
    if s.is_empty() or state["skills_owned"].has(id):
        return false
    var price: int = int(s["price"])
    if int(state["gems"]) < price:
        return false
    state["gems"] = int(state["gems"]) - price
    state["skills_owned"].append(id)
    return true

static func equip_skill(state: Dictionary, id: String) -> bool:
    if not state["skills_owned"].has(id) or state["skills_equipped"].has(id):
        return false
    if state["skills_equipped"].size() >= SkillsDB.MAX_EQUIPPED:
        return false
    state["skills_equipped"].append(id)
    return true

static func unequip_skill(state: Dictionary, id: String) -> bool:
    if not state["skills_equipped"].has(id):
        return false
    state["skills_equipped"].erase(id)
    return true
