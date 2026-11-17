extends TestCase

func test_flag_and_enabled_consistency() -> void:
    check(typeof(Balance.DEBUG_TOOLS) == TYPE_BOOL, "DEBUG_TOOLS é booleano")
    if not Balance.DEBUG_TOOLS:
        check(not DebugTools.enabled(), "constante desligada => desativado sempre")
    else:
        check(DebugTools.enabled() == OS.is_debug_build(), "ativo somente em build de debug")

func test_add_resources() -> void:
    var st := SaveData.default_state()
    DebugTools.add(st, "gold", 1000)
    DebugTools.add(st, "gems", 2000000)
    DebugTools.add(st, "shards", 10)
    check(int(st["gold"]) == 1000 and int(st["gems"]) == 2000000 and int(st["shards"]) == 10, "recursos somados")
    DebugTools.add(st, "gold", -5000)
    check(int(st["gold"]) == 0, "nunca negativo")
    var stage_before := int(st["stage"])
    DebugTools.add(st, "stage", 99)
    check(int(st["stage"]) == stage_before, "chave inválida é ignorada")

func test_gems_allow_buying_supreme() -> void:
    var st := SaveData.default_state()
    DebugTools.add(st, "gems", 2000000)
    check(Shop.buy_skill(st, "death_of_hell"), "2.000.000 gemas compram a suprema (custa 1.300.000)")

func test_unlock_all() -> void:
    var st := SaveData.default_state()
    DebugTools.unlock_all(st)
    check(st["skills_owned"].size() == 10, "10 habilidades")
    check(st["skills_equipped"].size() == SkillsDB.MAX_EQUIPPED, "3 equipadas")
    for cat in EquipmentDB.CATEGORIES:
        check(st["owned_equipment"][cat].size() == EquipmentDB.TIER_COUNT, "todos os tiers de " + cat)
        check(int(st["equipped"][cat]) == EquipmentDB.TIER_COUNT, "melhor equipado em " + cat)
    check(int(st["wings_level"]) == WingsDB.MAX_LEVEL, "asas no máximo")
    check(int(st["glow_tier"]) == WingsDB.GLOW.size(), "brilho no máximo")
    var s := StatsCalc.compute(st)
    check_approx(s["attack"], 10.0 * (1.0 + 0.5 + 0.75), "ataque: asas +50% e espada +75%", 0.001)
    check_approx(s["skill_power_mult"], 1.75, "brilho máximo +75%")
    var clean := SaveData.sanitize(st)
    check(clean["skills_owned"].size() == 10 and int(clean["equipped"]["sword"]) == 6, "estado desbloqueado sobrevive ao save/load")

func test_unlock_all_keeps_existing_equipped() -> void:
    var st := SaveData.default_state()
    st["gems"] = 100000
    Shop.buy_skill(st, "holy_shield")
    Shop.equip_skill(st, "holy_shield")
    DebugTools.unlock_all(st)
    check(st["skills_equipped"][0] == "holy_shield", "mantém a já equipada")
    check(st["skills_equipped"].size() == 3, "completa até 3")

func test_reset_cooldowns() -> void:
    var st := SaveData.default_state()
    st["gems"] = 1000
    Shop.buy_skill(st, "celestial_lance")
    Shop.equip_skill(st, "celestial_lance")
    var slots := SkillSlots.new()
    slots.load_from_state(st)
    slots.use("celestial_lance")
    check(not slots.can_use("celestial_lance"), "em recarga")
    slots.reset_cooldowns()
    check(slots.can_use("celestial_lance"), "recarga zerada")
