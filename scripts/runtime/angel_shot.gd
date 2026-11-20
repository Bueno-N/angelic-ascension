class_name AngelShot
extends Node2D
## Disparos do ataque básico do anjo, separados do corpo (assets/angel/), para MIRAR no inimigo em qualquer direção:
##   muzzle = clarão na mão; bolt = projétil de luz que voa até o alvo (ataque normal);
##   beam   = o RAIO da A MORTE DO INFERNO, saindo da mão e esticado até o alvo (substitui o projétil).
## Só visual: o dano continua sendo aplicado pelo Player no momento do ataque.

const DIR := "res://assets/angel/"
const SCALE := 0.5
## ponto de onde cada imagem "sai" (a mão), em pixels da imagem
const PIVOTS := {"atk_muzzle": Vector2(20.0, 53.0), "atk_bolt": Vector2(4.0, 76.0), "hell_beam": Vector2(6.0, 124.0)}
const BOLT_SPEED := 2000.0
const BEAM_TIME := 0.28
const MUZZLE_TIME := 0.10

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

static func _make(parent: Node, k: String, img: String, from: Vector2, to: Vector2) -> AngelShot:
    var s := AngelShot.new()
    s.kind = k
    s._from = from
    s._to = to
    s._spr = Sprite2D.new()
    s._spr.texture = tex(img)
    s._spr.centered = false
    s._spr.offset = -PIVOTS[img]
    s._spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    s._spr.material = SpriteLib.additive()
    s.add_child(s._spr)
    s.position = from
    s.rotation = (to - from).angle()
    s.z_index = 5
    parent.add_child(s)
    return s

## Clarão na mão (ataque normal).
static func muzzle(parent: Node, at: Vector2, to: Vector2) -> AngelShot:
    var s := _make(parent, "muzzle", "atk_muzzle", at, to)
    s._dur = MUZZLE_TIME
    s._base_scale = Vector2(SCALE, SCALE) * 0.8
    s._spr.scale = s._base_scale
    return s

## Projétil de luz voando da mão até o alvo (ataque normal).
static func bolt(parent: Node, from: Vector2, to: Vector2) -> AngelShot:
    var s := _make(parent, "bolt", "atk_bolt", from, to)
    s._dur = maxf(0.06, from.distance_to(to) / BOLT_SPEED)
    s._base_scale = Vector2(SCALE, SCALE)
    s._spr.scale = s._base_scale
    return s

## Raio da Morte do Inferno: sai da mão e estica até o alvo (um pouco além), some rápido.
static func beam(parent: Node, from: Vector2, to: Vector2) -> AngelShot:
    var s := _make(parent, "beam", "hell_beam", from, to)
    s._dur = BEAM_TIME
    var native: float = float(s._spr.texture.get_width()) * SCALE if s._spr.texture != null else 230.0
    var stretch: float = clampf((from.distance_to(to) + 40.0) / native, 0.55, 1.6)
    s._base_scale = Vector2(SCALE * stretch, SCALE * 0.85)
    s._spr.scale = s._base_scale
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
            _spr.modulate.a = 1.0
        "beam":
            # abre rápido, segura, e afina sumindo
            var open: float = minf(1.0, k / 0.15)
            _spr.scale = Vector2(_base_scale.x * (0.7 + 0.3 * open), _base_scale.y * (1.0 - 0.45 * k))
            _spr.modulate.a = 1.0 if k < 0.45 else 1.0 - (k - 0.45) / 0.55
        _:
            _spr.scale = _base_scale * (1.0 + 0.35 * k)
            _spr.modulate.a = 1.0 - k
    if _t >= _dur:
        queue_free()
