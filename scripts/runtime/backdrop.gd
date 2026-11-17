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
var _tile: Texture2D
var _torches: Array = []
var _flames: Array = []
var _glow: ColorRect
var _boss_mode := false
var _t := 0.0
var _pulse := 0.0

const FLAME_POS := [Vector2(0.03, 1.0), Vector2(0.97, 1.0), Vector2(0.03, 0.46), Vector2(0.97, 0.46)]

const TINTS := [Color(0.8, 0.65, 1.0), Color(1.0, 0.6, 0.55), Color(0.6, 0.9, 1.0), Color(0.95, 0.9, 0.85)]
const TORCH_POS := [Vector2(0.03, 0.36), Vector2(0.97, 0.36), Vector2(0.03, 0.82), Vector2(0.97, 0.82)]

func _ready() -> void:
    z_index = -100
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _tile = load("res://assets/sprites/ground.png")
    var area := get_viewport_rect().size
    for tp in TORCH_POS:
        var t := SpriteLib.make("torch", "idle", 2.0)
        t.position = Vector2(area.x * tp.x, area.y * tp.y)
        t.z_index = 1
        add_child(t)
        _torches.append(t)
    # Arena de chefe: chamas nos 4 cantos (sprite animado, mistura aditiva) + brilho vermelho pulsante
    for fp in FLAME_POS:
        var f := SpriteLib.make("fx_flame", "play", 3.5)
        f.centered = false
        f.offset = Vector2(-16.0, -48.0)
        f.position = Vector2(area.x * fp.x, area.y * fp.y)
        f.material = SpriteLib.additive()
        f.modulate = Color(1.0, 0.85, 0.7, 0.95)
        f.z_index = 2
        f.visible = false
        add_child(f)
        _flames.append(f)
    _glow = ColorRect.new()
    _glow.size = area
    _glow.color = Color(0.9, 0.1, 0.02, 0.0)
    _glow.material = SpriteLib.additive()
    _glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _glow.visible = false
    add_child(_glow)
    Events.boss_warning.connect(func(_n: String, _m: bool): _pulse = 1.0)
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

func set_fx(on: bool) -> void:
    if _embers != null:
        _embers.emitting = on
        _embers.visible = on

func _set_boss_mode(on: bool) -> void:
    _boss_mode = on
    for f in _flames:
        f.visible = on
    _glow.visible = on
    _embers.amount = 110 if on else 36

func _process(delta: float) -> void:
    if not _boss_mode and _pulse <= 0.0:
        return
    _t += delta
    _pulse = maxf(0.0, _pulse - delta * 1.2)
    _glow.visible = _boss_mode or _pulse > 0.0
    var base: float = 0.07 + 0.05 * sin(_t * 3.0) if _boss_mode else 0.0
    _glow.color.a = base + _pulse * 0.28

func set_stage(s: int) -> void:
    if s != _stage:
        _stage = s
        _set_boss_mode(StageLogic.is_boss_stage(s))
        queue_redraw()

func _draw() -> void:
    var area := get_viewport_rect().size
    var idx: int = UiLogic.stage_palette_index(_stage)
    var pal: Array = PALETTES[idx]
    var c0: Color = pal[0]
    var c1: Color = pal[1]
    var boss := StageLogic.is_boss_stage(_stage)
    # 1) chão de pedra em pixel art (ladrilho 64 px ampliado 2x), tingido pela paleta da fase
    if _tile != null:
        var tint: Color = TINTS[idx]
        if boss:
            tint = tint.lerp(Color(1.0, 0.45, 0.4), 0.5)
        draw_set_transform(Vector2.ZERO, 0.0, Vector2(2.0, 2.0))
        draw_texture_rect(_tile, Rect2(Vector2.ZERO, area / 2.0), true, tint)
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    # 2) gradiente translúcido por cima: escurece e dá o clima da fase
    for k in range(10):
        var col: Color = c0.lerp(c1, float(k) / 9.0)
        if boss:
            col = col.lerp(Color(0.3, 0.02, 0.02), 0.35)
        col.a = 0.72
        draw_rect(Rect2(0.0, area.y * float(k) / 10.0, area.x, area.y / 10.0 + 1.0), col)
    var lava := Color(1.0, 0.45, 0.12)
    for pts in _cracks:
        draw_polyline(pts, Color(lava, 0.12), 8.0)
        draw_polyline(pts, Color(lava, 0.9 if boss else 0.5), 2.0)
    # 3) luz quente das tochas
    for tp in TORCH_POS:
        var c := Vector2(area.x * tp.x, area.y * tp.y)
        draw_circle(c, 110.0, Color(1.0, 0.5, 0.15, 0.05))
        draw_circle(c, 70.0, Color(1.0, 0.55, 0.2, 0.06))
        draw_circle(c, 36.0, Color(1.0, 0.65, 0.25, 0.08))
    # 4) vinheta: bordas escurecidas
    for k in range(6):
        var w: float = 30.0 * float(k + 1)
        var v := Color(0, 0, 0, 0.06)
        draw_rect(Rect2(0, 0, w, area.y), v)
        draw_rect(Rect2(area.x - w, 0, w, area.y), v)
        draw_rect(Rect2(0, 0, area.x, w * 0.6), v)
        draw_rect(Rect2(0, area.y - w * 0.6, area.x, w * 0.6), v)
