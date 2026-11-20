class_name SkillCaster
extends Node
## Executa as habilidades equipadas: recarga, auto-cast, toque manual (SkillBar) e teclas 1/2/3 (desktop).

var player: Player
var fx_layer: Node2D
var slots := SkillSlots.new()
var casts := 0
var _auto_t := 0.0

func setup(p: Player, layer: Node2D) -> void:
    player = p
    fx_layer = layer
    slots.load_from_state(GameState.state)
    GameState.cooldown_provider = slots.remaining
    Events.state_changed.connect(_on_state_changed)

func _on_state_changed() -> void:
    if slots.equipped != GameState.state["skills_equipped"]:
        slots.sync(GameState.state)

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        var i: int = int(event.keycode) - int(KEY_1)
        if i >= 0 and i < SkillsDB.MAX_EQUIPPED:
            cast_slot(i)

func _process(delta: float) -> void:
    slots.tick(delta)
    _auto_t -= delta
    if _auto_t > 0.0:
        return
    _auto_t = Balance.AUTO_CHECK_INTERVAL
    if AutoCast.auto_count(GameState.state["settings"]) == 0:
        return
    var ctx := _context()
    for i in range(slots.equipped.size()):
        var id: String = slots.equipped[i]
        if AutoCast.slot_auto(GameState.state["settings"], i) and slots.can_use(id) and AutoCast.should_cast(id, ctx):
            cast(id)

func _context() -> Dictionary:
    var list := _enemies()
    var close := 0
    var boss := false
    for e in list:
        if e.global_position.distance_to(player.global_position) <= 150.0:
            close += 1
        if e.is_boss or e.is_mini:
            boss = true
    return {"total": list.size(), "close": close, "boss": boss, "hp_ratio": player.hp / maxf(player.max_hp, 1.0)}

func cast_slot(i: int) -> void:
    if i >= 0 and i < slots.equipped.size():
        cast(slots.equipped[i])

func cast(id: String) -> void:
    if slots.use(id):
        execute(id)

## Só para o modo --smoke do CI: exercita o código de TODAS as habilidades, ignorando recarga/equipamento.
func debug_cast_all() -> void:
    for id in SkillsDB.ids():
        execute(id)

# ---------------- dano ----------------
static func deal_damage(e: Node, id: String, atk: float, glow: float) -> void:
    if not is_instance_valid(e):
        return
    var d: float = SkillsDB.damage(id, atk, glow, e.is_boss)
    if e.is_boss:
        d = SkillsDB.boss_capped_damage(id, d, e.max_hp)
    e.take_damage(d)

func _enemies() -> Array:
    var out: Array = []
    for n in get_tree().get_nodes_in_group("enemies"):
        if is_instance_valid(n) and not n.is_queued_for_deletion() and n.hp > 0.0:
            out.append(n)
    return out

func _nearest() -> Node2D:
    var best: Node2D = null
    var best_d := INF
    for e in _enemies():
        var d: float = e.global_position.distance_to(player.global_position)
        if d < best_d:
            best_d = d
            best = e
    return best

func _strongest() -> Node2D:
    var best: Node2D = null
    var best_hp := -1.0
    for e in _enemies():
        if float(e.max_hp) > best_hp:
            best_hp = float(e.max_hp)
            best = e
    return best

func _damage_radius(pos: Vector2, r: float, id: String, atk: float, glow: float) -> void:
    for e in _enemies():
        if e.global_position.distance_to(pos) <= r + float(e.radius):
            deal_damage(e, id, atk, glow)

func _heal(id: String, glow: float) -> void:
    player.heal(player.max_hp * SkillsDB.scaled_heal_pct(id, glow))

# ---------------- efeitos visuais (sprites animados) ----------------
const GOLD := Color(1.0, 0.9, 0.5)
const BLUE := Color(0.55, 0.8, 1.0)
const ORANGE := Color(1.0, 0.55, 0.2)
const WHITE := Color(1.0, 1.0, 1.0)

func _fx(f: Fx) -> void:
    if fx_layer.get_child_count() > UiLogic.fx_cap(GameState.state["settings"]):
        f.free()   # teto de efeitos (poupa aparelhos intermediários)
        return
    fx_layer.add_child(f)

## Explosão em anel (o sprite tem 64 px: escala = diâmetro / 64).
func _ring(pos: Vector2, r: float, col: Color) -> void:
    SpriteFx.spawn(fx_layer, "fx_burst", pos, r * 2.0 / 64.0, col)

## Pilar de luz com a base em `pos`.
func _strike(pos: Vector2, col: Color, scale: float = 2.0) -> void:
    SpriteFx.spawn(fx_layer, "fx_strike", pos, scale, col, 0.0, true, Vector2(16.0, 90.0))
    SpriteFx.spawn(fx_layer, "fx_burst", pos, scale * 1.1, col)

