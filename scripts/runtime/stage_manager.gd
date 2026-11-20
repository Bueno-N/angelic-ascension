class_name StageManager
extends Node
## Fases: horda que ACELERA com o tempo, mini-chefe no fim da horda (fases 5, 15, 25...), chefe (10, 20, ...),
## contador de mobs e avisos de chefe.

var player: Player
var container: Node2D
var stage := 1
var to_spawn := 0
var alive := 0
var killed := 0
var total := 0
var boss_pending := false
var mini_pending := false
var repeat_mode := false   # depois de morrer: repete a fase anterior até o jogador pedir "Próxima fase"
var _label := "MOBS"
var _timer := 0.0
var _advancing := false
var _stage_time := 0.0
var rng := RandomNumberGenerator.new()
# Luta do boss semanal (Lucifer): a fase fica congelada e há um limite de tempo.
var weekly_active := false
var _w_left := 0.0
var _w_dealt := 0.0
var _w_max_hp := 1.0
var _w_return_stage := 1
var _w_clock := -1

func setup(p: Player, c: Node2D) -> void:
    player = p
    container = c
    rng.randomize()
    Events.enemy_died.connect(_on_enemy_died)
    Events.boss_hp_changed.connect(_on_boss_hp)
    Events.weekly_requested.connect(start_weekly)

func start_stage(s: int) -> void:
    stage = StageLogic.clamp_stage(s)
    GameState.set_stage(stage)
    for e in container.get_children():
        e.queue_free()
    alive = 0
    killed = 0
    _advancing = false
    _stage_time = 0.0
    _timer = 0.0
    boss_pending = StageLogic.is_boss_stage(stage)
    mini_pending = StageLogic.is_mini_stage(stage)
    to_spawn = 0 if boss_pending else StageLogic.enemy_count(stage)
    total = 1 if boss_pending else to_spawn + (1 if mini_pending else 0)
    _label = "CHEFE" if boss_pending else "MOBS"
    Events.boss_hp_changed.emit(0.0, 0.0)
    Events.stage_changed.emit(stage)
    _emit_progress()
    if boss_pending:
        Events.boss_warning.emit(str(EnemiesDB.boss_for(stage)["name"]), false)

func _emit_progress() -> void:
    Events.stage_progress.emit(killed, total, _label)

func set_repeat(on: bool) -> void:
    if repeat_mode != on:
        repeat_mode = on
        Events.repeat_mode_changed.emit(on)

## Botão "Próxima fase": vai para stage+1 imediatamente (só até uma fase já alcançada).
func request_next() -> void:
    if weekly_active:
        return
    if not StageLogic.can_skip_to_next(stage, int(GameState.state["max_stage"])):
        return
    set_repeat(false)
    start_stage(stage + 1)

## Escolhida no menu "Fases": vai para um andar JÁ alcançado e FICA nele (repete). No recorde, segue a progressão normal.
func goto_stage(target: int) -> void:
    if weekly_active:
        return
    var mx: int = int(GameState.state["max_stage"])
    if not StageLogic.can_enter(stage, mx, target):
        return
    set_repeat(target < mx)
    start_stage(target)

func _on_enemy_died(_pos: Vector2, d: Dictionary, _boss: bool, _gold: int) -> void:
    if weekly_active:
        if d.get("weekly", false):
            finish_weekly("killed")
        return   # na luta semanal a fase fica congelada
    if d.get("summon", false):
        return   # invocações não contam para a limpeza da fase
    alive = maxi(0, alive - 1)
    killed += 1
    _emit_progress()

func _process(delta: float) -> void:
    if container == null:
        return
    if weekly_active:
        _weekly_tick(delta)
        return
    _stage_time += delta / maxf(Engine.time_scale, 0.01)   # segundos REAIS (útil para calibrar)
    if boss_pending:
        boss_pending = false
        _spawn(true)
    elif to_spawn > 0:
        if alive < StageLogic.total_alive_cap(stage, _stage_time):
            _timer -= delta
            if _timer <= 0.0:
                _timer = StageLogic.spawn_interval(_stage_time)   # a horda acelera com o tempo
                to_spawn -= 1
                _spawn(false)
    elif mini_pending:
        if alive <= Balance.MINI_SPAWN_ALIVE:   # mini-chefe entra no FINAL da horda
            mini_pending = false
            _spawn_mini()
    elif alive == 0 and not _advancing:
        _advancing = true
        Events.stage_cleared.emit(stage, _stage_time)
        player.heal(StatsCalc.stage_clear_heal(player.max_hp))
        start_stage(stage if repeat_mode else StageLogic.stage_after_clear(stage))

