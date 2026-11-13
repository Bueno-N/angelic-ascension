class_name Player
extends Node2D

var hp: float = 100.0
var max_hp: float = 100.0
var joystick: VirtualJoystick
var buffs := BuffState.new()
var god_mode := false   # só no modo --smoke do CI
var _atk_timer := 0.0
var _aura_timer := 0.0
var _flash := 0.0
var _flash_target := Vector2.ZERO
var _hp_emit := 0.0

func _ready() -> void:
    add_to_group("player")
    Events.state_changed.connect(_on_state_changed)
    refresh_stats(true)

## Atributo final = (base + ouro) * (1 + asas% + equip%) * multiplicador dos buffs ativos.
func get_stat(stat_name: String) -> float:
    return float(GameState.stats[stat_name]) * buffs.multiplier(stat_name)

func refresh_stats(full_heal: bool) -> void:
    var new_max: float = float(GameState.stats["hp"])
    if full_heal:
        hp = new_max
    else:
        hp = minf(new_max, hp + maxf(0.0, new_max - max_hp))
    max_hp = new_max
    Events.player_hp_changed.emit(hp, max_hp)

func _on_state_changed() -> void:
    refresh_stats(false)

func heal(amount: float) -> void:
    hp = minf(max_hp, hp + amount)
    Events.player_hp_changed.emit(hp, max_hp)

func take_damage(raw: float) -> void:
    var after_shield: float = raw * (1.0 - buffs.absorb())
    hp -= StatsCalc.damage_after_armor(after_shield, get_stat("armor"))
    if god_mode:
        hp = maxf(hp, 1.0)
    Events.player_hp_changed.emit(maxf(hp, 0.0), max_hp)
    if hp <= 0.0:
        Events.player_died.emit()

func _process(delta: float) -> void:
    buffs.tick(delta)
    var dir := Vector2.ZERO
    if joystick != null:
        dir = joystick.output
    if dir == Vector2.ZERO:
        dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    var area := get_viewport_rect().size
    position = (position + dir * get_stat("speed") * delta).clamp(Vector2(40, 40), area - Vector2(40, 40))

    if hp > 0.0 and hp < max_hp:
        hp = minf(max_hp, hp + StatsCalc.regen_amount(max_hp, delta))
        _hp_emit -= delta
        if _hp_emit <= 0.0:
            _hp_emit = 0.2
            Events.player_hp_changed.emit(hp, max_hp)

    _atk_timer -= delta
    if _atk_timer <= 0.0:
        var target := _nearest_enemy(Balance.ATTACK_RANGE)
        if target != null:
            target.take_damage(get_stat("attack"))
            _flash = 0.12
            _flash_target = target.global_position
            _atk_timer = 1.0 / maxf(0.1, get_stat("attack_speed"))

    _aura_timer -= delta
    if _aura_timer <= 0.0:
        _aura_timer = Balance.AURA_TICK
        var tick: float = get_stat("aura") * Balance.AURA_TICK
        for e in get_tree().get_nodes_in_group("enemies"):
            if e.global_position.distance_to(global_position) <= Balance.AURA_RADIUS:
                e.take_damage(tick)

    _flash = maxf(0.0, _flash - delta)
    queue_redraw()

func _nearest_enemy(max_dist: float) -> Node2D:
    var best: Node2D = null
    var best_d := max_dist
    for e in get_tree().get_nodes_in_group("enemies"):
        var d: float = e.global_position.distance_to(global_position)
        if d < best_d:
            best_d = d
            best = e
    return best

func _draw() -> void:
    draw_circle(Vector2.ZERO, Balance.AURA_RADIUS, Color(1.0, 0.92, 0.55, 0.07))
    draw_arc(Vector2.ZERO, Balance.AURA_RADIUS, 0.0, TAU, 48, Color(1.0, 0.92, 0.55, 0.25), 2.0)
    AngelDraw.draw_angel(self, int(GameState.state["wings_level"]), int(GameState.state["glow_tier"]), 1.0)
    if buffs.absorb() > 0.0:
        draw_arc(Vector2.ZERO, 38.0, 0.0, TAU, 40, Color(0.6, 0.85, 1.0, 0.85), 4.0)
    if buffs.multiplier("attack") > 1.4:
        draw_arc(Vector2.ZERO, 46.0, 0.0, TAU, 40, Color(1.0, 0.55, 0.2, 0.85), 3.0)
    if _flash > 0.0:
        draw_line(Vector2.ZERO, _flash_target - global_position, Color(1.0, 1.0, 0.7, 0.9), 3.0)
