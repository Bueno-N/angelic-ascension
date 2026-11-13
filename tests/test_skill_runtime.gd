extends TestCase
## Lógica pura por trás das habilidades em combate (buffs, escala do brilho, auto-cast, slots).

func test_fury_buff_and_expiry() -> void:
    var b := BuffState.new()
    check_approx(b.multiplier("attack"), 1.0, "sem buff")
    b.add("celestial_fury", 5.0, SkillsDB.buff_mods("celestial_fury", 1.0))
    check_approx(b.multiplier("attack"), 2.0, "fúria: +100% ataque")
    check_approx(b.multiplier("attack_speed"), 1.5, "fúria: +50% vel. ataque")
    check_approx(b.multiplier("speed"), 1.3, "fúria: +30% vel. mov.")
    check_approx(b.multiplier("armor"), 1.0, "fúria não altera armadura")
    b.tick(4.9)
    check(b.is_active("celestial_fury"), "ativa aos 4,9 s")
    b.tick(0.2)
    check(not b.is_active("celestial_fury"), "expira após 5 s")
    check_approx(b.multiplier("attack"), 1.0, "volta ao normal")

func test_death_of_hell_buff_all_stats_but_hp() -> void:
    var b := BuffState.new()
    b.add("death_of_hell", 10.0, SkillsDB.buff_mods("death_of_hell", 1.0))
    for s in ["attack", "armor", "speed", "attack_speed", "aura"]:
        check_approx(b.multiplier(s), 2.0, "+100%% em %s" % s)
    check_approx(b.multiplier("hp"), 1.0, "vida máxima não dobra (decisão de design documentada)")

func test_same_id_refreshes_not_stacks() -> void:
    var b := BuffState.new()
    b.add("celestial_fury", 5.0, SkillsDB.buff_mods("celestial_fury", 1.0))
    b.tick(3.0)
    b.add("celestial_fury", 5.0, SkillsDB.buff_mods("celestial_fury", 1.0))
    check_approx(b.multiplier("attack"), 2.0, "renovar não empilha")
    check_approx(b.remaining("celestial_fury"), 5.0, "timer renovado")

func test_different_buffs_stack_additively() -> void:
    var b := BuffState.new()
    b.add("celestial_fury", 5.0, SkillsDB.buff_mods("celestial_fury", 1.0))
    b.add("death_of_hell", 10.0, SkillsDB.buff_mods("death_of_hell", 1.0))
    check_approx(b.multiplier("attack"), 3.0, "1 + 1 (fúria) + 1 (morte do inferno)")

func test_shield_absorb_and_cap() -> void:
    var b := BuffState.new()
    b.add("holy_shield", 3.0, {}, SkillsDB.scaled_absorb("holy_shield", 1.0))
    check_approx(b.absorb(), 0.4, "escudo absorve 40%")
    check_approx(SkillsDB.scaled_absorb("holy_shield", 1.5), 0.6, "brilho +50% => 60%")
    check_approx(SkillsDB.scaled_absorb("holy_shield", 10.0), SkillsDB.ABSORB_CAP, "limitado a 90%")
    b.tick(3.1)
    check_approx(b.absorb(), 0.0, "escudo expira em 3 s")

func test_glow_scales_heal_and_buffs() -> void:
    check_approx(SkillsDB.scaled_heal_pct("wings_of_redemption", 1.0), 0.15, "cura 15%")
    check_approx(SkillsDB.scaled_heal_pct("death_of_hell", 1.5), 0.75, "cura 50% x1.5")
    check_approx(float(SkillsDB.buff_mods("celestial_fury", 1.5)["attack"]), 1.5, "fúria escala com brilho")
    check(SkillsDB.buff_mods("celestial_lance", 1.0).is_empty(), "lança não tem buff")

func test_apocalypse_boss_cap_no_execute() -> void:
    var dmg := SkillsDB.damage("holy_apocalypse", 1000.0, 1.0)
    check_approx(SkillsDB.boss_capped_damage("holy_apocalypse", dmg, 100000.0), 25000.0, "máx. 25% da vida do chefe")
    check_approx(SkillsDB.boss_capped_damage("holy_apocalypse", 100.0, 100000.0), 100.0, "dano baixo passa intacto")
    check_approx(SkillsDB.boss_capped_damage("celestial_lance", 999999.0, 100.0), 999999.0, "outras habilidades sem limite")

