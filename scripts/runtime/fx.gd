class_name Fx
extends Node2D
## Efeito visual de curta duração (anel, disco, raio, feixe, clarão). Só desenha; o dano é feito pelo SkillCaster.

var kind := "ring"
var life := 0.5
var radius := 100.0
var color := Color(1.0, 0.95, 0.6)
var to := Vector2.ZERO
var _age := 0.0

static func make(k: String, pos: Vector2, life_s: float, r: float, col: Color) -> Fx:
    var f := Fx.new()
    f.kind = k
    f.position = pos
    f.life = life_s
    f.radius = r
    f.color = col
    return f

func _process(delta: float) -> void:
    _age += delta
    if _age >= life:
        queue_free()
        return
    queue_redraw()

func _draw() -> void:
    var t: float = clampf(_age / maxf(life, 0.001), 0.0, 1.0)
    var a: float = 1.0 - t
    match kind:
        "ring":
            draw_arc(Vector2.ZERO, maxf(1.0, radius * t), 0.0, TAU, 56, Color(color, a), 2.0 + 8.0 * a)
        "disc":
            draw_circle(Vector2.ZERO, maxf(1.0, radius * t), Color(color, 0.45 * a))
        "beam":
            draw_line(Vector2.ZERO, to, Color(color, a), 2.0 + 8.0 * a)
        "strike":
            var w: float = 3.0 + 14.0 * a
            draw_rect(Rect2(-w, -900.0, w * 2.0, 900.0), Color(color, a))
            draw_circle(Vector2.ZERO, radius * (0.4 + 0.6 * t), Color(color, 0.5 * a))
        "flash":
            draw_rect(Rect2(-3000.0, -3000.0, 6000.0, 6000.0), Color(color, 0.55 * a))
