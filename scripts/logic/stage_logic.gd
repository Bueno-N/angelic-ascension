class_name StageLogic
extends RefCounted
## Escala por fase, chefes e recompensas.

## "Próxima fase" a qualquer momento, mas só até uma fase JÁ alcançada (não dá para furar chefes não vencidos).
static func can_skip_to_next(stage: int, max_stage: int) -> bool:
    return stage < max_stage

static func is_mini_stage(stage: int) -> bool:
    return stage > 0 and stage % Balance.BOSS_EVERY == Balance.MINI_OFFSET

## Intervalo entre mobs: cai com o tempo de fase (a horda acelera).
static func spawn_interval(stage_time: float) -> float:
    return maxf(Balance.SPAWN_MIN_INTERVAL, Balance.SPAWN_INTERVAL / (1.0 + maxf(0.0, stage_time) / Balance.SPAWN_ACCEL_SECONDS))

static func extra_alive(stage_time: float) -> int:
    return mini(Balance.ALIVE_EXTRA_MAX, floori(maxf(0.0, stage_time) / Balance.ALIVE_EXTRA_EVERY))

static func total_alive_cap(stage: int, stage_time: float) -> int:
    return max_alive(stage) + extra_alive(stage_time)

## Próximo marco a partir desta fase (inclusive): {"kind": "boss"|"mini", "stage": N, "in": fases até lá}.
static func next_milestone(stage: int) -> Dictionary:
    for s in range(maxi(1, stage), maxi(1, stage) + 11):
        if is_boss_stage(s):
            return {"kind": "boss", "stage": s, "in": s - stage}
        if is_mini_stage(s):
            return {"kind": "mini", "stage": s, "in": s - stage}
    return {}

## O mini-chefe é sempre mais fraco que o chefe da MESMA fase (fração dele).
static func mini_hp(stage: int) -> float:
    return boss_hp(stage) * Balance.MINI_HP_FRAC

static func mini_dmg(stage: int) -> float:
    return boss_dmg(stage) * Balance.MINI_DMG_FRAC

static func mini_gold(stage: int) -> int:
    return maxi(1, int(round(float(boss_gold(stage)) * Balance.MINI_GOLD_FRAC)))

static func mini_gems(rng: RandomNumberGenerator) -> int:
    return rng.randi_range(Balance.MINI_GEM_MIN, Balance.MINI_GEM_MAX)

static func is_boss_stage(stage: int) -> bool:
    return stage > 0 and stage % Balance.BOSS_EVERY == 0

static func boss_index(stage: int) -> int:
    return maxi(1, floori(float(stage) / float(Balance.BOSS_EVERY)))

static func enemy_count(stage: int) -> int:
    var steps: int = floori(float(maxi(1, stage) - 1) / float(Balance.ENEMY_COUNT_STEP_EVERY))
    return mini(Balance.ENEMY_COUNT_MAX, Balance.ENEMY_COUNT_BASE + Balance.ENEMY_COUNT_STEP * steps)

static func max_alive(stage: int) -> int:
    return mini(Balance.ALIVE_MAX, Balance.ALIVE_BASE + int(Balance.ALIVE_PER_STAGE * float(stage - 1)))

static func enemy_hp(base: float, stage: int) -> float:
    return base * pow(Balance.ENEMY_HP_GROWTH, float(stage - 1))

static func enemy_dmg(base: float, stage: int) -> float:
    return base * pow(Balance.ENEMY_DMG_GROWTH, float(stage - 1))

static func enemy_gold(base: float, stage: int) -> int:
    return maxi(1, int(round(base * pow(Balance.ENEMY_GOLD_GROWTH, float(stage - 1)))))

static func boss_hp(stage: int) -> float:
    return enemy_hp(float(EnemiesDB.BOSS_BASE["hp"]), stage) * Balance.BOSS_HP_MULT

static func boss_dmg(stage: int) -> float:
    return enemy_dmg(float(EnemiesDB.BOSS_BASE["dmg"]), stage) * Balance.BOSS_DMG_MULT

static func boss_gold(stage: int) -> int:
    return maxi(1, int(round(enemy_gold(float(EnemiesDB.BOSS_BASE["gold"]), stage) * Balance.BOSS_GOLD_MULT)))

## [min, max] de gemas garantidas do chefe desta fase (opção C: cresce com o índice do chefe).
static func boss_gem_range(stage: int) -> Array:
    var scale: float = pow(Balance.BOSS_GEM_GROWTH, float(boss_index(stage) - 1))
    return [int(round(Balance.BOSS_GEM_MIN * scale)), int(round(Balance.BOSS_GEM_MAX * scale))]

static func boss_gems(stage: int, rng: RandomNumberGenerator) -> int:
    var r := boss_gem_range(stage)
    return rng.randi_range(int(r[0]), int(r[1]))

## Fragmentos de asa: EXCLUSIVAMENTE de chefes (0 em fases normais).
static func boss_shards(stage: int) -> int:
    if not is_boss_stage(stage):
        return 0
    return Balance.BOSS_SHARDS_BASE + floori(float(boss_index(stage) - 1) / float(Balance.BOSS_SHARDS_BONUS_EVERY))
