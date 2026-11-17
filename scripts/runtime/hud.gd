class_name HUD
extends CanvasLayer
## HUD: cartão do jogador (avatar -> perfil) com recursos embaixo e botões de velocidade/próxima fase ao lado;
## botão MENU no canto superior direito, com o botão FASES (mapa) logo abaixo. Pausam o jogo: PERFIL aberto, MAPA aberto
## e a tela de MORTE (get_tree().paused); o menu NÃO pausa.
## Todos os botões são UiButton (toque próprio): funcionam junto com o joystick (multitoque).

var _root: Control
var _top: HudTop
var _avatar_btn: UiButton
var _next_btn: UiButton
var _speed_btn: UiButton
var _menu_btn: UiButton
var _stages_btn: UiButton
var _map: MapPanel
var _weekly_btn: UiButton
var _weekly: WeeklyPanel
var _fight := false           # luta do boss semanal em andamento
var _menu: MenuPanel
var _profile: ProfilePanel
var _death: DeathOverlay
signal death_dismissed
var _smoke := false
var pause_checks := 0      # smoke: quantas vezes o jogo entrou em pausa ao abrir o perfil
var pause_errors := 0      # smoke: divergências entre "perfil aberto" e "jogo pausado"

func _ready() -> void:
    layer = 10
    _smoke = OS.get_cmdline_user_args().has("--smoke")
    process_mode = Node.PROCESS_MODE_ALWAYS    # a interface continua viva com o jogo em pausa
    _root = Control.new()
    _root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_root)
    _top = HudTop.new()
    _root.add_child(_top)
    _avatar_btn = _make_button("", "", Rect2(20.0, 16.0, 84.0, 84.0), _open_profile)
    # ao lado do cartão da vida (abaixo da barra de mobs, que fica no meio do topo): velocidade 2x e próxima fase
    _speed_btn = _make_button("", "speed", Rect2(404.0, 52.0, 150.0, 66.0), _on_speed)
    _next_btn = _make_button("", "next", Rect2(562.0, 52.0, 232.0, 66.0), _on_next)
    # estes não respondem com o jogo em pausa
    for b in [_avatar_btn, _speed_btn, _next_btn]:
        b.process_mode = Node.PROCESS_MODE_PAUSABLE
    _top.process_mode = Node.PROCESS_MODE_PAUSABLE
    _menu = MenuPanel.new()
    _root.add_child(_menu)
    _menu_btn = UiButton.new()
    _menu_btn.configure("MENU", "menu")
    _menu_btn.font_scale = 3
    _menu_btn.anchor_left = 1.0
    _menu_btn.anchor_right = 1.0
    _menu_btn.anchor_top = 0.0
    _menu_btn.anchor_bottom = 0.0
    _menu_btn.offset_left = -196.0     # canto superior direito
    _menu_btn.offset_right = -16.0
    _menu_btn.offset_top = 16.0
    _menu_btn.offset_bottom = 88.0
    _menu_btn.pressed.connect(_toggle_menu)
    _root.add_child(_menu_btn)
    _stages_btn = UiButton.new()          # logo ABAIXO do botão MENU: abre o mapa das 300 fases
    _stages_btn.configure("FASES", "stages")
    _stages_btn.font_scale = 3
    _stages_btn.anchor_left = 1.0
    _stages_btn.anchor_right = 1.0
    _stages_btn.offset_left = -196.0
    _stages_btn.offset_right = -16.0
    _stages_btn.offset_top = 96.0
    _stages_btn.offset_bottom = 160.0
    _stages_btn.pressed.connect(_toggle_map)
    _root.add_child(_stages_btn)
    _weekly_btn = UiButton.new()          # logo ABAIXO de FASES: boss semanal (bloqueado até concluir a fase 50)
    _weekly_btn.configure("BOSS\nSEMANAL", "lucifer", UiTheme.RED)
    _weekly_btn.font_scale = 2
    _weekly_btn.anchor_left = 1.0
    _weekly_btn.anchor_right = 1.0
    _weekly_btn.offset_left = -196.0
    _weekly_btn.offset_right = -16.0
    _weekly_btn.offset_top = 168.0
    _weekly_btn.offset_bottom = 240.0
    _weekly_btn.pressed.connect(_toggle_weekly)
    _root.add_child(_weekly_btn)
    _profile = ProfilePanel.new()
    _root.add_child(_profile)
    _map = MapPanel.new()            # tela cheia, por cima do jogo e dos botões
    _root.add_child(_map)
    _map.visibility_changed.connect(_update_pause)
    _death = DeathOverlay.new()      # por cima de tudo
    _root.add_child(_death)
    _death.dismissed.connect(_on_death_dismissed)
    _profile.visibility_changed.connect(_update_pause)
    _weekly = WeeklyPanel.new()      # tela cheia, por cima de tudo menos da morte
    _root.add_child(_weekly)
    _root.move_child(_weekly, _root.get_child_count() - 2)
    _weekly.visibility_changed.connect(_update_pause)
    Events.weekly_started.connect(_on_weekly_started)
    Events.weekly_finished.connect(_on_weekly_finished)
    _apply_safe_area()
    get_viewport().size_changed.connect(_apply_safe_area)
    Events.state_changed.connect(_refresh)
    Events.stage_changed.connect(_on_stage_changed)
    Events.player_hp_changed.connect(func(h: float, m: float): _top.hp = h; _top.max_hp = m; _top.queue_redraw())
    Events.boss_hp_changed.connect(func(h: float, m: float): _top.boss_hp = h; _top.boss_max = m; _top.queue_redraw())
    Events.stage_progress.connect(func(k: int, t: int, l: String): _top.killed = k; _top.total = t; _top.label = l; _top.queue_redraw())
    Events.stage_cleared.connect(func(_s: int, secs: float): _top.last_stage_secs = secs)
    Events.repeat_mode_changed.connect(func(on: bool): _top.repeat = on; _refresh())
    Events.boss_warning.connect(_on_boss_warning)
    _refresh()

