class_name AngelDraw
extends RefCounted
## Desenho do anjo compartilhado entre o jogo e a prévia do menu (chamar de dentro de _draw()).

static func draw_angel(c: CanvasItem, wings_level: int, glow_tier: int, s: float) -> void:
    var span: float = (34.0 + 6.0 * float(wings_level)) * s
    var alpha: float = minf(1.0, 0.65 + 0.1 * float(glow_tier))
    var wc := Color(0.95, 0.95, 1.0, alpha)
    if glow_tier > 0:
        c.draw_circle(Vector2.ZERO, span, Color(1.0, 0.9, 0.5, 0.04 + 0.02 * float(glow_tier)))
    c.draw_colored_polygon(PackedVector2Array([Vector2(-8, -4) * s, Vector2(-span, -span * 0.9), Vector2(-span * 0.7, 6.0 * s), Vector2(-8, 10) * s]), wc)
    c.draw_colored_polygon(PackedVector2Array([Vector2(8, -4) * s, Vector2(span, -span * 0.9), Vector2(span * 0.7, 6.0 * s), Vector2(8, 10) * s]), wc)
    c.draw_circle(Vector2.ZERO, 16.0 * s, Color(0.95, 0.85, 0.5))
    c.draw_circle(Vector2(0, -22) * s, 8.0 * s, Color(1.0, 0.95, 0.8))
