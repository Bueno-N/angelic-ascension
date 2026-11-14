extends TestCase

func test_fx_setting_default_and_toggle() -> void:
    var st := SaveData.default_state()
    check(UiLogic.fx_enabled(st["settings"]), "efeitos altos por padrão")
    check(UiLogic.fx_cap(st["settings"]) == Balance.FX_CAP_NORMAL, "teto normal")
    st["settings"]["low_fx"] = true
    check(not UiLogic.fx_enabled(st["settings"]), "efeitos baixos")
    check(UiLogic.fx_cap(st["settings"]) == Balance.FX_CAP_LOW, "teto reduzido")

func test_fx_setting_persists_and_survives_junk() -> void:
    var st := SaveData.default_state()
    st["settings"]["low_fx"] = true
    var back := SaveData.from_json(SaveData.to_json(st))
    check(bool(back["settings"]["low_fx"]), "sobrevive ao save")
    var junk := SaveData.sanitize({"settings": {"low_fx": "x"}})
    check(typeof(junk["settings"]["low_fx"]) == TYPE_BOOL and not junk["settings"]["low_fx"], "lixo vira falso")
    check(not bool(SaveData.default_state()["settings"]["low_fx"]), "padrão desligado")

func test_performance_constants_are_sane() -> void:
    check(Balance.MAX_FPS >= 30 and Balance.MAX_FPS <= 120, "FPS máximo razoável")
    check(Balance.AUTO_CHECK_INTERVAL >= 0.05 and Balance.AUTO_CHECK_INTERVAL <= 0.5, "auto-cast responsivo (<=0,5 s)")
    check(Balance.FX_CAP_LOW < Balance.FX_CAP_NORMAL and Balance.FX_CAP_LOW > 0, "teto baixo < teto normal")
    check(Balance.UI_REDRAW_INTERVAL > 0.0 and Balance.UI_REDRAW_INTERVAL <= 0.1, "barra de habilidades >= 10 fps")
    check(Balance.ALIVE_MAX <= 40, "inimigos simultâneos limitados (custo por frame)")
