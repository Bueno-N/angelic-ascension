class_name StageManager
extends Node

var player: Player
var container: Node2D
var stage := 1
var to_spawn := 0
var alive := 0
var boss_pending := false
var _timer := 0.0
var _advancing := false
var _stage_time := 0.0
var rng := RandomNumberGenerator.new()

func setup(p: Player, c: Node2D) -> void:
    player = p
    container = c
    rng.randomize()
    Events.enemy_died.connect(_on_enemy_died)

func start_stage(s: int) -> void:
    stage = maxi(1, s)
    GameState.set_stage(stage)
    for e in container.get_children():
        e.queue_free()
    alive = 0
    _advancing = false
    _stage_time = 0.0
    boss_pending = StageLogic.is_boss_stage(stage)
    to_spawn = 0 if boss_pending else StageLogic.enemy_count(stage)
    Events.boss_hp_changed.emit(0.0, 0.0)
    Events.stage_changed.emit(stage)

func _on_enemy_died(_pos: Vector2, _def: Dictionary, _boss: bool, _gold: int) -> void:
    alive = maxi(0, alive - 1)

func _process(delta: float) -> void:
    if container == null:
        return
    _stage_time += delta
    if boss_pending:
        boss_pending = false
        _spawn(true)
    elif to_spawn > 0 and alive < StageLogic.max_alive(stage):
        _timer -= delta
        if _timer <= 0.0:
            _timer = Balance.SPAWN_INTERVAL
            to_spawn -= 1
            _spawn(false)
    elif to_spawn == 0 and alive == 0 and not _advancing:
        _advancing = true
        Events.stage_cleared.emit(stage, _stage_time)
        player.heal(StatsCalc.stage_clear_heal(player.max_hp))
        start_stage(stage + 1)

func _spawn(boss: bool) -> void:
    var e := Enemy.new()
    var area := get_viewport().get_visible_rect().size
    var side := rng.randi_range(0, 3)
    var pos := Vector2.ZERO
    match side:
        0: pos = Vector2(rng.randf_range(0, area.x), -30)
        1: pos = Vector2(rng.randf_range(0, area.x), area.y + 30)
        2: pos = Vector2(-30, rng.randf_range(0, area.y))
        _: pos = Vector2(area.x + 30, rng.randf_range(0, area.y))
    e.position = pos
    container.add_child(e)
    e.setup({} if boss else EnemiesDB.pick_type(stage, rng), stage, boss, player)
    alive += 1
