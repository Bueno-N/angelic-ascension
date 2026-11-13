class_name Enemy
extends Node2D
## Inimigo comum, especial ou chefe. Chefes e especiais usam habilidades (EnemiesDB.ABILITIES) com
## AVISO VISUAL (telegraph) antes do golpe.

static var smoke_fast := false   # só no modo --smoke do CI: habilidades começam sem recarga inicial

var def: Dictionary = {}
var hp := 1.0
var max_hp := 1.0
var dmg := 1.0
var speed := 50.0
var gold := 1
var radius := 14.0
var is_boss := false
var is_summon := false
var stage := 1
var color := Color.RED
var player: Player
var abilities := AbilityCooldowns.new()
var _atk_cd := 0.0
var _hit := 0.0
var _cast_id := ""
var _cast_t := 0.0
var _cast_dir := Vector2.ZERO
var _dash_t := 0.0
var _dash_hit := false

func setup(d: Dictionary, st: int, boss: bool, target: Player, summon: bool = false) -> void:
    player = target
    is_boss = boss
    is_summon = summon
    stage = st
    add_to_group("enemies")
    var ability_ids: Array = []
    if boss:
        var b := EnemiesDB.boss_for(st)
        def = {"id": b["id"], "special": false}
        max_hp = StageLogic.boss_hp(st)
        dmg = StageLogic.boss_dmg(st)
        gold = StageLogic.boss_gold(st)
        speed = float(EnemiesDB.BOSS_BASE["speed"])
        radius = float(EnemiesDB.BOSS_BASE["radius"])
        color = Color(b["color"])
        ability_ids = b["abilities"]
    else:
        def = d.duplicate()
        max_hp = StageLogic.enemy_hp(float(d["hp"]), st)
        dmg = StageLogic.enemy_dmg(float(d["dmg"]), st)
        gold = StageLogic.enemy_gold(float(d["gold"]), st)
        speed = float(d["speed"])
        radius = float(d["radius"])
        color = Color(d["color"])
        if d.has("ability"):
            ability_ids = [d["ability"]]
    if summon:
        def["summon"] = true
        gold = 0
        add_to_group("summons")
    abilities.setup(ability_ids, EnemiesDB.ABILITIES, 0.0 if smoke_fast else EnemiesDB.ABILITY_INITIAL_FRACTION)
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
    _hit = maxf(0.0, _hit - delta)
    abilities.tick(delta)
    var to := player.global_position - global_position
    var dist := to.length()

    if _dash_t > 0.0:
        _process_dash(delta)
        queue_redraw()
        return
    if _cast_id != "":
        _cast_t -= delta
        if _cast_t <= 0.0:
            _execute_ability()
        queue_redraw()
        return
    if not abilities.is_empty():
        var nid := abilities.next_ready(EnemiesDB.ABILITIES, dist)
        if nid != "" and _can_start(nid):
            _start_cast(nid, to)
            queue_redraw()
            return

    var hold: float = radius + 18.0
    if str(def.get("ability", "")) == "fire_bolt":
        hold = float(EnemiesDB.ABILITIES["fire_bolt"]["max_range"]) * 0.8   # atirador: mantém distância
    if dist > hold:
        position += to / maxf(dist, 0.001) * speed * delta
    if dist <= radius + 18.0:
        _atk_cd -= delta
        if _atk_cd <= 0.0:
            player.take_damage(dmg)
            _atk_cd = 1.0
    queue_redraw()

func _can_start(id: String) -> bool:
    if id == "summon_demons":
        return get_tree().get_nodes_in_group("summons").size() < EnemiesDB.MAX_SUMMONS_ALIVE
    return true

func _start_cast(id: String, to: Vector2) -> void:
    _cast_id = id
    _cast_t = float(EnemiesDB.ABILITIES[id]["telegraph"])
    _cast_dir = to.normalized()
    abilities.start(id, EnemiesDB.ABILITIES)

