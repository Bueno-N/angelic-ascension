class_name AngelShot
extends Node2D
## Disparos do anjo, separados do corpo (assets/angel/), para MIRAR no inimigo em qualquer direção:
##   muzzle = esfera de luz que acende na mão;  bolt = cometa de luz que voa até o alvo e estoura (pop) ao chegar;
##   burst  = redemoinho de luz da transformação da Morte do Inferno.
## Golpe da A MORTE DO INFERNO (art_source/hell_projectile_sheet.webp), no lugar do cometa:
##   hcharge = esfera com penas acendendo na mão; hflash = estrela de luz do disparo;
##   hbolt   = projétil de penas e raios que voa até o alvo (hp_bolt_0 -> 1 -> 2 conforme avança);
##   hfade   = a luz se desfazendo em penas no alvo.
## Só visual: o dano continua sendo aplicado pelo Player no momento do ataque.

const DIR := "res://assets/angel/"
## ponto de referência de cada imagem: a cabeça do projétil, o centro da esfera/estrela
const PIVOTS := {
    "orb": Vector2(31.0, 24.0), "comet": Vector2(68.0, 25.0), "swirl": Vector2(70.5, 67.0),
    "hp_charge": Vector2(153.5, 129.5), "hp_burst": Vector2(222.0, 225.0), "hp_fade": Vector2(232.0, 112.0),
    "hp_bolt_0": Vector2(520.0, 139.0), "hp_bolt_1": Vector2(560.0, 181.0), "hp_bolt_2": Vector2(470.0, 172.0),
}
const HBOLT_FRAMES := ["hp_bolt_0", "hp_bolt_1", "hp_bolt_2"]
const BOLT_SPEED := 1500.0
const BOLT_SCALE := 0.85
const HBOLT_SPEED := 1100.0
const HBOLT_SCALE := 0.22          # projétil de ~550 px -> ~120 px na tela
const MUZZLE_TIME := 0.12
const POP_TIME := 0.16
const BURST_TIME := 0.55
const HCHARGE_TIME := 0.16
const HFLASH_TIME := 0.2
const HFADE_TIME := 0.32

static var _tex: Dictionary = {}

var kind := ""
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _t := 0.0
var _dur := 0.1
var _spr: Sprite2D
var _base_scale := Vector2.ONE
var _frame := ""

static func tex(name: String) -> Texture2D:
    if not _tex.has(name):
        var p: String = DIR + name + ".png"
        _tex[name] = load(p) if ResourceLoader.exists(p) else null
    return _tex[name]

## additive = brilho somado (luz pura); os efeitos da Morte do Inferno têm penas e detalhes escuros: mistura normal.
static func _make(parent: Node, k: String, img: String, from: Vector2, to: Vector2, dur: float, sc: Vector2, additive := true) -> AngelShot:
    var s := AngelShot.new()
    s.kind = k
    s._from = from
    s._to = to
    s._dur = dur
    s._base_scale = sc
    s._spr = Sprite2D.new()
    s._spr.centered = false
    s._spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    if additive:
        s._spr.material = SpriteLib.additive()
    s._spr.scale = sc
    s.add_child(s._spr)
    s._set_frame(img)
    s.position = from
    if to != from:
        s.rotation = (to - from).angle()
    s.z_index = 5
    parent.add_child(s)
    return s

func _set_frame(img: String) -> void:
    if img == _frame:
        return
    _frame = img
    _spr.texture = tex(img)
    _spr.offset = -PIVOTS[img]

## Esfera de luz acendendo na mão (ataque normal).
static func muzzle(parent: Node, at: Vector2, to: Vector2) -> AngelShot:
    return _make(parent, "muzzle", "orb", at, to, MUZZLE_TIME, Vector2(0.45, 0.45))

## Cometa de luz voando da mão até o alvo (ataque normal); estoura ao chegar.
static func bolt(parent: Node, from: Vector2, to: Vector2) -> AngelShot:
    return _make(parent, "bolt", "comet", from, to, maxf(0.06, from.distance_to(to) / BOLT_SPEED), Vector2(BOLT_SCALE, BOLT_SCALE))