## Só para o smoke do CI (o menu NÃO pausa; só o perfil): passo 0 abre o menu; 1..N percorre as abas; depois abre/fecha o perfil.
func debug_ui_step(step: int) -> void:
    var tabs: Array = MenuModel.tabs(true)
    if step == 0:
        _menu.toggle()
    elif step <= tabs.size():
        _menu.debug_open(str(tabs[step - 1]["id"]))
    elif step == tabs.size() + 1:
        _menu.close()
        _profile.open()
    else:
        _profile.close()

func add_control(c: Control) -> void:
    c.process_mode = Node.PROCESS_MODE_PAUSABLE   # joystick e habilidades param em pausa
    _root.add_child(c)
    _root.move_child(c, 0)   # joystick atrás dos botões

func _make_button(t: String, ic: String, r: Rect2, cb: Callable) -> UiButton:
    var b := UiButton.new()
    b.configure(t, ic)
    if t == "" and ic == "":
        b.avatar = 0
    b.position = r.position
    b.size = r.size
    b.pressed.connect(cb)
    _root.add_child(b)
    return b

## Garantia extra: a pausa SEMPRE acompanha o perfil aberto, mesmo que o sinal de visibilidade não dispare.
## (No smoke do CI não: lá a pausa é desfeita logo após conferir, para a cena continuar contando frames.)
func _process(_delta: float) -> void:
    if _smoke:
        return
    if get_tree().paused != OptionsLogic.should_pause(_profile.visible, _death.is_active(), _map.visible, _weekly.visible):
        _update_pause()

## Pausa o jogo enquanto o perfil estiver aberto (o menu não pausa); solta o joystick para não "grudar" a direção.
func _update_pause() -> void:
    var want: bool = OptionsLogic.should_pause(_profile.visible, _death.is_active(), _map.visible, _weekly.visible)
    get_tree().paused = want
    if want:
        pause_checks += 1
        Events.pause_started.emit()
    if get_tree().paused != want:
        pause_errors += 1
    if _smoke:
        get_tree().paused = false   # só no smoke do CI: o contador de frames da cena precisa continuar rodando

func _on_speed() -> void:
    if not get_tree().paused:
        GameState.toggle_speed()

func _on_next() -> void:
    if not get_tree().paused:
        Events.request_next_stage.emit()

func _toggle_menu() -> void:
    _map.close()
    _weekly.close()
    _menu.toggle()

func _toggle_map() -> void:
    if _fight:
        return    # durante a luta semanal o mapa fica fechado
    _menu.close()
    _weekly.close()
    _map.toggle()

## Só para o smoke do CI: 0 abre o mapa; 1 pula para uma dificuldade e escolhe uma fase; 2 fecha.
func debug_map_step(step: int) -> bool:
    match step:
        0:
            _map.open()
            return _map.is_open() and _map.selected() == int(GameState.state["stage"])
        1:
            _map.debug_select(Balance.MAX_STAGE, 3)
            return _map.selected() == Balance.MAX_STAGE
        _:
            _map.close()
            return not _map.is_open()

