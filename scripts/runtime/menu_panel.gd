class_name MenuPanel
extends PanelContainer
## Menu com 4 abas: Atributos (ouro), Equipamentos (gemas), Asas/Brilho (fragmentos/gemas), Habilidades (gemas).
## As linhas são criadas UMA vez e só têm texto/estado atualizados (não perde a rolagem do toque).

const TAB_NAMES := ["Atributos", "Equip.", "Asas", "Habilid."]
var _pages: Array = []
var _updaters: Array = []      # por aba: lista de Callables que atualizam os controles
var _tab_buttons: Array = []
var _current := 0
var _dirty := true
var _timer := 0.0

func _ready() -> void:
    anchor_left = 1.0
    anchor_right = 1.0
    anchor_top = 0.0
    anchor_bottom = 1.0
    offset_left = -640.0
    offset_right = -16.0
    offset_top = 96.0
    offset_bottom = -112.0
    visible = false
    var root := VBoxContainer.new()
    add_child(root)
    var tabs := HBoxContainer.new()
    root.add_child(tabs)
    for i in range(TAB_NAMES.size()):
        var tb := Button.new()
        tb.text = TAB_NAMES[i]
        tb.custom_minimum_size = Vector2(0, 60)
        tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        tb.add_theme_font_size_override("font_size", 22)
        tb.pressed.connect(_select_tab.bind(i))
        tabs.add_child(tb)
        _tab_buttons.append(tb)
        var sc := ScrollContainer.new()
        sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
        sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
        root.add_child(sc)
        var box := VBoxContainer.new()
        box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(box)
        _pages.append(sc)
        var upd: Array = []
        _updaters.append(upd)
        match i:
            0: _build_attrs(box, upd)
            1: _build_equip(box, upd)
            2: _build_wings(box, upd)
            _: _build_skills(box, upd)
    Events.state_changed.connect(func(): _dirty = true)
    visibility_changed.connect(func(): _dirty = true)
    _select_tab(0)

func _process(delta: float) -> void:
    if not visible or not _dirty:
        return
    _timer -= delta
    if _timer <= 0.0:
        _timer = 0.2
        _dirty = false
        _refresh()

func _select_tab(i: int) -> void:
    _current = i
    for k in range(_pages.size()):
        _pages[k].visible = (k == i)
        _tab_buttons[k].disabled = (k == i)
    _refresh()

func _refresh() -> void:
    for c in _updaters[_current]:
        c.call()

# ---------- helpers de UI ----------
func _button(font: int, min_h: float) -> Button:
    var b := Button.new()
    b.custom_minimum_size = Vector2(0, min_h)
    b.add_theme_font_size_override("font_size", font)
    b.alignment = HORIZONTAL_ALIGNMENT_LEFT
    b.clip_text = true
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    return b

func _label(text: String, font: int, color: Color) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", font)
    l.add_theme_color_override("font_color", color)
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.custom_minimum_size = Vector2(300, 0)
    l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    return l

func _gems() -> int:
    return int(GameState.state["gems"])

# ---------- aba 0: atributos (ouro) ----------
func _build_attrs(box: VBoxContainer, upd: Array) -> void:
    box.add_child(_label("Melhorias com OURO (valor fixo por nível)", 20, Color(1, 0.9, 0.5)))
    for attr in Balance.ATTRIBUTE_ORDER:
        var b := _button(20, 76)
        b.pressed.connect(GameState.buy_upgrade.bind(attr))
        box.add_child(b)
        upd.append(_upd_attr.bind(b, attr))

func _upd_attr(b: Button, attr: String) -> void:
    var s: Dictionary = GameState.state
    var d: Dictionary = Balance.ATTRIBUTES[attr]
    var lvl: int = Shop.upgrade_level(s, attr)
    var cost: int = StatsCalc.upgrade_cost(attr, lvl)
    var final_val: float = float(GameState.stats[attr])
    b.text = "%s  Nv %d   (atual: %.1f)\n+%s por nível   |   %s ouro" % [d["name"], lvl, final_val, str(d["per_level"]), UiLogic.fmt_int(cost)]
    b.disabled = int(s["gold"]) < cost

