class_name Enemy
extends Node2D
## Inimigo comum, especial ou chefe, com sprite animado (walk / cast). Chefes e especiais usam habilidades
## (EnemiesDB.ABILITIES) com AVISO VISUAL (telegraph) antes do golpe.

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
var is_mini := false
var stage := 1
var player: Player
var abilities := AbilityCooldowns.new()
var _spr: AnimatedSprite2D
var _base_mod := Color.WHITE
var _atk_cd := 0.0
var _hit := 0.0
var _cast_id := ""
var _cast_t := 0.0
var _cast_dir := Vector2.ZERO
var _dash_t := 0.0
var _dash_hit := false

func setup(d: Dictionary, st: int, boss: bool, target: Player, summon: bool = false, mini: Dictionary = {}) -> void:
    player = target
    is_boss = boss
    is_summon = summon
    is_mini = not mini.is_empty()
    stage = st
    add_to_group("enemies")
    var ability_ids: Array = []
    var sprite_name := "imp"
    if boss:
        var b := EnemiesDB.boss_for(st)
        def = {"id": b["id"], "special": false}
        max_hp = StageLogic.boss_hp(st)
        dmg = StageLogic.boss_dmg(st)
        gold = StageLogic.boss_gold(st)
        speed = float(EnemiesDB.BOSS_BASE["speed"])
        radius = float(EnemiesDB.BOSS_BASE["radius"])
        ability_ids = b["abilities"]
        sprite_name = str(b["sprite"])
    else:
        def = d.duplicate()
        max_hp = StageLogic.enemy_hp(float(d["hp"]), st)
        dmg = StageLogic.enemy_dmg(float(d["dmg"]), st)
        gold = StageLogic.enemy_gold(float(d["gold"]), st)
        speed = float(d["speed"])
        radius = float(d["radius"])
        sprite_name = str(d.get("sprite", "imp"))
        if is_mini:
            # mini-chefe: versão campeã do demônio comum (maior, mais forte, 1 habilidade)
            max_hp = StageLogic.mini_hp(st)
            dmg = StageLogic.mini_dmg(st)
            gold = StageLogic.mini_gold(st)
            radius *= Balance.MINI_RADIUS_MULT
            ability_ids = mini["abilities"]
            def["mini"] = true
            def["name"] = mini["name"]
            def["special"] = false
            def.erase("ability")
            _base_mod = Color(1.0, 0.82, 0.7)
        elif d.has("ability"):
            ability_ids = [d["ability"]]
    if summon:
        def["summon"] = true
        gold = 0
        add_to_group("summons")
        _base_mod = Color(0.8, 0.6, 1.0, 0.9)   # invocações ficam arroxeadas
    _spr = SpriteLib.make(sprite_name, "walk", Balance.MINI_SCALE if is_mini else EnemiesDB.SPRITE_SCALE)
    _spr.modulate = _base_mod
    _spr.speed_scale = clampf(speed / 70.0, 0.6, 1.5)
    add_child(_spr)
    abilities.setup(ability_ids, EnemiesDB.ABILITIES, 0.0 if smoke_fast else EnemiesDB.ABILITY_INITIAL_FRACTION)
    hp = max_hp
    if is_boss or is_mini:
        Events.boss_hp_changed.emit(hp, max_hp)

func take_damage(amount: float) -> void:
    if hp <= 0.0:
        return
    hp -= amount
    _hit = 0.08
    if _spr != null:
        _spr.modulate = Color(2.2, 2.2, 2.2, _base_mod.a)   # piscada branca ao levar dano
    queue_redraw()
    if is_boss or is_mini:
        Events.boss_hp_changed.emit(maxf(hp, 0.0), max_hp)
    if hp <= 0.0:
        Events.enemy_died.emit(global_position, def, is_boss, gold)
        queue_free()

func _process(delta: float) -> void:
    if player == null or not is_instance_valid(player):
        return
    var was_hit: bool = _hit > 0.0
    _think(delta)
    if was_hit and _hit <= 0.0 and _spr != null:
        _spr.modulate = _base_mod
    # Mover o nó não exige redesenhar; só o aviso de habilidade muda a cada frame.
    if _cast_id != "" or _dash_t > 0.0:
        queue_redraw()