func _spawn_mini() -> void:
    var md := EnemiesDB.mini_for(stage)
    var base := EnemiesDB.type_by_id(str(md["type"]))
    _spawn(false, base, md)
    _label = "MINI-CHEFE"
    _emit_progress()
    Events.boss_warning.emit(str(md["name"]), true)

## Só para o smoke do CI: cria um tipo específico de inimigo.
func debug_spawn_type(type_id: String, pos: Vector2, tanky: bool) -> void:
    for t in EnemiesDB.TYPES:
        if t["id"] == type_id:
            var e := _spawn(false, t)
            e.position = pos
            if tanky:
                e.max_hp = 1.0e9
                e.hp = 1.0e9
            return

func _spawn(boss: bool, forced: Dictionary = {}, mini: Dictionary = {}) -> Enemy:
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
    e.setup({} if boss else (forced if not forced.is_empty() else EnemiesDB.pick_type(stage, rng)), stage, boss, player, false, mini)
    alive += 1
    return e

# ---------------------------------------------------------------- boss semanal
## Começa a luta contra o Lucifer (a entrada já foi gasta por quem chamou). A fase atual é guardada e retomada no fim.
func start_weekly() -> void:
    if weekly_active:
        return
    _w_return_stage = stage
    for e in container.get_children():
        e.queue_free()
    alive = 0
    boss_pending = false
    mini_pending = false
    to_spawn = 0
    _advancing = false
    weekly_active = true
    _w_left = Balance.WEEKLY_TIME_LIMIT
    _w_dealt = 0.0
    _w_max_hp = WeeklyBoss.lucifer_hp()
    _w_clock = -1
    var area := get_viewport().get_visible_rect().size
    var luc := Enemy.new()
    luc.position = Vector2(area.x * 0.5, 120.0)
    container.add_child(luc)
    luc.setup_lucifer(player)
    Events.weekly_started.emit()
    Events.boss_warning.emit(str(EnemiesDB.LUCIFER["name"]), false)
    _weekly_progress()

func _on_boss_hp(h: float, m: float) -> void:
    if weekly_active and m >= _w_max_hp * 0.999:
        _w_dealt = maxf(_w_dealt, m - maxf(h, 0.0))

func _weekly_tick(delta: float) -> void:
    _w_left -= delta
    _weekly_progress()
    if _w_left <= 0.0:
        finish_weekly("timeout")

func _weekly_progress() -> void:
    var c: int = int(ceil(maxf(_w_left, 0.0)))
    if c != _w_clock:
        _w_clock = c
        Events.stage_progress.emit(c, int(Balance.WEEKLY_TIME_LIMIT), "TEMPO")

## Termina a luta: "killed" (Lucifer morreu), "timeout" (2 min) ou "died" (o anjo caiu). Volta à partida normal.
func finish_weekly(reason: String) -> void:
    if not weekly_active:
        return
    weekly_active = false
    var killed_it: bool = reason == "killed"
    var score: float = WeeklyBoss.compute_score(_w_dealt, _w_max_hp, killed_it, maxf(_w_left, 0.0))
    for e in container.get_children():
        e.queue_free()
    player.buffs.clear()
    player.refresh_stats(true)
    player.heal(player.max_hp)
    Events.boss_hp_changed.emit(0.0, 0.0)
    start_stage(_w_return_stage)
    var pct: float = clampf(_w_dealt / maxf(_w_max_hp, 1.0), 0.0, 1.0)
    var reward: Dictionary = GameState.weekly_attempt_reward(pct, killed_it)   # prêmio da luta, pago na hora
    Events.weekly_finished.emit({"score": score, "killed": killed_it, "reason": reason, "pct": pct, "reward": reward})

## Só para o smoke do CI: esgota o tempo da luta semanal.
func debug_weekly_timeout() -> void:
    _w_left = 0.01
