class_name HUD
extends CanvasLayer
## HUD fixa (fase, ouro, gemas, fragmentos, vida, chefe) + botão de menu + indicadores de calibração.

var _root: Control
var _gold: Label
var _gems: Label
var _shards: Label
var _stage: Label
var _pace: Label
var _hp_bar: ProgressBar
var _boss_bar: ProgressBar
var _menu: MenuPanel
var _next_btn: Button
var _speed_btn: Button
var _fx_btn: Button
var _repeat := false
var _last_stage_secs := 0.0
var _pace_timer := 0.0

func _ready() -> void:
    layer = 10
    _root = Control.new()
    _root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_root)
    _build_top()
    _build_stage_buttons()
    _build_menu()
    _apply_safe_area()
    get_viewport().size_changed.connect(_apply_safe_area)
    Events.state_changed.connect(_refresh)
    Events.player_hp_changed.connect(_on_hp)
    Events.stage_changed.connect(func(_s: int): _refresh())
    Events.stage_cleared.connect(func(_s: int, secs: float): _last_stage_secs = secs)
    Events.boss_hp_changed.connect(_on_boss_hp)
    Events.repeat_mode_changed.connect(func(on: bool): _repeat = on; _refresh())
    _refresh()

func add_control(c: Control) -> void:
    _root.add_child(c)
    _root.move_child(c, 0)   # joystick atrás dos botões

func _label(size: int) -> Label:
    var l := Label.new()
    l.add_theme_font_size_override("font_size", size)
    return l

func _build_top() -> void:
    var top := HBoxContainer.new()
    top.anchor_right = 1.0
    top.offset_left = 16.0
    top.offset_top = 8.0
    top.offset_right = -16.0
    top.add_theme_constant_override("separation", 28)
    top.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _root.add_child(top)
    _stage = _label(26)
    _gold = _label(26)
    _gems = _label(26)
    _shards = _label(26)
    _hp_bar = ProgressBar.new()
    _hp_bar.custom_minimum_size = Vector2(260, 26)
    _hp_bar.show_percentage = false
    _hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    for n in [_stage, _gold, _gems, _shards, _hp_bar]:
        top.add_child(n)
    _boss_bar = ProgressBar.new()
    _boss_bar.anchor_left = 0.2
    _boss_bar.anchor_right = 0.8
    _boss_bar.offset_top = 52.0
    _boss_bar.offset_bottom = 76.0
    _boss_bar.show_percentage = false
    _boss_bar.visible = false
    _boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _root.add_child(_boss_bar)
    # Indicador de calibração (para o teste no celular): tempo da última fase e gemas/h da sessão.
    _pace = _label(16)
    _pace.modulate = Color(1, 1, 1, 0.6)
    _pace.offset_left = 16.0
    _pace.offset_top = 46.0
    _root.add_child(_pace)

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

func _build_stage_buttons() -> void:
    _next_btn = Button.new()
    _next_btn.add_theme_font_size_override("font_size", 22)
    _next_btn.offset_left = 16.0
    _next_btn.offset_top = 80.0
    _next_btn.offset_right = 256.0
    _next_btn.offset_bottom = 132.0
    _next_btn.pressed.connect(func(): Events.request_next_stage.emit())
    _root.add_child(_next_btn)
    _speed_btn = Button.new()
    _speed_btn.add_theme_font_size_override("font_size", 22)
    _speed_btn.offset_left = 268.0
    _speed_btn.offset_top = 80.0
    _speed_btn.offset_right = 448.0
    _speed_btn.offset_bottom = 132.0
    _speed_btn.pressed.connect(func(): GameState.toggle_speed())
    _root.add_child(_speed_btn)
    _fx_btn = Button.new()
    _fx_btn.add_theme_font_size_override("font_size", 22)
    _fx_btn.offset_left = 460.0
    _fx_btn.offset_top = 80.0
    _fx_btn.offset_right = 650.0
    _fx_btn.offset_bottom = 132.0
    _fx_btn.pressed.connect(func(): GameState.toggle_low_fx())
    _root.add_child(_fx_btn)

func _build_menu() -> void:
    _menu = MenuPanel.new()
    _root.add_child(_menu)
    var btn := Button.new()
    btn.text = "Menu"
    btn.add_theme_font_size_override("font_size", 28)
    btn.anchor_left = 1.0
    btn.anchor_right = 1.0
    btn.anchor_top = 1.0
    btn.anchor_bottom = 1.0
    btn.offset_left = -216.0
    btn.offset_right = -16.0
    btn.offset_top = -96.0
    btn.offset_bottom = -16.0
    btn.pressed.connect(func(): _menu.visible = not _menu.visible)
    _root.add_child(btn)

func _process(delta: float) -> void:
    _pace_timer -= delta
    if _pace_timer <= 0.0:
        _pace_timer = 1.0
        _pace.text = ("[TESTE] " if DebugTools.enabled() else "") + "Última fase: %s | Gemas/h (sessão): %s" % [
            "-" if _last_stage_secs <= 0.0 else "%d s" % int(_last_stage_secs),
            "-" if GameState.session_gems_per_hour() <= 0.0 else "%.0f" % GameState.session_gems_per_hour()]

func _refresh() -> void:
    var s: Dictionary = GameState.state
    _gold.text = "Ouro: " + UiLogic.fmt_int(int(s["gold"]))
    _gems.text = "Gemas: " + UiLogic.fmt_int(int(s["gems"]))
    _shards.text = "Fragm.: " + UiLogic.fmt_int(int(s["shards"]))
    var stg: int = int(s["stage"])
    _stage.text = "Fase %d%s" % [stg, " (repetindo)" if _repeat else ""]
    _next_btn.text = "Próxima fase (%d)" % (stg + 1)
    _next_btn.disabled = not StageLogic.can_skip_to_next(stg, int(s["max_stage"]))
    _speed_btn.text = "Velocidade %dx" % int(UiLogic.time_scale(s["settings"]))
    _fx_btn.text = "Efeitos: Alto" if UiLogic.fx_enabled(s["settings"]) else "Efeitos: Baixo"

func _on_hp(hp: float, max_hp: float) -> void:
    _hp_bar.max_value = max_hp
    _hp_bar.value = hp

func _on_boss_hp(hp: float, max_hp: float) -> void:
    _boss_bar.visible = max_hp > 0.0 and hp > 0.0
    _boss_bar.max_value = maxf(max_hp, 1.0)
    _boss_bar.value = hp
