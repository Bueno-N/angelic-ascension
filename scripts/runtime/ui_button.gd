class_name UiButton
extends Control
## Botão de TOQUE próprio (multitoque): reage a InputEventScreenTouch, então um dedo no joystick e outro neste
## botão funcionam ao mesmo tempo (o Button padrão do Godot só atende o primeiro dedo).
## Modos: texto (+ícone), tile (ícone grande + texto) e avatar.

signal pressed
var text := ""
var icon := ""
var avatar := -1
var tile := false
var enabled := true
var accent := UiTheme.GOLD
var font_scale := 2
var _idx := -1
var _down := false

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP

func configure(t: String, ic: String = "", acc: Color = UiTheme.GOLD) -> void:
    text = t
    icon = ic
    accent = acc
    queue_redraw()

func set_text(t: String) -> void:
    if text != t:
        text = t
        queue_redraw()

func set_enabled(v: bool) -> void:
    if enabled != v:
        enabled = v
        queue_redraw()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed and _idx == -1 and enabled:
            _idx = event.index
            _down = true
            queue_redraw()
            accept_event()
        elif not event.pressed and event.index == _idx:
            var inside: bool = Rect2(Vector2.ZERO, size).has_point(event.position)
            _idx = -1
            _down = false
            queue_redraw()
            accept_event()
            if inside and enabled:
                AudioHub.play("ui_click", 1.0, 0.0)
                pressed.emit()
    elif event is InputEventScreenDrag and event.index == _idx:
        if not Rect2(Vector2.ZERO, size).grow(24.0).has_point(event.position):
            _idx = -1     # arrastou para fora: cancela
            _down = false
            queue_redraw()
        accept_event()

func _draw() -> void:
    var r := Rect2(Vector2.ZERO, size)
    var fill: Color = UiTheme.BG2 if enabled else Color(0.09, 0.09, 0.12, 0.92)
    if _down:
        fill = fill.lightened(0.2)
    var border: Color = accent if enabled else Color(0.32, 0.32, 0.4)
    UiTheme.panel(self, r, fill, border)
    var tc: Color = UiTheme.TEXT if enabled else UiTheme.TEXT_DIM
    if avatar >= 0:
        UiIcons.draw_avatar(self, avatar, Rect2(6.0, 6.0, size.x - 12.0, size.y - 12.0))
        return
    if tile:
        var isz: float = 72.0 if size.y >= 130.0 else 48.0
        UiIcons.draw(self, icon, Rect2((size.x - isz) / 2.0, 10.0, isz, isz), Color.WHITE if enabled else Color(0.5, 0.5, 0.55))
        PixelFont.draw(self, Vector2((size.x - float(PixelFont.width(text, font_scale))) / 2.0, size.y - 18.0 - 7.0 * float(font_scale)), text, font_scale, tc)
        return
    var x := 12.0
    if icon != "":
        UiIcons.draw(self, icon, Rect2(10.0, (size.y - 24.0) / 2.0, 24.0, 24.0), Color.WHITE if enabled else Color(0.5, 0.5, 0.55))
        x = 42.0
    var lines: PackedStringArray = text.split("\n")
    var lh: float = 7.0 * float(font_scale)
    var total_h: float = lh * float(lines.size()) + 6.0 * float(lines.size() - 1)
    for k in range(lines.size()):
        var tw: float = float(PixelFont.width(lines[k], font_scale))
        PixelFont.draw(self, Vector2(x + (size.x - x - 10.0 - tw) / 2.0, (size.y - total_h) / 2.0 + float(k) * (lh + 6.0)), lines[k], font_scale, tc)
