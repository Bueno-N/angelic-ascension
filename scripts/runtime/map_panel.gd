class_name MapPanel
extends Control
## Mapa das 300 fases: caminho sinuoso rolável (arraste), com "Fase N" em cima de cada bolinha. O fundo fica mais
## vermelho a cada dificuldade; chefes têm ícone de caveira, mini-chefes de espada. Toque numa fase para ver a
## projeção de ganhos e ir até ela (só fases já alcançadas). Tudo com toque próprio (ScreenTouch/Drag).

const TOP := 72.0
const BOTTOM := 124.0
const STRIP := 24.0
const TAP_SLOP := 16.0
const GOLD_NODE := Color(0.93, 0.72, 0.25)
const LOCKED_NODE := Color(0.32, 0.32, 0.4)

var _scroll := 0.0
var _vel := 0.0
var _drag := -1
var _moved := 0.0
var _sel := 1
var _t := 0.0
var _redraw_t := 0.0
var _close: UiButton
var _go: UiButton
var _here: UiButton
var _chips: Array = []

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    visible = false
    _close = UiButton.new()
    _close.configure("", "close", UiTheme.RED)
    _close.pressed.connect(close)
    add_child(_close)
    _go = UiButton.new()
    _go.configure("IR PARA A FASE", "next")
    _go.pressed.connect(_on_go)
    add_child(_go)
    _here = UiButton.new()
    _here.configure("FASE ATUAL", "")
    _here.pressed.connect(_center_on_current)
    add_child(_here)
    for t in range(Balance.TIER_NAMES.size()):
        var c := UiButton.new()
        c.configure(str(Balance.TIER_NAMES[t]).to_upper(), "", MapLogic.tier_accent(t))
        c.pressed.connect(_on_chip.bind(t))
        add_child(c)
        _chips.append(c)
    resized.connect(_layout)
    Events.state_changed.connect(_refresh)
    _layout()

func is_open() -> bool:
    return visible

func selected() -> int:
    return _sel

func open() -> void:
    visible = true
    _sel = int(GameState.state["stage"])
    _vel = 0.0
    _scroll = clampf(MapLogic.scroll_for(_sel, size.x), 0.0, _max_scroll())
    _refresh()
    queue_redraw()

func close() -> void:
    visible = false
    _drag = -1

func toggle() -> void:
    if visible:
        close()
    else:
        open()

func _max_scroll() -> float:
    return maxf(0.0, MapLogic.total_width() - size.x)

func _map_h() -> float:
    return maxf(200.0, size.y - TOP - BOTTOM)

func _info() -> Dictionary:
    return MapLogic.info(_sel, int(GameState.state["stage"]), int(GameState.state["max_stage"]))

func _refresh() -> void:
    if _go == null:
        return
    var inf := _info()
    _go.set_text(str(inf["button"]))
    _go.set_enabled(bool(inf["enabled"]))
    if visible:
        queue_redraw()

func _layout() -> void:
    if _go == null:
        return
    var w: float = size.x
    var h: float = size.y
    _close.position = Vector2(w - 66.0, 10.0)
    _close.size = Vector2(52.0, 52.0)
    var avail: float = w - 66.0 - 14.0 - 300.0
    var cw: float = minf(132.0, avail / float(_chips.size()) - 6.0)
    for i in range(_chips.size()):
        _chips[i].position = Vector2(300.0 + float(i) * (cw + 6.0), 14.0)
        _chips[i].size = Vector2(cw, 44.0)
    _go.position = Vector2(w - 296.0, h - BOTTOM + 16.0)
    _go.size = Vector2(280.0, 84.0)
    _here.position = Vector2(w - 496.0, h - BOTTOM + 16.0)
    _here.size = Vector2(190.0, 84.0)
    _scroll = clampf(_scroll, 0.0, _max_scroll())
    queue_redraw()

func _on_chip(tier: int) -> void:
    var first: int = StageLogic.tier_first_stage(tier)
    _sel = first
    _vel = 0.0
    _scroll = clampf(MapLogic.node_x(first) - 220.0, 0.0, _max_scroll())
    _refresh()

func _center_on_current() -> void:
    _sel = int(GameState.state["stage"])
    _vel = 0.0
    _scroll = clampf(MapLogic.scroll_for(_sel, size.x), 0.0, _max_scroll())
    _refresh()

func _on_go() -> void:
    var inf := _info()
    if str(inf["state"]) == "go":
        var target: int = int(inf["stage"])
        close()
        Events.goto_stage_requested.emit(target)

## Só para o smoke do CI.
func debug_select(stage: int, tier_jump: int = -1) -> void:
    if tier_jump >= 0:
        _on_chip(tier_jump)
    _sel = StageLogic.clamp_stage(stage)
    _refresh()

