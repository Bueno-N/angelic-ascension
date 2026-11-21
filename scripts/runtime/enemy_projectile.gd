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
var art := ""                        # pasta do chefe com bola de fogo própria (ex.: "mordath"); "" = sprite antigo
var _spr: AnimatedSprite2D
var _rot_off := 0.0

func _ready() -> void:
    if art != "" and BossFx.has_fireball(art):
        _spr = BossFx.fireball(art)    # bola de fogo desenhada (Mordath)
        _rot_off = -BossFx.FIREBALL_NATIVE_ANGLE
    else:
        _spr = SpriteLib.make("fx_fireball", "play", 1.6)
        _spr.modulate = tint
    _spr.rotation = velocity.angle() + _rot_off
    add_child(_spr)

func _end() -> void:
    if art != "" and BossFx.has_fireball(art) and get_parent() != null:
        BossFx.explode(get_parent(), position, art)
    queue_free()

func _process(delta: float) -> void:
    life -= delta
    if homing > 0.0 and player != null and is_instance_valid(player):
        var want: float = (player.global_position - global_position).angle()
        velocity = velocity.rotated(clampf(angle_difference(velocity.angle(), want), -homing * delta, homing * delta))
        if _spr != null:
            _spr.rotation = velocity.angle() + _rot_off
    position += velocity * delta
    if player != null and is_instance_valid(player) and player.global_position.distance_to(global_position) <= hit_radius + 16.0:
        player.take_damage(damage)
        _end()
        return
    if life <= 0.0:
        _end()
