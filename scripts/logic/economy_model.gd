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

## Fases por hora no ritmo do modelo ao chegar na fase `stage` (derivada de fase(h) = PACE * h^EXP).
static func stages_per_hour_at(stage: int) -> float:
    var h: float = maxf(hours_at_stage(stage), 0.001)
    return Balance.MODEL_STAGES_PER_HOUR * Balance.MODEL_PACE_EXPONENT * pow(h, Balance.MODEL_PACE_EXPONENT - 1.0)

## Devolve {"stage": int, "hours": float}. Como o jogo para em MAX_STAGE (300), depois dela o jogador fica repetindo
## a última fase no mesmo ritmo: nesse caso o resultado tem "farming": true. Devolve {} só se a fase não rende gemas.
static func time_to_accumulate(total_gems: float, max_stage: int = Balance.MAX_STAGE) -> Dictionary:
    var acc := 0.0
    for s in range(1, max_stage + 1):
        acc += expected_gems_in_stage(s)
        if acc >= total_gems:
            return {"stage": s, "hours": hours_at_stage(s)}
    var rate: float = expected_gems_in_stage(max_stage) * stages_per_hour_at(max_stage)
    if rate <= 0.0:
        return {}
    return {"stage": max_stage, "hours": hours_at_stage(max_stage) + (total_gems - acc) / rate, "farming": true}
