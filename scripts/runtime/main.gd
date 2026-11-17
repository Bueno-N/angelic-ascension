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
var _fx_ok := false
var _warn_count := 0
var _mini_count := 0
var _profile_ok := false
var _opt_ok := false
var _dead := false
var _before_death := 1
var _death_ok := false
var _goto_ok := false
var _map_ok := true

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
    player.fx_layer = fx_layer
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
    hud.death_dismissed.connect(_revive)
    Events.goto_stage_requested.connect(func(s: int): stage_mgr.goto_stage(s))
    Events.state_changed.connect(_apply_fx)
    Events.stage_changed.connect(backdrop.set_stage)
    Events.enemy_died.connect(_on_enemy_died_fx)
    Events.request_next_stage.connect(func(): stage_mgr.request_next())
    Events.debug_goto_stage.connect(func(s: int): stage_mgr.set_repeat(false); stage_mgr.start_stage(s))
    Events.debug_heal.connect(func(): player.heal(player.max_hp))
    Events.debug_reset_cooldowns.connect(func(): caster.slots.reset_cooldowns())
    stage_mgr.start_stage(int(GameState.state["stage"]))
    _apply_fx()
    if _smoke:
        Events.stage_cleared.connect(func(_s: int, _t: float): _cleared += 1)
        Events.ability_cast.connect(_on_ability_cast)
        Events.boss_warning.connect(_on_warning)
        _prepare_smoke()

func _apply_fx() -> void:
    backdrop.set_fx(UiLogic.fx_enabled(GameState.state["settings"]))

## Derrota: o jogo congela e roda a animação de morte (HUD). Só quando o jogador TOCA NA TELA é que
## ele volta UMA fase e fica repetindo ela (modo repetir) até tocar em "Próxima fase".
func _on_player_died() -> void:
    if _dead:
        return   # vários golpes no mesmo frame
    _dead = true
    _before_death = stage_mgr.stage
    player.visible = false          # quem cai é o anjo desenhado pela tela de morte
    hud.show_death(player.global_position, maxi(1, stage_mgr.stage - 1))

func _revive() -> void:
    _dead = false
    player.visible = true
    player.buffs.clear()
    player.refresh_stats(true)
    var back: int = maxi(1, stage_mgr.stage - 1)
    stage_mgr.set_repeat(back < stage_mgr.stage)
    stage_mgr.start_stage(back)

## Explosão de partículas ao derrotar um inimigo (limitada para poupar aparelhos intermediários).
func _on_enemy_died_fx(pos: Vector2, def: Dictionary, is_boss: bool, _gold: int) -> void:
    var settings: Dictionary = GameState.state["settings"]
    if fx_layer.get_child_count() > UiLogic.fx_cap(settings):
        return
    if not UiLogic.fx_enabled(settings) and not is_boss:
        return   # "Efeitos: Baixo" só mantém a explosão dos chefes
    SpriteFx.spawn(fx_layer, "fx_poof", pos, 5.0 if is_boss else 2.0, Color(0.75, 0.35, 1.0) if def.get("special", false) else Color(1.0, 0.6, 0.3))
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

