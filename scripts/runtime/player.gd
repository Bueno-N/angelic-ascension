class_name Player
extends Node2D
## O anjo: sprite com a arte nova por pose (AngelSprite), aura rúnica giratória, disparo de luz que mira (AngelShot) e faíscas.

var hp: float = 100.0
var max_hp: float = 100.0
const REVIVE_INVULN_SECONDS := 2.5
var invuln_t := 0.0              # > 0: não recebe dano (usado ao reviver pelo anúncio)
var joystick: VirtualJoystick
var fx_layer: Node2D
var buffs := BuffState.new()
var god_mode := false   # só no modo --smoke do CI
var visual: AngelSprite
var aura_fx: AnimatedSprite2D
var shield_fx: AnimatedSprite2D
var _atk_timer := 0.0
var _aura_timer := 0.0
var _aura_pulse := 0.0
var _aura_scale := 2.0
var _hurt := 0.0
var _hp_emit := 0.0
var _sparks: CPUParticles2D
var _sparks_tier := -1

func _ready() -> void:
    add_to_group("player")
    aura_fx = SpriteLib.make("fx_aura", "play", 2.0)   # anel rúnico: raio visual = raio da aura (112 px)
    aura_fx.material = SpriteLib.additive()
    aura_fx.modulate = Color(1.0, 0.9, 0.5, 0.5)
    add_child(aura_fx)
    visual = AngelSprite.new()
    add_child(visual)
    shield_fx = SpriteLib.make("fx_shield", "play", 2.4)
    shield_fx.material = SpriteLib.additive()
    shield_fx.modulate = Color(0.6, 0.85, 1.0, 0.85)
    shield_fx.visible = false
    add_child(shield_fx)
    Events.state_changed.connect(_on_state_changed)
    _setup_sparks()
    _update_look()
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
    _update_sparks()
    _update_look()

func _update_look() -> void:
    visual.set_look(int(GameState.state["wings_level"]), int(GameState.state["glow_tier"]), GameState.state["equipped"])

## Pose de conjuração (chamada pelo SkillCaster).
func cast_anim() -> void:
    visual.cast()

func heal(amount: float) -> void:
    hp = minf(max_hp, hp + amount)
    Events.player_hp_changed.emit(hp, max_hp)

func start_invulnerable(seconds: float) -> void:
    invuln_t = maxf(invuln_t, seconds)

func take_damage(raw: float) -> void:
    if invuln_t > 0.0:
        return
    var after_shield: float = raw * (1.0 - buffs.absorb())
    hp -= StatsCalc.damage_after_armor(after_shield, get_stat("armor"))
    _hurt = 0.12
    AudioHub.play("hurt", 1.0, 0.06)
    visual.modulate = Color(1.7, 0.7, 0.7)   # piscada vermelha ao ser atingido
    if god_mode:
        hp = maxf(hp, 1.0)
    Events.player_hp_changed.emit(maxf(hp, 0.0), max_hp)
    if hp <= 0.0:
        Events.player_died.emit()

## Partículas celestiais ao redor do anjo: surgem ao comprar o brilho das asas e aumentam com o tier.
func _setup_sparks() -> void:
    _sparks = CPUParticles2D.new()
    _sparks.lifetime = 1.4
    _sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
    _sparks.emission_sphere_radius = 52.0
    _sparks.direction = Vector2(0, -1)
    _sparks.spread = 40.0
    _sparks.gravity = Vector2(0, -20)
    _sparks.initial_velocity_min = 8.0
    _sparks.initial_velocity_max = 30.0
    _sparks.scale_amount_min = 1.5
    _sparks.scale_amount_max = 3.0
    var g := Gradient.new()
    g.set_color(0, Color(1.0, 0.95, 0.6, 0.9))
    g.set_color(1, Color(1.0, 0.9, 0.4, 0.0))
    _sparks.color_ramp = g
    _sparks.emitting = false
    add_child(_sparks)
    _update_sparks()

func _update_sparks() -> void:
    var tier: int = int(GameState.state["glow_tier"])
    var fx: bool = UiLogic.fx_enabled(GameState.state["settings"])
    var key: int = tier * 2 + (1 if fx else 0)
    if key == _sparks_tier:
        return
    _sparks_tier = key
    _sparks.emitting = tier > 0 and fx
    if tier > 0:
        _sparks.amount = 6 + 6 * tier