func _toggle_weekly() -> void:
    if _fight:
        return
    _menu.close()
    _map.close()
    _weekly.toggle()

func _on_weekly_started() -> void:
    _fight = true
    _menu.close()
    _map.close()
    _weekly.close()
    _refresh()

## Fim da luta: aviso grande na tela (tempo esgotado, derrota ou vitória) e volta à partida normal.
func _on_weekly_finished(res: Dictionary) -> void:
    _fight = false
    var score_txt: String = "Pontos: %s" % WeeklyBoss.fmt_score(float(res.get("score", 0.0)))
    match str(res.get("reason", "")):
        "timeout":
            _top.show_banner("O SEU TEMPO ACABOU", score_txt, "boss")
        "killed":
            _top.show_banner("LUCIFER DERROTADO!", score_txt, "stage")
        _:
            _top.show_banner("VOCE CAIU", score_txt, "boss")
    _refresh()

func _open_profile() -> void:
    _weekly.close()
    _map.close()
    _menu.close()
    _profile.open()

## Aviso ao entrar numa fase (também ao voltar por morte ou escolher no menu "Fases").
func _on_stage_changed(stg: int) -> void:
    _refresh()
    _top.show_banner("FASE %d" % stg, "Dificuldade: %s" % StageLogic.tier_name(stg), "stage")

## Morte: congela o jogo e mostra a animação; o jogador toca na tela para voltar (ver Main).
func show_death(world_pos: Vector2, to_stage: int) -> void:
    _menu.close()
    _weekly.close()
    _map.close()
    if _profile.visible:
        _profile.close()
    _death.start(world_pos, to_stage)
    _update_pause()

func _on_death_dismissed() -> void:
    _update_pause()
    death_dismissed.emit()

## Só para o smoke do CI: 0 = painel semanal fechado/aberto com a fase 50 ainda não concluída; 1 = abre e entra na luta.
func debug_weekly_step(step: int) -> bool:
    match step:
        0:
            _weekly.open()
            var locked: bool = _weekly.is_open() and WeeklyBoss.block_reason(GameState.weekly(), int(GameState.state["max_stage"])) == "locked"
            var refused: bool = not _weekly.debug_enter()
            _weekly.close()
            return locked and refused and not _weekly_btn.enabled
        1:
            _weekly.open()
            var ok: bool = _weekly.is_open() and _weekly_btn.enabled and _weekly.debug_enter()
            return ok and not _weekly.is_open()
        _:
            return not _weekly.is_open()

func death_active() -> bool:
    return _death.is_active()

## Só para o smoke do CI.
func debug_tap_death() -> bool:
    return _death.debug_tap()

func _on_boss_warning(boss_name: String, is_mini: bool) -> void:
    _top.boss_name = boss_name
    _top.boss_is_mini = is_mini
    _top.show_banner("MINI-CHEFE!" if is_mini else "AVISO: CHEFE!", boss_name, "boss")

## Só em aparelhos móveis: afasta o HUD do notch/cantos arredondados (DisplayServer.get_display_safe_area).
func _apply_safe_area() -> void:
    if not OS.has_feature("mobile"):
        return
    var safe: Rect2i = DisplayServer.get_display_safe_area()
    var m := UiLogic.safe_margins(Vector2(safe.position), Vector2(safe.size), Vector2(DisplayServer.window_get_size()),
        get_viewport().get_visible_rect().size)
    _root.offset_left = m["l"]
    _root.offset_top = m["t"]
    _root.offset_right = -m["r"]
    _root.offset_bottom = -m["b"]

func _refresh() -> void:
    var s: Dictionary = GameState.state
    var stg: int = int(s["stage"])
    _avatar_btn.avatar = int(s["profile"]["avatar"])
    _avatar_btn.queue_redraw()
    _next_btn.set_text("PRÓX. FASE %d" % mini(stg + 1, Balance.MAX_STAGE))
    _next_btn.set_enabled(StageLogic.can_skip_to_next(stg, int(s["max_stage"])))
    _speed_btn.set_text("VEL. %dX" % int(UiLogic.time_scale(s["settings"])))
    _weekly_btn.set_enabled(WeeklyBoss.is_unlocked(int(s["max_stage"])) and not _fight)   # bloqueado até concluir a fase 50
    _top.queue_redraw()
