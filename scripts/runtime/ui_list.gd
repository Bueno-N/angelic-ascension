class_name UiList
extends Control
## Lista rolável desenhada por código (ícones, fonte pixel, botões com custo). Cada dedo é rastreado pelo seu
## índice: arrastar rola a lista; um toque curto num botão dispara `action`. Como usa ScreenTouch/Drag, o dedo
## no joystick e outro nesta lista funcionam juntos (multitoque).

signal action(id: String)
const PAD := 8.0
const BTN_W := 150.0
const BTN_H := 58.0
const ICON := 48.0
var _rows: Array = []
var _layout: Array = []
var _content_h := 0.0
var _scroll := 0.0
var _touches := {}
var _press_row := -1

func _ready() -> void:
    clip_contents = true
    mouse_filter = Control.MOUSE_FILTER_STOP
    resized.connect(_relayout)

func set_rows(rows: Array) -> void:
    _rows = rows
    _relayout()

func scroll_to_top() -> void:
    _scroll = 0.0
    queue_redraw()

func _max_scroll() -> float:
    return maxf(0.0, _content_h - size.y)

func _text_w() -> int:
    return int(size.x - PAD * 2.0 - ICON - 40.0 - BTN_W)

func _relayout() -> void:
    _layout.clear()
    if size.x < 80.0:
        return
    var y := PAD
    for r in _rows:
        var kind: String = str(r.get("kind", "item"))
        var h := 0.0
        var lines: Array = []
        if kind == "header":
            h = 40.0
        elif kind == "stat":
            h = 40.0
        elif kind == "info":
            lines = PixelFont.wrap(str(r.get("sub", "")), int(size.x - PAD * 2.0 - 24.0), 2)
            h = 18.0 + float(lines.size()) * 20.0
        else:
            var has_btn: bool = str(r.get("button", "")) != ""
            var w: int = _text_w() if has_btn else int(size.x - PAD * 2.0 - ICON - 40.0)
            lines = PixelFont.wrap(str(r.get("sub", "")), w, 2)
            h = maxf(86.0, 44.0 + float(lines.size()) * 20.0 + (14.0 if r.has("ratio") else 4.0))
        _layout.append({"y": y, "h": h, "lines": lines})
        y += h + 8.0
    _content_h = y + PAD
    _scroll = clampf(_scroll, 0.0, _max_scroll())
    queue_redraw()

func _btn_rect(i: int) -> Rect2:
    var L: Dictionary = _layout[i]
    return Rect2(size.x - PAD - BTN_W - 8.0, float(L["y"]) + (float(L["h"]) - BTN_H) / 2.0, BTN_W, BTN_H)

func _hit_button(pos_content: Vector2) -> int:
    for i in range(mini(_rows.size(), _layout.size())):
        if str(_rows[i].get("kind", "item")) == "item" and str(_rows[i].get("button", "")) != "":
            if _btn_rect(i).has_point(pos_content):
                return i
    return -1

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            _touches[event.index] = {"start": event.position, "scroll": false}
            _press_row = _hit_button(event.position + Vector2(0.0, _scroll))
            queue_redraw()
            accept_event()
        elif _touches.has(event.index):
            var t: Dictionary = _touches[event.index]
            _touches.erase(event.index)
            var was: int = _press_row
            _press_row = -1
            if not bool(t["scroll"]):
                var hit: int = _hit_button(event.position + Vector2(0.0, _scroll))
                if hit >= 0 and hit == was:
                    _fire(hit)
            queue_redraw()
            accept_event()
    elif event is InputEventScreenDrag and _touches.has(event.index):
        var t2: Dictionary = _touches[event.index]
        if not bool(t2["scroll"]) and (event.position - t2["start"]).length() > 14.0:
            t2["scroll"] = true
            _press_row = -1
        if bool(t2["scroll"]):
            _scroll = clampf(_scroll - event.relative.y, 0.0, _max_scroll())
            queue_redraw()
        accept_event()

func _fire(i: int) -> void:
    var r: Dictionary = _rows[i]
    if bool(r.get("enabled", true)) and str(r.get("action", "")) != "":
        action.emit(str(r["action"]))

func _draw() -> void:
    draw_set_transform(Vector2(0.0, -_scroll), 0.0, Vector2.ONE)
    for i in range(mini(_rows.size(), _layout.size())):
        var L: Dictionary = _layout[i]
        if float(L["y"]) + float(L["h"]) < _scroll or float(L["y"]) > _scroll + size.y:
            continue
        _draw_row(_rows[i], L, i)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    if _content_h > size.y:   # barra de rolagem fina
        var bh: float = maxf(30.0, size.y * size.y / _content_h)
        var by: float = (size.y - bh) * (_scroll / _max_scroll())
        draw_rect(Rect2(size.x - 5.0, by, 4.0, bh), Color(UiTheme.GOLD, 0.6))

