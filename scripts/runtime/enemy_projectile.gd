class_name EnemyProjectile
extends Node2D
## Projétil inimigo (bola de fogo, projéteis infernais). Fica no mesmo container dos inimigos,
## então é removido junto quando a fase muda.

var velocity := Vector2.ZERO
var damage := 1.0
var hit_radius := 14.0
var life := 4.0
var player: Player

func _process(delta: float) -> void:
    life -= delta
    position += velocity * delta
    if player != null and is_instance_valid(player) and player.global_position.distance_to(global_position) <= hit_radius + 16.0:
        player.take_damage(damage)
        queue_free()
        return
    if life <= 0.0:
        queue_free()
        return
    queue_redraw()

func _draw() -> void:
    draw_circle(Vector2.ZERO, hit_radius, Color(1.0, 0.4, 0.1, 0.9))
    draw_circle(Vector2.ZERO, hit_radius * 0.5, Color(1.0, 0.9, 0.5))
