extends TestCase
## Fonte pixel, ícones e avatares: tabelas coerentes com os PNGs, e TODO texto do jogo é desenhável.

const FIXED_TEXTS := ["PRÓX. FASE 12", "VELOC. 2X", "EFEITOS: ALTO", "EFEITOS: BAIXO", "MENU", "VOLTAR", "FECHAR", "PERFIL DO ANJO",
    "Nome", "Escolha seu ícone", "Status", "AVISO: CHEFE!", "MINI-CHEFE!", "CHEFE", "MOBS", "MINI-CHEFE", "(repetindo)", "Próx.: Mini-chefe na fase 15 (em 3)",
    "Próx.: Chefe AGORA", "Última fase: 85 s | Gemas/h: 60", "[TESTE] ", "FASE 10", "HP", "AUTO ON", "AUTO OFF", "vazio", "Atributos", "Habilidades", "Asas", "Equipamentos", "Teste", "Opções", "Gráficos", "Som", "MUDO", "MÁXIMO", "MÍNIMO",
    "AUMENTAR", "DIMINUIR", "ALTERAR", "Volume do jogo  80%"]
const FIXED_ICONS := ["coin", "gem", "shard", "menu", "close", "back", "speed", "fx", "next", "user", "skills", "wings", "armor", "gear", "speaker"]

func _font_image() -> Image:
    return Image.load_from_file(ProjectSettings.globalize_path("res://assets/sprites/font.png"))

func test_font_atlas_matches_tables() -> void:
    var chars: String = SpriteManifest.FONT_CHARS
    check(SpriteManifest.FONT_ADV.size() == chars.length(), "um avanço por glifo")
    var img := _font_image()
    check(img != null, "font.png legível")
    if img != null:
        var rows: int = ceili(float(chars.length()) / float(SpriteManifest.FONT_COLS))
        check(img.get_width() == SpriteManifest.FONT_COLS * SpriteManifest.FONT_CW, "largura do atlas")
        check(img.get_height() == rows * SpriteManifest.FONT_CH, "altura do atlas")
    var seen := {}
    for i in range(chars.length()):
        check(not seen.has(chars[i]), "glifo repetido: " + chars[i])
        seen[chars[i]] = true
    for a in SpriteManifest.FONT_ADV:
        check(int(a) >= 3 and int(a) <= 7, "avanço entre 3 e 7 px")

func test_font_has_every_character_portuguese_needs() -> void:
    var chars: String = SpriteManifest.FONT_CHARS
    for ch in "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,:;!?-+*/%()[]|'\"=<>_#&":
        check(chars.contains(ch), "glifo básico: " + ch)
    for ch in "áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÉÈÊÍÓÔÕÚÜÇ":
        check(chars.contains(ch), "glifo com acento: " + ch)

func test_every_glyph_has_pixels() -> void:
    var img := _font_image()
    if img == null:
        return
    var chars: String = SpriteManifest.FONT_CHARS
    for i in range(chars.length()):
        if chars[i] == " ":
            continue
        var ox: int = (i % SpriteManifest.FONT_COLS) * SpriteManifest.FONT_CW
        var oy: int = floori(float(i) / float(SpriteManifest.FONT_COLS)) * SpriteManifest.FONT_CH
        var n := 0
        for y in range(SpriteManifest.FONT_CH):
            for x in range(SpriteManifest.FONT_CW):
                if img.get_pixel(ox + x, oy + y).a > 0.5:
                    n += 1
        check(n >= 2, "glifo '%s' tem pixels" % chars[i])

func test_pixel_font_measure_and_wrap() -> void:
    check(PixelFont.width("", 2) == 0, "texto vazio")
    check(PixelFont.width("Ola mundo", 3) == PixelFont.width("Ola mundo", 1) * 3, "largura proporcional à escala")
    check(PixelFont.width("AB", 2) == 2 * (int(SpriteManifest.FONT_ADV[PixelFont.glyph_index("A")]) + int(SpriteManifest.FONT_ADV[PixelFont.glyph_index("B")])), "soma dos avanços")
    check(PixelFont.glyph_index("@") == PixelFont.glyph_index("?"), "caractere desconhecido vira ?")
    var lines := PixelFont.wrap("uma frase bem comprida para quebrar em varias linhas de texto", 160, 2)
    check(lines.size() > 1, "quebra em várias linhas")
    for l in lines:
        check(PixelFont.width(str(l), 2) <= 160, "linha cabe na largura: " + str(l))
    check(PixelFont.wrap("a\nb", 999, 2).size() == 2, "respeita quebra manual")
    check(PixelFont.wrap("curto", 999, 2).size() == 1, "texto curto = 1 linha")

