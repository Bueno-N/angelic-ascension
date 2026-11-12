extends TestCase

func test_reference_drop_parameters() -> void:
    check_approx(Balance.GEM_CHANCE_COMMON, 0.005, "0,5% comum")
    check_approx(Balance.GEM_CHANCE_SPECIAL, 0.02, "2% especial")
    check(Balance.GEM_SPECIAL_MIN == 1 and Balance.GEM_SPECIAL_MAX == 3, "especial dropa 1..3")

func test_boss_gems_first_boss_10_to_20() -> void:
    var r := StageLogic.boss_gem_range(10)
    check(int(r[0]) == 10 and int(r[1]) == 20, "chefe da fase 10: 10..20")

func test_boss_gems_grow_with_stage() -> void:
    var prev := 0
    for st in range(10, 501, 10):
        var r := StageLogic.boss_gem_range(st)
        check(int(r[0]) >= 10, "mínimo nunca abaixo de 10")
        check(int(r[1]) >= int(r[0]), "max >= min")
        check(int(r[1]) >= prev, "não decresce na fase %d" % st)
        prev = int(r[1])
    check(StageLogic.boss_gem_range(200)[1] > StageLogic.boss_gem_range(10)[1], "fase 200 > fase 10")

func test_boss_gems_roll_within_range() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 42
    for i in range(500):
        var g := StageLogic.boss_gems(30, rng)
        var r := StageLogic.boss_gem_range(30)
        check(g >= int(r[0]) and g <= int(r[1]), "gemas do chefe dentro da faixa")

func test_shards_only_from_bosses() -> void:
    for st in range(1, 101):
        if StageLogic.is_boss_stage(st):
            check(StageLogic.boss_shards(st) >= 1, "chefe dropa fragmento na fase %d" % st)
        else:
            check(StageLogic.boss_shards(st) == 0, "fase normal %d sem fragmento" % st)

func test_gold_cannot_buy_gem_items() -> void:
    var st := SaveData.default_state()
    st["gold"] = 999999999
    check(not Shop.buy_equipment(st, "sword", 1), "ouro não compra espada")
    check(not Shop.buy_glow(st, 1), "ouro não compra brilho")
    check(not Shop.buy_skill(st, "celestial_lance"), "ouro não compra habilidade")
    check(not Shop.evolve_wings(st), "ouro não evolui asas")

func test_gems_cannot_buy_gold_upgrades() -> void:
    var st := SaveData.default_state()
    st["gems"] = 999999999
    check(not Shop.buy_upgrade(st, "attack"), "gemas não compram atributo de ouro")

func test_buy_upgrade_spends_gold_and_levels() -> void:
    var st := SaveData.default_state()
    st["gold"] = 10
    check(Shop.buy_upgrade(st, "attack"), "compra nv1 (custo 10)")
    check(int(st["gold"]) == 0, "gastou 10")
    check(Shop.upgrade_level(st, "attack") == 1, "nível 1")
    check(not Shop.buy_upgrade(st, "attack"), "sem ouro para nv2")

func test_equipment_purchase_equip_rules() -> void:
    var st := SaveData.default_state()
    st["gems"] = 100000
    check(Shop.buy_equipment(st, "sword", 1), "compra tier1")
    check(int(st["equipped"]["sword"]) == 1, "auto-equipa")
    check(Shop.buy_equipment(st, "sword", 3), "compra tier3")
    check(int(st["equipped"]["sword"]) == 3, "equipa melhor")
    check(st["owned_equipment"]["sword"].has(1), "tier1 continua desbloqueado")
    check(Shop.equip_equipment(st, "sword", 1), "pode voltar ao tier1")
    check(int(st["equipped"]["sword"]) == 1, "apenas um por categoria")
    check(not Shop.equip_equipment(st, "sword", 5), "não equipa não comprado")
    check(not Shop.buy_equipment(st, "sword", 1), "não recompra")
    var before := int(st["gems"])
    check(not Shop.buy_equipment(st, "boots", 99), "tier inválido")
    check(int(st["gems"]) == before, "falha não gasta gemas")

func test_equipment_prices_increase() -> void:
    var prev := 0
    for t in range(1, EquipmentDB.TIER_COUNT + 1):
        var p: int = int(EquipmentDB.get_item("sword", t)["price"])
        check(p > prev, "preço crescente tier %d" % t)
        prev = p

func test_wings_evolution_with_shards() -> void:
    var st := SaveData.default_state()
    check(not Shop.evolve_wings(st), "sem fragmentos")
    st["shards"] = WingsDB.shards_for_next(0)
    check(Shop.evolve_wings(st), "evolui nv1")
    check(int(st["shards"]) == 0, "gastou fragmentos")
    check(int(st["wings_level"]) == 1, "nível 1")
    st["shards"] = 100000
    for i in range(30):
        Shop.evolve_wings(st)
    check(int(st["wings_level"]) == WingsDB.MAX_LEVEL, "respeita nível máximo")

func test_glow_purchase_rules() -> void:
    var st := SaveData.default_state()
    st["gems"] = 1000000
    check(Shop.buy_glow(st, 2), "compra tier 2")
    check(not Shop.buy_glow(st, 1), "não compra tier inferior")
    check(int(st["glow_tier"]) == 2, "tier 2 ativo")

## Metas de design (avisos, não reprovam): ordem de grandeza do tempo para comprar cada habilidade.
func test_calibration_targets_are_warnings_only() -> void:
    var prev_h := -1.0
    for s in SkillsDB.SKILLS:
        var r := EconomyModel.time_to_accumulate(float(s["price"]))
        if r.is_empty():
            warn_if_not(false, "modelo não alcança %s dentro do limite de fases" % s["name"])
            continue
        warn_if_not(float(r["hours"]) >= prev_h, "tempo crescente em " + str(s["name"]))
        prev_h = float(r["hours"])
    var first := EconomyModel.time_to_accumulate(100.0)
    warn_if_not(not first.is_empty() and float(first["hours"]) <= 12.0, "1ª habilidade deveria sair em poucas horas")
    var last := EconomyModel.time_to_accumulate(2000000.0)
    var days: float = float(last.get("hours", 1e9)) / Balance.MODEL_HOURS_PER_DAY
    warn_if_not(days >= 60.0, "habilidade suprema deveria levar meses (modelo: %.0f dias)" % days)
    check(true, "calibração executada")