## Estouro de luz no alvo.
static func pop(parent: Node, at: Vector2) -> AngelShot:
    return _make(parent, "pop", "orb", at, at, POP_TIME, Vector2(0.6, 0.6))

## Golpe da Morte do Inferno: esfera com penas + estrela na mão, e o projétil voando até o alvo.
static func hell_shot(parent: Node, from: Vector2, to: Vector2) -> AngelShot:
    _make(parent, "hcharge", "hp_charge", from, from, HCHARGE_TIME, Vector2(0.2, 0.2), false)
    _make(parent, "hflash", "hp_burst", from, from, HFLASH_TIME, Vector2(0.12, 0.12), false)
    return _make(parent, "hbolt", "hp_bolt_0", from, to, maxf(0.14, from.distance_to(to) / HBOLT_SPEED), Vector2(HBOLT_SCALE, HBOLT_SCALE), false)

## A luz do golpe se desfazendo em penas no alvo.
static func hell_fade(parent: Node, at: Vector2, dir_angle: float) -> AngelShot:
    var s := _make(parent, "hfade", "hp_fade", at, at, HFADE_TIME, Vector2(0.24, 0.24), false)
    s.rotation = dir_angle
    return s

## Redemoinho de luz (transformação da Morte do Inferno).
static func burst(parent: Node, at: Vector2) -> AngelShot:
    var s := _make(parent, "burst", "swirl", at, at, BURST_TIME, Vector2(0.5, 0.5))
    s.z_index = -1
    return s

## Quadro do projétil da Morte do Inferno conforme o quanto já voou (0..1).
static func hbolt_frame(k: float) -> String:
    return HBOLT_FRAMES[clampi(int(k * float(HBOLT_FRAMES.size())), 0, HBOLT_FRAMES.size() - 1)]

## Quanto falta (0..1) — usado nos testes.
func progress() -> float:
    return clampf(_t / _dur, 0.0, 1.0)

func current_frame() -> String:
    return _frame

func _process(delta: float) -> void:
    _t += delta
    var k: float = progress()
    match kind:
        "bolt":
            position = _from.lerp(_to, k)
            _spr.scale = _base_scale * (0.75 + 0.25 * minf(1.0, k * 4.0))   # o cometa "estica" ao sair da mão
        "hbolt":
            position = _from.lerp(_to, k)
            _set_frame(hbolt_frame(k))
            # a cauda "cresce" enquanto sai da mão (no começo não passa por cima do anjo)
            var grow: float = minf(1.0, k / 0.4)
            _spr.scale = Vector2(_base_scale.x * (0.15 + 0.85 * grow), _base_scale.y * (0.7 + 0.3 * grow))
        "burst":
            rotation += delta * 5.0
            _spr.scale = _base_scale * (0.6 + 1.6 * k)
            _spr.modulate.a = 1.0 if k < 0.35 else 1.0 - (k - 0.35) / 0.65
        "hcharge":
            _spr.rotation += delta * 4.0
            _spr.scale = _base_scale * (0.8 + 0.5 * k)
            _spr.modulate.a = 1.0 - k * k
        "hflash":
            _spr.scale = _base_scale * (0.6 + 1.0 * k)
            _spr.modulate.a = 1.0 if k < 0.3 else 1.0 - (k - 0.3) / 0.7
        "hfade":
            _spr.scale = _base_scale * (1.0 + 0.3 * k)
            _spr.modulate.a = 1.0 - k
        _:   # muzzle / pop: cresce e some
            _spr.scale = _base_scale * (1.0 + 0.8 * k)
            _spr.modulate.a = 1.0 - k
    if _t >= _dur:
        if get_parent() != null:
            if kind == "bolt":
                AngelShot.pop(get_parent(), _to)
            elif kind == "hbolt":
                AngelShot.hell_fade(get_parent(), _to, rotation)
        queue_free()
