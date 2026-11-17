extends TestCase
## 300 andares, dificuldade a cada 50, escolha de fase, projeção de ganhos e menu "Fases".

func test_tiers_every_50_stages() -> void:
    check(Balance.MAX_STAGE == 300 and Balance.TIER_SIZE == 50, "300 andares, degraus de 50")
    check(Balance.TIER_NAMES.size() == Balance.MAX_STAGE / Balance.TIER_SIZE, "um nome por degrau")
    check(Balance.TIER_HP_MULT.size() == Balance.TIER_NAMES.size() and Balance.TIER_DMG_MULT.size() == Balance.TIER_NAMES.size()
        and Balance.TIER_REWARD_MULT.size() == Balance.TIER_NAMES.size(), "tabelas do mesmo tamanho")
    check(StageLogic.tier_name(1) == "Fácil" and StageLogic.tier_name(50) == "Fácil", "1-50 Fácil")
    check(StageLogic.tier_name(51) == "Normal" and StageLogic.tier_name(100) == "Normal", "51-100 Normal")
    check(StageLogic.tier_index(101) == 2 and StageLogic.tier_index(300) == 5, "101 = 3º degrau, 300 = último")
    check(StageLogic.tier_index(0) == 0 and StageLogic.tier_index(9999) == 5, "fora da faixa fica nos extremos")
    check(StageLogic.tier_first_stage(1) == 51 and StageLogic.tier_last_stage(5) == 300, "limites dos degraus")
    for t in range(1, Balance.TIER_NAMES.size()):
        check(float(Balance.TIER_HP_MULT[t]) > float(Balance.TIER_HP_MULT[t - 1]), "vida sobe no degrau %d" % t)
        check(float(Balance.TIER_DMG_MULT[t]) > float(Balance.TIER_DMG_MULT[t - 1]), "dano sobe no degrau %d" % t)
        check(float(Balance.TIER_REWARD_MULT[t]) >= float(Balance.TIER_REWARD_MULT[t - 1]), "ganho não cai no degrau %d" % t)
    check_approx(float(Balance.TIER_HP_MULT[0]), 1.0, "degrau Fácil não altera a vida")

func test_difficulty_jumps_at_tier_boundary() -> void:
    var base := 20.0
    var step := StageLogic.enemy_hp(base, 51) / StageLogic.enemy_hp(base, 50)
    var normal := StageLogic.enemy_hp(base, 50) / StageLogic.enemy_hp(base, 49)
    check(step > normal * 1.3, "a vida dá um salto extra ao entrar no degrau Normal")
    check(StageLogic.enemy_dmg(5.0, 51) / StageLogic.enemy_dmg(5.0, 50) > StageLogic.enemy_dmg(5.0, 50) / StageLogic.enemy_dmg(5.0, 49) * 1.1, "dano também")
    check(StageLogic.enemy_gold(10.0, 51) > StageLogic.enemy_gold(10.0, 50), "ganho sobe")

func test_stage_after_clear_caps_at_300() -> void:
    check(StageLogic.stage_after_clear(1) == 2 and StageLogic.stage_after_clear(299) == 300, "avança normalmente")
    check(StageLogic.stage_after_clear(300) == 300, "andar 300 só se repete")
    check(StageLogic.clamp_stage(0) == 1 and StageLogic.clamp_stage(999) == 300, "limites")
    check(not StageLogic.can_skip_to_next(300, 300), "sem próxima fase depois da 300")

func test_can_enter_only_reached_stages() -> void:
    check(StageLogic.can_enter(10, 25, 3), "já alcançada")
    check(StageLogic.can_enter(10, 25, 25), "o recorde também")
    check(not StageLogic.can_enter(10, 25, 26), "não alcançada")
    check(not StageLogic.can_enter(10, 25, 10), "a fase atual não conta")
    check(not StageLogic.can_enter(10, 25, 0) and not StageLogic.can_enter(10, 25, -4), "fase inválida")
    check(not StageLogic.can_enter(10, 999, 301), "não passa de 300")

func test_projection_values() -> void:
    var p1 := StageLogic.projection(1)
    check(int(p1["mobs"]) == 50 and not bool(p1["boss"]) and not bool(p1["mini"]), "fase 1: 50 mobs")
    check_approx(float(p1["gold"]), 50.0 * float(StageLogic.enemy_gold(2.0, 1)), "fase 1: só demônios comuns (2 de ouro cada)")
    check_approx(float(p1["gems"]), 50.0 * Balance.GEM_CHANCE_COMMON, "fase 1: 0,25 gema")
    check(int(p1["shards"]) == 0, "sem fragmento")
    var p5 := StageLogic.projection(5)
    check(bool(p5["mini"]) and int(p5["mobs"]) == 51, "fase 5: mini-chefe no fim (51 mortes)")
    check(float(p5["gems"]) > 1.0, "mini-chefe garante gemas")
    var p10 := StageLogic.projection(10)
    check(bool(p10["boss"]) and int(p10["shards"]) >= 1, "fase 10: chefe dá fragmento")
    check_approx(float(p10["gems"]), 15.0, "chefe 1: média de 10..20")
    check_approx(float(p10["gold"]), float(StageLogic.boss_gold(10)), "ouro do chefe")
    var last := 0.0
    for st in range(1, Balance.MAX_STAGE + 1):
        var p := StageLogic.projection(st)
        check(float(p["gold"]) > 0.0 and float(p["gems"]) >= 0.0, "projeção válida na fase %d" % st)
        if not bool(p["boss"]) and not bool(p["mini"]):
            check(float(p["gold"]) >= 0.0, "ouro >= 0")
        last = float(p["gold"])
    check(StageLogic.projection(300)["boss"] == true, "fase 300 é de chefe")
    check(float(StageLogic.projection(300)["gold"]) > float(StageLogic.projection(10)["gold"]), "ganho cresce com a fase")
    check(last > 0.0, "última projeção calculada")

