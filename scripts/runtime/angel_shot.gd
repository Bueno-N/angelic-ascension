class_name AngelShot
extends Node2D
## Disparos do anjo, separados do corpo (assets/angel/), para MIRAR no inimigo em qualquer direção:
##   muzzle = esfera de luz que acende na mão;  bolt = cometa de luz que voa até o alvo e estoura (pop) ao chegar;
##   sphere = a ESFERA DE PODER da A MORTE DO INFERNO (redemoinho dourado do Power Surge): sai da mão girando,
##            voa até o alvo e explode (blast) ao chegar. Substitui o cometa enquanto a habilidade está ativa.
## Só visual: o dano continua sendo aplicado pelo Player no momento do ataque.

const DIR := "res://assets/angel/"
## ponto de referência de cada imagem: a cabeça do cometa, o centro da esfera, a origem do raio
const PIVOTS := {"orb": Vector2(31.0, 24.0), "comet": Vector2(68.0, 25.0), "swirl": Vector2(70.5, 67.0)}
const BOLT_SPEED := 1500.0
const BOLT_SCALE := 0.85
const SPHERE_SPEED := 900.0
const SPHERE_SCALE := 0.42         # redemoinho de ~140 px -> ~60 px voando
const BLAST_TIME := 0.32
const MUZZLE_TIME := 0.12
const POP_TIME := 0.16

static var _tex: Dictionary = {}

var kind := ""
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _t := 0.0
var _dur := 0.1
var _spr: Sprite2D
var _base_scale := Vector2.ONE

static func tex(name: String) -> Texture2D:
    if not _tex.has(name):
        var p: String = DIR + name + ".png"
        _tex[name] = load(p) if ResourceLoader.exists(p) else null
    return _tex[name]

static func _make(parent: Node, k: String, img: String, from: Vector2, to: Vector2, dur: float, sc: Vector2) -> AngelShot:
    var s := AngelShot.new()
    s.kind = k
    s._from = from
    s._to = to
    s._dur = dur
    s._base_scale = sc
    s._spr = Sprite2D.new()
    s._spr.texture = tex(img)
    s._spr.centered = false
    s._spr.offset = -PIVOTS[img]
    s._spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    s._spr.material = SpriteLib.additive()
    s._spr.scale = sc
    s.add_child(s._spr)
    s.position = from
    if to != from:
        s.rotation = (to - from).angle()
    s.z_index = 5
    parent.add_child(s)
    return s

## Esfera de luz acendendo na mão (ataque normal).
static func muzzle(parent: Node, at: Vector2, to: Vector2) -> AngelShot:
    return _make(parent, "muzzle", "orb", at, to, MUZZLE_TIME, Vector2(0.45, 0.45))

## Cometa de luz voando da mão até o alvo (ataque normal); estoura ao chegar.
static func bolt(parent: Node, from: Vector2, to: Vector2) -> AngelShot:
    return _make(parent, "bolt", "comet", from, to, maxf(0.06, from.distance_to(to) / BOLT_SPEED), Vector2(BOLT_SCALE, BOLT_SCALE))

## Estouro de luz no alvo.
static func pop(parent: Node, at: Vector2) -> AngelShot:
    return _make(parent, "pop", "orb", at, at, POP_TIME, Vector2(0.6, 0.6))

## Esfera de poder da Morte do Inferno: sai da mão girando e voa até o alvo; explode ao chegar.
static func sphere(parent: Node, from: Vector2, to: Vector2) -> AngelShot:
    return _make(parent, "sphere", "swirl", from, to, maxf(0.08, from.distance_to(to) / SPHERE_SPEED), Vector2(SPHERE_SCALE, SPHERE_SCALE))

## Explosão da esfera de poder no alvo.
static func blast(parent: Node, at: Vector2) -> AngelShot:
    return _make(parent, "blast", "swirl", at, at, BLAST_TIME, Vector2(0.5, 0.5))

## Quanto falta (0..1) — usado nos testes.
func progress() -> float:
    return clampf(_t / _dur, 0.0, 1.0)

func _process(delta: float) -> void:
    _t += delta
    var k: float = progress()
    match kind:
        "bolt":
            position = _from.lerp(_to, k)
            _spr.scale = _base_scale * (0.75 + 0.25 * minf(1.0, k * 4.0))   # o cometa "estica" ao sair da mão
        "sphere":
            position = _from.lerp(_to, k)
            _spr.rotation += delta * 9.0                                     # gira enquanto voa
            _spr.scale = _base_scale * (0.6 + 0.4 * minf(1.0, k * 5.0)) * (1.0 + 0.06 * sin(_t * 30.0))
        "blast":
            _spr.rotation += delta * 6.0
            _spr.scale = _base_scale * (0.8 + 1.2 * k)
            _spr.modulate.a = 1.0 if k < 0.3 else 1.0 - (k - 0.3) / 0.7
        _:   # muzzle / pop: cresce e some
            _spr.scale = _base_scale * (1.0 + 0.8 * k)
            _spr.modulate.a = 1.0 - k
    if _t >= _dur:
        if kind == "bolt" and get_parent() != null:
            AngelShot.pop(get_parent(), _to)
        elif kind == "sphere" and get_parent() != null:
            AngelShot.blast(get_parent(), _to)
        queue_free()
