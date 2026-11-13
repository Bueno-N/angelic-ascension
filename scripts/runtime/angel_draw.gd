class_name AngelDraw
extends RefCounted
## Desenho do anjo compartilhado entre o jogo e as prévias do menu (chamar de dentro de _draw()).
## O visual evolui com: nível das asas (tamanho), brilho (halo), e equipamentos (espada, armadura, botas, luvas).

const TIER_COLORS := [
    Color(0.75, 0.78, 0.85), Color(0.6, 0.85, 0.6), Color(0.45, 0.7, 1.0),
    Color(0.75, 0.5, 1.0), Color(1.0, 0.7, 0.3), Color(1.0, 0.95, 0.6),
]
const SKIN := Color(0.95, 0.85, 0.5)

static func tier_color(tier: int) -> Color:
    return TIER_COLORS[clampi(tier, 1, TIER_COLORS.size()) - 1]

static func draw_angel(c: CanvasItem, wings_level: int, glow_tier: int, s: float, equipped: Dictionary = {}) -> void:
    var sword: int = int(equipped.get("sword", 0))
    var armor: int = int(equipped.get("armor", 0))
    var boots: int = int(equipped.get("boots", 0))
    var gloves: int = int(equipped.get("gloves", 0))

    # asas + halo do brilho
    var span: float = (34.0 + 6.0 * float(wings_level)) * s
    var alpha: float = minf(1.0, 0.65 + 0.1 * float(glow_tier))
    var wc := Color(0.95, 0.95, 1.0, alpha)
    if glow_tier > 0:
        c.draw_circle(Vector2.ZERO, span, Color(1.0, 0.9, 0.5, 0.04 + 0.02 * float(glow_tier)))
    c.draw_colored_polygon(PackedVector2Array([Vector2(-8, -4) * s, Vector2(-span, -span * 0.9), Vector2(-span * 0.7, 6.0 * s), Vector2(-8, 10) * s]), wc)
    c.draw_colored_polygon(PackedVector2Array([Vector2(8, -4) * s, Vector2(span, -span * 0.9), Vector2(span * 0.7, 6.0 * s), Vector2(8, 10) * s]), wc)

    # botas
    if boots > 0:
        var bc := tier_color(boots)
        c.draw_circle(Vector2(-8, 20) * s, 5.5 * s, bc)
        c.draw_circle(Vector2(8, 20) * s, 5.5 * s, bc)
        if boots >= 4:
            c.draw_arc(Vector2(-8, 20) * s, 8.0 * s, 0.0, TAU, 16, Color(bc, 0.6), 2.0)
            c.draw_arc(Vector2(8, 20) * s, 8.0 * s, 0.0, TAU, 16, Color(bc, 0.6), 2.0)

    # corpo + armadura
    var body := SKIN
    if armor > 0:
        body = tier_color(armor).lerp(SKIN, 0.3)
    c.draw_circle(Vector2.ZERO, 16.0 * s, body)
    if armor > 0:
        var ac := tier_color(armor)
        c.draw_colored_polygon(PackedVector2Array([Vector2(-10, -8) * s, Vector2(10, -8) * s, Vector2(7, 12) * s, Vector2(-7, 12) * s]), ac)
        if armor >= 3:
            c.draw_circle(Vector2(-17, -6) * s, 6.0 * s, ac)
            c.draw_circle(Vector2(17, -6) * s, 6.0 * s, ac)
        if armor >= 5:
            c.draw_arc(Vector2.ZERO, 22.0 * s, 0.0, TAU, 28, Color(ac, 0.7), 2.5)

    # cabeça (+ aro de luz com armadura alta)
    c.draw_circle(Vector2(0, -22) * s, 8.0 * s, Color(1.0, 0.95, 0.8))
    if armor >= 4:
        c.draw_arc(Vector2(0, -33) * s, 7.0 * s, 0.0, TAU, 16, Color(1.0, 0.95, 0.5, 0.9), 2.0)

    # luvas
    if gloves > 0:
        var gc := tier_color(gloves)
        c.draw_circle(Vector2(-20, 4) * s, 4.5 * s, gc)
        c.draw_circle(Vector2(20, 4) * s, 4.5 * s, gc)

    # espada (na mão direita): comprimento e cor crescem com o tier
    if sword > 0:
        var sc := tier_color(sword)
        var base := Vector2(20, 4) * s
        var tip := base + Vector2(8.0, -(22.0 + 6.0 * float(sword))) * s
        c.draw_line(base, tip, Color(sc, 0.35), 8.0 * s)
        c.draw_line(base, tip, sc, 3.5 * s)
        c.draw_line(base + Vector2(-5, -4) * s, base + Vector2(5, -4) * s, Color(0.9, 0.8, 0.4), 3.0 * s)
        if sword >= 4:
            c.draw_circle(tip, 5.0 * s, Color(sc, 0.7))
