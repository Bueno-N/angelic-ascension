class_name Backdrop
extends Node2D
## Cenário: arena infernal (assets/env/arena_bg.png), braseiros animados nas laterais, brasas subindo e vinheta.
## A cada 10 fases o tom da arena muda levemente; nas fases de chefe acendem fogueiras no chão e um brilho vermelho pulsa.

const PALETTES := [
    [Color(0.07, 0.03, 0.12), Color(0.16, 0.05, 0.18)],   # roxo sombrio
    [Color(0.10, 0.02, 0.03), Color(0.24, 0.05, 0.04)],   # vermelho
    [Color(0.02, 0.07, 0.09), Color(0.05, 0.15, 0.17)],   # abismo
    [Color(0.07, 0.07, 0.08), Color(0.17, 0.15, 0.14)],   # cinzas
]
var _stage := 1
var _embers: CPUParticles2D
var _bg: Texture2D
var _torches: Array = []
var _flames: Array = []
var _glow: ColorRect
var _boss_mode := false
var _t := 0.0
var _pulse := 0.0

# fogueiras das fases de chefe: na borda de baixo da arena (base da chama no ponto)
const FLAME_POS := [Vector2(0.10, 1.0), Vector2(0.30, 1.0), Vector2(0.70, 1.0), Vector2(0.90, 1.0)]
const FLAME_HEIGHT := 92.0
# tom da arena por bloco de 10 fases (multiplica a imagem; branco = original)
const TINTS := [Color(1.0, 1.0, 1.0), Color(1.0, 0.82, 0.78), Color(0.78, 0.92, 1.0), Color(0.9, 0.88, 0.86)]
const TINT_STRENGTH := 0.55
# braseiros nas laterais (base do braseiro no ponto)
const TORCH_POS := [Vector2(0.035, 0.44), Vector2(0.965, 0.44), Vector2(0.035, 0.90), Vector2(0.965, 0.90)]
const TORCH_HEIGHT := 100.0

func _ready() -> void:
    z_index = -100
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _bg = EnvArt.background()
    var area := get_viewport_rect().size
    for tp in TORCH_POS:
        var t := EnvArt.make("brazier", TORCH_HEIGHT)
        t.position = Vector2(area.x * tp.x, area.y * tp.y)
        t.z_index = 1
        add_child(t)
        _torches.append(t)
    # Arena de chefe: fogueiras no chão (cada uma uma variação, tremulando) + brilho vermelho pulsante
    for i in range(FLAME_POS.size()):
        var fp: Vector2 = FLAME_POS[i]
        var f := EnvArt.make_fire(i + 1, FLAME_HEIGHT)
        f.position = Vector2(area.x * fp.x, area.y * fp.y)
        f.z_index = 2
        f.visible = false
        f.set_meta("base_scale", f.scale)
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
    if _boss_mode:   # fogueiras tremulam (altura e brilho), cada uma num ritmo
        for i in range(_flames.size()):
            var f: Sprite2D = _flames[i]
            var b: Vector2 = f.get_meta("base_scale")
            var w: float = sin(_t * (7.0 + float(i) * 1.3) + float(i) * 2.0)
            f.scale = Vector2(b.x * (1.0 - 0.04 * w), b.y * (1.0 + 0.08 * w))
            f.modulate = Color(1.0, 1.0, 1.0, 0.88 + 0.12 * w)

func set_stage(s: int) -> void:
    if s != _stage:
        _stage = s
        _set_boss_mode(StageLogic.is_boss_stage(s))
        queue_redraw()

func _draw() -> void:
    var area := get_viewport_rect().size
    var idx: int = UiLogic.stage_palette_index(_stage)
    var boss := StageLogic.is_boss_stage(_stage)
    # 1) arena (imagem inteira esticada na tela), com o tom do bloco de fases
    var tint: Color = Color.WHITE.lerp(TINTS[idx], TINT_STRENGTH)
    if boss:
        tint = tint.lerp(Color(1.0, 0.55, 0.5), 0.35)
    if _bg != null:
        draw_texture_rect(_bg, Rect2(Vector2.ZERO, area), false, tint)
    else:
        draw_rect(Rect2(Vector2.ZERO, area), Color(0.09, 0.04, 0.1))
    # 2) luz quente dos braseiros
    for tp in TORCH_POS:
        var c := Vector2(area.x * tp.x, area.y * tp.y - TORCH_HEIGHT * 0.75)
        draw_circle(c, 120.0, Color(1.0, 0.5, 0.15, 0.04))
        draw_circle(c, 76.0, Color(1.0, 0.55, 0.2, 0.05))
        draw_circle(c, 40.0, Color(1.0, 0.65, 0.25, 0.06))
    # 3) vinheta leve: bordas escurecidas (a arte já tem moldura de pedra e lava)
    for k in range(5):
        var w: float = 26.0 * float(k + 1)
        var v := Color(0, 0, 0, 0.045)
        draw_rect(Rect2(0, 0, w, area.y), v)
        draw_rect(Rect2(area.x - w, 0, w, area.y), v)
        draw_rect(Rect2(0, 0, area.x, w * 0.6), v)
        draw_rect(Rect2(0, area.y - w * 0.6, area.x, w * 0.6), v)
