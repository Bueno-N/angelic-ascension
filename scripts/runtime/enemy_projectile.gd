class_name EnemyProjectile
extends Node2D
## Projétil inimigo (bola de fogo, projéteis infernais): sprite animado. Fica no mesmo container dos
## inimigos, então é removido junto quando a fase muda.

var velocity := Vector2.ZERO
var damage := 1.0
var hit_radius := 14.0
var life := 4.0
var homing := 0.0                    # rad/s de curva em direção ao anjo (0 = reto)
var tint := Color.WHITE
var player: Player
var _spr: AnimatedSprite2D

func _ready() -> void:
    _spr = SpriteLib.make("fx_fireball", "play", 1.6)
    _spr.rotation = velocity.angle()
    _spr.modulate = tint
    add_child(_spr)

func _process(delta: float) -> void:
    life -= delta
    if homing > 0.0 and player != null and is_instance_valid(player):
        var want: float = (player.global_position - global_position).angle()
        velocity = velocity.rotated(clampf(angle_difference(velocity.angle(), want), -homing * delta, homing * delta))
        if _spr != null:
            _spr.rotation = velocity.angle()
    position += velocity * delta
    if player != null and is_instance_valid(player) and player.global_position.distance_to(global_position) <= hit_radius + 16.0:
        player.take_damage(damage)
        queue_free()
        return
    if life <= 0.0:
        queue_free()