func test_formatting() -> void:
    check(UiLogic.fmt_short(0.25) == "0,25", "0,25")
    check(UiLogic.fmt_short(15.0) == "15", "inteiro sem casas")
    check(UiLogic.fmt_short(12.5) == "12,5", "12,5")
    check(UiLogic.fmt_short(340.0) == "340", "340")
    check(UiLogic.fmt_short(1234.0) == "1,23K", "1,23K")
    check(UiLogic.fmt_short(4500000.0) == "4,5M", "4,5M")
    check(UiLogic.fmt_short(2.0e12) == "2T", "2T")
    check(UiLogic.fmt_mult(1.5) == "1,5" and UiLogic.fmt_mult(1.0) == "1" and UiLogic.fmt_mult(1.25) == "1,25", "multiplicadores")
    for v in [0.0, 0.001, 9.99, 999.0, 1000.0, 123456789.0, 9.9e15]:
        for ch in UiLogic.fmt_short(v):
            check(SpriteManifest.FONT_CHARS.contains(ch), "a fonte desenha '%s' (%s)" % [ch, str(v)])

func test_stages_menu_rows() -> void:
    var st := SaveData.default_state()
    st["stage"] = 12
    st["max_stage"] = 40
    var rows := MenuModel.rows("stages", st, StatsCalc.compute(st), {})
    check(rows.size() == 1 + Balance.TIER_NAMES.size() * MenuModel.STAGE_ROWS_PER_TIER, "linhas: resumo + 6 degraus (cabeçalho, info, 50 fases)")
    var seen := {}
    for r in rows:
        if r["kind"] == "item":
            seen[str(r["title"]).split("  ")[0]] = true
    check(seen.size() == Balance.MAX_STAGE, "300 fases listadas, cada uma uma vez")
    for n in [1, 12, 40, 41, 50, 51, 150, 299, 300]:
        var i := MenuModel.stage_row_index(n)
        check(i >= 0 and i < rows.size() and str(rows[i]["title"]).begins_with("Fase %d" % n), "índice da fase %d aponta para a linha certa" % n)
    var cur: Dictionary = rows[MenuModel.stage_row_index(12)]
    check(str(cur["button"]) == "ATUAL" and not bool(cur["enabled"]), "fase atual: ATUAL")
    var past: Dictionary = rows[MenuModel.stage_row_index(5)]
    check(str(past["button"]) == "IR" and str(past["action"]) == "stage_go|5" and bool(past["enabled"]), "fase já alcançada: IR")
    var rec: Dictionary = rows[MenuModel.stage_row_index(40)]
    check(str(rec["button"]) == "IR", "o recorde também dá para escolher")
    var locked: Dictionary = rows[MenuModel.stage_row_index(41)]
    check(str(locked["button"]) == "BLOQUEADO" and not bool(locked["enabled"]) and str(locked["action"]) == "", "fase não alcançada: BLOQUEADO")
    check(str(rows[MenuModel.stage_row_index(10)]["title"]).contains("Chefe"), "fase 10 marcada como chefe")
    check(str(rows[MenuModel.stage_row_index(15)]["title"]).contains("Mini-chefe"), "fase 15 marcada como mini-chefe")
    check(str(rows[MenuModel.stage_row_index(10)]["sub"]).contains("Frag."), "chefe mostra fragmentos")
    check(str(rows[MenuModel.stage_row_index(1)]["sub"]).contains("Ouro") and str(rows[MenuModel.stage_row_index(1)]["sub"]).contains("Gemas"), "projeção de ouro e gemas")
    var headers := 0
    for r in rows:
        if r["kind"] == "header":
            headers += 1
    check(headers == Balance.TIER_NAMES.size(), "um cabeçalho por dificuldade")

func test_stage_go_action_validates_only() -> void:
    var st := SaveData.default_state()
    st["stage"] = 12
    st["max_stage"] = 40
    check(MenuModel.perform(st, "stage_go|5"), "andar alcançado é válido")
    check(int(st["stage"]) == 12, "perform não muda a fase (quem muda é o StageManager)")
    check(not MenuModel.perform(st, "stage_go|41"), "não alcançado é recusado")
    check(not MenuModel.perform(st, "stage_go|12"), "a fase atual é recusada")
    check(not MenuModel.perform(st, "stage_go"), "ação incompleta")

func test_save_clamps_stage_range() -> void:
    var s := SaveData.sanitize({"stage": 5000, "max_stage": 9000})
    check(int(s["stage"]) == 300 and int(s["max_stage"]) == 300, "save com fase absurda é limitado a 300")
    var back := SaveData.from_json(SaveData.to_json(s))
    check(int(back["stage"]) == 300, "volta igual")
