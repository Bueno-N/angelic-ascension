class_name SkillBar
extends Control
## 3 botões de habilidade com recarga visual. EM CIMA de cada ícone há um botão AUTO ON/OFF só daquele slot.
## Toque no ícone = lança manualmente; toque na faixa de cima = liga/desliga o automático do slot.
## Usa InputEventScreenTouch (multitoque: o dedo no joystick não bloqueia estes toques).

const BTN := 96.0
const GAP := 12.0
const TOGGLE_H := 34.0
const TOGGLE_GAP := 6.0
const RARITY_COLORS := {
    "Comum": Color(0.7, 0.7, 0.72), "Incomum": Color(0.45, 0.8, 0.45), "Rara": Color(0.4, 0.65, 1.0),
    "Épica": Color(0.7, 0.5, 1.0), "Lendária": Color(1.0, 0.65, 0.25), "Mítica": Color(1.0, 0.4, 0.4),
    "Divina": Color(1.0, 0.9, 0.4), "Suprema": Color(1.0, 0.75, 0.9),
}
var caster: SkillCaster
var _t := 0.0

func _ready() -> void:
    anchor_left = 1.0
    anchor_right = 1.0
    anchor_top = 1.0
    anchor_bottom = 1.0
    offset_right = -232.0
    offset_left = -232.0 - float(SkillsDB.MAX_EQUIPPED) * (BTN + GAP)
    offset_bottom = -16.0
    offset_top = -16.0 - (TOGGLE_H + TOGGLE_GAP + BTN)
    mouse_filter = Control.MOUSE_FILTER_STOP

func _process(delta: float) -> void:
    _t -= delta
    if _t <= 0.0:
        _t = Balance.UI_REDRAW_INTERVAL
        queue_redraw()

func _slot_x(i: int) -> float:
    return GAP + float(i) * (BTN + GAP)

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch and event.pressed:
        var x: float = event.position.x
        var y: float = event.position.y
        for i in range(SkillsDB.MAX_EQUIPPED):
            if x >= _slot_x(i) and x <= _slot_x(i) + BTN and i < caster.slots.equipped.size():
                if y <= TOGGLE_H:
                    GameState.toggle_slot_auto(i)
                else:
                    caster.cast_slot(i)
        accept_event()

func _draw_pie(center: Vector2, r: float, frac: float, col: Color) -> void:
    var f: float = minf(frac, 0.995)
    if f <= 0.0:
        return
    var pts := PackedVector2Array([center])
    var steps: int = maxi(2, int(40.0 * f))
    for k in range(steps + 1):
        var a: float = -PI / 2.0 + TAU * f * float(k) / float(steps)
        pts.append(center + Vector2(cos(a), sin(a)) * r)
    draw_colored_polygon(pts, col)

func _draw() -> void:
    var font := ThemeDB.fallback_font
    var settings: Dictionary = GameState.state["settings"]
    var oy: float = TOGGLE_H + TOGGLE_GAP
    for i in range(SkillsDB.MAX_EQUIPPED):
        var x0: float = _slot_x(i)
        var c := Vector2(x0 + BTN / 2.0, oy + BTN / 2.0)
        if caster == null or i >= caster.slots.equipped.size():
            draw_arc(c, 44.0, 0.0, TAU, 32, Color(1, 1, 1, 0.25), 2.0)
            draw_string(font, Vector2(x0, c.y + 6.0), "vazio", HORIZONTAL_ALIGNMENT_CENTER, BTN, 16, Color(1, 1, 1, 0.35))
            continue
        var id: String = caster.slots.equipped[i]
        var sk := SkillsDB.get_skill(id)
        var col: Color = RARITY_COLORS.get(sk["rarity"], Color.WHITE)
        # botão AUTO ON/OFF deste slot (em cima do ícone)
        var on: bool = AutoCast.slot_auto(settings, i)
        var tcol := Color(0.5, 1.0, 0.6) if on else Color(0.7, 0.7, 0.72)
        draw_rect(Rect2(x0, 0.0, BTN, TOGGLE_H), Color(0.08, 0.2, 0.1, 0.85) if on else Color(0.1, 0.1, 0.12, 0.85))
        draw_rect(Rect2(x0, 0.0, BTN, TOGGLE_H), tcol, false, 2.0)
        draw_string(font, Vector2(x0, TOGGLE_H - 10.0), "AUTO ON" if on else "AUTO OFF", HORIZONTAL_ALIGNMENT_CENTER, BTN, 17, tcol)
        # ícone
        var rem: float = caster.slots.remaining(id)
        var ratio: float = rem / maxf(float(sk["cooldown"]), 0.01)
        draw_circle(c, 44.0, Color(0.08, 0.08, 0.12, 0.85))
        draw_arc(c, 44.0, 0.0, TAU, 40, col if rem <= 0.0 else Color(col, 0.4), 4.0)
        draw_string(font, Vector2(x0, c.y + 10.0), SkillsDB.abbr(id), HORIZONTAL_ALIGNMENT_CENTER, BTN, 30, col)
        if rem > 0.0:
            _draw_pie(c, 42.0, ratio, Color(0, 0, 0, 0.6))
            draw_string(font, Vector2(x0, c.y + 8.0), "%d" % int(ceil(rem)), HORIZONTAL_ALIGNMENT_CENTER, BTN, 34, Color.WHITE)
        draw_string(font, Vector2(x0 + 8.0, oy + 18.0), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.5))
