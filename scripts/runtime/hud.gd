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
var _last_stage_secs := 0.0
var _pace_timer := 0.0

func _ready() -> void:
    layer = 10
    _root = Control.new()
    _root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_root)
    _build_top()
    _build_menu()
    Events.state_changed.connect(_refresh)
    Events.player_hp_changed.connect(_on_hp)
    Events.stage_changed.connect(func(_s: int): _refresh())
    Events.stage_cleared.connect(func(_s: int, secs: float): _last_stage_secs = secs)
    Events.boss_hp_changed.connect(_on_boss_hp)
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
    _pace.offset_top = 44.0
    _root.add_child(_pace)

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
        _pace.text = "Última fase: %s | Gemas/h (sessão): %s" % [
            "-" if _last_stage_secs <= 0.0 else "%d s" % int(_last_stage_secs),
            "-" if GameState.session_gems_per_hour() <= 0.0 else "%.0f" % GameState.session_gems_per_hour()]

func _refresh() -> void:
    var s: Dictionary = GameState.state
    _gold.text = "Ouro: " + UiLogic.fmt_int(int(s["gold"]))
    _gems.text = "Gemas: " + UiLogic.fmt_int(int(s["gems"]))
    _shards.text = "Fragm.: " + UiLogic.fmt_int(int(s["shards"]))
    _stage.text = "Fase " + str(int(s["stage"]))

func _on_hp(hp: float, max_hp: float) -> void:
    _hp_bar.max_value = max_hp
    _hp_bar.value = hp

func _on_boss_hp(hp: float, max_hp: float) -> void:
    _boss_bar.visible = max_hp > 0.0 and hp > 0.0
    _boss_bar.max_value = maxf(max_hp, 1.0)
    _boss_bar.value = hp
