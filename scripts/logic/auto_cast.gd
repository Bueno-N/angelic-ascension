class_name AutoCast
extends RefCounted
## Decide quando uma habilidade equipada é lançada automaticamente.
## ctx: {"total": inimigos vivos, "close": inimigos a <=150px, "boss": bool, "hp_ratio": 0..1}

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
