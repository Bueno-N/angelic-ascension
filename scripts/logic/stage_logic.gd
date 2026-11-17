class_name StageLogic
extends RefCounted
## Escala por fase, chefes e recompensas.

## "Próxima fase" a qualquer momento, mas só até uma fase JÁ alcançada (não dá para furar chefes não vencidos).
static func can_skip_to_next(stage: int, max_stage: int) -> bool:
    return stage < mini(max_stage, Balance.MAX_STAGE)

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
    return base * pow(float(maxi(stage, 1)), Balance.ENEMY_HP_POWER) * float(Balance.TIER_HP_MULT[tier_index(stage)])

static func enemy_dmg(base: float, stage: int) -> float:
    return base * pow(float(maxi(stage, 1)), Balance.ENEMY_DMG_POWER) * float(Balance.TIER_DMG_MULT[tier_index(stage)])

static func enemy_gold(base: float, stage: int) -> int:
    return maxi(1, int(round(base * pow(Balance.ENEMY_GOLD_GROWTH, float(stage - 1)) * reward_mult(stage))))

# ---------------------------------------------------------------- andares e dificuldade (a cada 50 andares)
static func clamp_stage(stage: int) -> int:
    return clampi(stage, 1, Balance.MAX_STAGE)

## 0 = Fácil (1-50), 1 = Normal (51-100)... até o último degrau.
static func tier_index(stage: int) -> int:
    return clampi(floori(float(maxi(1, stage) - 1) / float(Balance.TIER_SIZE)), 0, Balance.TIER_NAMES.size() - 1)

static func tier_name(stage: int) -> String:
    return str(Balance.TIER_NAMES[tier_index(stage)])

static func tier_first_stage(tier: int) -> int:
    return tier * Balance.TIER_SIZE + 1

static func tier_last_stage(tier: int) -> int:
    return mini(Balance.MAX_STAGE, (tier + 1) * Balance.TIER_SIZE)

static func reward_mult(stage: int) -> float:
    return float(Balance.TIER_REWARD_MULT[tier_index(stage)])

## Próxima fase ao limpar: sobe 1, mas o último andar (300) só se repete.
static func stage_after_clear(stage: int) -> int:
    return mini(stage + 1, Balance.MAX_STAGE)

## Escolher andar no menu: só andares JÁ alcançados (<= recorde) e diferentes do atual.
static func can_enter(current: int, max_stage: int, target: int) -> bool:
    return target >= 1 and target <= mini(max_stage, Balance.MAX_STAGE) and target != current

## Projeção do ganho MÉDIO por vitória no andar (não é garantido): {mobs, gold, gems, shards, boss, mini}.
static func projection(stage: int) -> Dictionary:
    var st: int = clamp_stage(stage)
    var out := {"stage": st, "boss": is_boss_stage(st), "mini": is_mini_stage(st), "mobs": 0, "gold": 0.0, "gems": 0.0, "shards": 0}
    if out["boss"]:
        var r := boss_gem_range(st)
        out["mobs"] = 1
        out["gold"] = float(boss_gold(st))
        out["gems"] = (float(r[0]) + float(r[1])) / 2.0
        out["shards"] = boss_shards(st)
        return out
    var n_sum := 0.0
    var n_cnt := 0
    var s_sum := 0.0
    var s_cnt := 0
    for t in EnemiesDB.available_types(st):
        var g: float = float(enemy_gold(float(t["gold"]), st))
        if t["special"]:
            s_sum += g
            s_cnt += 1
        else:
            n_sum += g
            n_cnt += 1
    var p_spec: float = Balance.SPECIAL_SPAWN_CHANCE if s_cnt > 0 else 0.0
    var avg_n: float = n_sum / float(maxi(1, n_cnt))
    var avg_s: float = s_sum / float(maxi(1, s_cnt))
    var count: int = enemy_count(st)
    var spec_gems: float = Balance.GEM_CHANCE_SPECIAL * (float(Balance.GEM_SPECIAL_MIN) + float(Balance.GEM_SPECIAL_MAX)) / 2.0
    out["mobs"] = count
    out["gold"] = float(count) * ((1.0 - p_spec) * avg_n + p_spec * avg_s)
    out["gems"] = float(count) * ((1.0 - p_spec) * Balance.GEM_CHANCE_COMMON + p_spec * spec_gems)
    if out["mini"]:
        out["mobs"] = count + 1
        out["gold"] = float(out["gold"]) + float(mini_gold(st))
        out["gems"] = float(out["gems"]) + (float(Balance.MINI_GEM_MIN) + float(Balance.MINI_GEM_MAX)) / 2.0
    return out

static func boss_hp(stage: int) -> float:
    return enemy_hp(float(EnemiesDB.BOSS_BASE["hp"]), stage) * Balance.BOSS_HP_MULT

static func boss_dmg(stage: int) -> float:
    return enemy_dmg(float(EnemiesDB.BOSS_BASE["dmg"]), stage) * Balance.BOSS_DMG_MULT

static func boss_gold(stage: int) -> int:
    return maxi(1, int(round(enemy_gold(float(EnemiesDB.BOSS_BASE["gold"]), stage) * Balance.BOSS_GOLD_MULT)))

## [min, max] de gemas garantidas do chefe desta fase (opção C: cresce com o índice do chefe).
static func boss_gem_range(stage: int) -> Array:
    var scale: float = pow(Balance.BOSS_GEM_GROWTH, float(boss_index(stage) - 1)) * reward_mult(stage)
    return [int(round(Balance.BOSS_GEM_MIN * scale)), int(round(Balance.BOSS_GEM_MAX * scale))]

static func boss_gems(stage: int, rng: RandomNumberGenerator) -> int:
    var r := boss_gem_range(stage)
    return rng.randi_range(int(r[0]), int(r[1]))

## Fragmentos de asa: EXCLUSIVAMENTE de chefes (0 em fases normais).
static func boss_shards(stage: int) -> int:
    if not is_boss_stage(stage):
        return 0
    return Balance.BOSS_SHARDS_BASE + floori(float(boss_index(stage) - 1) / float(Balance.BOSS_SHARDS_BONUS_EVERY))
