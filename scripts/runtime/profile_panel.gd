class_name ProfilePanel
extends Control
## Perfil do jogador: avatar (8 ícones do jogo), nome editável e TODOS os status do anjo.

var _close: UiButton
var _name: LineEdit
var _list: UiList
var _avatar_rects: Array = []
var _taps := {}

func _ready() -> void:
    anchor_left = 0.5
    anchor_right = 0.5
    anchor_top = 0.5
    anchor_bottom = 0.5
    offset_left = -310.0
    offset_right = 310.0
    offset_top = -310.0
    offset_bottom = 310.0
    visible = false
    mouse_filter = Control.MOUSE_FILTER_STOP
    _close = UiButton.new()
    _close.configure("FECHAR", "close", UiTheme.RED)
    _close.pressed.connect(close)
    add_child(_close)
    _name = LineEdit.new()
    _name.max_length = ProfileLogic.MAX_NAME
    _name.placeholder_text = "Seu nome"
    _name.add_theme_font_size_override("font_size", 26)
    _name.text_submitted.connect(func(_t: String): _commit(); _name.release_focus())
    _name.focus_exited.connect(_commit)
    add_child(_name)
    _list = UiList.new()
    add_child(_list)
    resized.connect(_layout)
    Events.state_changed.connect(_refresh_rows)
    _layout()

func open() -> void:
    visible = true
    _name.text = str(GameState.state["profile"]["name"])
    _layout()
    _refresh_rows()
    queue_redraw()

func close() -> void:
    _commit()
    visible = false

func _commit() -> void:
    GameState.set_profile(_name.text, int(GameState.state["profile"]["avatar"]))
    _name.text = str(GameState.state["profile"]["name"])

func _refresh_rows() -> void:
    if visible and _list != null:
        _list.set_rows(ProfileLogic.stat_rows(GameState.state, GameState.stats))
        queue_redraw()

func _layout() -> void:
    if _list == null:
        return
    var w: float = size.x
    var h: float = size.y
    _name.position = Vector2(140.0, 92.0)
    _name.size = Vector2(w - 164.0, 48.0)
    _avatar_rects.clear()
    for i in range(ProfileLogic.AVATAR_COUNT):
        _avatar_rects.append(Rect2(24.0 + float(i) * 72.0, 200.0, 64.0, 64.0))
    _list.position = Vector2(12.0, 282.0)
    _list.size = Vector2(w - 24.0, h - 282.0 - 74.0)
    _close.position = Vector2(w - 192.0, h - 64.0)
    _close.size = Vector2(176.0, 50.0)

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            _name.release_focus()
            _taps[event.index] = event.position
        elif _taps.has(event.index):
            var start: Vector2 = _taps[event.index]
            _taps.erase(event.index)
            if (event.position - start).length() < 20.0:
                for i in range(_avatar_rects.size()):
                    if _avatar_rects[i].has_point(event.position):
                        GameState.set_profile(_name.text, i)
                        queue_redraw()
        accept_event()

func _draw() -> void:
    UiTheme.panel(self, Rect2(Vector2.ZERO, size), UiTheme.BG, UiTheme.GOLD)
    PixelFont.draw(self, Vector2(24.0, 20.0), "PERFIL DO ANJO", 3, UiTheme.GOLD)
    var cur: int = int(GameState.state["profile"]["avatar"])
    UiTheme.panel(self, Rect2(24.0, 64.0, 100.0, 100.0), Color(0.03, 0.02, 0.07, 1.0), UiTheme.GOLD)
    UiIcons.draw_avatar(self, cur, Rect2(30.0, 70.0, 88.0, 88.0))
    PixelFont.draw(self, Vector2(140.0, 68.0), "Nome", 2, UiTheme.TEXT_DIM)
    PixelFont.draw(self, Vector2(24.0, 176.0), "Escolha seu ícone", 2, UiTheme.TEXT_DIM)
    for i in range(_avatar_rects.size()):
        var r: Rect2 = _avatar_rects[i]
        UiTheme.panel(self, r, Color(0.03, 0.02, 0.07, 1.0), UiTheme.GOLD if i == cur else UiTheme.GOLD_D)
        UiIcons.draw_avatar(self, i, r.grow(-5.0))
    PixelFont.draw(self, Vector2(24.0, 266.0), "Status", 2, UiTheme.GOLD)
