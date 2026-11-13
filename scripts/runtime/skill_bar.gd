class_name SkillBar
extends Control
## Botão AUTO + 3 botões de habilidade com recarga visual. Usa InputEventScreenTouch (multitoque:
## o dedo no joystick não bloqueia o toque nas habilidades).

const BTN := 96.0
const GAP := 12.0
const AUTO_W := 76.0
const RARITY_COLORS := {
    "Comum": Color(0.7, 0.7, 0.72), "Incomum": Color(0.45, 0.8, 0.45), "Rara": Color(0.4, 0.65, 1.0),
    "Épica": Color(0.7, 0.5, 1.0), "Lendária": Color(1.0, 0.65, 0.25), "Mítica": Color(1.0, 0.4, 0.4),
    "Divina": Color(1.0, 0.9, 0.4), "Suprema": Color(1.0, 0.75, 0.9),
}
var caster: SkillCaster

func _ready() -> void:
    anchor_left = 1.0
    anchor_right = 1.0
    anchor_top = 1.0
    anchor_bottom = 1.0
    offset_right = -232.0
    offset_left = -232.0 - (AUTO_W + 3.0 * (BTN + GAP))
    offset_bottom = -16.0
    offset_top = -16.0 - BTN
    mouse_filter = Control.MOUSE_FILTER_STOP

func _process(_delta: float) -> void:
    queue_redraw()

func _slot_x(i: int) -> float:
    return AUTO_W + GAP + float(i) * (BTN + GAP)

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch and event.pressed:
        var x: float = event.position.x
        if x < AUTO_W:
            GameState.toggle_auto_skills()
        else:
            for i in range(SkillsDB.MAX_EQUIPPED):
                if x >= _slot_x(i) and x <= _slot_x(i) + BTN:
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
    var auto_on: bool = bool(GameState.state["settings"].get("auto_skills", true))
    draw_rect(Rect2(0, 0, AUTO_W, BTN), Color(0.08, 0.08, 0.12, 0.8))
    draw_rect(Rect2(0, 0, AUTO_W, BTN), Color(0.5, 1.0, 0.6) if auto_on else Color(0.6, 0.6, 0.6), false, 2.0)
    draw_string(font, Vector2(0, 40), "AUTO", HORIZONTAL_ALIGNMENT_CENTER, AUTO_W, 20, Color.WHITE)
    draw_string(font, Vector2(0, 68), "ON" if auto_on else "OFF", HORIZONTAL_ALIGNMENT_CENTER, AUTO_W, 22, Color(0.5, 1.0, 0.6) if auto_on else Color(0.8, 0.8, 0.8))
    for i in range(SkillsDB.MAX_EQUIPPED):
        var c := Vector2(_slot_x(i) + BTN / 2.0, BTN / 2.0)
        if caster == null or i >= caster.slots.equipped.size():
            draw_arc(c, 44.0, 0.0, TAU, 32, Color(1, 1, 1, 0.25), 2.0)
            draw_string(font, Vector2(_slot_x(i), c.y + 6.0), "vazio", HORIZONTAL_ALIGNMENT_CENTER, BTN, 16, Color(1, 1, 1, 0.35))
            continue
        var id: String = caster.slots.equipped[i]
        var sk := SkillsDB.get_skill(id)
        var col: Color = RARITY_COLORS.get(sk["rarity"], Color.WHITE)
        var rem: float = caster.slots.remaining(id)
        var ratio: float = rem / maxf(float(sk["cooldown"]), 0.01)
        draw_circle(c, 44.0, Color(0.08, 0.08, 0.12, 0.85))
        draw_arc(c, 44.0, 0.0, TAU, 40, col if rem <= 0.0 else Color(col, 0.4), 4.0)
        draw_string(font, Vector2(_slot_x(i), c.y + 10.0), SkillsDB.abbr(id), HORIZONTAL_ALIGNMENT_CENTER, BTN, 30, col)
        if rem > 0.0:
            _draw_pie(c, 42.0, ratio, Color(0, 0, 0, 0.6))
            draw_string(font, Vector2(_slot_x(i), c.y + 8.0), "%d" % int(ceil(rem)), HORIZONTAL_ALIGNMENT_CENTER, BTN, 34, Color.WHITE)
        draw_string(font, Vector2(_slot_x(i) + 8.0, 18.0), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.5))
