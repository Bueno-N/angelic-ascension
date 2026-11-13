class_name AutoCast
extends RefCounted
## Decide quando uma habilidade equipada é lançada automaticamente.
## ctx: {"total": inimigos vivos, "close": inimigos a <=150px, "boss": bool, "hp_ratio": 0..1}

const RULE_TEXT := {
    "holy_shield": "Lança quando há inimigo colado em você.",
    "wings_of_redemption": "Lança com inimigo perto e vida abaixo de 80% (ou 3+ inimigos).",
    "rain_of_light": "Lança com 3+ inimigos ou chefe.",
    "swords_of_paradise": "Lança com 3+ inimigos ou chefe.",
    "army_of_archangels": "Lança com 3+ inimigos ou chefe.",
    "celestial_fury": "Lança com 3+ inimigos ou chefe.",
    "holy_apocalypse": "Lança com 3+ inimigos ou chefe.",
    "death_of_hell": "Lança com chefe, 8+ inimigos ou vida abaixo de 35%.",
}

static func rule_text(id: String) -> String:
    return str(RULE_TEXT.get(id, "Lança quando há algum inimigo em campo."))

## Slot (0..2) em modo automático? Slots ausentes contam como automático.
static func slot_auto(settings: Dictionary, i: int) -> bool:
    var a = settings.get("auto_slots", [true, true, true])
    if a is Array and i >= 0 and i < a.size():
        return bool(a[i])
    return true

static func auto_count(settings: Dictionary) -> int:
    var n := 0
    for i in range(SkillsDB.MAX_EQUIPPED):
        if slot_auto(settings, i):
            n += 1
    return n

static func should_cast(id: String, ctx: Dictionary) -> bool:
    var total: int = int(ctx.get("total", 0))
    var close: int = int(ctx.get("close", 0))
    var boss: bool = bool(ctx.get("boss", false))
    var hp_ratio: float = float(ctx.get("hp_ratio", 1.0))
    if total <= 0:
        return false
    match id:
        "holy_shield":
            return close >= 1
        "wings_of_redemption":
            return close >= 1 and (hp_ratio < 0.8 or total >= 3)
        "rain_of_light", "swords_of_paradise", "army_of_archangels", "celestial_fury", "holy_apocalypse":
            return total >= 3 or boss
        "death_of_hell":
            return boss or total >= 8 or hp_ratio < 0.35
        _:
            return true
