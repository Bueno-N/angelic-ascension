class_name Backdrop
extends Node2D
## Cenário do MUNDO (Arena.WORLD, maior que a tela): lava em volta (assets/env/lava.png, repetida e pulsando),
## chão de pedra no meio (floor.png, repetido) e a margem de rochas entre os dois (shore.png, nas 4 bordas).
## A cada 10 fases o tom muda levemente; nas fases de chefe tudo fica mais vermelho e um brilho pulsa.
## Ordem de desenho: lava (filho atrás) < chão (este nó) < margem (filho na frente) < brasas.

const PALETTES := [
    [Color(0.07, 0.03, 0.12), Color(0.16, 0.05, 0.18)],   # roxo sombrio
    [Color(0.10, 0.02, 0.03), Color(0.24, 0.05, 0.04)],   # vermelho
    [Color(0.02, 0.07, 0.09), Color(0.05, 0.15, 0.17)],   # abismo
    [Color(0.07, 0.07, 0.08), Color(0.17, 0.15, 0.14)],   # cinzas
]
# tom do chão por bloco de 10 fases (multiplica a imagem; branco = original)
const TINTS := [Color(1.0, 1.0, 1.0), Color(1.0, 0.82, 0.78), Color(0.78, 0.92, 1.0), Color(0.9, 0.88, 0.86)]
const TINT_STRENGTH := 0.55
const SHORE_OUT := 110.0             # quanto a faixa da margem avança para dentro da lava (a parede de rocha fica ~25 px fora do chão)
const CORNER_AT := Vector2(87.5, 175.0)   # ponto da peça de canto que fica no canto do chão (pedra acima/direita, lava abaixo/esquerda)
const SHORE_END := 45.0              # quanto cada faixa passa do canto do chão (as faixas se cruzam nos cantos)
const LAVA_EXTRA := 600.0            # lava desenhada além do mundo (telas muito largas nunca veem o vazio)

var _stage := 1
var _embers: CPUParticles2D
var _glow: ColorRect
var _lava: Node2D
var _shore: Node2D
var _boss_mode := false
var _t := 0.0
var _pulse := 0.0
var _floor_tex: Texture2D
var _lava_tex: Texture2D
var _shore_tex: Texture2D
var _corner_tex: Texture2D

func _ready() -> void:
    z_index = -100
    texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
    _floor_tex = EnvArt.texture("floor.png")
    _lava_tex = EnvArt.texture("lava.png")
    _shore_tex = EnvArt.texture("shore.png")
    _corner_tex = EnvArt.texture("corner.png")
    _lava = Node2D.new()
    _lava.show_behind_parent = true
    _lava.draw.connect(_draw_lava)
    add_child(_lava)
    _shore = Node2D.new()
    _shore.draw.connect(_draw_shore)
    add_child(_shore)
    var world := Arena.WORLD
    _glow = ColorRect.new()
    _glow.position = -Vector2(LAVA_EXTRA, LAVA_EXTRA)
    _glow.size = world + Vector2(LAVA_EXTRA, LAVA_EXTRA) * 2.0
    _glow.color = Color(0.9, 0.1, 0.02, 0.0)
    _glow.material = SpriteLib.additive()
    _glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _glow.visible = false
    add_child(_glow)
    Events.boss_warning.connect(func(_n: String, _m: bool): _pulse = 1.0)
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
    _redraw_all()

func set_fx(on: bool) -> void:
    if _embers != null:
        _embers.emitting = on
        _embers.visible = on

func _set_boss_mode(on: bool) -> void:
    _boss_mode = on
    _glow.visible = on
    _embers.amount = 160 if on else 70

## A lava "respira" (brilho sobe e desce devagar) — só muda o modulate, sem redesenhar.
func _process(delta: float) -> void:
    _t += delta
    var k: float = 0.92 + 0.08 * sin(_t * 1.6) + 0.03 * sin(_t * 4.1)
    _lava.modulate = Color(k, k, k)
    if not _boss_mode and _pulse <= 0.0:
        return
    _pulse = maxf(0.0, _pulse - delta * 1.2)
    _glow.visible = _boss_mode or _pulse > 0.0
    var base: float = 0.06 + 0.04 * sin(_t * 3.0) if _boss_mode else 0.0
    _glow.color.a = base + _pulse * 0.25

