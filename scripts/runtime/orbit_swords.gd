class_name OrbitSwords
extends Node2D
## Espadas do Paraíso: espadas de luz (sprite) giram em volta do anjo (filho do Player) e ferem a cada `tick`.

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

func _ready() -> void:
    for i in range(count):
        var s := SpriteLib.make("sword_orbit", "idle", 1.8)
        s.material = SpriteLib.additive()
        s.modulate = Color(1.0, 0.95, 0.7, 0.95)
        add_child(s)
        _sprites.append(s)

func _process(delta: float) -> void:
    _age += delta
    _tick_t -= delta
    if _tick_t <= 0.0:
        _tick_t = tick
        _hit()
    if _age >= duration:
        queue_free()
        return
    for i in range(_sprites.size()):
        var a: float = _age * 4.0 + TAU * float(i) / float(maxi(1, count))
        _sprites[i].position = Vector2.from_angle(a) * orbit_r
        _sprites[i].rotation = a + PI / 2.0   # a ponta aponta para fora
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
