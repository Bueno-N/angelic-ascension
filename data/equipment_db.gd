class_name EquipmentDB
extends RefCounted
## Equipamentos (compra com GEMAS, bônus em %). Os PREÇOS são PLACEHOLDERS: o design não os definiu.

const CATEGORIES := ["sword", "armor", "boots", "gloves"]
const TIER_COUNT := 6
const TIER_RARITY := ["Comum", "Incomum", "Rara", "Épica", "Lendária", "Mítica"]
const TIER_PRICES := [25, 100, 400, 1500, 6000, 25000]   # PLACEHOLDER

const ITEMS := {
    "sword": {"label": "Espadas", "stats": ["attack"],
        "names": ["Espada Celestial", "Espada Sagrada", "Lâmina da Luz", "Excalibur Divina", "Espada do Arcanjo", "Lâmina do Criador"],
        "bonus": [0.05, 0.10, 0.20, 0.35, 0.50, 0.75]},
    "armor": {"label": "Armaduras", "stats": ["hp", "armor"],
        "names": ["Vestimenta Celestial", "Armadura Sagrada", "Armadura do Guardião", "Armadura do Arcanjo", "Armadura Divina", "Armadura do Éden"],
        "bonus": [0.05, 0.10, 0.20, 0.35, 0.50, 0.75]},
    "boots": {"label": "Botas", "stats": ["speed"],
        "names": ["Botas Celestiais", "Botas da Luz", "Botas do Guardião", "Botas do Arcanjo", "Botas Divinas", "Botas do Éden"],
        "bonus": [0.05, 0.10, 0.20, 0.35, 0.50, 0.75]},
    "gloves": {"label": "Luvas", "stats": ["attack_speed"],
        "names": ["Luvas Celestiais", "Luvas Sagradas", "Luvas do Guardião", "Luvas do Arcanjo", "Luvas Divinas", "Luvas do Éden"],
        "bonus": [0.05, 0.10, 0.20, 0.35, 0.50, 0.75]},
}

static func get_item(cat: String, tier: int) -> Dictionary:
    if not ITEMS.has(cat) or tier < 1 or tier > TIER_COUNT:
        return {}
    var d: Dictionary = ITEMS[cat]
    return {
        "id": "%s_%d" % [cat, tier], "category": cat, "tier": tier,
        "name": d["names"][tier - 1], "rarity": TIER_RARITY[tier - 1],
        "price": TIER_PRICES[tier - 1], "bonus": d["bonus"][tier - 1], "stats": d["stats"],
    }

## equipped: {categoria: tier (0 = nada)} -> {atributo: bônus %}
static func bonuses_for(equipped: Dictionary) -> Dictionary:
    var out := {}
    for cat in CATEGORIES:
        var tier: int = int(equipped.get(cat, 0))
        if tier < 1 or tier > TIER_COUNT:
            continue
        var item := get_item(cat, tier)
        for stat in item["stats"]:
            out[stat] = float(out.get(stat, 0.0)) + float(item["bonus"])
    return out
