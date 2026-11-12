extends TestCase

func test_exactly_ten_unique_skills() -> void:
    check(SkillsDB.SKILLS.size() == 10, "devem existir 10 habilidades")
    var seen := {}
    for s in SkillsDB.SKILLS:
        check(not seen.has(s["id"]), "id duplicado " + str(s["id"]))
        seen[s["id"]] = true

func test_prices_match_design_and_increase() -> void:
    var expected := [100, 500, 2000, 7500, 20000, 50000, 120000, 300000, 750000, 2000000]
    var prev := 0
    for i in range(10):
        var p: int = int(SkillsDB.SKILLS[i]["price"])
        check(p == expected[i], "preço da habilidade %d" % (i + 1))
        check(p > prev, "preço crescente na habilidade %d" % (i + 1))
        prev = p

func test_cooldowns_8s_except_ultimate_60s() -> void:
    for i in range(9):
        check_approx(float(SkillsDB.SKILLS[i]["cooldown"]), 8.0, "recarga 8s na habilidade %d" % (i + 1))
    check_approx(float(SkillsDB.SKILLS[9]["cooldown"]), 60.0, "A Morte do Inferno = 60s")

func test_damage_scales_with_rarity() -> void:
    var prev := 0.0
    for s in SkillsDB.SKILLS:
        var d := SkillsDB.damage(s["id"], 100.0, 1.0)
        check(d > prev, "dano crescente: " + str(s["id"]))
        prev = d

func test_damage_formula_and_glow() -> void:
    check_approx(SkillsDB.damage("celestial_lance", 20.0, 1.0), 30.0, "150% de 20")
    check_approx(SkillsDB.damage("celestial_lance", 20.0, 1.5), 45.0, "brilho +50%")
    check_approx(SkillsDB.damage("death_of_hell", 10.0, 1.0), 1500.0, "15000% de 10")

func test_judgment_extra_vs_boss() -> void:
    var normal := SkillsDB.damage("divine_judgment", 10.0, 1.0, false)
    var boss := SkillsDB.damage("divine_judgment", 10.0, 1.0, true)
    check_approx(boss, normal * 1.5, "+50% em chefes (valor sugerido)")
    check(SkillsDB.get_skill("holy_apocalypse")["effects"].get("no_execute", false), "Apocalipse sem execução")

func test_only_three_slots() -> void:
    var st := SaveData.default_state()
    st["gems"] = 10000000
    for id in ["celestial_lance", "holy_shield", "rain_of_light", "swords_of_paradise"]:
        check(Shop.buy_skill(st, id), "comprar " + id)
    check(Shop.equip_skill(st, "celestial_lance"), "equipa 1")
    check(Shop.equip_skill(st, "holy_shield"), "equipa 2")
    check(Shop.equip_skill(st, "rain_of_light"), "equipa 3")
    check(not Shop.equip_skill(st, "swords_of_paradise"), "4ª deve falhar")
    check(Shop.unequip_skill(st, "holy_shield"), "desequipa")
    check(Shop.equip_skill(st, "swords_of_paradise"), "troca livre")
    check(not Shop.equip_skill(st, "death_of_hell"), "não comprada não equipa")

func test_cooldown_logic() -> void:
    var st := SaveData.default_state()
    st["gems"] = 1000
    Shop.buy_skill(st, "celestial_lance")
    Shop.equip_skill(st, "celestial_lance")
    var slots := SkillSlots.new()
    slots.load_from_state(st)
    check(slots.can_use("celestial_lance"), "pronta no início")
    check(slots.use("celestial_lance"), "usa")
    check(not slots.can_use("celestial_lance"), "em recarga")
    slots.tick(7.9)
    check(not slots.can_use("celestial_lance"), "ainda em recarga aos 7,9s")
    slots.tick(0.2)
    check(slots.can_use("celestial_lance"), "pronta após 8s")
    check(not slots.can_use("death_of_hell"), "não equipada não usa")