func _play(anim: String) -> void:
    if _spr != null and _spr.sprite_frames != null and _spr.sprite_frames.has_animation(anim) and _spr.animation != anim:
        _spr.play(anim)

func _think(delta: float) -> void:
    _hit = maxf(0.0, _hit - delta)
    abilities.tick(delta)
    var to := player.global_position - global_position
    var dist := to.length()
    if _spr != null and absf(to.x) > 2.0:
        _spr.flip_h = to.x < 0.0

    if _dash_t > 0.0:
        _process_dash(delta)
        return
    if _cast_id != "":
        _cast_t -= delta
        if _cast_t <= 0.0:
            _execute_ability()
        return
    if not abilities.is_empty():
        var nid := abilities.next_ready(EnemiesDB.ABILITIES, dist)
        if nid != "" and _can_start(nid):
            _start_cast(nid, to)
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

func _can_start(id: String) -> bool:
    if id == "summon_demons":
        return get_tree().get_nodes_in_group("summons").size() < EnemiesDB.MAX_SUMMONS_ALIVE
    return true

func _start_cast(id: String, to: Vector2) -> void:
    _cast_id = id
    _cast_t = float(EnemiesDB.ABILITIES[id]["telegraph"])
    _cast_dir = to.normalized()
    abilities.start(id, EnemiesDB.ABILITIES)
    _play("cast")   # pose de conjuração durante o aviso

func _execute_ability() -> void:
    var id := _cast_id
    var cfg: Dictionary = EnemiesDB.ABILITIES[id]
    _cast_id = ""
    _play("walk")
    Events.ability_cast.emit(id)
    match id:
        "area_slam":
            _burst(float(cfg["radius"]), Color(1.0, 0.3, 0.2))
            if player.global_position.distance_to(global_position) <= float(cfg["radius"]):
                player.take_damage(dmg * float(cfg["dmg_mult"]))
        "charge":
            _dash_t = float(cfg["duration"])
            _dash_hit = false
        "summon_demons":
            _burst(80.0, Color(0.7, 0.3, 1.0))
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
                queue_redraw()
                var beam := Fx.make("beam", global_position, 0.3, 0.0, Color(0.3, 1.0, 0.7))
                beam.to = player.global_position - global_position
                get_parent().add_child(beam)
                SpriteFx.spawn(get_parent(), "fx_hit", player.global_position, 2.0, Color(0.4, 1.0, 0.8))

func _process_dash(delta: float) -> void:
    var cfg: Dictionary = EnemiesDB.ABILITIES["charge"]
    _dash_t -= delta
    var area := get_viewport().get_visible_rect().size
    position = (position + _cast_dir * float(cfg["speed"]) * delta).clamp(Vector2(-20, -20), area + Vector2(20, 20))
    if not _dash_hit and player.global_position.distance_to(global_position) <= radius + float(cfg["width"]):
        _dash_hit = true
        player.take_damage(dmg * float(cfg["dmg_mult"]))

func _burst(r: float, col: Color) -> void:
    SpriteFx.spawn(get_parent(), "fx_burst", global_position, r * 2.0 / 64.0, col)

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
    # sombra no chão (dá peso ao sprite)
    draw_set_transform(Vector2(0, radius + 6.0), 0.0, Vector2(1.0, 0.32))
    draw_circle(Vector2.ZERO, radius * 1.25, Color(0, 0, 0, 0.35))
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    if hp < max_hp and not is_boss:
        var w := radius * 2.0
        draw_rect(Rect2(-radius, -radius - 16.0, w, 4.0), Color(0, 0, 0, 0.6))
        draw_rect(Rect2(-radius, -radius - 16.0, w * clampf(hp / max_hp, 0.0, 1.0), 4.0), Color(0.9, 0.2, 0.2))
    if _cast_id != "":
        _draw_telegraph()

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