# ---------------------------------------------------------------- toque
func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            if event.position.y < TOP or event.position.y > size.y - BOTTOM:
                return
            if _drag == -1:
                _drag = event.index
                _moved = 0.0
                _vel = 0.0
            accept_event()
        elif event.index == _drag:
            _drag = -1
            if _moved < TAP_SLOP:
                _vel = 0.0
                _tap(event.position)
            accept_event()
    elif event is InputEventScreenDrag and event.index == _drag:
        _moved += absf(event.relative.x) + absf(event.relative.y)
        _scroll = clampf(_scroll - event.relative.x, 0.0, _max_scroll())
        _vel = -event.velocity.x
        queue_redraw()
        accept_event()

func _tap(pos: Vector2) -> void:
    var s: int = MapLogic.hit(Vector2(pos.x + _scroll, pos.y), TOP, _map_h(), 46.0)
    if s > 0:
        _sel = s
        _refresh()

func _process(delta: float) -> void:
    if not visible:
        return
    var d: float = delta / maxf(Engine.time_scale, 0.01)    # tempo real (ignora o 2x)
    _t += d
    var moving := false
    if _drag == -1 and absf(_vel) > 25.0:    # inércia ao soltar o dedo
        var before := _scroll
        _scroll = clampf(_scroll + _vel * d, 0.0, _max_scroll())
        if is_equal_approx(before, _scroll):
            _vel = 0.0
        _vel *= pow(0.04, d)
        moving = true
    else:
        _vel = 0.0 if _drag == -1 else _vel
    _redraw_t -= d
    if moving or _redraw_t <= 0.0:
        _redraw_t = 0.05
        queue_redraw()

# ---------------------------------------------------------------- desenho
func _draw() -> void:
    var w: float = size.x
    var h: float = size.y
    var mh: float = _map_h()
    var s: Dictionary = GameState.state
    var cur: int = int(s["stage"])
    var mx: int = int(s["max_stage"])
    # fundo: mais vermelho a cada dificuldade
    var x := 0.0
    while x < w:
        var pos: float = (x + STRIP / 2.0 + _scroll - MapLogic.X0) / MapLogic.SPACING + 1.0
        draw_rect(Rect2(x, TOP, STRIP + 1.0, mh), MapLogic.bg_color(pos))
        x += STRIP
    draw_rect(Rect2(0.0, TOP, w, 36.0), Color(0, 0, 0, 0.22))
    draw_rect(Rect2(0.0, TOP + mh - 36.0, w, 36.0), Color(0, 0, 0, 0.22))
    # divisas de dificuldade
    for tier in range(Balance.TIER_NAMES.size()):
        var first: int = StageLogic.tier_first_stage(tier)
        var px: float = MapLogic.node_x(first) - 62.0 - _scroll
        if px > -260.0 and px < w:
            draw_rect(Rect2(px, TOP, 3.0, mh), Color(1, 1, 1, 0.16))
            PixelFont.draw(self, Vector2(px + 12.0, TOP + 10.0), str(Balance.TIER_NAMES[tier]).to_upper(), 3, MapLogic.tier_accent(tier))
            PixelFont.draw(self, Vector2(px + 12.0, TOP + 40.0), "Fases %d a %d" % [first, StageLogic.tier_last_stage(tier)], 2, Color(1, 1, 1, 0.55))
    # caminho
    var lo: int = maxi(1, floori((_scroll - MapLogic.X0) / MapLogic.SPACING))
    var hi: int = mini(Balance.MAX_STAGE, ceili((_scroll + w - MapLogic.X0) / MapLogic.SPACING) + 2)
    for st in range(lo, hi):
        var a: Vector2 = MapLogic.node_pos(st, TOP, mh) - Vector2(_scroll, 0.0)
        var b: Vector2 = MapLogic.node_pos(st + 1, TOP, mh) - Vector2(_scroll, 0.0)
        draw_line(a, b, Color(0, 0, 0, 0.55), 11.0)
        draw_line(a, b, GOLD_NODE if st + 1 <= mx else Color(0.5, 0.5, 0.58, 0.8), 5.0)
    for st in range(lo, hi + 1):
        _draw_node(st, cur, mx, mh)
    _draw_legend(mh)
    # barras (cobrem o que passar das bordas)
    UiTheme.panel(self, Rect2(0.0, 0.0, w, TOP), UiTheme.BG, UiTheme.GOLD_D)
    PixelFont.draw(self, Vector2(20.0, 25.0), "MAPA DAS FASES", 3, UiTheme.GOLD)
    UiTheme.panel(self, Rect2(8.0, h - BOTTOM + 6.0, w - 16.0, BOTTOM - 12.0), UiTheme.BG, UiTheme.GOLD)
    var inf := _info()
    PixelFont.draw(self, Vector2(28.0, h - BOTTOM + 20.0), str(inf["title"]), 3, UiTheme.GOLD)
    PixelFont.draw(self, Vector2(28.0, h - BOTTOM + 50.0), str(inf["tag"]), 2, MapLogic.tier_accent(StageLogic.tier_index(int(inf["stage"]))))
    PixelFont.draw(self, Vector2(28.0, h - BOTTOM + 72.0), str(inf["line1"]), 2, UiTheme.TEXT)
    PixelFont.draw(self, Vector2(28.0, h - BOTTOM + 94.0), str(inf["line2"]), 2, UiTheme.TEXT_DIM)

