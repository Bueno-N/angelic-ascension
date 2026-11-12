class_name Enemy
extends Node2D

var def: Dictionary = {}
var hp := 1.0
var max_hp := 1.0
var dmg := 1.0
var speed := 50.0
var gold := 1
var radius := 14.0
var is_boss := false
var color := Color.RED
var player: Player
var _atk_cd := 0.0
var _hit := 0.0

func setup(d: Dictionary, stage: int, boss: bool, target: Player) -> void:
    player = target
    is_boss = boss
    add_to_group("enemies")
    if boss:
        var b := EnemiesDB.boss_for(stage)
        def = {"id": b["id"], "special": false}
        max_hp = StageLogic.boss_hp(stage)
        dmg = StageLogic.boss_dmg(stage)
        gold = StageLogic.boss_gold(stage)
        speed = float(EnemiesDB.BOSS_BASE["speed"])
        radius = float(EnemiesDB.BOSS_BASE["radius"])
        color = Color(b["color"])
    else:
        def = d
        max_hp = StageLogic.enemy_hp(float(d["hp"]), stage)
        dmg = StageLogic.enemy_dmg(float(d["dmg"]), stage)
        gold = StageLogic.enemy_gold(float(d["gold"]), stage)
        speed = float(d["speed"])
        radius = float(d["radius"])
        color = Color(d["color"])
    hp = max_hp
    if is_boss:
        Events.boss_hp_changed.emit(hp, max_hp)

func take_damage(amount: float) -> void:
    if hp <= 0.0:
        return
    hp -= amount
    _hit = 0.08
    if is_boss:
        Events.boss_hp_changed.emit(maxf(hp, 0.0), max_hp)
    if hp <= 0.0:
        Events.enemy_died.emit(global_position, def, is_boss, gold)
        queue_free()

func _process(delta: float) -> void:
    if player == null or not is_instance_valid(player):
        return
    var to := player.global_position - global_position
    var dist := to.length()
    if dist > radius + 18.0:
        position += to / maxf(dist, 0.001) * speed * delta
    else:
        _atk_cd -= delta
        if _atk_cd <= 0.0:
            player.take_damage(dmg)
            _atk_cd = 1.0
    _hit = maxf(0.0, _hit - delta)
    queue_redraw()

func _draw() -> void:
    var c := Color.WHITE if _hit > 0.0 else color
    draw_circle(Vector2.ZERO, radius, c)
    draw_colored_polygon(PackedVector2Array([Vector2(-radius * 0.7, -radius * 0.5), Vector2(-radius * 0.9, -radius * 1.4), Vector2(-radius * 0.2, -radius * 0.8)]), c.darkened(0.3))
    draw_colored_polygon(PackedVector2Array([Vector2(radius * 0.7, -radius * 0.5), Vector2(radius * 0.9, -radius * 1.4), Vector2(radius * 0.2, -radius * 0.8)]), c.darkened(0.3))
    draw_circle(Vector2(-radius * 0.35, -radius * 0.1), radius * 0.15, Color(1.0, 0.9, 0.2))
    draw_circle(Vector2(radius * 0.35, -radius * 0.1), radius * 0.15, Color(1.0, 0.9, 0.2))
    if hp < max_hp and not is_boss:
        var w := radius * 2.0
        draw_rect(Rect2(-radius, radius + 4.0, w, 4.0), Color(0, 0, 0, 0.6))
        draw_rect(Rect2(-radius, radius + 4.0, w * clampf(hp / max_hp, 0.0, 1.0), 4.0), Color(0.9, 0.2, 0.2))
