class_name AngelShot
extends Node2D
## Disparos do anjo, separados do corpo (assets/angel/), para MIRAR no inimigo em qualquer direção:
##   muzzle = esfera de luz que acende na mão;  bolt = cometa de luz que voa até o alvo e estoura (pop) ao chegar;
##   beam   = o RAIO da A MORTE DO INFERNO, saindo da mão e esticado até o alvo (substitui o cometa);
##   burst  = redemoinho de luz da transformação da Morte do Inferno.
## Só visual: o dano continua sendo aplicado pelo Player no momento do ataque.

const DIR := "res://assets/angel/"
## ponto de referência de cada imagem: a cabeça do cometa, o centro da esfera, a origem do raio
const PIVOTS := {"orb": Vector2(31.0, 24.0), "comet": Vector2(68.0, 25.0), "hell_beam": Vector2(6.0, 124.0), "swirl": Vector2(70.5, 67.0)}
const BOLT_SPEED := 1500.0
const BOLT_SCALE := 0.85
const BEAM_SCALE := 0.5
const BEAM_TIME := 0.28
const MUZZLE_TIME := 0.12
const POP_TIME := 0.16
const BURST_TIME := 0.55

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

## Raio da Morte do Inferno: sai da mão e estica até o alvo (um pouco além), some rápido.
static func beam(parent: Node, from: Vector2, to: Vector2) -> AngelShot:
    var t: Texture2D = tex("hell_beam")
    var native: float = float(t.get_width()) * BEAM_SCALE if t != null else 230.0
    var stretch: float = clampf((from.distance_to(to) + 40.0) / native, 0.55, 1.6)
    return _make(parent, "beam", "hell_beam", from, to, BEAM_TIME, Vector2(BEAM_SCALE * stretch, BEAM_SCALE * 0.85))

## Redemoinho de luz (transformação da Morte do Inferno).
static func burst(parent: Node, at: Vector2) -> AngelShot:
    var s := _make(parent, "burst", "swirl", at, at, BURST_TIME, Vector2(0.5, 0.5))
    s.z_index = -1
    return s

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
        "beam":
            # abre rápido, segura, e afina sumindo
            var open: float = minf(1.0, k / 0.15)
            _spr.scale = Vector2(_base_scale.x * (0.7 + 0.3 * open), _base_scale.y * (1.0 - 0.45 * k))
            _spr.modulate.a = 1.0 if k < 0.45 else 1.0 - (k - 0.45) / 0.55
        "burst":
            rotation += delta * 5.0
            _spr.scale = _base_scale * (0.6 + 1.6 * k)
            _spr.modulate.a = 1.0 if k < 0.35 else 1.0 - (k - 0.35) / 0.65
        _:   # muzzle / pop: cresce e some
            _spr.scale = _base_scale * (1.0 + 0.8 * k)
            _spr.modulate.a = 1.0 - k
    if _t >= _dur:
        if kind == "bolt" and get_parent() != null:
            AngelShot.pop(get_parent(), _to)
        queue_free()