func _draw_node(st: int, cur: int, mx: int, mh: float) -> void:
    var p: Vector2 = MapLogic.node_pos(st, TOP, mh) - Vector2(_scroll, 0.0)
    var kind: String = MapLogic.node_kind(st)
    var r: float = MapLogic.node_radius(kind)
    var reached: bool = st <= mx
    var fill: Color
    var ring: Color = GOLD_NODE if reached else Color(0.5, 0.5, 0.58)
    match kind:
        "boss":
            fill = Color(0.5, 0.07, 0.1) if reached else Color(0.22, 0.1, 0.13)
            draw_circle(p, r + 9.0, Color(1.0, 0.25, 0.15, 0.28 if reached else 0.12))
        "mini":
            fill = Color(0.88, 0.48, 0.14) if reached else Color(0.3, 0.22, 0.2)
        _:
            fill = GOLD_NODE if reached else LOCKED_NODE
    draw_circle(p, r + 4.0, Color(0, 0, 0, 0.85))
    draw_circle(p, r + 2.0, ring)
    draw_circle(p, r, fill)
    draw_circle(p - Vector2(r * 0.28, r * 0.28), r * 0.3, Color(1, 1, 1, 0.22))
    var tint: Color = Color.WHITE if reached else Color(0.6, 0.6, 0.66)
    if kind == "boss":
        UiIcons.draw(self, "skull", Rect2(p - Vector2(23.0, 23.0), Vector2(46.0, 46.0)), tint)
    elif kind == "mini":
        UiIcons.draw(self, "sword", Rect2(p - Vector2(16.0, 16.0), Vector2(32.0, 32.0)), tint)
    var label := "Fase %d" % st
    var lc: Color = UiTheme.TEXT if reached else UiTheme.TEXT_DIM
    PixelFont.draw(self, Vector2(p.x - float(PixelFont.width(label, 2)) / 2.0, p.y - r - 30.0), label, 2, lc)
    if st == _sel:
        draw_arc(p, r + 11.0, 0.0, TAU, 40, Color.WHITE, 3.0)
    if st == cur:
        var pulse: float = 3.0 * sin(_t * 4.0)
        draw_arc(p, r + 15.0 + pulse, 0.0, TAU, 40, UiTheme.GOLD, 3.0)
        UiIcons.draw_avatar(self, int(GameState.state["profile"]["avatar"]), Rect2(p.x - 20.0, p.y + r + 14.0, 40.0, 40.0))

func _draw_legend(mh: float) -> void:
    var y: float = TOP + mh - 32.0
    var x := 16.0
    UiIcons.draw(self, "skull", Rect2(x, y, 24.0, 24.0))
    PixelFont.draw(self, Vector2(x + 30.0, y + 6.0), "Chefe", 2, UiTheme.TEXT)
    x += 30.0 + float(PixelFont.width("Chefe", 2)) + 22.0
    UiIcons.draw(self, "sword", Rect2(x, y, 24.0, 24.0))
    PixelFont.draw(self, Vector2(x + 30.0, y + 6.0), "Mini-chefe", 2, UiTheme.TEXT)
    x += 30.0 + float(PixelFont.width("Mini-chefe", 2)) + 22.0
    draw_circle(Vector2(x + 10.0, y + 12.0), 9.0, GOLD_NODE)
    PixelFont.draw(self, Vector2(x + 30.0, y + 6.0), "Alcançada", 2, UiTheme.TEXT)
    x += 30.0 + float(PixelFont.width("Alcançada", 2)) + 22.0
    draw_circle(Vector2(x + 10.0, y + 12.0), 9.0, LOCKED_NODE)
    PixelFont.draw(self, Vector2(x + 30.0, y + 6.0), "Bloqueada", 2, UiTheme.TEXT)
