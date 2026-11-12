extends Node2D
## Monta a cena de jogo em código (menos .tscn escritos à mão = menos pontos de falha sem editor).

var player: Player
var enemies: Node2D
var stage_mgr: StageManager
var hud: HUD
var joystick: VirtualJoystick
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
    hud = HUD.new()
    add_child(hud)
    joystick = VirtualJoystick.new()
    hud.add_control(joystick)
    player.joystick = joystick
    stage_mgr = StageManager.new()
    add_child(stage_mgr)
    stage_mgr.setup(player, enemies)
    Events.player_died.connect(_on_player_died)
    stage_mgr.start_stage(int(GameState.state["stage"]))
    if _smoke:
        stage_mgr.to_spawn = 3   # só no modo de verificação: permite testar a limpeza de fase em 30 s

func _on_player_died() -> void:
    # Derrota: volta uma fase (reaparece o chefe ao reavançar), vida cheia.
    player.refresh_stats(true)
    stage_mgr.start_stage(maxi(1, stage_mgr.stage - 1))

## Modo de verificação do CI: godot --headless --fixed-fps 60 -- --smoke (30 s simulados).
func _process(_delta: float) -> void:
    if not _smoke:
        return
    _frames += 1
    if _frames >= 1800:
        var s: Dictionary = GameState.state
        print("SMOKE_RESULT stage=%d gold=%d gems=%d hp=%.1f alive=%d" % [int(s["stage"]), int(s["gold"]), int(s["gems"]), player.hp, stage_mgr.alive])
        get_tree().quit(0)
