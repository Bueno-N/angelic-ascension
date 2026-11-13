extends Node2D
## Monta a cena de jogo em código (menos .tscn escritos à mão = menos pontos de falha sem editor).

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

func _ready() -> void:
    _smoke = OS.get_cmdline_user_args().has("--smoke")
    RenderingServer.set_default_clear_color(Color(0.05, 0.03, 0.08))
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
    Events.debug_goto_stage.connect(func(s: int): stage_mgr.start_stage(s))
    Events.debug_heal.connect(func(): player.heal(player.max_hp))
    Events.debug_reset_cooldowns.connect(func(): caster.slots.reset_cooldowns())
    stage_mgr.start_stage(int(GameState.state["stage"]))
    if _smoke:
        _prepare_smoke()

func _on_player_died() -> void:
    # Derrota: volta uma fase (reaparece o chefe ao reavançar), vida cheia, sem buffs.
    player.buffs.clear()
    player.refresh_stats(true)
    stage_mgr.start_stage(maxi(1, stage_mgr.stage - 1))

## Modo de verificação do CI: godot --headless --fixed-fps 60 -- --smoke (30 s simulados).
func _prepare_smoke() -> void:
    stage_mgr.to_spawn = 6   # fase curta: permite testar limpeza de fase + cura em 30 s
    var st: Dictionary = GameState.state
    st["skills_owned"] = SkillsDB.ids()
    st["skills_equipped"] = ["celestial_lance", "holy_shield", "rain_of_light"]
    st["settings"]["auto_skills"] = true
    GameState.recalc()

func _process(_delta: float) -> void:
    if not _smoke:
        return
    _frames += 1
    if _frames == 240:
        caster.debug_cast_all()
    if _frames >= 1800:
        var s: Dictionary = GameState.state
        print("SMOKE_RESULT stage=%d gold=%d gems=%d hp=%.1f alive=%d casts=%d" % [int(s["stage"]), int(s["gold"]), int(s["gems"]), player.hp, stage_mgr.alive, caster.casts])
        get_tree().quit(0)
