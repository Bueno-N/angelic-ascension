class_name EconomyModel
extends RefCounted
## PROJEÇÃO teórica (não é medição): quantas horas até acumular N gemas, dado o modelo de ritmo
## fase(h) = MODEL_STAGES_PER_HOUR * h^MODEL_PACE_EXPONENT. Serve para calibrar BOSS_GEM_GROWTH e preços.

static func hours_at_stage(stage: int) -> float:
    return pow(float(stage) / Balance.MODEL_STAGES_PER_HOUR, 1.0 / Balance.MODEL_PACE_EXPONENT)

static func expected_gems_in_stage(stage: int) -> float:
    var mobs: float = float(StageLogic.enemy_count(stage)) * (0.9 * Balance.GEM_CHANCE_COMMON + 0.1 * Balance.GEM_CHANCE_SPECIAL * 2.0)
    if StageLogic.is_boss_stage(stage):
        var r := StageLogic.boss_gem_range(stage)
        mobs += (float(r[0]) + float(r[1])) / 2.0
    return mobs

## Devolve {"stage": int, "hours": float} ou {} se não atingir dentro do limite.
static func time_to_accumulate(total_gems: float, max_stage: int = 20000) -> Dictionary:
    var acc := 0.0
    for s in range(1, max_stage + 1):
        acc += expected_gems_in_stage(s)
        if acc >= total_gems:
            return {"stage": s, "hours": hours_at_stage(s)}
    return {}
