extends TestCase
## Próxima fase, modo repetir, velocidade 2x, área segura, paleta do cenário e visuais por tier.

func test_can_skip_to_next_only_to_reached_stage() -> void:
    check(StageLogic.can_skip_to_next(9, 10), "caiu para a 9 (recorde 10): pode ir para a 10")
    check(StageLogic.can_skip_to_next(1, 5), "fase 1 com recorde 5")
    check(not StageLogic.can_skip_to_next(10, 10), "no recorde: não pode pular (precisa limpar)")
    check(not StageLogic.can_skip_to_next(1, 1), "início: não pode pular")

func test_death_drop_then_skip_flow() -> void:
    # Simula a regra: morrer em 10 => fase 9 (repetir) => "Próxima fase" volta a 10 (chefe).
    var stage := 10
    var max_stage := 10
    var back := maxi(1, stage - 1)
    var repeat := back < stage
    check(back == 9 and repeat, "morte volta 1 fase e ativa repetir")
    check(StageLogic.can_skip_to_next(back, max_stage), "botão liberado na fase 9")
    check(StageLogic.is_boss_stage(back + 1), "a próxima é a do chefe")
    var died_on_1 := maxi(1, 1 - 1)
    check(not (died_on_1 < 1), "morte na fase 1 não entra em modo repetir")

func test_speed_setting() -> void:
    var st := SaveData.default_state()
    check_approx(UiLogic.time_scale(st["settings"]), 1.0, "padrão 1x")
    st["settings"]["speed_2x"] = true
    check_approx(UiLogic.time_scale(st["settings"]), Balance.FAST_MODE_SCALE, "2x quando ligado")
    check_approx(Balance.FAST_MODE_SCALE, 2.0, "constante é 2x")
    var back := SaveData.from_json(SaveData.to_json(st))
    check(bool(back["settings"]["speed_2x"]), "velocidade 2x sobrevive ao save")
    var junk := SaveData.sanitize({"settings": {"speed_2x": "x"}})
    check(typeof(junk["settings"]["speed_2x"]) == TYPE_BOOL, "valor sempre booleano")
    check(not bool(SaveData.default_state()["settings"]["speed_2x"]), "padrão desligado")

func test_safe_margins() -> void:
    var z := UiLogic.safe_margins(Vector2.ZERO, Vector2(2000, 1000), Vector2(2000, 1000), Vector2(1280, 640))
    check(z["l"] == 0.0 and z["t"] == 0.0 and z["r"] == 0.0 and z["b"] == 0.0, "tela inteira segura => sem margem")
    var m := UiLogic.safe_margins(Vector2(100, 0), Vector2(1800, 1000), Vector2(2000, 1000), Vector2(1000, 500))
    check_approx(float(m["l"]), 50.0, "notch esquerdo 100 px reais = 50 na viewport")
    check_approx(float(m["r"]), 50.0, "100 px à direita")
    check_approx(float(m["t"]), 0.0, "sem margem em cima")
    var empty := UiLogic.safe_margins(Vector2.ZERO, Vector2.ZERO, Vector2(2000, 1000), Vector2(1000, 500))
    check(empty["l"] == 0.0 and empty["r"] == 0.0, "área segura inválida => sem margem")
    var nowin := UiLogic.safe_margins(Vector2.ZERO, Vector2(100, 100), Vector2.ZERO, Vector2(1000, 500))
    check(nowin["l"] == 0.0 and nowin["b"] == 0.0, "janela inválida => sem margem")

func test_stage_palette_cycles_every_10_stages() -> void:
    check(UiLogic.stage_palette_index(1) == 0 and UiLogic.stage_palette_index(10) == 0, "fases 1-10 = paleta 0")
    check(UiLogic.stage_palette_index(11) == 1 and UiLogic.stage_palette_index(20) == 1, "11-20 = paleta 1")
    check(UiLogic.stage_palette_index(31) == 3, "31-40 = paleta 3")
    check(UiLogic.stage_palette_index(41) == 0, "ciclo recomeça na 41")
    for st in range(1, 300):
        var i := UiLogic.stage_palette_index(st)
        check(i >= 0 and i < Backdrop.PALETTES.size(), "índice válido na fase %d" % st)

func test_visual_tier_tables_match_data() -> void:
    check(AngelDraw.TIER_COLORS.size() == EquipmentDB.TIER_COUNT, "uma cor por tier de equipamento")
    check(AngelDraw.tier_color(0) == AngelDraw.TIER_COLORS[0], "tier 0 limitado ao primeiro")
    check(AngelDraw.tier_color(99) == AngelDraw.TIER_COLORS[EquipmentDB.TIER_COUNT - 1], "tier alto limitado ao último")
    check(Backdrop.PALETTES.size() == 4, "4 paletas de cenário")