func test_skill_effect_params_exist() -> void:
    var need := {
        "holy_shield": ["radius", "damage_absorb"], "rain_of_light": ["projectiles", "radius", "spread_time"],
        "swords_of_paradise": ["swords", "orbit_radius", "hit_radius", "tick"],
        "wings_of_redemption": ["radius", "heal_pct"], "army_of_archangels": ["summons", "ally_tick"],
        "celestial_fury": ["radius", "damage_mult", "attack_speed_mult", "speed_mult"],
        "death_of_hell": ["heal_pct", "all_stats_mult"],
    }
    for id in need.keys():
        for k in need[id]:
            check(SkillsDB.get_skill(id)["effects"].has(k), "%s.effects.%s" % [id, k])
    for id in SkillsDB.ids():
        check(SkillsDB.abbr(id) != "?" and SkillsDB.abbr(id).length() <= 3, "abreviação de " + str(id))
    check(int(SkillsDB.get_skill("army_of_archangels")["effects"]["summons"]) == 3, "3 guerreiros")
    check(float(SkillsDB.get_skill("swords_of_paradise")["duration"]) == 4.0, "espadas 4 s")
    check(float(SkillsDB.get_skill("death_of_hell")["duration"]) == 10.0, "bônus final 10 s")

func test_auto_cast_rules() -> void:
    var none := {"total": 0, "close": 0, "boss": false, "hp_ratio": 1.0}
    for id in SkillsDB.ids():
        check(not AutoCast.should_cast(id, none), "sem inimigos não lança " + str(id))
    var one_far := {"total": 1, "close": 0, "boss": false, "hp_ratio": 1.0}
    check(AutoCast.should_cast("celestial_lance", one_far), "lança com 1 inimigo")
    check(AutoCast.should_cast("divine_judgment", one_far), "julgamento com 1 inimigo")
    check(not AutoCast.should_cast("holy_shield", one_far), "escudo só com inimigo perto")
    check(not AutoCast.should_cast("rain_of_light", one_far), "chuva exige 3+ ou chefe")
    var pack := {"total": 5, "close": 2, "boss": false, "hp_ratio": 1.0}
    check(AutoCast.should_cast("holy_shield", pack), "escudo com inimigos perto")
    check(AutoCast.should_cast("rain_of_light", pack), "chuva com 5 inimigos")
    check(AutoCast.should_cast("wings_of_redemption", pack), "asas com 3+ e perto")
    check(not AutoCast.should_cast("death_of_hell", pack), "suprema espera chefe/8+/vida baixa")
    check(AutoCast.should_cast("death_of_hell", {"total": 8, "close": 0, "boss": false, "hp_ratio": 1.0}), "suprema com 8+")
    check(AutoCast.should_cast("death_of_hell", {"total": 1, "close": 1, "boss": true, "hp_ratio": 1.0}), "suprema com chefe")
    check(AutoCast.should_cast("death_of_hell", {"total": 2, "close": 2, "boss": false, "hp_ratio": 0.3}), "suprema com vida baixa")
    check(AutoCast.should_cast("rain_of_light", {"total": 1, "close": 1, "boss": true, "hp_ratio": 1.0}), "chuva com chefe")

func test_slot_sync_keeps_cooldowns_and_delays_new() -> void:
    var st := SaveData.default_state()
    st["gems"] = 100000
    for id in ["celestial_lance", "holy_shield", "rain_of_light"]:
        Shop.buy_skill(st, id)
    Shop.equip_skill(st, "celestial_lance")
    var slots := SkillSlots.new()
    slots.load_from_state(st)
    check(slots.use("celestial_lance"), "usa a lança")
    slots.tick(3.0)
    Shop.equip_skill(st, "holy_shield")
    slots.sync(st)
    check_approx(slots.remaining("celestial_lance"), 5.0, "recarga da lança preservada (8-3)")
    check_approx(slots.remaining("holy_shield"), SkillsDB.EQUIP_DELAY, "nova habilidade começa com atraso")
    Shop.unequip_skill(st, "celestial_lance")
    slots.sync(st)
    check(not slots.equipped.has("celestial_lance"), "removida dos slots")
    check(slots.equipped.size() == 1, "um slot ocupado")
