extends TestCase

func test_boss_every_10_stages() -> void:
    for st in range(1, 101):
        check(StageLogic.is_boss_stage(st) == (st % 10 == 0), "chefe só em múltiplos de 10 (fase %d)" % st)
    check(StageLogic.boss_index(10) == 1 and StageLogic.boss_index(40) == 4, "índice do chefe")

func test_enemy_scaling_monotonic() -> void:
    var hp := 0.0
    var dmg := 0.0
    var cnt := 0
    for st in range(1, 201):
        var h := StageLogic.enemy_hp(20.0, st)
        var d := StageLogic.enemy_dmg(5.0, st)
        var c := StageLogic.enemy_count(st)
        check(h > hp, "vida cresce fase %d" % st)
        check(d > dmg, "dano cresce fase %d" % st)
        check(c >= cnt, "quantidade não decresce fase %d" % st)
        check(c <= Balance.ENEMY_COUNT_MAX, "quantidade limitada")
        hp = h
        dmg = d
        cnt = c
    check(StageLogic.enemy_count(1) == Balance.ENEMY_COUNT_BASE, "fase 1 usa quantidade base")

func test_enemy_count_starts_at_50_and_grows_5_every_5_stages() -> void:
    check(Balance.ENEMY_COUNT_BASE == 50, "começa em 50 mobs")
    for st in range(1, 6):
        check(StageLogic.enemy_count(st) == 50, "fases 1-5: 50 (fase %d)" % st)
    for st in range(6, 11):
        check(StageLogic.enemy_count(st) == 55, "fases 6-10: 55 (fase %d)" % st)
    check(StageLogic.enemy_count(11) == 60 and StageLogic.enemy_count(15) == 60, "fases 11-15: 60")
    check(StageLogic.enemy_count(26) == 75 and StageLogic.enemy_count(30) == 75, "fases 26-30: 75")
    check(StageLogic.enemy_count(100) == 50 + 5 * 19, "fase 100: 145")
    check(StageLogic.enemy_count(10000) == Balance.ENEMY_COUNT_MAX, "respeita o teto")
    check(StageLogic.enemy_count(0) == 50 and StageLogic.enemy_count(-3) == 50, "fase inválida usa a base")

func test_mobs_get_stronger_with_stage() -> void:
    for t in EnemiesDB.TYPES:
        check(StageLogic.enemy_hp(float(t["hp"]), 30) > StageLogic.enemy_hp(float(t["hp"]), 1) * 10.0, "vida de %s cresce forte" % t["id"])
        check(StageLogic.enemy_dmg(float(t["dmg"]), 30) > StageLogic.enemy_dmg(float(t["dmg"]), 1) * 5.0, "dano de %s cresce" % t["id"])
        check(StageLogic.enemy_gold(float(t["gold"]), 30) > StageLogic.enemy_gold(float(t["gold"]), 1), "ouro de %s cresce" % t["id"])

func test_boss_stronger_than_regular() -> void:
    for st in [10, 20, 50, 100]:
        check(StageLogic.boss_hp(st) > StageLogic.enemy_hp(float(EnemiesDB.TYPES[3]["hp"]), st), "chefe tem mais vida na fase %d" % st)
        check(StageLogic.boss_dmg(st) > StageLogic.enemy_dmg(float(EnemiesDB.TYPES[3]["dmg"]), st), "chefe tem mais dano na fase %d" % st)
        check(StageLogic.boss_gold(st) > StageLogic.enemy_gold(float(EnemiesDB.TYPES[3]["gold"]), st), "chefe dá mais ouro")

func test_boss_definitions() -> void:
    check(EnemiesDB.BOSSES.size() >= 4, "ao menos 4 chefes")
    for b in EnemiesDB.BOSSES:
        check(b["abilities"].size() == 2, "chefe %s tem exatamente 2 habilidades" % b["name"])
    check(EnemiesDB.boss_for(10)["id"] == EnemiesDB.BOSSES[0]["id"], "fase 10 = 1º chefe")
    check(EnemiesDB.boss_for(40)["id"] == EnemiesDB.BOSSES[3]["id"], "fase 40 = 4º chefe")
    check(EnemiesDB.boss_for(50)["id"] == EnemiesDB.BOSSES[0]["id"], "ciclo após o último")

func test_enemy_types_and_unlocks() -> void:
    var kinds := {}
    for t in EnemiesDB.TYPES:
        kinds[t["kind"]] = true
        for k in ["hp", "dmg", "speed", "gold"]:
            check(float(t[k]) > 0.0, "%s.%s > 0" % [t["id"], k])
    for k in ["common", "warrior", "shadow", "beast", "special"]:
        check(kinds.has(k), "existe tipo " + k)
    check(EnemiesDB.available_types(1).size() == 1, "fase 1 só tem demônio comum")
    check(EnemiesDB.available_types(50).size() == EnemiesDB.TYPES.size(), "fase 50 tem todos")
    var prev := 0
    for st in range(1, 40):
        var n := EnemiesDB.available_types(st).size()
        check(n >= prev, "tipos só aumentam")
        prev = n

func test_pick_type_never_returns_locked() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 7
    for st in [1, 3, 6, 12, 40]:
        for i in range(300):
            var t := EnemiesDB.pick_type(st, rng)
            check(int(t["unlock_stage"]) <= st, "tipo bloqueado sorteado na fase %d" % st)

func test_wings_cost_progression() -> void:
    var prev := 0
    for lvl in range(WingsDB.MAX_LEVEL):
        var c := WingsDB.shards_for_next(lvl)
        check(c >= prev and c > 0, "custo de asas crescente nv %d" % lvl)
        prev = c
    check(WingsDB.shards_for_next(WingsDB.MAX_LEVEL) == 0, "sem custo além do máximo")
    check_approx(WingsDB.bonus_for_level(1), 0.05, "nv1 +5%")
    check_approx(WingsDB.bonus_for_level(4), 0.20, "nv4 +20%")

func test_pacing_params() -> void:
    var prev := 0
    for st in range(1, 200):
        var a := StageLogic.max_alive(st)
        check(a >= prev and a >= Balance.ALIVE_BASE and a <= Balance.ALIVE_MAX, "simultâneos limitados e crescentes (fase %d)" % st)
        prev = a
    check(StageLogic.max_alive(1) == Balance.ALIVE_BASE, "fase 1 usa ALIVE_BASE")
    var min_secs: float = float(StageLogic.enemy_count(1)) * Balance.SPAWN_INTERVAL
    check(min_secs >= 40.0 and min_secs <= 180.0, "tempo máximo da fase 1 (sem aceleração) entre 40 e 180 s (obtido %.0f s)" % min_secs)
