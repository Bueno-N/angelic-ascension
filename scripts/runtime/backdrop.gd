class_name Backdrop
extends Node2D
## Cenário do MUNDO: o mapa desenhado da fase (Arena.texture(), ver ArenaMaps), ampliado para Arena.WORLD.
## A cada 10 fases o tom muda levemente; nas fases de chefe tudo fica mais vermelho e um brilho pulsa.
## Brasas sobem pela arena inteira.

const PALETTES := [
    [Color(0.07, 0.03, 0.12), Color(0.16, 0.05, 0.18)],   # roxo sombrio
    [Color(0.10, 0.02, 0.03), Color(0.24, 0.05, 0.04)],   # vermelho
    [Color(0.02, 0.07, 0.09), Color(0.05, 0.15, 0.17)],   # abismo
    [Color(0.07, 0.07, 0.08), Color(0.17, 0.15, 0.14)],   # cinzas
]
# tom do mapa por bloco de 10 fases (multiplica a imagem; branco = original)
const TINTS := [Color(1.0, 1.0, 1.0), Color(1.0, 0.86, 0.82), Color(0.85, 0.93, 1.0), Color(0.93, 0.91, 0.89)]
const TINT_STRENGTH := 0.5
const OUTSIDE := 600.0               # cor de fundo além do mundo (telas muito largas)

var _stage := 1
var _embers: CPUParticles2D
var _glow: ColorRect
var _boss_mode := false
var _t := 0.0
var _pulse := 0.0

func _ready() -> void:
    z_index = -100
    texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    var world := Arena.WORLD
    _glow = ColorRect.new()
    _glow.size = world
    _glow.color = Color(0.9, 0.1, 0.02, 0.0)
    _glow.material = SpriteLib.additive()
    _glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _glow.visible = false
    add_child(_glow)
    Events.boss_warning.connect(func(_n: String, _m: bool): _pulse = 1.0)
    Events.weekly_started.connect(queue_redraw)
    # brasas subindo pela arena inteira
    _embers = CPUParticles2D.new()
    _embers.amount = 70
    _embers.lifetime = 7.0
    _embers.preprocess = 7.0
    _embers.position = world / 2.0
    _embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
    _embers.emission_rect_extents = world / 2.0
    _embers.direction = Vector2(0, -1)
    _embers.spread = 25.0
    _embers.gravity = Vector2.ZERO
    _embers.initial_velocity_min = 20.0
    _embers.initial_velocity_max = 60.0
    _embers.scale_amount_min = 1.5
    _embers.scale_amount_max = 3.5
    var g := Gradient.new()
    g.set_color(0, Color(1.0, 0.6, 0.2, 0.0))
    g.add_point(0.15, Color(1.0, 0.6, 0.2, 0.9))
    g.set_color(g.get_point_count() - 1, Color(1.0, 0.2, 0.05, 0.0))
    _embers.color_ramp = g
    add_child(_embers)
    queue_redraw()

func set_fx(on: bool) -> void:
    if _embers != null:
        _embers.emitting = on
        _embers.visible = on

func _set_boss_mode(on: bool) -> void:
    _boss_mode = on
    _glow.visible = on
    _embers.amount = 160 if on else 70

func _process(delta: float) -> void:
    _t += delta
    if not _boss_mode and _pulse <= 0.0:
        return
    _pulse = maxf(0.0, _pulse - delta * 1.2)
    _glow.visible = _boss_mode or _pulse > 0.0
    var base: float = 0.05 + 0.035 * sin(_t * 3.0) if _boss_mode else 0.0
    _glow.color.a = base + _pulse * 0.25

func set_stage(s: int) -> void:
    _stage = s
    _set_boss_mode(StageLogic.is_boss_stage(s))
    queue_redraw()

func _tint() -> Color:
    var idx: int = UiLogic.stage_palette_index(_stage)
    var tint: Color = Color.WHITE.lerp(TINTS[idx], TINT_STRENGTH)
    if StageLogic.is_boss_stage(_stage):
        tint = tint.lerp(Color(1.0, 0.7, 0.66), 0.3)
    return tint

func _draw() -> void:
    draw_rect(Arena.world_rect().grow(OUTSIDE), Color(0.12, 0.04, 0.03))
    var tex := Arena.texture()
    if tex != null:
        draw_texture_rect(tex, Arena.world_rect(), false, _tint())
