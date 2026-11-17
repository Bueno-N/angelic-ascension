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

func test_map_nodes_and_kinds() -> void:
    check(MapLogic.node_kind(10) == "boss" and MapLogic.node_kind(300) == "boss", "chefes: caveira")
    check(MapLogic.node_kind(5) == "mini" and MapLogic.node_kind(295) == "mini", "mini-chefes: espada")
    check(MapLogic.node_kind(1) == "normal" and MapLogic.node_kind(11) == "normal", "demais: bolinha")
    var bosses := 0
    for st in range(1, Balance.MAX_STAGE + 1):
        if MapLogic.node_kind(st) == "boss":
            bosses += 1
    check(bosses == 30, "30 chefes no mapa (de 10 em 10)")
    check(MapLogic.node_radius("boss") > MapLogic.node_radius("mini") and MapLogic.node_radius("mini") > MapLogic.node_radius("normal"), "chefe é o maior nó")
    var prev := -1.0
    for st in range(1, Balance.MAX_STAGE + 1):
        var p := MapLogic.node_pos(st, 72.0, 520.0)
        check(p.x > prev, "x cresce (fase %d)" % st)
        check(p.y > 72.0 and p.y < 72.0 + 520.0, "nó dentro da área do mapa (fase %d)" % st)
        prev = p.x
    check_approx(MapLogic.total_width(), MapLogic.X0 * 2.0 + 299.0 * MapLogic.SPACING, "largura total do mapa")
    check(MapLogic.node_pos(300, 72.0, 520.0).x < MapLogic.total_width(), "a fase 300 cabe no mapa")
    check(MapLogic.SPACING >= float(PixelFont.width("Fase 300", 2)), "o rótulo 'Fase N' cabe entre dois nós")

func test_map_background_gets_redder_with_difficulty() -> void:
    check(MapLogic.TIER_BG.size() == Balance.TIER_NAMES.size(), "uma cor por dificuldade")
    var prev := -10.0
    for t in range(MapLogic.TIER_BG.size()):
        var c: Color = MapLogic.TIER_BG[t]
        var redness: float = c.r - (c.g + c.b) / 2.0
        check(redness > prev, "degrau %d é mais vermelho que o anterior" % t)
        prev = redness
    var easy := MapLogic.bg_color(1.0)
    var hard := MapLogic.bg_color(300.0)
    check(hard.r > easy.r and hard.b < easy.b, "fase 300 mais vermelha e menos azul que a 1")
    var last := -10.0
    for st in range(1, 301, 7):
        var c2 := MapLogic.bg_color(float(st))
        var red2: float = c2.r - (c2.g + c2.b) / 2.0
        check(red2 >= last - 0.0001, "o fundo nunca fica menos vermelho ao avançar (fase %d)" % st)
        last = red2
    check(MapLogic.bg_color(25.0).is_equal_approx(MapLogic.TIER_BG[0]), "meio do degrau 1 = cor pura")
    check(MapLogic.bg_color(75.0).is_equal_approx(MapLogic.TIER_BG[1]), "meio do degrau 2 = cor pura")
    check(MapLogic.bg_color(-5.0).is_equal_approx(MapLogic.TIER_BG[0]) and MapLogic.bg_color(9999.0).is_equal_approx(MapLogic.TIER_BG[5]), "fora da faixa")
    check(MapLogic.tier_accent(5).r > MapLogic.tier_accent(0).r and MapLogic.tier_accent(5).b < MapLogic.tier_accent(0).b, "destaque também esquenta")

func test_map_hit_test() -> void:
    var top := 72.0
    var mh := 520.0
    for st in [1, 12, 100, 299, 300]:
        var p := MapLogic.node_pos(st, top, mh)
        check(MapLogic.hit(p, top, mh, 46.0) == st, "toque no centro da fase %d" % st)
        check(MapLogic.hit(p + Vector2(20.0, -15.0), top, mh, 46.0) == st, "toque perto da fase %d" % st)
    check(MapLogic.hit(Vector2(MapLogic.node_x(10) + 60.0, top + 5.0), top, mh, 20.0) == 0, "toque no vazio não seleciona")
    check(MapLogic.hit(Vector2(-500.0, 300.0), top, mh, 46.0) == 0, "fora do mapa")

func test_map_scroll_centering() -> void:
    check_approx(MapLogic.scroll_for(1, 1280.0), 0.0, "fase 1 não rola para a esquerda")
    check_approx(MapLogic.scroll_for(300, 1280.0), MapLogic.total_width() - 1280.0, "fase 300 encosta no fim")
    check_approx(MapLogic.scroll_for(50, 1280.0), MapLogic.node_x(50) - 640.0, "fase do meio centralizada")

func test_map_info_panel() -> void:
    var cur := MapLogic.info(12, 12, 40)
    check(str(cur["state"]) == "current" and str(cur["button"]) == "FASE ATUAL" and not bool(cur["enabled"]), "fase atual")
    var go := MapLogic.info(5, 12, 40)
    check(str(go["state"]) == "go" and str(go["button"]) == "IR PARA A FASE" and bool(go["enabled"]), "fase alcançada: pode ir")
    var rec := MapLogic.info(40, 12, 40)
    check(bool(rec["enabled"]), "o recorde também")
    var locked := MapLogic.info(41, 12, 40)
    check(str(locked["state"]) == "locked" and str(locked["button"]) == "BLOQUEADA" and not bool(locked["enabled"]), "fase não alcançada")
    var boss := MapLogic.info(10, 1, 1)
    check(str(boss["title"]) == "Fase 10 - Chefe" and str(boss["line1"]).begins_with("Chefe: ") and str(boss["line2"]).contains("Frag."), "chefe: nome e fragmentos")
    var mini := MapLogic.info(15, 1, 1)
    check(str(mini["title"]).contains("Mini-chefe") and str(mini["line1"]).contains("mobs"), "mini-chefe")
    var norm := MapLogic.info(1, 1, 1)
    check(str(norm["line1"]) == "50 mobs" and str(norm["line2"]).contains("Ouro") and str(norm["line2"]).contains("Gemas"), "projeção de ouro e gemas")
    check(str(MapLogic.info(51, 1, 1)["tag"]) == "Dificuldade: Normal", "dificuldade do degrau")
    var chars: String = SpriteManifest.FONT_CHARS
    for st in range(1, Balance.MAX_STAGE + 1):
        var inf := MapLogic.info(st, 1, 300)
        for k in ["title", "tag", "line1", "line2", "button"]:
            for ch in str(inf[k]):
                check(chars.contains(ch), "a fonte desenha '%s' (fase %d, %s)" % [ch, st, k])

func test_save_clamps_stage_range() -> void:
    var s := SaveData.sanitize({"stage": 5000, "max_stage": 9000})
    check(int(s["stage"]) == 300 and int(s["max_stage"]) == 300, "save com fase absurda é limitado a 300")
    var back := SaveData.from_json(SaveData.to_json(s))
    check(int(back["stage"]) == 300, "volta igual")