func _on_warning(_n: String, is_mini: bool) -> void:
    _warn_count += 1
    if is_mini:
        _mini_count += 1

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
            # um de cada tipo comum (sprites de todos os demônios são instanciados)
            for t in EnemiesDB.TYPES:
                if not t["special"]:
                    stage_mgr.debug_spawn_type(str(t["id"]), player.position + Vector2(-300.0, float(randi() % 200) - 100.0), false)
        400:
            _map_ok = _map_ok and hud.debug_map_step(0)      # mapa das fases: abre, rola para outra dificuldade, escolhe, fecha
        430:
            _map_ok = _map_ok and hud.debug_map_step(1)
        460:
            _map_ok = _map_ok and hud.debug_map_step(2)
        2700:
            Events.player_died.emit()               # morte: congela, mostra a animação e espera o toque
            _death_ok = hud.death_active() and not player.visible and not hud.debug_tap_death()   # travado nos primeiros 1,2 s
        2790:
            var before: int = _before_death         # toque na tela: volta 1 fase e entra em modo repetir
            _death_ok = _death_ok and hud.debug_tap_death() and not hud.death_active() and player.visible
            _repeat_ok = stage_mgr.stage == maxi(1, before - 1) and stage_mgr.repeat_mode
        2800:
            var b2: int = stage_mgr.stage          # "Próxima fase": avança 1 e sai do modo repetir
            stage_mgr.request_next()
            _next_ok = stage_mgr.stage == b2 + 1 and not stage_mgr.repeat_mode
        2820:
            var mx: int = int(GameState.state["max_stage"])      # menu "Fases": ir a andar já alcançado / ignorar o não alcançado
            Events.goto_stage_requested.emit(1)
            _goto_ok = stage_mgr.stage == 1 and stage_mgr.repeat_mode == (mx > 1)
            Events.goto_stage_requested.emit(mx + 5)
            _goto_ok = _goto_ok and stage_mgr.stage == 1
            stage_mgr.set_repeat(false)
        2850:
            GameState.toggle_speed()
            _speed_ok = is_equal_approx(Engine.time_scale, Balance.FAST_MODE_SCALE)
        2880:
            GameState.toggle_speed()
            _speed_ok = _speed_ok and is_equal_approx(Engine.time_scale, 1.0)
        2890:
            GameState.toggle_low_fx()
            _fx_ok = not UiLogic.fx_enabled(GameState.state["settings"])
        2910:
            GameState.toggle_low_fx()
            _fx_ok = _fx_ok and UiLogic.fx_enabled(GameState.state["settings"])
        2930:
            # opções (mesmo caminho do menu): volume em passos, mudo e efeitos
            var v0: int = OptionsLogic.volume(GameState.state["settings"])
            GameState.menu_action("opt|vol|-10")
            _opt_ok = OptionsLogic.volume(GameState.state["settings"]) == maxi(0, v0 - 10)
            GameState.menu_action("opt|fx|0")
            _opt_ok = _opt_ok and not UiLogic.fx_enabled(GameState.state["settings"])
        2940:
            GameState.menu_action("opt|fx|0")
            GameState.menu_action("opt|vol|10")
            _opt_ok = _opt_ok and UiLogic.fx_enabled(GameState.state["settings"]) and OptionsLogic.volume(GameState.state["settings"]) >= 10
        2960:
            stage_mgr.start_stage(30)    # chefe 3 (Ignarr): chuva de meteoros + sopro flamejante
        3560:
            stage_mgr.start_stage(40)    # chefe 4 (Azazel): passo sombrio + orbes de almas
        4160:
            stage_mgr.start_stage(5)     # mini-chefe 1 (Capitão Infernal) no fim da horda
            stage_mgr.to_spawn = 2
        4540:
            stage_mgr.start_stage(15)    # mini-chefe 2 (Cérbero das Cinzas)
            stage_mgr.to_spawn = 2
    # interface: menu (todas as abas) e perfil, com o desenho real rodando em frames seguidos
    var last_step: int = MenuModel.tabs(true).size() + 2   # abrir, 1 passo por aba, fechar+perfil, fechar perfil
    if _frames >= 180 and _frames % 20 == 0 and _frames <= 180 + 20 * last_step:
        var step: int = floori(float(_frames - 180) / 20.0)
        hud.debug_ui_step(step)
        if step == last_step:
            GameState.set_profile("Teste", 3)
            _profile_ok = str(GameState.state["profile"]["name"]) == "Teste" and int(GameState.state["profile"]["avatar"]) == 3
    if _frames >= 4940:
        var s: Dictionary = GameState.state
        var kinds: Array = _ability_kinds.keys()
        kinds.sort()
        print("SMOKE_RESULT stage=%d gold=%d gems=%d hp=%.1f alive=%d casts=%d cleared=%d abilities=%d kinds=%s repeat=%d next=%d speed=%d fx=%d warn=%d mini=%d profile=%d pause=%d opt=%d title=%d death=%d goto=%d map=%d" % [
            int(s["stage"]), int(s["gold"]), int(s["gems"]), player.hp, stage_mgr.alive, caster.casts, _cleared,
            _ability_count, ",".join(kinds), int(_repeat_ok), int(_next_ok), int(_speed_ok), int(_fx_ok), _warn_count, _mini_count, int(_profile_ok),
            int(hud.pause_checks >= 1 and hud.pause_errors == 0), int(_opt_ok), int(GameState.title_ok), int(_death_ok), int(_goto_ok), int(_map_ok)])
        get_tree().quit(0)
