class_name HUD
extends CanvasLayer
## HUD: cartão do jogador (avatar -> perfil) com recursos embaixo e botões de velocidade/próxima fase ao lado;
## botão MENU no canto superior direito. Só o PERFIL aberto pausa o jogo (get_tree().paused); o menu NÃO pausa.
## Todos os botões são UiButton (toque próprio): funcionam junto com o joystick (multitoque).

var _root: Control
var _top: HudTop
var _avatar_btn: UiButton
var _next_btn: UiButton
var _speed_btn: UiButton
var _menu_btn: UiButton
var _menu: MenuPanel
var _profile: ProfilePanel
var _smoke := false
var pause_checks := 0      # smoke: quantas vezes o jogo entrou em pausa ao abrir o perfil
var pause_errors := 0      # smoke: divergências entre "perfil aberto" e "jogo pausado"

func _ready() -> void:
    layer = 10
    _smoke = OS.get_cmdline_user_args().has("--smoke")
    process_mode = Node.PROCESS_MODE_ALWAYS    # a interface continua viva com o jogo em pausa
    _root = Control.new()
    _root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_root)
    _top = HudTop.new()
    _root.add_child(_top)
    _avatar_btn = _make_button("", "", Rect2(20.0, 16.0, 84.0, 84.0), _open_profile)
    # ao lado do cartão da vida: velocidade 2x em cima, próxima fase embaixo
    _speed_btn = _make_button("", "speed", Rect2(404.0, 8.0, 224.0, 52.0), _on_speed)
    _next_btn = _make_button("", "next", Rect2(404.0, 66.0, 224.0, 52.0), _on_next)
    # estes não respondem com o jogo em pausa
    for b in [_avatar_btn, _speed_btn, _next_btn]:
        b.process_mode = Node.PROCESS_MODE_PAUSABLE
    _top.process_mode = Node.PROCESS_MODE_PAUSABLE
    _menu = MenuPanel.new()
    _root.add_child(_menu)
    _menu_btn = UiButton.new()
    _menu_btn.configure("MENU", "menu")
    _menu_btn.font_scale = 3
    _menu_btn.anchor_left = 1.0
    _menu_btn.anchor_right = 1.0
    _menu_btn.anchor_top = 0.0
    _menu_btn.anchor_bottom = 0.0
    _menu_btn.offset_left = -196.0     # canto superior direito
    _menu_btn.offset_right = -16.0
    _menu_btn.offset_top = 16.0
    _menu_btn.offset_bottom = 88.0
    _menu_btn.pressed.connect(_menu.toggle)
    _root.add_child(_menu_btn)
    _profile = ProfilePanel.new()
    _root.add_child(_profile)
    _profile.visibility_changed.connect(_update_pause)
    _apply_safe_area()
    get_viewport().size_changed.connect(_apply_safe_area)
    Events.state_changed.connect(_refresh)
    Events.stage_changed.connect(func(_s: int): _refresh())
    Events.player_hp_changed.connect(func(h: float, m: float): _top.hp = h; _top.max_hp = m; _top.queue_redraw())
    Events.boss_hp_changed.connect(func(h: float, m: float): _top.boss_hp = h; _top.boss_max = m; _top.queue_redraw())
    Events.stage_progress.connect(func(k: int, t: int, l: String): _top.killed = k; _top.total = t; _top.label = l; _top.queue_redraw())
    Events.stage_cleared.connect(func(_s: int, secs: float): _top.last_stage_secs = secs)
    Events.repeat_mode_changed.connect(func(on: bool): _top.repeat = on; _refresh())
    Events.boss_warning.connect(_on_boss_warning)
    _refresh()

## Só para o smoke do CI (o menu NÃO pausa; só o perfil): passo 0 abre o menu; 1..N percorre as abas; depois abre/fecha o perfil.
func debug_ui_step(step: int) -> void:
    var tabs: Array = MenuModel.tabs(true)
    if step == 0:
        _menu.toggle()
    elif step <= tabs.size():
        _menu.debug_open(str(tabs[step - 1]["id"]))
    elif step == tabs.size() + 1:
        _menu.close()
        _profile.open()
    else:
        _profile.close()

func add_control(c: Control) -> void:
    c.process_mode = Node.PROCESS_MODE_PAUSABLE   # joystick e habilidades param em pausa
    _root.add_child(c)
    _root.move_child(c, 0)   # joystick atrás dos botões

func _make_button(t: String, ic: String, r: Rect2, cb: Callable) -> UiButton:
    var b := UiButton.new()
    b.configure(t, ic)
    if t == "" and ic == "":
        b.avatar = 0
    b.position = r.position
    b.size = r.size
    b.pressed.connect(cb)
    _root.add_child(b)
    return b

## Garantia extra: a pausa SEMPRE acompanha o perfil aberto, mesmo que o sinal de visibilidade não dispare.
## (No smoke do CI não: lá a pausa é desfeita logo após conferir, para a cena continuar contando frames.)
func _process(_delta: float) -> void:
    if _smoke:
        return
    if get_tree().paused != OptionsLogic.should_pause(_profile.visible):
        _update_pause()

## Pausa o jogo enquanto o perfil estiver aberto (o menu não pausa); solta o joystick para não "grudar" a direção.
func _update_pause() -> void:
    var want: bool = OptionsLogic.should_pause(_profile.visible)
    get_tree().paused = want
    if want:
        pause_checks += 1
        Events.pause_started.emit()
    if get_tree().paused != want:
        pause_errors += 1
    if _smoke:
        get_tree().paused = false   # só no smoke do CI: o contador de frames da cena precisa continuar rodando

func _on_speed() -> void:
    if not get_tree().paused:
        GameState.toggle_speed()

func _on_next() -> void:
    if not get_tree().paused:
        Events.request_next_stage.emit()

func _open_profile() -> void:
    _menu.close()
    _profile.open()

func _on_boss_warning(boss_name: String, is_mini: bool) -> void:
    _top.boss_name = boss_name
    _top.boss_is_mini = is_mini
    _top.show_banner("MINI-CHEFE!" if is_mini else "AVISO: CHEFE!", boss_name)

## Só em aparelhos móveis: afasta o HUD do notch/cantos arredondados (DisplayServer.get_display_safe_area).
func _apply_safe_area() -> void:
    if not OS.has_feature("mobile"):
        return
    var safe: Rect2i = DisplayServer.get_display_safe_area()
    var m := UiLogic.safe_margins(Vector2(safe.position), Vector2(safe.size), Vector2(DisplayServer.window_get_size()),
        get_viewport().get_visible_rect().size)
    _root.offset_left = m["l"]
    _root.offset_top = m["t"]
    _root.offset_right = -m["r"]
    _root.offset_bottom = -m["b"]

func _refresh() -> void:
    var s: Dictionary = GameState.state
    var stg: int = int(s["stage"])
    _avatar_btn.avatar = int(s["profile"]["avatar"])
    _avatar_btn.queue_redraw()
    _next_btn.set_text("PRÓX. FASE %d" % (stg + 1))
    _next_btn.set_enabled(StageLogic.can_skip_to_next(stg, int(s["max_stage"])))
    _speed_btn.set_text("VELOC. %dX" % int(UiLogic.time_scale(s["settings"])))
    _top.queue_redraw()