func _spark(pos: Vector2, col: Color) -> void:
    SpriteFx.spawn(fx_layer, "fx_hit", pos, 2.2, col)

func _flash(col: Color) -> void:
    _fx(Fx.make("flash", player.global_position, 0.6, 0.0, col))

# ---------------- as 10 habilidades ----------------
func execute(id: String) -> void:
    var glow: float = float(GameState.stats["skill_power_mult"])
    var atk: float = player.get_stat("attack")
    var sk := SkillsDB.get_skill(id)
    if sk.is_empty():
        return
    var e: Dictionary = sk["effects"]
    casts += 1
    player.cast_anim()
    AudioHub.play(AudioLogic.skill_sfx(id), 1.0, 0.0)
    match id:
        "celestial_lance":
            var t := _nearest()
            if t != null:
                # a lança surge acima do anjo, carrega e voa até o alvo; o dano entra no impacto
                var lance := LanceFx.spawn(fx_layer, player.global_position, t)
                lance.hit.connect(func(_at: Vector2): deal_damage(t, id, atk, glow))
        "holy_shield":
            _ring(player.global_position, float(e["radius"]), BLUE)
            _damage_radius(player.global_position, float(e["radius"]), id, atk, glow)
            player.buffs.add(id, float(sk["duration"]), {}, SkillsDB.scaled_absorb(id, glow))
        "rain_of_light":
            _rain(id, atk, glow, e)
        "swords_of_paradise":
            var s := OrbitSwords.new()
            s.id = id
            s.atk = atk
            s.glow = glow
            s.duration = float(sk["duration"])
            s.count = int(e["swords"])
            s.orbit_r = float(e["orbit_radius"])
            s.hit_r = float(e["hit_radius"])
            s.tick = float(e["tick"])
            player.add_child(s)
        "divine_judgment":
            var t2 := _strongest()
            if t2 != null:
                _strike(t2.global_position, WHITE, 3.0)
                deal_damage(t2, id, atk, glow)
        "wings_of_redemption":
            _ring(player.global_position, float(e["radius"]), GOLD)
            _damage_radius(player.global_position, float(e["radius"]), id, atk, glow)
            _heal(id, glow)
            SpriteFx.spawn(fx_layer, "fx_hit", player.global_position, 4.0, GOLD)
        "army_of_archangels":
            var n: int = int(e["summons"])
            for i in range(n):
                var a := ArchangelAlly.new()
                a.id = id
                a.atk = atk
                a.glow = glow
                a.duration = float(sk["duration"])
                a.tick = float(e["ally_tick"])
                a.position = player.global_position + Vector2.from_angle(TAU * float(i) / float(maxi(1, n))) * 60.0
                fx_layer.add_child(a)
                _ring(a.position, 40.0, GOLD)
        "celestial_fury":
            _ring(player.global_position, float(e["radius"]), ORANGE)
            _damage_radius(player.global_position, float(e["radius"]), id, atk, glow)
            player.buffs.add(id, float(sk["duration"]), SkillsDB.buff_mods(id, glow))
        "holy_apocalypse":
            _flash(Color(1.0, 0.97, 0.8))
            _ring(player.global_position, 700.0, WHITE)
            var shown := 0
            for en in _enemies():
                deal_damage(en, id, atk, glow)
                if shown < 10:
                    _strike(en.global_position, GOLD, 1.6)
                    shown += 1
        "death_of_hell":
            _flash(Color(1.0, 0.9, 0.6))
            _ring(player.global_position, 900.0, WHITE)
            _ring(player.global_position, 450.0, GOLD)
            for en in _enemies():
                deal_damage(en, id, atk, glow)
            _heal(id, glow)
            player.buffs.add(id, float(sk["duration"]), SkillsDB.buff_mods(id, glow))

func _rain(id: String, atk: float, glow: float, e: Dictionary) -> void:
    var n: int = int(e["projectiles"])
    var r: float = float(e["radius"])
    var spread: float = float(e["spread_time"])
    var list := _enemies()
    var area := get_viewport().get_visible_rect().size
    for i in range(n):
        var pos := Vector2(randf_range(60.0, area.x - 60.0), randf_range(60.0, area.y - 60.0))
        if not list.is_empty():
            pos = list[randi() % list.size()].global_position
        get_tree().create_timer(spread * float(i) / float(n)).timeout.connect(_rain_hit.bind(pos, r, id, atk, glow))

func _rain_hit(pos: Vector2, r: float, id: String, atk: float, glow: float) -> void:
    AudioHub.play("sk_rain_hit", 1.0, 0.12)
    _strike(pos, GOLD, 2.0)
    _damage_radius(pos, r, id, atk, glow)