func test_icon_and_avatar_sheets() -> void:
    var names: Array = SpriteManifest.ICON_NAMES
    check(int(SpriteManifest.DATA["ui_icons"]["frames"]) == names.size(), "um quadro por ícone")
    var seen := {}
    for n in names:
        check(not seen.has(n), "ícone repetido: " + str(n))
        seen[n] = true
    check(int(SpriteManifest.DATA["avatars"]["frames"]) == SpriteManifest.AVATAR_COUNT, "um quadro por avatar")
    check(int(SpriteManifest.DATA["ui_icons"]["fw"]) == 24 and int(SpriteManifest.DATA["avatars"]["fw"]) == 32, "tamanhos 24 e 32")

func _all_states() -> Array:
    var rich := SaveData.default_state()
    rich["gold"] = 1000000000
    rich["gems"] = 1000000000
    rich["shards"] = 100000
    var mid := SaveData.default_state()
    mid["gems"] = 1000
    Shop.buy_skill(mid, "celestial_lance")
    Shop.equip_skill(mid, "celestial_lance")
    Shop.buy_equipment(mid, "sword", 1)
    mid["wings_level"] = 3
    mid["shards"] = 1
    Shop.buy_glow(mid, 1)
    var maxed := SaveData.default_state()
    DebugTools.unlock_all(maxed)
    return [SaveData.default_state(), rich, mid, maxed]

func _collect_texts(rows: Array, out: Array) -> void:
    for r in rows:
        for k in ["title", "sub", "button", "value", "abbr"]:
            if r.has(k):
                out.append(str(r[k]))

func test_every_ui_text_is_drawable_by_the_font() -> void:
    var texts: Array = []
    texts.append_array(FIXED_TEXTS)
    for st in _all_states():
        var stats := StatsCalc.compute(st)
        for t in MenuModel.tabs(true):
            for armed in [false, true]:
                _collect_texts(MenuModel.rows(str(t["id"]), st, stats, {"cooldowns": {"celestial_lance": 2.0}, "reset_armed": armed}), texts)
        _collect_texts(ProfileLogic.stat_rows(st, stats), texts)
        texts.append(UiLogic.total_bonus_text(st))
    for b in EnemiesDB.BOSSES:
        texts.append(str(b["name"]))
    for m in EnemiesDB.MINIS:
        texts.append(str(m["name"]))
    for s in SkillsDB.SKILLS:
        texts.append_array([str(s["name"]), str(s["desc"]), str(s["rarity"]), AutoCast.rule_text(str(s["id"]))])
    var chars: String = SpriteManifest.FONT_CHARS
    var missing := {}
    for t in texts:
        for i in range(str(t).length()):
            var ch: String = str(t)[i]
            if ch != "\n" and not chars.contains(ch):
                missing[ch] = str(t).substr(0, 40)
    for ch in missing.keys():
        check(false, "a fonte não desenha '%s' (ex.: %s)" % [ch, missing[ch]])
    check(texts.size() > 200, "textos coletados: %d" % texts.size())

func test_every_icon_name_used_by_the_ui_exists() -> void:
    var names: Array = SpriteManifest.ICON_NAMES
    var used: Array = []
    used.append_array(FIXED_ICONS)
    for st in _all_states():
        var stats := StatsCalc.compute(st)
        for t in MenuModel.tabs(true):
            used.append(str(t["icon"]))
            for r in MenuModel.rows(str(t["id"]), st, stats, {}):
                for k in ["icon", "cost_icon"]:
                    if r.has(k) and str(r[k]) != "":
                        used.append(str(r[k]))
        for r in ProfileLogic.stat_rows(st, stats):
            used.append(str(r["icon"]))
    for n in used:
        check(names.has(n), "ícone existe no atlas: " + str(n))
