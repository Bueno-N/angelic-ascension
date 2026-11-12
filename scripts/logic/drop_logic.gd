class_name DropLogic
extends RefCounted

## Gemas dropadas por um inimigo comum/especial (chefes usam StageLogic.boss_gems).
static func roll_gems(def: Dictionary, rng: RandomNumberGenerator) -> int:
    if def.get("special", false):
        if rng.randf() < Balance.GEM_CHANCE_SPECIAL:
            return rng.randi_range(Balance.GEM_SPECIAL_MIN, Balance.GEM_SPECIAL_MAX)
        return 0
    if rng.randf() < Balance.GEM_CHANCE_COMMON:
        return 1
    return 0