func set_stage(s: int) -> void:
    if s != _stage:
        _stage = s
        _set_boss_mode(StageLogic.is_boss_stage(s))
        _redraw_all()

func _redraw_all() -> void:
    queue_redraw()
    _lava.queue_redraw()
    _shore.queue_redraw()

func _tint() -> Color:
    var idx: int = UiLogic.stage_palette_index(_stage)
    var tint: Color = Color.WHITE.lerp(TINTS[idx], TINT_STRENGTH)
    if StageLogic.is_boss_stage(_stage):
        tint = tint.lerp(Color(1.0, 0.55, 0.5), 0.35)
    return tint

## Chão de pedra (repetido) só dentro da área jogável.
func _draw() -> void:
    var f := Arena.floor_rect()
    if _floor_tex != null:
        draw_texture_rect(_floor_tex, f, true, _tint())
    else:
        draw_rect(f, Color(0.12, 0.08, 0.1))

## Lava cobrindo o mundo inteiro (e um pouco além).
func _draw_lava() -> void:
    var r := Arena.world_rect().grow(LAVA_EXTRA)
    var lava_tint: Color = Color(1.0, 0.85, 0.8) if StageLogic.is_boss_stage(_stage) else Color.WHITE
    if _lava_tex != null:
        _lava.draw_texture_rect(_lava_tex, r, true, lava_tint)
    else:
        _lava.draw_rect(r, Color(0.9, 0.35, 0.05))

## Margem de rochas nas 4 bordas do chão (a imagem tem a lava à ESQUERDA; gira para a lava ficar sempre para fora).
func _draw_shore() -> void:
    if _shore_tex == null:
        return
    var f := Arena.floor_rect()
    var w: float = float(_shore_tex.get_width())
    var tint := _tint()
    # esquerda
    _shore.draw_set_transform(Vector2(f.position.x - SHORE_OUT, f.position.y - SHORE_END), 0.0)
    _shore.draw_texture_rect(_shore_tex, Rect2(0.0, 0.0, w, f.size.y + SHORE_END * 2.0), true, tint)
    # direita
    _shore.draw_set_transform(Vector2(f.end.x + SHORE_OUT, f.end.y + SHORE_END), PI)
    _shore.draw_texture_rect(_shore_tex, Rect2(0.0, 0.0, w, f.size.y + SHORE_END * 2.0), true, tint)
    # cima
    _shore.draw_set_transform(Vector2(f.end.x + SHORE_END, f.position.y - SHORE_OUT), PI / 2.0)
    _shore.draw_texture_rect(_shore_tex, Rect2(0.0, 0.0, w, f.size.x + SHORE_END * 2.0), true, tint)
    # baixo
    _shore.draw_set_transform(Vector2(f.position.x - SHORE_END, f.end.y + SHORE_OUT), -PI / 2.0)
    _shore.draw_texture_rect(_shore_tex, Rect2(0.0, 0.0, w, f.size.x + SHORE_END * 2.0), true, tint)
    # cantos: peça própria (lava em 2 lados) girada para cada canto, por cima do encontro das faixas
    if _corner_tex != null:
        var cs: Vector2 = _corner_tex.get_size()
        var corners := [[Vector2(f.position.x, f.end.y), 0.0], [f.position, PI / 2.0],
            [Vector2(f.end.x, f.position.y), PI], [f.end, -PI / 2.0]]
        for cr in corners:
            _shore.draw_set_transform(cr[0], cr[1])
            _shore.draw_texture_rect(_corner_tex, Rect2(-CORNER_AT, cs), false, tint)
    _shore.draw_set_transform(Vector2.ZERO, 0.0)
