class_name ArchangelAlly
extends Node2D
## Guerreiro celestial invocado: persegue o inimigo mais próximo e golpeia a cada `tick`.

var id := ""
var atk := 0.0
var glow := 1.0
var duration := 5.0
var tick := 2.0
var _age := 0.0
var _cd := 0.0

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
        if best_d > reach:
            global_position += to_t / maxf(best_d, 0.001) * 420.0 * delta
        elif _cd <= 0.0:
            _cd = tick
            SkillCaster.deal_damage(best, id, atk, glow)
    if _age >= duration:
        queue_free()
        return
    queue_redraw()

func _draw() -> void:
    draw_colored_polygon(PackedVector2Array([Vector2(-6, -2), Vector2(-24, -22), Vector2(-16, 4)]), Color(0.9, 0.95, 1.0, 0.9))
    draw_colored_polygon(PackedVector2Array([Vector2(6, -2), Vector2(24, -22), Vector2(16, 4)]), Color(0.9, 0.95, 1.0, 0.9))
    draw_circle(Vector2.ZERO, 12.0, Color(1.0, 0.9, 0.55))
    draw_circle(Vector2(0, -16), 6.0, Color(1.0, 0.97, 0.85))