func _process(delta: float) -> void:
    buffs.tick(delta)
    if invuln_t > 0.0:
        invuln_t = maxf(0.0, invuln_t - delta)
        visual.modulate.a = 1.0 if invuln_t <= 0.0 else (0.45 if int(invuln_t * 10.0) % 2 == 0 else 1.0)   # pisca enquanto invulnerável
    var dir := Vector2.ZERO
    if joystick != null:
        dir = joystick.output
    if dir == Vector2.ZERO:
        dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    var area := get_viewport_rect().size
    position = (position + dir * get_stat("speed") * delta).clamp(Vector2(40, 40), area - Vector2(40, 40))
    if dir.x != 0.0:
        visual.face(dir.x)
    visual.set_moving(dir != Vector2.ZERO)   # andando: quadros de voo
    visual.set_speed(get_stat("attack_speed"))
    visual.set_hell(buffs.is_active("death_of_hell"))   # A MORTE DO INFERNO: transformação + forma de poder; ataque com o raio

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
            _attack(target)
            _atk_timer = 1.0 / maxf(0.1, get_stat("attack_speed"))

    _aura_timer -= delta
    if _aura_timer <= 0.0:
        _aura_timer = Balance.AURA_TICK
        _aura_pulse = 1.0   # a aura "pulsa" a cada tick de dano
        var tick: float = get_stat("aura") * Balance.AURA_TICK
        for e in get_tree().get_nodes_in_group("enemies"):
            if e.global_position.distance_to(global_position) <= Balance.AURA_RADIUS:
                e.take_damage(tick)

    _update_aura(delta)
    shield_fx.visible = buffs.absorb() > 0.0
    if _hurt > 0.0:
        _hurt -= delta
        if _hurt <= 0.0:
            visual.modulate = Color.WHITE

## Aura: intensidade cresce com o nível de Aura; muda de cor/tamanho com Fúria e Morte do Inferno.
func _update_aura(delta: float) -> void:
    var lvl: int = int(GameState.state["upgrades"].get("aura", 0))
    var base_a: float = 0.35 + minf(0.4, float(lvl) * 0.01)
    var tint := Color(1.0, 0.9, 0.5)
    var target_scale := 2.0
    var atk_m: float = buffs.multiplier("attack")
    if atk_m > 2.5:
        tint = Color(1.0, 1.0, 0.92)
        target_scale = 2.6
    elif atk_m > 1.4:
        tint = Color(1.0, 0.55, 0.25)
        target_scale = 2.3
    _aura_scale = lerpf(_aura_scale, target_scale, minf(1.0, delta * 6.0))
    aura_fx.scale = Vector2(_aura_scale, _aura_scale)
    _aura_pulse = maxf(0.0, _aura_pulse - delta * 2.5)
    aura_fx.modulate = Color(tint, minf(1.0, base_a + _aura_pulse * 0.4))

func _attack(target: Node2D) -> void:
    var to_t: Vector2 = target.global_position - global_position
    visual.face(to_t.x)
    visual.attack()
    AudioHub.play("atk", 1.0, 0.07)
    AudioHub.play("mob_hit", 1.0, 0.12)
    target.take_damage(get_stat("attack"))
    if fx_layer != null:
        # o disparo sai da MÃO e mira no inimigo (a pose só mostra o braço estendido)
        var hand: Vector2 = visual.to_global(visual.hand_local())
        var at: Vector2 = target.global_position
        if visual.is_hell():
            AngelShot.beam(fx_layer, hand, at)        # A MORTE DO INFERNO: o raio, sem o cometa
            SpriteFx.spawn(fx_layer, "fx_hit", at, 2.0, Color(1.0, 0.75, 0.3))
        else:
            AngelShot.muzzle(fx_layer, hand, at)
            AngelShot.bolt(fx_layer, hand, at)   # o cometa estoura em luz ao chegar no alvo

func _nearest_enemy(max_dist: float) -> Node2D:
    var best: Node2D = null
    var best_d := max_dist
    for e in get_tree().get_nodes_in_group("enemies"):
        var d: float = e.global_position.distance_to(global_position)
        if d < best_d:
            best_d = d
            best = e
    return best

