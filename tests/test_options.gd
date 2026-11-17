extends TestCase
## Aba Opções: volume, gráficos alto/baixo, persistência e regra de pausa.

func test_defaults() -> void:
    var st := SaveData.default_state()
    check(OptionsLogic.volume(st["settings"]) == OptionsLogic.DEFAULT_VOLUME, "volume padrão")
    check_approx(OptionsLogic.volume_linear(st["settings"]), 0.8, "linear 0,8")
    check(UiLogic.fx_enabled(st["settings"]), "gráficos altos por padrão")

func test_volume_steps_and_limits() -> void:
    var s := {"volume": 95}
    check(OptionsLogic.step_volume(s, 10) == 100, "teto em 100")
    s["volume"] = 5
    check(OptionsLogic.step_volume(s, -10) == 0, "piso em 0")
    check(OptionsLogic.volume({"volume": 500}) == 100 and OptionsLogic.volume({"volume": -3}) == 0, "valores fora da faixa")
    check(OptionsLogic.volume({}) == OptionsLogic.DEFAULT_VOLUME, "ausente = padrão")
    check(OptionsLogic.volume_db({"volume": 0}) <= -80.0, "0 = mudo")
    check_approx(OptionsLogic.volume_db({"volume": 100}), 0.0, "100 = 0 dB")

func test_apply_actions() -> void:
    var st := SaveData.default_state()
    check(MenuModel.perform(st, "opt|vol|-10"), "diminuir muda")
    check(OptionsLogic.volume(st["settings"]) == 70, "80 -> 70")
    check(MenuModel.perform(st, "opt|vol|10") and OptionsLogic.volume(st["settings"]) == 80, "aumentar volta a 80")
    st["settings"]["volume"] = 100
    check(not MenuModel.perform(st, "opt|vol|10"), "no máximo não muda")
    check(MenuModel.perform(st, "opt|fx|0") and not UiLogic.fx_enabled(st["settings"]), "efeitos -> baixo")
    check(MenuModel.perform(st, "opt|fx|0") and UiLogic.fx_enabled(st["settings"]), "efeitos -> alto")
    check(not MenuModel.perform(st, "opt"), "ação incompleta é ignorada")
    check(not MenuModel.perform(st, "opt|nada|1"), "ação desconhecida é ignorada")

func test_rows() -> void:
    var st := SaveData.default_state()
    var rows := MenuModel.rows("options", st, StatsCalc.compute(st), {})
    var actions := []
    for r in rows:
        if r["kind"] == "item":
            actions.append(str(r["action"]))
    check(actions.has("opt|fx|0") and actions.has("opt|vol|10") and actions.has("opt|vol|-10"), "ações de efeitos e volume")
    check(actions.has("opt|title|0"), "no jogo: voltar ao menu inicial")
    var title_rows := MenuModel.rows("options", st, StatsCalc.compute(st), {"in_game": false})
    var title_has := false
    for r in title_rows:
        if r["kind"] == "item" and str(r["action"]) == "opt|title|0":
            title_has = true
    check(not title_has, "no menu inicial não há 'voltar ao menu inicial'")
    st["settings"]["volume"] = 0
    var r0 := MenuModel.rows("options", st, StatsCalc.compute(st), {})
    var dim_enabled := true
    for r in r0:
        if r["kind"] == "item" and str(r["action"]) == "opt|vol|-10":
            dim_enabled = bool(r["enabled"])
    check(not dim_enabled, "diminuir desabilitado no mudo")

func test_save_roundtrip_and_junk() -> void:
    var st := SaveData.default_state()
    st["settings"]["volume"] = 30
    var back := SaveData.from_json(SaveData.to_json(st))
    check(OptionsLogic.volume(back["settings"]) == 30, "volume sobrevive ao save")
    var junk := SaveData.sanitize({"settings": {"volume": "x"}})
    check(typeof(junk["settings"]["volume"]) == TYPE_INT, "volume sempre inteiro")
    check(SaveData.sanitize({"settings": {"volume": 999}})["settings"]["volume"] == 100, "limita a 100")
    check(SaveData.sanitize({"gold": 5})["settings"]["volume"] == OptionsLogic.DEFAULT_VOLUME, "save antigo sem volume = padrão")

func test_pause_rule() -> void:
    check(not OptionsLogic.should_pause(false), "perfil fechado: o jogo roda (inclusive com o menu aberto)")
    check(OptionsLogic.should_pause(true), "perfil aberto: pausa")
    check(OptionsLogic.should_pause(false, true), "tela de morte: pausa")
    check(not OptionsLogic.should_pause(false, false), "sem perfil nem morte: não pausa")
