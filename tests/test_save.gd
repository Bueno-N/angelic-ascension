extends TestCase

func test_roundtrip_preserves_everything() -> void:
    var st := SaveData.default_state()
    st["gold"] = 123456
    st["gems"] = 77
    st["shards"] = 5
    st["stage"] = 42
    st["max_stage"] = 55
    st["upgrades"]["attack"] = 12
    st["upgrades"]["aura"] = 3
    st["gems"] = 1000000
    Shop.buy_equipment(st, "sword", 2)
    Shop.buy_equipment(st, "armor", 1)
    st["wings_level"] = 4
    Shop.buy_glow(st, 3)
    Shop.buy_skill(st, "celestial_lance")
    Shop.buy_skill(st, "holy_shield")
    Shop.equip_skill(st, "holy_shield")
    var back := SaveData.from_json(SaveData.to_json(st))
    check(int(back["gold"]) == 123456, "ouro")
    check(int(back["gems"]) == int(st["gems"]), "gemas")
    check(int(back["shards"]) == 5, "fragmentos")
    check(int(back["stage"]) == 42 and int(back["max_stage"]) == 55, "fases")
    check(int(back["upgrades"]["attack"]) == 12, "upgrade ataque")
    check(back["owned_equipment"]["sword"] == [2], "espada comprada")
    check(int(back["equipped"]["sword"]) == 2, "espada equipada")
    check(int(back["equipped"]["armor"]) == 1, "armadura equipada")
    check(int(back["wings_level"]) == 4, "asas")
    check(int(back["glow_tier"]) == 3, "brilho")
    check(back["skills_owned"].size() == 2, "habilidades compradas")
    check(back["skills_equipped"] == ["holy_shield"], "habilidade equipada")
    check(StatsCalc.compute(back) == StatsCalc.compute(st), "atributos idênticos após carregar")

func test_corrupt_or_empty_save_returns_default() -> void:
    for txt in ["", "not json", "[1,2,3]", "null", "{\"gold\": \"abc\"}"]:
        var s := SaveData.from_json(txt)
        check(int(s["gold"]) == 0 and int(s["stage"]) == 1, "padrão para entrada: " + txt)

func test_sanitize_rejects_invalid_values() -> void:
    var s := SaveData.sanitize({
        "gold": -50, "stage": 0, "wings_level": 999, "glow_tier": 99,
        "owned_equipment": {"sword": [1, 1, 99, -2]},
        "equipped": {"sword": 5, "armor": 3},
        "skills_owned": ["celestial_lance", "fake_skill", "celestial_lance"],
        "skills_equipped": ["celestial_lance", "holy_shield", "fake_skill"],
    })
    check(int(s["gold"]) == 0, "ouro negativo vira 0")
    check(int(s["stage"]) == 1, "fase mínima 1")
    check(int(s["wings_level"]) == WingsDB.MAX_LEVEL, "asas limitadas")
    check(int(s["glow_tier"]) == WingsDB.GLOW.size(), "brilho limitado")
    check(s["owned_equipment"]["sword"] == [1], "só tiers válidos e únicos")
    check(int(s["equipped"]["sword"]) == 0, "não equipa o que não possui")
    check(int(s["equipped"]["armor"]) == 0, "não equipa o que não possui (armadura)")
    check(s["skills_owned"] == ["celestial_lance"], "só ids válidos e únicos")
    check(s["skills_equipped"] == ["celestial_lance"], "equipada ⊆ comprada")

func test_equipped_skills_capped_at_three() -> void:
    var ids := SkillsDB.ids()
    var s := SaveData.sanitize({"skills_owned": ids, "skills_equipped": ids})
    check(s["skills_equipped"].size() == 3, "máximo 3 ao carregar")

func test_missing_fields_filled_with_defaults() -> void:
    var s := SaveData.sanitize({"gold": 10})
    check(int(s["gold"]) == 10, "mantém ouro")
    check(s["upgrades"].size() == Balance.ATTRIBUTE_ORDER.size(), "upgrades completos")
    check(s["equipped"].size() == EquipmentDB.CATEGORIES.size(), "categorias completas")

func test_sanitize_survives_junk_types_everywhere() -> void:
    var s := SaveData.sanitize({
        "gold": [1], "gems": {"a": 1}, "shards": "9", "stage": "7", "max_stage": null,
        "upgrades": {"attack": {"x": 1}, "hp": "5", "armor": [3], "speed": 2.9},
        "owned_equipment": {"sword": [1, "2", {}, null, 99], "armor": "x", "boots": 7},
        "equipped": {"sword": "x", "armor": {}, "boots": [1]},
        "wings_level": [], "glow_tier": null,
        "skills_owned": [1, 2, {}, "celestial_lance"], "skills_equipped": [{}, "celestial_lance"],
        "settings": {"auto_slots": ["x", 1, null, 4], "speed_2x": 5},
    })
    check(int(s["gold"]) == 0 and int(s["gems"]) == 0 and int(s["shards"]) == 0, "recursos inválidos viram 0")
    check(int(s["stage"]) == 1, "fase em string é ignorada")
    check(int(s["upgrades"]["attack"]) == 0, "upgrade com dicionário vira 0")
    check(int(s["upgrades"]["hp"]) == 5, "string numérica aceita")
    check(int(s["upgrades"]["speed"]) == 2, "float truncado")
    check(s["owned_equipment"]["sword"] == [1, 2], "só tiers válidos")
    check(int(s["equipped"]["sword"]) == 0, "equipado inválido vira 0")
    check(int(s["wings_level"]) == 0 and int(s["glow_tier"]) == 0, "asas/brilho inválidos vira 0")
    check(s["skills_owned"] == ["celestial_lance"], "só ids válidos")
    check(s["skills_equipped"] == ["celestial_lance"], "equipada válida")
    check(s["settings"]["auto_slots"].size() == 3, "3 slots automáticos")
    check(typeof(s["settings"]["speed_2x"]) == TYPE_BOOL, "speed_2x sempre bool")

func test_safe_converters() -> void:
    check(SaveData.as_int("12") == 12 and SaveData.as_int("x", 4) == 4 and SaveData.as_int(null, 3) == 3, "as_int")
    check(SaveData.as_int(2.7) == 2 and SaveData.as_int([], 1) == 1, "as_int float/array")
    check(SaveData.as_bool(true) and not SaveData.as_bool(false), "as_bool bool")
    check(SaveData.as_bool(1) and not SaveData.as_bool(0.0), "as_bool número")
    check(SaveData.as_bool("x", true) and not SaveData.as_bool("x", false), "as_bool usa o padrão para texto")