# ---------- aba 1: equipamentos (gemas) ----------
func _build_equip(box: VBoxContainer, upd: Array) -> void:
    var summary := _label("", 18, Color(0.9, 0.85, 0.55))
    box.add_child(summary)
    upd.append(_upd_summary.bind(summary))
    for cat in EquipmentDB.CATEGORIES:
        box.add_child(_label(EquipmentDB.ITEMS[cat]["label"], 24, Color(1, 0.9, 0.6)))
        for tier in range(1, EquipmentDB.TIER_COUNT + 1):
            var b := _button(18, 64)
            b.pressed.connect(_on_equip_pressed.bind(cat, tier))
            box.add_child(b)
            upd.append(_upd_equip.bind(b, cat, tier))

func _upd_summary(l: Label) -> void:
    l.text = "Gemas: %s\nBônus totais (asas + equipamentos): %s" % [UiLogic.fmt_int(_gems()), UiLogic.total_bonus_text(GameState.state)]

func _on_equip_pressed(cat: String, tier: int) -> void:
    match UiLogic.equipment_state(GameState.state, cat, tier):
        "locked": GameState.buy_equipment(cat, tier)
        "owned": GameState.equip_equipment(cat, tier)
        _: GameState.equip_equipment(cat, 0)

func _upd_equip(b: Button, cat: String, tier: int) -> void:
    var item := EquipmentDB.get_item(cat, tier)
    var stats_txt: Array = []
    for st in item["stats"]:
        stats_txt.append(UiLogic.STAT_LABELS[st])
    var head := "%s  [%s]\n+%s %s   |   " % [item["name"], item["rarity"], UiLogic.pct(float(item["bonus"])), " e ".join(stats_txt)]
    match UiLogic.equipment_state(GameState.state, cat, tier):
        "locked":
            b.text = head + UiLogic.fmt_int(int(item["price"])) + " gemas"
            b.disabled = _gems() < int(item["price"])
        "owned":
            b.text = head + "Comprado - tocar para equipar"
            b.disabled = false
        _:
            b.text = head + "EQUIPADO - tocar para remover"
            b.disabled = false

# ---------- aba 2: asas e brilho ----------
func _build_wings(box: VBoxContainer, upd: Array) -> void:
    var prev := WingsPreview.new()
    prev.custom_minimum_size = Vector2(0, 190)
    box.add_child(prev)
    upd.append(prev.queue_redraw)
    var info := _label("", 20, Color(0.95, 0.95, 1.0))
    box.add_child(info)
    var bar := ProgressBar.new()
    bar.custom_minimum_size = Vector2(0, 26)
    bar.show_percentage = false
    box.add_child(bar)
    var evolve := _button(22, 64)
    evolve.pressed.connect(GameState.evolve_wings)
    box.add_child(evolve)
    upd.append(_upd_wings.bind(info, bar, evolve))
    box.add_child(_label("Brilho das asas (gemas): aumenta o poder de TODAS as habilidades", 20, Color(1, 0.9, 0.6)))
    for tier in range(1, WingsDB.GLOW.size() + 1):
        var b := _button(18, 60)
        b.pressed.connect(GameState.buy_glow.bind(tier))
        box.add_child(b)
        upd.append(_upd_glow.bind(b, tier))

