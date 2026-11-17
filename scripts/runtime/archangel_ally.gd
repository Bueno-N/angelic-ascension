class_name ArchangelAlly
extends Node2D
## Guerreiro celestial invocado (sprite animado): persegue o inimigo mais próximo e golpeia a cada `tick`.

var id := ""
var atk := 0.0
var glow := 1.0
var duration := 5.0
var tick := 2.0
var _age := 0.0
var _cd := 0.0
var _spr: AnimatedSprite2D

func _ready() -> void:
    _spr = SpriteLib.make("ally", "walk", 2.0)
    add_child(_spr)

func _process(delta: float) -> void:
    _age += delta
    _cd -= delta
    var best: Node2D = null
    var best_d := INF
    for e in get_tree().get_nodes_in_group("enemies"):
        if is_instance_valid(e) and e.hp > 0.0:
            var d: float = e.global_position.distance_to(global_position)
            if d < best_d:
                best_d = d
                best = e
    if best != null:
        var to_t: Vector2 = best.global_position - global_position
        var reach: float = 28.0 + float(best.radius)
        _spr.flip_h = to_t.x < 0.0
        if best_d > reach:
            global_position += to_t / maxf(best_d, 0.001) * 420.0 * delta
        elif _cd <= 0.0:
            _cd = tick
            SkillCaster.deal_damage(best, id, atk, glow)
            AudioHub.play("ally_strike", 1.0, 0.1)
            var parent := get_parent()
            if parent != null:
                SpriteFx.spawn(parent, "fx_hit", best.global_position, 2.0, Color(1.0, 0.9, 0.5))
    var fade: float = clampf((duration - _age) / 0.5, 0.0, 1.0)
    _spr.modulate.a = fade
    if _age >= duration:
        queue_free()
