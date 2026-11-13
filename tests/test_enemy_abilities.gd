extends TestCase

func test_boss_abilities_defined_and_cover_the_design() -> void:
    var seen := {}
    for b in EnemiesDB.BOSSES:
        check(b["abilities"].size() == 2, "chefe %s com 2 habilidades" % b["name"])
        for a in b["abilities"]:
            check(EnemiesDB.ABILITIES.has(a), "habilidade definida: " + str(a))
            seen[a] = true
    for need in ["area_slam", "charge", "summon_demons", "hellfire_projectiles"]:
        check(seen.has(need), "design pede: " + need)

func test_special_enemies_have_defined_abilities() -> void:
    var n := 0
    for t in EnemiesDB.TYPES:
        if t["special"]:
            n += 1
            check(t.has("ability") and EnemiesDB.ABILITIES.has(t["ability"]), "especial %s com habilidade válida" % t["id"])
    check(n >= 2, "ao menos 2 inimigos especiais")

func test_ability_config_is_sane() -> void:
    for id in EnemiesDB.ABILITIES.keys():
        var c: Dictionary = EnemiesDB.ABILITIES[id]
        check(float(c["cooldown"]) > 0.0, id + ": recarga > 0")
        check(float(c["telegraph"]) > 0.0, id + ": aviso visual (telegraph) > 0")
        check(float(c["min_range"]) <= float(c["max_range"]), id + ": faixa válida")
    check(int(EnemiesDB.ABILITIES["summon_demons"]["count"]) >= 1, "invoca ao menos 1")
    check(int(EnemiesDB.ABILITIES["hellfire_projectiles"]["count"]) >= 2, "leque com 2+ projéteis")
    check(float(EnemiesDB.ABILITIES["life_steal"]["heal_pct"]) > 0.0, "drenar vida cura")
    check(EnemiesDB.MAX_SUMMONS_ALIVE > 0, "limite de invocações")

func test_cooldown_logic_and_ranges() -> void:
    var cfg: Dictionary = EnemiesDB.ABILITIES
    var ac := AbilityCooldowns.new()
    ac.setup(["area_slam", "charge"], cfg, 0.5)
    check(ac.next_ready(cfg, 100.0) == "", "nada pronto no início (recarga inicial)")
    ac.tick(3.4)
    check(ac.next_ready(cfg, 100.0) == "", "pancada ainda em recarga aos 3,4 s")
    ac.tick(0.2)
    check(ac.next_ready(cfg, 100.0) == "area_slam", "pancada pronta aos 3,6 s")
    check(ac.next_ready(cfg, 500.0) == "", "fora da faixa da pancada (max 260)")
    ac.start("area_slam", cfg)
    check(ac.remaining("area_slam") == 7.0, "recarga cheia após usar")
    ac.tick(1.0)
    check(ac.next_ready(cfg, 100.0) == "", "investida pronta mas perto demais (min 140)")
    check(ac.next_ready(cfg, 300.0) == "charge", "investida pronta e na faixa")

func test_initial_fraction_zero_is_immediate() -> void:
    var ac := AbilityCooldowns.new()
    ac.setup(["fire_bolt"], EnemiesDB.ABILITIES, 0.0)
    check(ac.next_ready(EnemiesDB.ABILITIES, 100.0) == "fire_bolt", "sem recarga inicial")
    check(ac.next_ready(EnemiesDB.ABILITIES, 1000.0) == "", "fora do alcance (420)")

func test_pick_normal_never_special() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 2024
    for st in [1, 5, 12, 50]:
        for i in range(200):
            var t := EnemiesDB.pick_normal(st, rng)
            check(not t["special"], "invocação sorteou especial na fase %d" % st)
            check(int(t["unlock_stage"]) <= st, "tipo bloqueado na fase %d" % st)
