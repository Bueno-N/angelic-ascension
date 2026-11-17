class_name TitleScreen
extends Control
## Menu inicial: INICIAR JOGO (novo jogo / carregar jogo salvo, máx. 2 jogos), CONFIGURAÇÕES e SAIR.
## Novo jogo exige escolher um nome. Tudo por controles próprios (UiButton / UiList). Nada aqui pausa nem usa Button padrão.

var _mode := "main"            # main | start | slots | name | settings
var _slot_mode := "new"        # new | load
var _armed := ""               # "del:1", "over:2": toque de confirmação pendente
var _pending_slot := 0
var _sums: Array = []
var _backdrop: Backdrop
var _angel: AngelSprite
var _b_start: UiButton
var _b_settings: UiButton
var _b_quit: UiButton
var _b_new: UiButton
var _b_load: UiButton
var _b_back_start: UiButton
var _slot_btn: Array = []
var _del_btn: Array = []
var _b_back_slots: UiButton
var _name_edit: LineEdit
var _b_go: UiButton
var _b_back_name: UiButton
var _list: UiList
var _b_back_set: UiButton
var _smoke := false
var _frames := 0
var _smoke_ok := true

func _ready() -> void:
    _smoke = OS.get_cmdline_user_args().has("--smoke")
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    RenderingServer.set_default_clear_color(Color(0.05, 0.03, 0.08))
    _backdrop = Backdrop.new()
    add_child(_backdrop)
    _backdrop.set_fx(UiLogic.fx_enabled(GameState.global_settings))
    AudioHub.play_music(AudioLogic.TITLE_TRACK)
    _angel = AngelSprite.new()
    _angel.scale = Vector2(2.6, 2.6)
    _angel.set_look(7, 4, {"boots": 3, "armor": 3, "gloves": 3, "sword": 3})
    add_child(_angel)
    _b_start = _mk("INICIAR JOGO", "next", func(): _show("start"), 3)
    _b_settings = _mk("CONFIGURAÇÕES", "gear", func(): _show("settings"), 3)
    _b_quit = _mk("SAIR", "close", func(): get_tree().quit(), 3, UiTheme.RED)
    _b_new = _mk("NOVO JOGO", "sword", func(): _open_slots("new"), 3)
    _b_load = _mk("CARREGAR JOGO", "user", func(): _open_slots("load"), 3)
    _b_back_start = _mk("VOLTAR", "back", func(): _show("main"), 3)
    for i in range(SlotLogic.MAX_SLOTS):
        _slot_btn.append(_mk("", "", _on_slot.bind(i + 1), 2))
        _del_btn.append(_mk("APAGAR", "", _on_delete.bind(i + 1), 2, UiTheme.RED))
    _b_back_slots = _mk("VOLTAR", "back", func(): _show("start"), 3)
    _name_edit = LineEdit.new()
    _name_edit.max_length = ProfileLogic.MAX_NAME
    _name_edit.placeholder_text = "Seu nome"
    _name_edit.add_theme_font_size_override("font_size", 30)
    _name_edit.text_changed.connect(func(_t: String): _update_go())
    _name_edit.text_submitted.connect(func(_t: String): _start_new())
    add_child(_name_edit)
    _b_go = _mk("COMEÇAR", "next", _start_new, 3)
    _b_back_name = _mk("VOLTAR", "back", func(): _show("slots"), 3)
    _list = UiList.new()
    _list.action.connect(_on_setting_action)
    add_child(_list)
    _b_back_set = _mk("VOLTAR", "back", func(): _show("main"), 3)
    resized.connect(_layout)
    _show("main")

func _mk(t: String, ic: String, cb: Callable, fs: int = 2, acc: Color = UiTheme.GOLD) -> UiButton:
    var b := UiButton.new()
    b.configure(t, ic, acc)
    b.font_scale = fs
    b.pressed.connect(cb)
    add_child(b)
    return b

# ---------------------------------------------------------------- navegação
func _show(mode: String) -> void:
    _mode = mode
    _armed = ""
    if mode == "slots":
        _sums = SaveManager.summaries()
    elif mode == "name":
        _name_edit.text = ""
        if not _smoke:
            _name_edit.grab_focus.call_deferred()
    elif mode == "settings":
        _refresh_settings()
    _layout()

func _open_slots(m: String) -> void:
    _slot_mode = m
    _show("slots")

func _on_slot(n: int) -> void:
    var s: Dictionary = _sums[n - 1]
    if _slot_mode == "load":
        if bool(s["exists"]) and GameState.load_game(n):
            _enter_game()
        return
    if bool(s["exists"]) and _armed != "over:%d" % n:
        _armed = "over:%d" % n          # espaço ocupado: pede um segundo toque para sobrescrever
        _layout()
        return
    _pending_slot = n
    _show("name")