func _execute_ability() -> void:
    var id := _cast_id
    var cfg: Dictionary = EnemiesDB.ABILITIES[id]
    _cast_id = ""
    Events.ability_cast.emit(id)
    match id:
        "area_slam":
            _fx("ring", float(cfg["radius"]), Color(1.0, 0.3, 0.2))
            if player.global_position.distance_to(global_position) <= float(cfg["radius"]):
                player.take_damage(dmg * float(cfg["dmg_mult"]))
        "charge":
            _dash_t = float(cfg["duration"])
            _dash_hit = false
        "summon_demons":
            _summon(int(cfg["count"]))
        "hellfire_projectiles":
            _fan(cfg)
        "fire_bolt":
            _shoot((player.global_position - global_position).normalized(), cfg, 1.0)
        "life_steal":
            var amount: float = dmg * float(cfg["dmg_mult"])
            if player.global_position.distance_to(global_position) <= float(cfg["max_range"]) + 40.0:
                player.take_damage(amount)
                hp = minf(max_hp, hp + amount * float(cfg["heal_pct"]))
                var beam := Fx.make("beam", global_position, 0.3, 0.0, Color(0.3, 1.0, 0.7))
                beam.to = player.global_position - global_position
                get_parent().add_child(beam)

func _process_dash(delta: float) -> void:
    var cfg: Dictionary = EnemiesDB.ABILITIES["charge"]
    _dash_t -= delta
    var area := get_viewport().get_visible_rect().size
    position = (position + _cast_dir * float(cfg["speed"]) * delta).clamp(Vector2(-20, -20), area + Vector2(20, 20))
    if not _dash_hit and player.global_position.distance_to(global_position) <= radius + float(cfg["width"]):
        _dash_hit = true
        player.take_damage(dmg * float(cfg["dmg_mult"]))

func _fx(kind: String, r: float, col: Color) -> void:
    get_parent().add_child(Fx.make(kind, global_position, 0.5, r, col))

func _shoot(dir: Vector2, cfg: Dictionary, dmg_scale: float) -> void:
    var p := EnemyProjectile.new()
    p.position = global_position
    p.velocity = dir * float(cfg["speed"])
    p.damage = dmg * float(cfg["dmg_mult"]) * dmg_scale
    p.hit_radius = float(cfg["hit_radius"])
    p.player = player
    get_parent().add_child(p)

func _fan(cfg: Dictionary) -> void:
    var n: int = int(cfg["count"])
    var spread: float = deg_to_rad(float(cfg["spread_deg"]))
    var base_dir: Vector2 = (player.global_position - global_position).normalized()
    for i in range(n):
        var t: float = 0.5 if n == 1 else float(i) / float(n - 1)
        _shoot(base_dir.rotated(-spread / 2.0 + spread * t), cfg, 1.0)

func _summon(n: int) -> void:
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    for i in range(n):
        var m := Enemy.new()
        m.position = position + Vector2.from_angle(TAU * float(i) / float(maxi(1, n)) + rng.randf()) * (radius + 30.0)
        get_parent().add_child(m)
        m.setup(EnemiesDB.pick_normal(stage, rng), stage, false, player, true)

func _draw() -> void:
    var c := Color.WHITE if _hit > 0.0 else color
    draw_circle(Vector2.ZERO, radius, c)
    draw_colored_polygon(PackedVector2Array([Vector2(-radius * 0.7, -radius * 0.5), Vector2(-radius * 0.9, -radius * 1.4), Vector2(-radius * 0.2, -radius * 0.8)]), c.darkened(0.3))
    draw_colored_polygon(PackedVector2Array([Vector2(radius * 0.7, -radius * 0.5), Vector2(radius * 0.9, -radius * 1.4), Vector2(radius * 0.2, -radius * 0.8)]), c.darkened(0.3))
    draw_circle(Vector2(-radius * 0.35, -radius * 0.1), radius * 0.15, Color(1.0, 0.9, 0.2))
    draw_circle(Vector2(radius * 0.35, -radius * 0.1), radius * 0.15, Color(1.0, 0.9, 0.2))
    _draw_kind_details(c)
    if hp < max_hp and not is_boss:
        var w := radius * 2.0
        draw_rect(Rect2(-radius, radius + 4.0, w, 4.0), Color(0, 0, 0, 0.6))
        draw_rect(Rect2(-radius, radius + 4.0, w * clampf(hp / max_hp, 0.0, 1.0), 4.0), Color(0.9, 0.2, 0.2))
    if _cast_id != "":
        _draw_telegraph()

