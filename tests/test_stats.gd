extends TestCase

func _st() -> Dictionary:
    return SaveData.default_state()

func test_base_stats() -> void:
    var s := StatsCalc.compute(_st())
    check_approx(s["attack"], 10.0, "ataque base")
    check_approx(s["hp"], 100.0, "vida base")
    check_approx(s["armor"], 0.0, "armadura base")
    check_approx(s["speed"], 220.0, "velocidade base")
    check_approx(s["attack_speed"], 1.0, "vel. ataque base")
    check_approx(s["aura"], 5.0, "aura base")
    check_approx(s["skill_power_mult"], 1.0, "sem brilho = x1")

func test_gold_upgrades_are_flat() -> void:
    var st := _st()
    st["upgrades"]["attack"] = 5
    check_approx(StatsCalc.compute(st)["attack"], 20.0, "10 + 2*5")
    st["upgrades"]["hp"] = 10
    check_approx(StatsCalc.compute(st)["hp"], 250.0, "100 + 15*10")

func test_costs_strictly_increase() -> void:
    for a in Balance.ATTRIBUTE_ORDER:
        var prev := -1
        for lvl in range(0, 51):
            var c := StatsCalc.upgrade_cost(a, lvl)
            check(c > prev, "custo de %s deve crescer (nível %d)" % [a, lvl])
            prev = c

func test_wings_boost_all_stats() -> void:
    var st := _st()
    for a in Balance.ATTRIBUTE_ORDER:
        st["upgrades"][a] = 10
    var base := StatsCalc.compute(st)
    st["wings_level"] = 3
    var w := StatsCalc.compute(st)
    for a in Balance.ATTRIBUTE_ORDER:
        check_approx(w[a], base[a] * 1.15, "asas nv3 = +15%% em %s" % a, 0.001)

func test_equipment_targets_correct_stats() -> void:
    var st := _st()
    for a in Balance.ATTRIBUTE_ORDER:
        st["upgrades"][a] = 10
    var base := StatsCalc.compute(st)
    st["equipped"]["sword"] = 4   # +35% ataque
    var s := StatsCalc.compute(st)
    check_approx(s["attack"], base["attack"] * 1.35, "espada nv4 +35% ataque", 0.001)
    check_approx(s["hp"], base["hp"], "espada não altera vida")
    st["equipped"]["armor"] = 3   # +20% vida e armadura
    s = StatsCalc.compute(st)
    check_approx(s["hp"], base["hp"] * 1.20, "armadura +20% vida", 0.001)
    check_approx(s["armor"], base["armor"] * 1.20, "armadura +20% armadura", 0.001)
    st["equipped"]["boots"] = 2   # +10% velocidade
    st["equipped"]["gloves"] = 6  # +75% vel. ataque
    s = StatsCalc.compute(st)
    check_approx(s["speed"], base["speed"] * 1.10, "botas +10%", 0.001)
    check_approx(s["attack_speed"], base["attack_speed"] * 1.75, "luvas +75%", 0.001)

func test_percent_bonuses_are_additive_not_compounded() -> void:
    var st := _st()
    st["wings_level"] = 2      # +10%
    st["equipped"]["sword"] = 5  # +50%
    check_approx(StatsCalc.compute(st)["attack"], 10.0 * 1.60, "x1.60 (aditivo), não x1.65", 0.001)

func test_glow_does_not_change_attributes_only_skill_power() -> void:
    var st := _st()
    st["glow_tier"] = 5
    var s := StatsCalc.compute(st)
    check_approx(s["attack"], 10.0, "brilho não altera ataque")
    check_approx(s["skill_power_mult"], 1.5, "Luz do Paraíso = +50%")

func test_armor_reduction() -> void:
    check_approx(StatsCalc.damage_after_armor(100.0, 0.0), 100.0, "sem armadura")
    check_approx(StatsCalc.damage_after_armor(100.0, 100.0), 50.0, "armadura 100 = -50%")
    check(StatsCalc.damage_after_armor(100.0, 1000.0) > 0.0, "nunca zera o dano")

func test_regen_and_clear_heal() -> void:
    check_approx(StatsCalc.regen_amount(100.0, 1.0), 1.5, "1,5% de 100 por segundo")
    check_approx(StatsCalc.regen_amount(200.0, 0.5), 1.5, "escala com vida máxima e delta")
    check_approx(StatsCalc.stage_clear_heal(100.0), 30.0, "30% ao limpar fase")
    var full_seconds := 1.0 / Balance.HP_REGEN_PCT_PER_SEC
    check(full_seconds >= 30.0 and full_seconds <= 120.0, "regen total em 30-120 s (obtido %.0f s)" % full_seconds)