func _on_delete(n: int) -> void:
    if _armed != "del:%d" % n:
        _armed = "del:%d" % n
    else:
        SaveManager.delete_slot(n)
        _sums = SaveManager.summaries()
        _armed = ""
    _layout()

func _update_go() -> void:
    _b_go.set_enabled(SlotLogic.name_valid(_name_edit.text))

func _start_new() -> void:
    if _mode != "name" or not SlotLogic.name_valid(_name_edit.text):
        return
    if GameState.new_game(_pending_slot, SlotLogic.clean_new_name(_name_edit.text)):
        _enter_game()

func _enter_game() -> void:
    get_tree().change_scene_to_file.call_deferred(GameState.GAME_SCENE)

func _refresh_settings() -> void:
    var rows := MenuModel.rows("options", {"settings": GameState.global_settings}, {}, {"in_game": false})
    _list.scroll_to_top()
    _list.set_rows(rows)

func _on_setting_action(id: String) -> void:
    GameState.set_global_option(id.split("|"))
    _backdrop.set_fx(UiLogic.fx_enabled(GameState.global_settings))
    _refresh_settings()

# ---------------------------------------------------------------- layout
func _card_rect(i: int) -> Rect2:
    var cw: float = minf(size.x - 60.0, 1000.0)
    return Rect2((size.x - cw) / 2.0, 150.0 + float(i) * 150.0, cw, 130.0)

func _layout() -> void:
    if _list == null:
        return
    var w: float = size.x
    var h: float = size.y
    var cx: float = w / 2.0
    for b in [_b_start, _b_settings, _b_quit, _b_new, _b_load, _b_back_start, _b_back_slots, _b_go, _b_back_name, _b_back_set]:
        b.visible = false
    for b in _slot_btn + _del_btn:
        b.visible = false
    _name_edit.visible = _mode == "name"
    _list.visible = _mode == "settings"
    _angel.visible = _mode == "main" or _mode == "start"
    _angel.position = Vector2(w - 190.0, h * 0.58)
    match _mode:
        "main":
            _place(_b_start, cx - 190.0, 260.0, 380.0, 84.0)
            _place(_b_settings, cx - 190.0, 360.0, 380.0, 84.0)
            _place(_b_quit, cx - 190.0, 460.0, 380.0, 84.0)
        "start":
            _place(_b_new, cx - 190.0, 240.0, 380.0, 84.0)
            _place(_b_load, cx - 190.0, 340.0, 380.0, 84.0)
            _place(_b_back_start, cx - 190.0, 470.0, 380.0, 70.0)
        "slots":
            for i in range(SlotLogic.MAX_SLOTS):
                var r := _card_rect(i)
                var s: Dictionary = _sums[i] if i < _sums.size() else SlotLogic.summary(i + 1, {})
                var occ: bool = bool(s["exists"])
                var sb: UiButton = _slot_btn[i]
                var db: UiButton = _del_btn[i]
                _place(sb, r.position.x + r.size.x - 400.0, r.position.y + 20.0, 230.0, 90.0)
                _place(db, r.position.x + r.size.x - 156.0, r.position.y + 20.0, 140.0, 90.0)
                db.visible = occ
                if _slot_mode == "load":
                    sb.set_text("CONTINUAR" if occ else "VAZIO")
                    sb.set_enabled(occ)
                else:
                    sb.set_text(("CONFIRMAR" if _armed == "over:%d" % (i + 1) else "SOBRESCREVER") if occ else "ESCOLHER")
                    sb.set_enabled(true)
                db.set_text("CONFIRMAR" if _armed == "del:%d" % (i + 1) else "APAGAR")
            _place(_b_back_slots, cx - 190.0, 150.0 + 2.0 * 150.0 + 10.0, 380.0, 70.0)
        "name":
            _name_edit.position = Vector2(cx - 300.0, 250.0)
            _name_edit.size = Vector2(600.0, 70.0)
            _place(_b_go, cx - 300.0, 350.0, 290.0, 84.0)
            _place(_b_back_name, cx + 10.0, 350.0, 290.0, 84.0)
            _update_go()
        "settings":
            _list.position = Vector2(cx - 350.0, 110.0)
            _list.size = Vector2(700.0, maxf(120.0, h - 110.0 - 110.0))
            _place(_b_back_set, cx - 190.0, h - 90.0, 380.0, 70.0)
    queue_redraw()

func _place(b: UiButton, x: float, y: float, bw: float, bh: float) -> void:
    b.position = Vector2(x, y)
    b.size = Vector2(bw, bh)
    b.visible = true

