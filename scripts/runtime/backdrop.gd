class_name Backdrop
extends Node2D
## Cenário sombrio: gradiente, rachaduras de lava, vinheta e brasas subindo. Muda de paleta a cada 10 fases
## (e fica avermelhado nas fases de chefe).

const PALETTES := [
    [Color(0.07, 0.03, 0.12), Color(0.16, 0.05, 0.18)],   # roxo sombrio
    [Color(0.10, 0.02, 0.03), Color(0.24, 0.05, 0.04)],   # vermelho
    [Color(0.02, 0.07, 0.09), Color(0.05, 0.15, 0.17)],   # abismo
    [Color(0.07, 0.07, 0.08), Color(0.17, 0.15, 0.14)],   # cinzas
]
var _stage := 1
var _cracks: Array = []
var _embers: CPUParticles2D

func _ready() -> void:
    z_index = -100
    var area := get_viewport_rect().size
    var rng := RandomNumberGenerator.new()
    rng.seed = 7
    for i in range(9):
        var pts := PackedVector2Array()
        var p := Vector2(rng.randf_range(0.0, area.x), rng.randf_range(0.0, area.y))
        pts.append(p)
        for k in range(rng.randi_range(4, 7)):
            p += Vector2(rng.randf_range(-70.0, 70.0), rng.randf_range(-70.0, 70.0))
            pts.append(p)
        _cracks.append(pts)
    _embers = CPUParticles2D.new()
    _embers.amount = 36
    _embers.lifetime = 9.0
    _embers.preprocess = 9.0
    _embers.position = Vector2(area.x * 0.5, area.y + 10.0)
    _embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
    _embers.emission_rect_extents = Vector2(area.x * 0.5, 5.0)
    _embers.direction = Vector2(0, -1)
    _embers.spread = 25.0
    _embers.gravity = Vector2.ZERO
    _embers.initial_velocity_min = 25.0
    _embers.initial_velocity_max = 70.0
    _embers.scale_amount_min = 1.5
    _embers.scale_amount_max = 3.5
    var g := Gradient.new()
    g.set_color(0, Color(1.0, 0.6, 0.2, 0.9))
    g.set_color(1, Color(1.0, 0.2, 0.05, 0.0))
    _embers.color_ramp = g
    add_child(_embers)
    queue_redraw()

func set_stage(s: int) -> void:
    if s != _stage:
        _stage = s
        queue_redraw()

func _draw() -> void:
    var area := get_viewport_rect().size
    var pal: Array = PALETTES[UiLogic.stage_palette_index(_stage)]
    var c0: Color = pal[0]
    var c1: Color = pal[1]
    var boss := StageLogic.is_boss_stage(_stage)
    for k in range(10):
        var col: Color = c0.lerp(c1, float(k) / 9.0)
        if boss:
            col = col.lerp(Color(0.3, 0.02, 0.02), 0.35)
        draw_rect(Rect2(0.0, area.y * float(k) / 10.0, area.x, area.y / 10.0 + 1.0), col)
    var lava := Color(1.0, 0.45, 0.12)
    for pts in _cracks:
        draw_polyline(pts, Color(lava, 0.12), 8.0)
        draw_polyline(pts, Color(lava, 0.5), 2.0)
    for k in range(6):   # vinheta: bordas escurecidas
        var w: float = 30.0 * float(k + 1)
        var v := Color(0, 0, 0, 0.06)
        draw_rect(Rect2(0, 0, w, area.y), v)
        draw_rect(Rect2(area.x - w, 0, w, area.y), v)
        draw_rect(Rect2(0, 0, area.x, w * 0.6), v)
        draw_rect(Rect2(0, area.y - w * 0.6, area.x, w * 0.6), v)
