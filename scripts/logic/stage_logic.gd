class_name StageLogic
extends RefCounted
## Escala por fase, chefes e recompensas.

## "Próxima fase" a qualquer momento, mas só até uma fase JÁ alcançada (não dá para furar chefes não vencidos).
static func can_skip_to_next(stage: int, max_stage: int) -> bool:
    return stage < max_stage

static func is_boss_stage(stage: int) -> bool:
    return stage > 0 and stage % Balance.BOSS_EVERY == 0

static func boss_index(stage: int) -> int:
    return maxi(1, floori(float(stage) / float(Balance.BOSS_EVERY)))

static func enemy_count(stage: int) -> int:
    return mini(Balance.ENEMY_COUNT_MAX, Balance.ENEMY_COUNT_BASE + int(Balance.ENEMY_COUNT_PER_STAGE * float(stage - 1)))

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