# ---------------------------------------------------------------- desenho
func _center_text(t: String, y: float, scale: int, col: Color) -> void:
    PixelFont.draw(self, Vector2((size.x - float(PixelFont.width(t, scale))) / 2.0, y), t, scale, col)

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.01, 0.05, 0.35))
    match _mode:
        "main":
            _center_text("ANGELIC", 50.0, 9, UiTheme.GOLD)
            _center_text("ASCENSION", 135.0, 9, Color(1.0, 0.95, 0.8))
            _center_text("Um anjo guerreiro contra o inferno", 215.0, 2, UiTheme.TEXT_DIM)
        "start":
            _center_text("INICIAR JOGO", 110.0, 5, UiTheme.GOLD)
            _center_text("Máximo de %d jogos salvos por conta" % SlotLogic.MAX_SLOTS, 180.0, 2, UiTheme.TEXT_DIM)
        "slots":
            _center_text("NOVO JOGO" if _slot_mode == "new" else "CARREGAR JOGO", 50.0, 5, UiTheme.GOLD)
            _center_text("Escolha um espaço", 104.0, 2, UiTheme.TEXT_DIM)
            for i in range(SlotLogic.MAX_SLOTS):
                var s: Dictionary = _sums[i] if i < _sums.size() else SlotLogic.summary(i + 1, {})
                var r := _card_rect(i)
                var occ: bool = bool(s["exists"])
                UiTheme.panel(self, r, UiTheme.BG, UiTheme.GOLD if occ else UiTheme.GOLD_D)
                PixelFont.draw(self, Vector2(r.position.x + 20.0, r.position.y + 14.0), "ESPAÇO %d" % (i + 1), 2, UiTheme.TEXT_DIM)
                if occ:
                    UiIcons.draw_avatar(self, int(s["avatar"]), Rect2(r.position.x + 20.0, r.position.y + 40.0, 72.0, 72.0))
                    PixelFont.draw(self, Vector2(r.position.x + 108.0, r.position.y + 44.0), str(s["name"]), 3, UiTheme.GOLD)
                    PixelFont.draw(self, Vector2(r.position.x + 108.0, r.position.y + 76.0), str(s["text1"]), 2, UiTheme.TEXT)
                    PixelFont.draw(self, Vector2(r.position.x + 108.0, r.position.y + 98.0), str(s["text2"]), 2, UiTheme.TEXT_DIM)
                else:
                    PixelFont.draw(self, Vector2(r.position.x + 20.0, r.position.y + 62.0), "Vazio", 3, UiTheme.TEXT_DIM)
            if _armed.begins_with("over:"):   # (o botão já mudou para CONFIRMAR)
                _center_text("Toque em CONFIRMAR para substituir este jogo ao começar um novo", 150.0 + 2.0 * 150.0 + 100.0, 2, UiTheme.RED)
            elif _armed.begins_with("del:"):
                _center_text("Toque em CONFIRMAR para apagar este jogo salvo", 150.0 + 2.0 * 150.0 + 100.0, 2, UiTheme.RED)
        "name":
            _center_text("NOME DO SEU ANJO", 110.0, 5, UiTheme.GOLD)
            _center_text("Escolha um nome (até %d letras). Dá para mudar depois no perfil." % ProfileLogic.MAX_NAME, 190.0, 2, UiTheme.TEXT_DIM)
            _center_text("Espaço %d" % _pending_slot, 222.0, 2, UiTheme.TEXT_DIM)
        "settings":
            _center_text("CONFIGURAÇÕES", 40.0, 5, UiTheme.GOLD)

# ---------------------------------------------------------------- smoke do CI: percorre todas as telas e segue para o jogo
func _process(_delta: float) -> void:
    if not _smoke:
        return
    _frames += 1
    match _frames:
        4:
            _show("start")
        8:
            _open_slots("new")
            _smoke_ok = _smoke_ok and _sums.size() == SlotLogic.MAX_SLOTS
        12:
            _pending_slot = 1
            _show("name")
            _name_edit.text = "Teste"
            _update_go()
            _smoke_ok = _smoke_ok and _b_go.enabled and SlotLogic.name_valid(_name_edit.text)
        16:
            _name_edit.text = "   "
            _update_go()
            _smoke_ok = _smoke_ok and not SlotLogic.name_valid(_name_edit.text) and not _b_go.enabled
        20:
            _open_slots("load")
        24:
            _show("settings")
            var v0: int = OptionsLogic.volume(GameState.global_settings)
            var first := "opt|vol|-10" if v0 >= 10 else "opt|vol|10"
            var back := "opt|vol|10" if v0 >= 10 else "opt|vol|-10"
            GameState.set_global_option("opt|fx|0".split("|"))
            _smoke_ok = _smoke_ok and not UiLogic.fx_enabled(GameState.global_settings)
            GameState.set_global_option("opt|fx|0".split("|"))
            GameState.set_global_option(first.split("|"))
            _smoke_ok = _smoke_ok and OptionsLogic.volume(GameState.global_settings) != v0
            GameState.set_global_option(back.split("|"))
            _smoke_ok = _smoke_ok and OptionsLogic.volume(GameState.global_settings) == v0 and UiLogic.fx_enabled(GameState.global_settings)
        30:
            _show("main")
        36:
            GameState.title_ok = _smoke_ok
            GameState.start_unsaved()
            _enter_game()