## Detalhes visuais por tipo de demônio (a silhueta ajuda a reconhecer o perigo).
func _draw_kind_details(c: Color) -> void:
    var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) / 220.0)
    var kind: String = "boss" if is_boss else str(def.get("kind", "common"))
    match kind:
        "warrior":
            draw_arc(Vector2(radius * 0.9, 0), radius * 0.6, -PI / 2.0, PI / 2.0, 12, c.lightened(0.35), 3.0)
        "shadow":
            draw_circle(Vector2(0, radius * 0.9), radius * 0.6, Color(c, 0.35))
            draw_circle(Vector2(0, radius * 1.5), radius * 0.35, Color(c, 0.2))
        "beast":
            for k in range(3):
                var x: float = (float(k) - 1.0) * radius * 0.6
                draw_colored_polygon(PackedVector2Array([Vector2(x - 4, -radius * 0.9), Vector2(x, -radius * 1.4), Vector2(x + 4, -radius * 0.9)]), c.darkened(0.4))
        "special":
            draw_arc(Vector2.ZERO, radius + 6.0, 0.0, TAU, 24, Color(color.lightened(0.4), 0.4 + 0.5 * pulse), 2.0)
        "boss":
            for k in range(5):
                var x2: float = (float(k) - 2.0) * radius * 0.35
                draw_colored_polygon(PackedVector2Array([Vector2(x2 - 6, -radius * 0.95), Vector2(x2, -radius * 1.5), Vector2(x2 + 6, -radius * 0.95)]), Color(1.0, 0.75, 0.2))
            draw_arc(Vector2.ZERO, radius * 1.35, 0.0, TAU, 40, Color(1.0, 0.2, 0.1, 0.25 + 0.35 * pulse), 4.0)

## AVISO VISUAL: a área/linha fica mais vermelha até o golpe acontecer.
func _draw_telegraph() -> void:
    var cfg: Dictionary = EnemiesDB.ABILITIES[_cast_id]
    var t: float = 1.0 - clampf(_cast_t / maxf(float(cfg["telegraph"]), 0.001), 0.0, 1.0)
    var warn := Color(1.0, 0.15, 0.15, 0.2 + 0.4 * t)
    match _cast_id:
        "area_slam":
            draw_circle(Vector2.ZERO, float(cfg["radius"]), warn)
            draw_arc(Vector2.ZERO, float(cfg["radius"]), 0.0, TAU, 48, Color(1.0, 0.3, 0.3, 0.9), 3.0)
        "charge":
            draw_line(Vector2.ZERO, _cast_dir * float(cfg["speed"]) * float(cfg["duration"]), warn, float(cfg["width"]) * 2.0)
        "hellfire_projectiles":
            var spread: float = deg_to_rad(float(cfg["spread_deg"]))
            for k in range(3):
                var ang: float = -spread / 2.0 + spread * float(k) / 2.0
                draw_line(Vector2.ZERO, _cast_dir.rotated(ang) * 420.0, warn, 4.0)
        "summon_demons":
            draw_arc(Vector2.ZERO, radius + 20.0, 0.0, TAU, 32, Color(0.7, 0.3, 1.0, 0.4 + 0.5 * t), 4.0)
        _:
            draw_arc(Vector2.ZERO, radius + 10.0, 0.0, TAU, 24, warn, 4.0)
