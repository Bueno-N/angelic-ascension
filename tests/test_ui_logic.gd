extends TestCase

func test_fmt_int() -> void:
    check(UiLogic.fmt_int(0) == "0", "zero")
    check(UiLogic.fmt_int(999) == "999", "999")
    check(UiLogic.fmt_int(1000) == "1.000", "mil")
    check(UiLogic.fmt_int(2000000) == "2.000.000", "2 milhões")
    check(UiLogic.fmt_int(-12345) == "-12.345", "negativo")
    check(UiLogic.pct(0.35) == "35%", "pct")

func test_equipment_states() -> void:
    var st := SaveData.default_state()
    check(UiLogic.equipment_state(st, "sword", 1) == "locked", "bloqueado")
    st["gems"] = 1000
    Shop.buy_equipment(st, "sword", 1)
    check(UiLogic.equipment_state(st, "sword", 1) == "equipped", "comprado vira equipado")
    Shop.buy_equipment(st, "sword", 2)
    check(UiLogic.equipment_state(st, "sword", 1) == "owned", "anterior fica 'owned'")
    check(UiLogic.equipment_state(st, "sword", 2) == "equipped", "novo equipado")
    Shop.equip_equipment(st, "sword", 0)
    check(UiLogic.equipment_state(st, "sword", 2) == "owned", "removido volta a 'owned'")

func test_skill_and_glow_states() -> void:
    var st := SaveData.default_state()
    st["gems"] = 100000
    check(UiLogic.skill_state(st, "celestial_lance") == "locked", "habilidade bloqueada")
    Shop.buy_skill(st, "celestial_lance")
    check(UiLogic.skill_state(st, "celestial_lance") == "owned", "comprada")
    Shop.equip_skill(st, "celestial_lance")
    check(UiLogic.skill_state(st, "celestial_lance") == "equipped", "equipada")
    Shop.buy_glow(st, 2)
    check(UiLogic.glow_state(st, 1) == "superseded", "brilho 1 superado")
    check(UiLogic.glow_state(st, 2) == "active", "brilho 2 ativo")
    check(UiLogic.glow_state(st, 3) == "available", "brilho 3 disponível")

func test_next_skill_goal() -> void:
    var st := SaveData.default_state()
    st["gems"] = 30
    var g := UiLogic.next_skill_goal(st)
    check(g["id"] == "celestial_lance" and int(g["missing"]) == 70, "faltam 70 gemas para a 1ª")
    st["gems"] = 5000
    Shop.buy_skill(st, "celestial_lance")
    g = UiLogic.next_skill_goal(st)
    check(g["id"] == "holy_shield" and int(g["missing"]) == 0, "próxima é o Escudo; já dá para comprar")
    st["skills_owned"] = SkillsDB.ids()
    check(UiLogic.next_skill_goal(st).is_empty(), "sem meta quando tudo comprado")

func test_wings_progress() -> void:
    var st := SaveData.default_state()
    var w := UiLogic.wings_progress(st)
    check(int(w["level"]) == 0 and int(w["cost"]) == 2 and not w["ready"], "início: custo 2, não pronto")
    st["shards"] = 1
    check_approx(float(UiLogic.wings_progress(st)["ratio"]), 0.5, "progresso 1/2")
    st["shards"] = 5
    check(UiLogic.wings_progress(st)["ready"], "pronto com fragmentos suficientes")
    st["wings_level"] = WingsDB.MAX_LEVEL
    check(UiLogic.wings_progress(st)["maxed"], "nível máximo")

func test_total_bonus() -> void:
    var st := SaveData.default_state()
    check(UiLogic.total_bonus_pct(st).is_empty(), "sem bônus no início")
    st["wings_level"] = 2
    st["equipped"]["sword"] = 5
    st["equipped"]["armor"] = 3
    var b := UiLogic.total_bonus_pct(st)
    check_approx(float(b["attack"]), 0.6, "ataque 10% asas + 50% espada")
    check_approx(float(b["hp"]), 0.3, "vida 10% + 20%")
    check_approx(float(b["speed"]), 0.1, "velocidade só asas")
    check(UiLogic.total_bonus_text(st).contains("ataque +60%"), "texto contém ataque +60%")

func test_gems_per_hour() -> void:
    check_approx(UiLogic.gems_per_hour(100, 30.0), 0.0, "menos de 60s = 0")
    check_approx(UiLogic.gems_per_hour(50, 1800.0), 100.0, "50 gemas em 30 min = 100/h")
