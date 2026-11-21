class_name OrbitSwords
extends Node2D
## Espadas do Paraíso: espadas de luz giram em volta do anjo (filho do Player) e ferem a cada `tick`.
## Arte nova (assets/skills/swords_of_paradise/sword_00..11): surgem (00..02), brilham em laço (03..08) e se desfazem (09..11).
## A espada da arte aponta para CIMA; aqui ela é girada para apontar para fora do círculo.

const APPEAR := ["sword_00", "sword_01", "sword_02"]
const LOOP := ["sword_03", "sword_04", "sword_05", "sword_06", "sword_07", "sword_08"]
const VANISH := ["sword_09", "sword_10", "sword_11"]
const FRAME_T := 0.08
const SCALE := 0.8                    # espada de ~110 px no quadro -> ~88 px na tela

var id := ""
var atk := 0.0
var glow := 1.0
var duration := 4.0
var count := 3
var orbit_r := 90.0
var hit_r := 40.0
var tick := 0.5
var _age := 0.0
var _tick_t := 0.0
var _sprites: Array = []
var _art := false

func _ready() -> void:
    _art = SkillFx.has_art("swords_of_paradise")
    for i in range(count):
        var s: Node2D
        if _art:
            var sp := Sprite2D.new()
            sp.texture = SkillFx.tex("swords_of_paradise", APPEAR[0])
            sp.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
            sp.scale = Vector2(SCALE, SCALE)
            s = sp
        else:
            var a := SpriteLib.make("sword_orbit", "idle", 1.8)
            a.material = SpriteLib.additive()
            a.modulate = Color(1.0, 0.95, 0.7, 0.95)
            s = a
        add_child(s)
        _sprites.append(s)

## Quadro da arte para a idade atual (lógica pura, testável).
static func frame_for(age: float, dur: float) -> String:
    var left: float = dur - age
    var vanish_t: float = FRAME_T * float(VANISH.size())
    if left <= vanish_t:
        return VANISH[clampi(int((vanish_t - left) / FRAME_T), 0, VANISH.size() - 1)]
    var n := int(age / FRAME_T)
    if n < APPEAR.size():
        return APPEAR[n]
    return LOOP[(n - APPEAR.size()) % LOOP.size()]

func _process(delta: float) -> void:
    _age += delta
    _tick_t -= delta
    if _tick_t <= 0.0:
        _tick_t = tick
        _hit()
    if _age >= duration:
        queue_free()
        return
    var fr := frame_for(_age, duration)
    for i in range(_sprites.size()):
        var a: float = _age * 4.0 + TAU * float(i) / float(maxi(1, count))
        _sprites[i].position = Vector2.from_angle(a) * orbit_r
        _sprites[i].rotation = a + PI / 2.0   # a ponta aponta para fora
        if _art:
            (_sprites[i] as Sprite2D).texture = SkillFx.tex("swords_of_paradise", fr)
        else:
            var fade: float = clampf((duration - _age) / 0.4, 0.0, 1.0)
            _sprites[i].modulate.a = 0.95 * fade

func _sword_local(i: int) -> Vector2:
    return Vector2.from_angle(_age * 4.0 + TAU * float(i) / float(maxi(1, count))) * orbit_r

func _hit() -> void:
    for e in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(e) or e.hp <= 0.0:
            continue
        for i in range(count):
            if e.global_position.distance_to(to_global(_sword_local(i))) <= hit_r + e.radius:
                SkillCaster.deal_damage(e, id, atk, glow)
                break
