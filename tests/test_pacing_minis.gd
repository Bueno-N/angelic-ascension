extends TestCase
## Horda que acelera, mini-chefes (fases 5/15/25), marcos e contador.

func test_spawn_interval_accelerates_and_is_bounded() -> void:
    check_approx(StageLogic.spawn_interval(0.0), Balance.SPAWN_INTERVAL, "começa no intervalo base")
    check_approx(StageLogic.spawn_interval(Balance.SPAWN_ACCEL_SECONDS), Balance.SPAWN_INTERVAL / 2.0, "metade após o tempo de aceleração")
    var prev := 999.0
    for t in range(0, 400, 5):
        var v := StageLogic.spawn_interval(float(t))
        check(v <= prev + 0.000001, "nunca fica mais lento (t=%d)" % t)
        check(v >= Balance.SPAWN_MIN_INTERVAL, "respeita o mínimo (t=%d)" % t)
        prev = v
    check_approx(StageLogic.spawn_interval(99999.0), Balance.SPAWN_MIN_INTERVAL, "satura no mínimo")
    check_approx(StageLogic.spawn_interval(-5.0), Balance.SPAWN_INTERVAL, "tempo negativo = início")

func test_extra_alive_grows_and_caps() -> void:
    check(StageLogic.extra_alive(0.0) == 0, "sem extra no início")
    check(StageLogic.extra_alive(Balance.ALIVE_EXTRA_EVERY) == 1, "+1 após o intervalo")
    check(StageLogic.extra_alive(99999.0) == Balance.ALIVE_EXTRA_MAX, "limitado")
    var prev := 0
    for t in range(0, 400, 10):
        var c := StageLogic.total_alive_cap(10, float(t))
        check(c >= prev, "teto simultâneo não diminui (t=%d)" % t)
        prev = c
    check(StageLogic.total_alive_cap(1, 0.0) == Balance.ALIVE_BASE, "fase 1 começa com ALIVE_BASE")

func test_mini_stages_are_5_15_25_and_never_boss() -> void:
    for st in [5, 15, 25, 95, 105]:
        check(StageLogic.is_mini_stage(st), "fase %d tem mini-chefe" % st)
        check(not StageLogic.is_boss_stage(st), "fase %d não é de chefe" % st)
    for st in [0, 1, 4, 6, 10, 20, 30, 14]:
        check(not StageLogic.is_mini_stage(st), "fase %d sem mini-chefe" % st)
    for st in range(1, 300):
        check(not (StageLogic.is_mini_stage(st) and StageLogic.is_boss_stage(st)), "nunca os dois (fase %d)" % st)

func test_next_milestone() -> void:
    var m := StageLogic.next_milestone(1)
    check(m["kind"] == "mini" and int(m["stage"]) == 5 and int(m["in"]) == 4, "da fase 1: mini-chefe na 5 (em 4)")
    m = StageLogic.next_milestone(5)
    check(m["kind"] == "mini" and int(m["in"]) == 0, "na fase 5: agora")
    m = StageLogic.next_milestone(6)
    check(m["kind"] == "boss" and int(m["stage"]) == 10 and int(m["in"]) == 4, "da fase 6: chefe na 10")
    m = StageLogic.next_milestone(10)
    check(m["kind"] == "boss" and int(m["in"]) == 0, "na fase 10: agora")
    m = StageLogic.next_milestone(11)
    check(m["kind"] == "mini" and int(m["stage"]) == 15, "da 11: mini-chefe na 15")
    for st in range(1, 200):
        check(not StageLogic.next_milestone(st).is_empty(), "sempre há próximo marco (fase %d)" % st)

func test_mini_boss_is_between_normal_and_boss() -> void:
    for st in [5, 15, 25, 55, 105]:
        check(StageLogic.mini_hp(st) < StageLogic.boss_hp(st), "mini tem menos vida que o chefe (fase %d)" % st)
        check(StageLogic.mini_dmg(st) <= StageLogic.boss_dmg(st), "mini não bate mais que o chefe")
        check(StageLogic.mini_gold(st) < StageLogic.boss_gold(st), "mini dá menos ouro que o chefe")
        for md in EnemiesDB.MINIS:
            var base := EnemiesDB.type_by_id(str(md["type"]))
            check(StageLogic.mini_hp(st) > StageLogic.enemy_hp(float(base["hp"]), st), "mini > %s comum (fase %d)" % [md["type"], st])

func test_mini_definitions() -> void:
    check(EnemiesDB.MINIS.size() == 3, "3 mini-chefes")
    var ids := {}
    for md in EnemiesDB.MINIS:
        check(not EnemiesDB.type_by_id(str(md["type"])).is_empty(), "tipo base existe: " + str(md["type"]))
        check(str(md["name"]).length() > 3, "tem nome")
        check(md["abilities"].size() == 1, "1 habilidade")
        for a in md["abilities"]:
            check(EnemiesDB.ABILITIES.has(a), "habilidade definida: " + str(a))
        ids[md["id"]] = true
    check(ids.size() == 3, "ids únicos")
    check(EnemiesDB.mini_for(5)["id"] == EnemiesDB.MINIS[0]["id"], "fase 5 = 1º")
    check(EnemiesDB.mini_for(15)["id"] == EnemiesDB.MINIS[1]["id"], "fase 15 = 2º")
    check(EnemiesDB.mini_for(25)["id"] == EnemiesDB.MINIS[2]["id"], "fase 25 = 3º")
    check(EnemiesDB.mini_for(35)["id"] == EnemiesDB.MINIS[0]["id"], "ciclo recomeça na 35")

func test_mini_rewards_have_no_wing_shards() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 55
    for i in range(500):
        var g := StageLogic.mini_gems(rng)
        check(g >= Balance.MINI_GEM_MIN and g <= Balance.MINI_GEM_MAX, "gemas do mini-chefe na faixa")
    for st in [5, 15, 25]:
        check(StageLogic.boss_shards(st) == 0, "fragmentos de asa só de chefes (fase %d)" % st)
    check(Balance.MINI_GEM_MAX <= Balance.BOSS_GEM_MIN, "mini-chefe nunca rende mais gemas que o mínimo de um chefe")
