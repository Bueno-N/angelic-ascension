class_name MenuPanel
extends PanelContainer
## Menu com 4 abas: Atributos (ouro), Equipamentos (gemas), Asas/Brilho (fragmentos/gemas), Habilidades (gemas).
## As linhas são criadas UMA vez e só têm texto/estado atualizados (não perde a rolagem do toque).

const TAB_NAMES := ["Atributos", "Equip.", "Asas", "Habilid.", "Auto"]
const TAB_SKILLS := 3
var _tab_names: Array = []
var _reset_armed := false
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
    _tab_names = TAB_NAMES.duplicate()
    if DebugTools.enabled():
        _tab_names.append("Teste")
    var root := VBoxContainer.new()
    add_child(root)
    var tabs := HBoxContainer.new()
    root.add_child(tabs)
    for i in range(_tab_names.size()):
        var tb := Button.new()
        tb.text = _tab_names[i]
        tb.custom_minimum_size = Vector2(0, 60)
        tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        tb.add_theme_font_size_override("font_size", 18)
        tb.pressed.connect(_select_tab.bind(i))
        tabs.add_child(tb)
        _tab_buttons.append(tb)
        var sc := ScrollContainer.new()
        sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
        sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
        sc.scroll_deadzone = 12                                   # tolerância: toque curto = clique, arrasto = rolagem
        sc.get_v_scroll_bar().custom_minimum_size = Vector2(28, 0)  # barra larga e arrastável com o dedo
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
            3: _build_skills(box, upd)
            4: _build_auto(box, upd)
            _: _build_debug(box, upd)
    var nav := HBoxContainer.new()
    root.add_child(nav)
    for pair in [["Topo", -2], ["Subir", -1], ["Descer", 1]]:
        var nb := Button.new()
        nb.text = pair[0]
        nb.custom_minimum_size = Vector2(0, 52)
        nb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        nb.add_theme_font_size_override("font_size", 20)
        nb.pressed.connect(_scroll.bind(pair[1]))
        nav.add_child(nb)
    Events.state_changed.connect(func(): _dirty = true)
    visibility_changed.connect(func(): _dirty = true)
    _select_tab(0)

func _process(delta: float) -> void:
    if not visible:
        return
    if not _dirty and _current != TAB_SKILLS:
        return
    _timer -= delta
    if _timer <= 0.0:
        _timer = 0.2
        _dirty = false
        _refresh()

func _scroll(mode: int) -> void:
    var sc: ScrollContainer = _pages[_current]
    if mode == -2:
        sc.scroll_vertical = 0
    else:
        sc.scroll_vertical = maxi(0, sc.scroll_vertical + mode * int(sc.size.y * 0.8))

func _select_tab(i: int) -> void:
    _current = i
    _pages[i].scroll_vertical = 0
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
    b.mouse_filter = Control.MOUSE_FILTER_PASS   # deixa o arrasto chegar ao ScrollContainer (rolagem por toque)
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
    prev.mouse_filter = Control.MOUSE_FILTER_PASS
    box.add_child(prev)
    upd.append(prev.queue_redraw)
    var info := _label("", 20, Color(0.95, 0.95, 1.0))
    box.add_child(info)
    var bar := ProgressBar.new()
    bar.custom_minimum_size = Vector2(0, 26)
    bar.show_percentage = false
    bar.mouse_filter = Control.MOUSE_FILTER_PASS
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
    txt += "\nSó dá para remover/trocar uma habilidade que NÃO está em recarga."
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
            var rem: float = GameState.skill_remaining(id)
            if rem > 0.0:
                b.text = head + "EM RECARGA %ds (não pode trocar)" % int(ceil(rem))
                b.disabled = true
            else:
                b.text = head + "EQUIPADA (tocar p/ remover)"
                b.disabled = false

# ---------- aba 4: habilidades automáticas por slot ----------
func _build_auto(box: VBoxContainer, upd: Array) -> void:
    box.add_child(_label("Escolha quais slots lançam sozinhos. AUTOMÁTICA: a habilidade é lançada quando a situação pede (regra abaixo). MANUAL: só ao tocar no botão (ou teclas 1, 2, 3).", 17, Color(0.75, 0.75, 0.8)))
    for i in range(SkillsDB.MAX_EQUIPPED):
        var b := _button(20, 84)
        b.pressed.connect(GameState.toggle_slot_auto.bind(i))
        box.add_child(b)
        upd.append(_upd_auto_slot.bind(b, i))
    var all_on := _button(20, 60)
    all_on.text = "Todas automáticas"
    all_on.pressed.connect(GameState.set_all_auto.bind(true))
    box.add_child(all_on)
    var all_off := _button(20, 60)
    all_off.text = "Todas manuais"
    all_off.pressed.connect(GameState.set_all_auto.bind(false))
    box.add_child(all_off)

func _upd_auto_slot(b: Button, i: int) -> void:
    var eq: Array = GameState.state["skills_equipped"]
    var nm := "vazio"
    var rule := "Equipe uma habilidade na aba Habilid."
    if i < eq.size():
        nm = str(SkillsDB.get_skill(eq[i])["name"])
        rule = AutoCast.rule_text(eq[i])
    var on: bool = AutoCast.slot_auto(GameState.state["settings"], i)
    b.text = "Slot %d: %s   -   %s\n%s" % [i + 1, nm, "AUTOMÁTICA" if on else "MANUAL", rule if on else "Toque para tornar automática"]

# ---------- aba de teste (só aparece em builds de debug) ----------
const DEBUG_BUTTONS := [
    ["+1.000 ouro", "gold", 1000], ["+100.000 ouro", "gold", 100000],
    ["+1.000 gemas", "gems", 1000], ["+100.000 gemas", "gems", 100000], ["+2.000.000 gemas", "gems", 2000000],
    ["+10 fragmentos de asa", "shards", 10], ["+100 fragmentos de asa", "shards", 100],
    ["Ir para a fase 9 (o chefe é o próximo)", "stage", 9], ["Ir para a fase 10 (chefe)", "stage", 10],
    ["Fase +10", "stage_add", 10],
    ["Curar totalmente", "heal", 0], ["Zerar recargas das habilidades", "cooldowns", 0],
    ["Desbloquear tudo (itens, asas, brilho, habilidades)", "unlock_all", 0],
]

func _build_debug(box: VBoxContainer, upd: Array) -> void:
    box.add_child(_label("MODO DE TESTE (só existe em builds de debug). As alterações são salvas no progresso: use o reset no fim.", 18, Color(1.0, 0.6, 0.5)))
    for d in DEBUG_BUTTONS:
        var b := _button(20, 56)
        b.text = d[0]
        b.pressed.connect(_on_debug.bind(d[1], d[2]))
        box.add_child(b)
    var rb := _button(20, 56)
    rb.pressed.connect(_on_debug_reset)
    box.add_child(rb)
    upd.append(_upd_reset.bind(rb))

func _on_debug(action: String, arg: int) -> void:
    _reset_armed = false
    GameState.debug_apply(action, arg)
    _refresh()

func _on_debug_reset() -> void:
    if not _reset_armed:
        _reset_armed = true
    else:
        _reset_armed = false
        GameState.debug_apply("reset", 0)
    _refresh()

func _upd_reset(b: Button) -> void:
    b.text = "TOQUE DE NOVO PARA CONFIRMAR O RESET" if _reset_armed else "Resetar progresso (2 toques)"
