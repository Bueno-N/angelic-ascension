class_name LanceFx
extends Node2D
## Animação da habilidade LANÇA CELESTIAL (assets/skills/celestial_lance/frame_1..6.png, de art_source/spear_frames.zip):
##   1) frame_1: a lança surge de um círculo de luz acima do anjo;  2) frame_2: lança erguida com raios (carregando);
##   3) frame_3 -> frame_4: disparo e voo até o inimigo (a PONTA lidera e acompanha o alvo se ele andar);
##   4) frame_5: impacto (emite `hit` — o dano é aplicado aí);  5) frame_6: a luz se desfaz.
## Para trocar a arte: substitua os PNGs da pasta (mesmos nomes) e, se o tamanho mudar, ajuste PIVOTS.

signal hit(at: Vector2)

const DIR := "res://assets/skills/celestial_lance/"
## ponto de referência de cada quadro (pixels da imagem): centro nos de surgir/carregar, PONTA nos de voo, estrela no impacto
const PIVOTS := {
    "frame_1": Vector2(271.0, 299.0), "frame_2": Vector2(153.0, 384.0),
    "frame_3": Vector2(741.0, 187.0), "frame_4": Vector2(781.0, 220.0),
    "frame_5": Vector2(610.0, 241.0), "frame_6": Vector2(500.0, 184.0),
}
const SCALE := 0.15                # quadros de ~750 px -> ~115 px na tela
const SUMMON_OFFSET := Vector2(0.0, -70.0)   # onde a lança surge, em relação ao anjo
## duração de cada fase (s)
const T_SUMMON := 0.14
const T_CHARGE := 0.12
const SPEED := 1700.0
const MIN_FLIGHT := 0.1
const T_IMPACT := 0.1
const T_FADE := 0.24

static var _tex: Dictionary = {}

var phase := "summon"              # summon -> charge -> flight -> impact -> fade
var _t := 0.0
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _target: Node2D
var _flight := 0.1
var _spr: Sprite2D

static func tex(name: String) -> Texture2D:
    if not _tex.has(name):
        var p: String = DIR + name + ".png"
        _tex[name] = load(p) if ResourceLoader.exists(p) else null
    return _tex[name]

## Cria a lança acima de `from` mirando em `target`.
static func spawn(parent: Node, from: Vector2, target: Node2D) -> LanceFx:
    var l := LanceFx.new()
    l._from = from + SUMMON_OFFSET
    l._target = target
    l._to = target.global_position if is_instance_valid(target) else from
    l._spr = Sprite2D.new()
    l._spr.centered = false
    l._spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    l._spr.scale = Vector2(SCALE, SCALE)
    l.add_child(l._spr)
    l.position = l._from
    l.z_index = 6
    l._set_frame("frame_1")
    parent.add_child(l)
    return l

func _set_frame(f: String) -> void:
    if _spr.texture == tex(f):
        return
    _spr.texture = tex(f)
    _spr.offset = -PIVOTS[f]

func current_frame() -> String:
    for f in PIVOTS:
        if tex(f) == _spr.texture:
            return f
    return ""

func _process(delta: float) -> void:
    _t += delta
    if is_instance_valid(_target) and phase != "impact" and phase != "fade":
        _to = _target.global_position
    match phase:
        "summon":
            _spr.modulate.a = minf(1.0, _t / 0.06)
            if _t >= T_SUMMON:
                _next("charge", "frame_2")
        "charge":
            if _t >= T_CHARGE:
                _flight = maxf(MIN_FLIGHT, _from.distance_to(_to) / SPEED)
                rotation = (_to - _from).angle()
                _next("flight", "frame_3")
        "flight":
            var k: float = clampf(_t / _flight, 0.0, 1.0)
            position = _from.lerp(_to, k)
            rotation = (_to - _from).angle()
            _set_frame("frame_3" if k < 0.35 else "frame_4")
            if k >= 1.0:
                hit.emit(_to)
                _next("impact", "frame_5")
        "impact":
            if _t >= T_IMPACT:
                _next("fade", "frame_6")
        "fade":
            _spr.modulate.a = 1.0 - clampf(_t / T_FADE, 0.0, 1.0)
            if _t >= T_FADE:
                queue_free()

func _next(p: String, f: String) -> void:
    phase = p
    _t = 0.0
    _set_frame(f)
    if p == "charge":
        rotation = 0.0