func _upd_wings(info: Label, bar: ProgressBar, evolve: Button) -> void:
    var w := UiLogic.wings_progress(GameState.state)
    var glow_tier: int = int(GameState.state["glow_tier"])
    var glow_name: String = "nenhum" if glow_tier == 0 else str(WingsDB.GLOW[glow_tier - 1]["name"])
    info.text = "Asas Nv %d/%d  -  +%s em TODOS os atributos\nFragmentos: %d%s\nBrilho atual: %s (+%s nas habilidades)" % [
        w["level"], w["max"], UiLogic.pct(WingsDB.bonus_for_level(int(w["level"]))), w["shards"],
        "" if w["maxed"] else " / %d para o próximo nível" % int(w["cost"]),
        glow_name, UiLogic.pct(WingsDB.glow_bonus(glow_tier))]
    bar.max_value = 1.0
    bar.value = float(w["ratio"])
    if w["maxed"]:
        evolve.text = "Asas no nível máximo"
        evolve.disabled = true
    else:
        evolve.text = "Evoluir asas  (%d fragmentos)" % int(w["cost"])
        evolve.disabled = not w["ready"]

func _upd_glow(b: Button, tier: int) -> void:
    var g: Dictionary = WingsDB.GLOW[tier - 1]
    var head := "%s   +%s habilidades   |   " % [g["name"], UiLogic.pct(float(g["bonus"]))]
    match UiLogic.glow_state(GameState.state, tier):
        "active":
            b.text = head + "ATIVO"
            b.disabled = true
        "superseded":
            b.text = head + "Superado"
            b.disabled = true
        _:
            b.text = head + UiLogic.fmt_int(int(g["price"])) + " gemas"
            b.disabled = _gems() < int(g["price"])

# ---------- aba 3: habilidades (gemas) ----------
func _build_skills(box: VBoxContainer, upd: Array) -> void:
    var head := _label("", 18, Color(0.9, 0.85, 0.55))
    box.add_child(head)
    upd.append(_upd_skill_header.bind(head))
    for s in SkillsDB.SKILLS:
        var id: String = s["id"]
        var b := _button(20, 60)
        b.pressed.connect(_on_skill_pressed.bind(id))
        box.add_child(b)
        var extra := ""
        if float(s["duration"]) > 0.0:
            extra = "  |  Duração: %ds" % int(s["duration"])
        box.add_child(_label("%s\nDano: %d%% do ataque  |  Recarga: %ds%s" % [s["desc"], int(round(float(s["damage_pct"]) * 100.0)), int(s["cooldown"]), extra], 16, Color(0.75, 0.75, 0.8)))
        upd.append(_upd_skill.bind(b, id))

func _upd_skill_header(l: Label) -> void:
    var s: Dictionary = GameState.state
    var goal := UiLogic.next_skill_goal(s)
    var txt := "Gemas: %s   |   Equipadas: %d/%d" % [UiLogic.fmt_int(_gems()), s["skills_equipped"].size(), SkillsDB.MAX_EQUIPPED]
    if goal.is_empty():
        txt += "\nTodas as habilidades desbloqueadas!"
    else:
        txt += "\nPróxima: %s - faltam %s gemas" % [goal["name"], UiLogic.fmt_int(int(goal["missing"]))]
    l.text = txt

func _on_skill_pressed(id: String) -> void:
    match UiLogic.skill_state(GameState.state, id):
        "locked": GameState.buy_skill(id)
        "owned": GameState.equip_skill(id)
        _: GameState.unequip_skill(id)

func _upd_skill(b: Button, id: String) -> void:
    var sk := SkillsDB.get_skill(id)
    var head := "%s  [%s]  -  " % [sk["name"], sk["rarity"]]
    match UiLogic.skill_state(GameState.state, id):
        "locked":
            b.text = head + UiLogic.fmt_int(int(sk["price"])) + " gemas"
            b.disabled = _gems() < int(sk["price"])
        "owned":
            var full: bool = GameState.state["skills_equipped"].size() >= SkillsDB.MAX_EQUIPPED
            b.text = head + ("slots cheios (remova uma)" if full else "tocar para equipar")
            b.disabled = full
        _:
            b.text = head + "EQUIPADA (tocar p/ remover)"
            b.disabled = false
