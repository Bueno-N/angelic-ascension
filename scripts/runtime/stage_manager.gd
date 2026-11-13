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
var repeat_mode := false   # depois de morrer: repete a fase anterior até o jogador pedir "Próxima fase"
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

func set_repeat(on: bool) -> void:
    if repeat_mode != on:
        repeat_mode = on
        Events.repeat_mode_changed.emit(on)

## Botão "Próxima fase": vai para stage+1 imediatamente (só até uma fase já alcançada).
func request_next() -> void:
    if not StageLogic.can_skip_to_next(stage, int(GameState.state["max_stage"])):
        return
    set_repeat(false)
    start_stage(stage + 1)

func _on_enemy_died(_pos: Vector2, d: Dictionary, _boss: bool, _gold: int) -> void:
    if d.get("summon", false):
        return   # invocações não contam para a limpeza da fase
    alive = maxi(0, alive - 1)

func _process(delta: float) -> void:
    if container == null:
        return
    _stage_time += delta / maxf(Engine.time_scale, 0.01)   # segundos REAIS (útil para calibrar)
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
        start_stage(stage if repeat_mode else stage + 1)

## Só para o smoke do CI: cria um tipo específico de inimigo.
func debug_spawn_type(type_id: String) -> void:
    for t in EnemiesDB.TYPES:
        if t["id"] == type_id:
            _spawn(false, t)
            return

func _spawn(boss: bool, forced: Dictionary = {}) -> void:
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
    e.setup({} if boss else (forced if not forced.is_empty() else EnemiesDB.pick_type(stage, rng)), stage, boss, player)
    alive += 1