func _draw_row(r: Dictionary, L: Dictionary, i: int) -> void:
    var y: float = L["y"]
    var h: float = L["h"]
    var kind: String = str(r.get("kind", "item"))
    var w: float = size.x - PAD * 2.0
    if kind == "header":
        PixelFont.draw(self, Vector2(PAD + 6.0, y + 12.0), str(r["title"]), 2, UiTheme.GOLD)
        draw_rect(Rect2(PAD, y + 32.0, w, 2.0), UiTheme.GOLD_D)
        return
    if kind == "stat":
        UiTheme.panel(self, Rect2(PAD, y, w, h), UiTheme.BG2, UiTheme.GOLD_D)
        UiIcons.draw(self, str(r.get("icon", "")), Rect2(PAD + 10.0, y + 8.0, 24.0, 24.0))
        PixelFont.draw(self, Vector2(PAD + 46.0, y + 13.0), str(r["title"]), 2, UiTheme.TEXT)
        var vt: String = str(r.get("value", ""))
        PixelFont.draw(self, Vector2(size.x - PAD - 12.0 - float(PixelFont.width(vt, 2)), y + 13.0), vt, 2, UiTheme.GOLD)
        return
    if kind == "info":
        UiTheme.panel(self, Rect2(PAD, y, w, h), Color(0.08, 0.06, 0.16, 0.9), UiTheme.GOLD_D)
        var ls: Array = L["lines"]
        for k in range(ls.size()):
            PixelFont.draw(self, Vector2(PAD + 12.0, y + 12.0 + float(k) * 20.0), str(ls[k]), 2, UiTheme.TEXT_DIM)
        return
    # item
    var tone: String = str(r.get("tone", "ok"))
    var border: Color = UiTheme.GOLD_D
    if tone == "active":
        border = UiTheme.GREEN_D
    elif tone == "buy":
        border = Color(0.6, 0.45, 0.15)
    UiTheme.panel(self, Rect2(PAD, y, w, h), UiTheme.BG2, border)
    var ix: float = PAD + 12.0
    var iy: float = y + (h - ICON) / 2.0
    if r.has("abbr"):
        var rc: Color = SkillBar.RARITY_COLORS.get(str(r.get("rarity", "Comum")), Color.WHITE)
        UiTheme.panel(self, Rect2(ix, iy, ICON, ICON), Color(0.05, 0.04, 0.1, 1.0), rc)
        if str(r.get("icon", "")) != "":
            UiIcons.draw(self, str(r["icon"]), Rect2(ix, iy, ICON, ICON))
        else:
            var ab: String = str(r["abbr"])
            PixelFont.draw(self, Vector2(ix + (ICON - float(PixelFont.width(ab, 3))) / 2.0, iy + (ICON - 21.0) / 2.0), ab, 3, rc)
    elif str(r.get("icon", "")) != "":
        UiIcons.draw(self, str(r["icon"]), Rect2(ix, iy, ICON, ICON), r.get("tint", Color.WHITE))
    var tx: float = ix + ICON + 14.0
    PixelFont.draw(self, Vector2(tx, y + 12.0), str(r.get("title", "")), 2, UiTheme.TEXT)
    var lines: Array = L["lines"]
    for k in range(lines.size()):
        PixelFont.draw(self, Vector2(tx, y + 36.0 + float(k) * 20.0), str(lines[k]), 2, UiTheme.TEXT_DIM)
    if r.has("ratio"):
        var bw: float = float(_text_w())
        draw_rect(Rect2(tx, y + h - 16.0, bw, 8.0), Color(0, 0, 0, 0.6))
        draw_rect(Rect2(tx, y + h - 16.0, bw * clampf(float(r["ratio"]), 0.0, 1.0), 8.0), UiTheme.GREEN)
    var label: String = str(r.get("button", ""))
    if label == "":
        return
    var br := _btn_rect(i)
    var en: bool = bool(r.get("enabled", true))
    var bc: Color = UiTheme.GOLD
    var fill: Color = Color(0.2, 0.15, 0.05, 1.0)
    if tone == "active":
        bc = UiTheme.GREEN
        fill = Color(0.05, 0.2, 0.08, 1.0)
    elif not en:
        bc = Color(0.38, 0.38, 0.46)
        fill = Color(0.1, 0.1, 0.14, 1.0)
    if _press_row == i:
        fill = fill.lightened(0.25)
    UiTheme.panel(self, br, fill, bc)
    var cost: int = int(r.get("cost", 0))
    var lc: Color = UiTheme.TEXT if en else UiTheme.TEXT_DIM
    if cost > 0:
        PixelFont.draw(self, Vector2(br.position.x + (br.size.x - float(PixelFont.width(label, 2))) / 2.0, br.position.y + 8.0), label, 2, lc)
        var ct: String = UiLogic.fmt_int(cost)
        var cw: float = 24.0 + 4.0 + float(PixelFont.width(ct, 2))
        var cx: float = br.position.x + (br.size.x - cw) / 2.0
        UiIcons.draw(self, str(r.get("cost_icon", "coin")), Rect2(cx, br.position.y + 28.0, 24.0, 24.0))
        PixelFont.draw(self, Vector2(cx + 28.0, br.position.y + 33.0), ct, 2, UiTheme.RED if bool(r.get("poor", false)) else UiTheme.TEXT)
    else:
        PixelFont.draw(self, Vector2(br.position.x + (br.size.x - float(PixelFont.width(label, 2))) / 2.0, br.position.y + (br.size.y - 14.0) / 2.0), label, 2, lc)
