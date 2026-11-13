extends Node2D
## Monta a cena de jogo em código (menos .tscn escritos à mão = menos pontos de falha sem editor).

var backdrop: Backdrop
var player: Player
var enemies: Node2D
var fx_layer: Node2D
var stage_mgr: StageManager
var caster: SkillCaster
var hud: HUD
var joystick: VirtualJoystick
var skill_bar: SkillBar
var _smoke := false
var _frames := 0
var _cleared := 0
var _ability_count := 0
var _ability_kinds := {}
var _repeat_ok := false
var _next_ok := false
var _speed_ok := false

func _ready() -> void:
    _smoke = OS.get_cmdline_user_args().has("--smoke")
    RenderingServer.set_default_clear_color(Color(0.05, 0.03, 0.08))
    backdrop = Backdrop.new()
    add_child(backdrop)
    enemies = Node2D.new()
    add_child(enemies)
    player = Player.new()
    player.position = get_viewport_rect().size / 2.0
    add_child(player)
    fx_layer = Node2D.new()
    add_child(fx_layer)
    caster = SkillCaster.new()
    add_child(caster)
    caster.setup(player, fx_layer)
    hud = HUD.new()
    add_child(hud)
    joystick = VirtualJoystick.new()
    hud.add_control(joystick)
    player.joystick = joystick
    skill_bar = SkillBar.new()
    skill_bar.caster = caster
    hud.add_control(skill_bar)
    stage_mgr = StageManager.new()
    add_child(stage_mgr)
    stage_mgr.setup(player, enemies)
    Events.player_died.connect(_on_player_died)
    Events.stage_changed.connect(backdrop.set_stage)
    Events.enemy_died.connect(_on_enemy_died_fx)
    Events.request_next_stage.connect(func(): stage_mgr.request_next())
    Events.debug_goto_stage.connect(func(s: int): stage_mgr.set_repeat(false); stage_mgr.start_stage(s))
    Events.debug_heal.connect(func(): player.heal(player.max_hp))
    Events.debug_reset_cooldowns.connect(func(): caster.slots.reset_cooldowns())
    stage_mgr.start_stage(int(GameState.state["stage"]))
    if _smoke:
        Events.stage_cleared.connect(func(_s: int, _t: float): _cleared += 1)
        Events.ability_cast.connect(_on_ability_cast)
        _prepare_smoke()

## Derrota: volta UMA fase e fica repetindo ela (modo repetir) até o jogador tocar em "Próxima fase".
func _on_player_died() -> void:
    player.buffs.clear()
    player.refresh_stats(true)
    var back: int = maxi(1, stage_mgr.stage - 1)
    stage_mgr.set_repeat(back < stage_mgr.stage)
    stage_mgr.start_stage(back)

## Explosão de partículas ao derrotar um inimigo (limitada para poupar aparelhos intermediários).
func _on_enemy_died_fx(pos: Vector2, def: Dictionary, is_boss: bool, _gold: int) -> void:
    if fx_layer.get_child_count() > 60:
        return
    var p := CPUParticles2D.new()
    p.position = pos
    p.one_shot = true
    p.explosiveness = 1.0
    p.amount = 40 if is_boss else (6 if def.get("summon", false) else 12)
    p.lifetime = 0.8 if is_boss else 0.5
    p.spread = 180.0
    p.gravity = Vector2.ZERO
    p.initial_velocity_min = 60.0
    p.initial_velocity_max = 260.0 if is_boss else 160.0
    p.scale_amount_min = 2.0
    p.scale_amount_max = 4.0
    p.color = Color(0.75, 0.35, 1.0, 0.9) if def.get("special", false) else Color(1.0, 0.5, 0.2, 0.9)
    fx_layer.add_child(p)
    p.emitting = true
    get_tree().create_timer(p.lifetime + 0.3).timeout.connect(p.queue_free)

# ---------------- verificação do CI (godot --headless --fixed-fps 60 -- --smoke) ----------------
func _prepare_smoke() -> void:
    stage_mgr.to_spawn = 6   # fase curta: permite testar limpeza de fase + cura
    var st: Dictionary = GameState.state
    st["skills_owned"] = SkillsDB.ids()
    st["skills_equipped"] = ["celestial_lance", "holy_shield", "rain_of_light"]
    Shop.set_all_auto(st, true)
    DebugTools.unlock_all(st)   # exercita os visuais de todos os equipamentos/asas/brilho
    player.god_mode = true      # o smoke precisa que o anjo sobreviva aos chefes
    Enemy.smoke_fast = true     # habilidades inimigas sem recarga inicial
    GameState.recalc()

func _on_ability_cast(id: String) -> void:
    _ability_count += 1
    _ability_kinds[id] = true

func _process(_delta: float) -> void:
    if not _smoke:
        return
    _frames += 1
    match _frames:
        240:
            caster.debug_cast_all()
        900:
            stage_mgr.start_stage(10)    # chefe 1: pancada em área + investida
        1500:
            stage_mgr.start_stage(20)    # chefe 2: invocação + projéteis infernais
        2100:
            stage_mgr.start_stage(12)    # inimigos especiais: bola de fogo + drenar vida
            # Dentro do alcance e muito resistentes (só no smoke): o anjo desbloqueado os mataria antes de agirem.
            stage_mgr.debug_spawn_type("hex_caster", player.position + Vector2(350.0, 0.0), true)
            stage_mgr.debug_spawn_type("soul_leech", player.position + Vector2(0.0, -260.0), true)
        2700:
            var before: int = stage_mgr.stage      # morte: volta 1 fase e entra em modo repetir
            Events.player_died.emit()
            _repeat_ok = stage_mgr.stage == maxi(1, before - 1) and stage_mgr.repeat_mode
        2800:
            var b2: int = stage_mgr.stage          # "Próxima fase": avança 1 e sai do modo repetir
            stage_mgr.request_next()
            _next_ok = stage_mgr.stage == b2 + 1 and not stage_mgr.repeat_mode
        2850:
            GameState.toggle_speed()
            _speed_ok = is_equal_approx(Engine.time_scale, Balance.FAST_MODE_SCALE)
        2880:
            GameState.toggle_speed()
            _speed_ok = _speed_ok and is_equal_approx(Engine.time_scale, 1.0)
    if _frames >= 2900:
        var s: Dictionary = GameState.state
        var kinds: Array = _ability_kinds.keys()
        kinds.sort()
        print("SMOKE_RESULT stage=%d gold=%d gems=%d hp=%.1f alive=%d casts=%d cleared=%d abilities=%d kinds=%s repeat=%d next=%d speed=%d" % [
            int(s["stage"]), int(s["gold"]), int(s["gems"]), player.hp, stage_mgr.alive, caster.casts, _cleared,
            _ability_count, ",".join(kinds), int(_repeat_ok), int(_next_ok), int(_speed_ok)])
        get_tree().quit(0)
