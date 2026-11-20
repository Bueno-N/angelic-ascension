class_name WeeklyPanel
extends Control
## Tela do BOSS SEMANAL (Lucifer): estado (bloqueado / entradas / nova semana), melhor pontuação, recompensas e RANKING MUNDIAL.
## Online só se data/online_config.gd estiver preenchido; senão funciona OFFLINE (a luta e a pontuação local continuam valendo).
## O jogo pausa enquanto a tela está aberta. Toda a rede passa por OnlineClient.

var _close: UiButton
var _enter: UiButton
var _claim: UiButton
var _refresh_btn: UiButton
var _client: OnlineClient
var _ov: Dictionary = {}          # última resposta do servidor (já normalizada)
var _loading := false
var _net_fail := false
var _msg := ""
var _msg_warn := false
var _t := 0.0
var _fight := false              # luta em andamento (o botão do HUD também fica travado)
var started_requests := 0         # smoke: quantas lutas este painel iniciou

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    visible = false
    _close = UiButton.new()
    _close.configure("", "close", UiTheme.RED)
    _close.pressed.connect(close)
    add_child(_close)
    _enter = UiButton.new()
    _enter.configure("ENTRAR", "lucifer", UiTheme.RED)
    _enter.font_scale = 3
    _enter.pressed.connect(_on_enter)
    add_child(_enter)
    _claim = UiButton.new()
    _claim.configure("RESGATAR PREMIO", "gem")
    _claim.pressed.connect(_on_claim)
    add_child(_claim)
    _refresh_btn = UiButton.new()
    _refresh_btn.configure("ATUALIZAR", "")
    _refresh_btn.pressed.connect(_fetch)
    add_child(_refresh_btn)
    _client = OnlineClient.new()
    add_child(_client)
    _client.done.connect(_on_net)
    resized.connect(_layout)
    Events.weekly_finished.connect(_on_finished)
    Events.weekly_started.connect(func(): _fight = true; _update_buttons())
    Events.state_changed.connect(_update_buttons)
    _layout()

func is_open() -> bool:
    return visible

func open() -> void:
    GameState.weekly_sync()
    _msg = ""
    _ov = {}
    _net_fail = false
    visible = true
    _update_buttons()
    _fetch()
    queue_redraw()

func close() -> void:
    visible = false

func toggle() -> void:
    if visible:
        close()
    else:
        open()

func _panel_rect() -> Rect2:
    var w: float = minf(size.x - 60.0, 1180.0)
    var h: float = size.y - 40.0
    return Rect2((size.x - w) / 2.0, 20.0, w, h)

func _layout() -> void:
    if _enter == null:
        return
    var r: Rect2 = _panel_rect()
    _close.position = Vector2(r.end.x - 64.0, r.position.y + 12.0)
    _close.size = Vector2(52.0, 52.0)
    _enter.position = Vector2(r.position.x + 24.0, r.end.y - 104.0)
    _enter.size = Vector2(250.0, 84.0)
    _claim.position = Vector2(r.position.x + 288.0, r.end.y - 104.0)
    _claim.size = Vector2(250.0, 84.0)
    _refresh_btn.position = Vector2(r.end.x - 214.0, r.end.y - 84.0)
    _refresh_btn.size = Vector2(190.0, 64.0)
    queue_redraw()

# ---------------------------------------------------------------- estado
func _reason() -> String:
    return WeeklyBoss.block_reason(GameState.weekly(), int(GameState.state["max_stage"]))

func _update_buttons() -> void:
    if _enter == null:
        return
    var w: Dictionary = GameState.weekly()
    _enter.set_enabled(_reason() == "" and not _loading and not _fight)
    _claim.visible = WeeklyBoss.claimable(w)
    _claim.set_enabled(WeeklyBoss.claimable(w) and not _loading and (not OnlineConfig.enabled() or not _ov.is_empty()))
    _refresh_btn.visible = OnlineConfig.enabled()
    if visible:
        queue_redraw()

func _set_msg(t: String, warn: bool = false) -> void:
    _msg = t
    _msg_warn = warn
    queue_redraw()

# ---------------------------------------------------------------- rede
func _fetch() -> void:
    if not OnlineConfig.enabled():
        return
    _loading = true
    _net_fail = false
    _update_buttons()
    _client.overview(str(GameState.weekly()["pid"]))

func _on_net(kind: String, ok: bool, data: Variant) -> void:
    _loading = false
    match kind:
        "overview":
            if ok:
                var ov: Dictionary = WeeklyBoss.parse_overview(data)
                if bool(ov["ok"]):
                    _ov = ov
                    _net_fail = false
                    if int(ov["week"]) > 0:
                        GameState.weekly_sync(int(ov["week"]))   # o servidor é quem manda na semana (relógio do aparelho pode estar errado)
                    GameState.weekly_set_entries(int(ov["attempts"]))
                else:
                    _net_fail = true
            else:
                _net_fail = true
        "attempt":
            var at: Dictionary = WeeklyBoss.parse_attempt(data if ok else null)
            if bool(at["ok"]):
                if int(at["week"]) > 0:
                    GameState.weekly_sync(int(at["week"]))
                GameState.weekly_set_entries(int(at["attempts"]))
                _start_fight()
            elif bool(at["net"]):
                GameState.weekly_set_entries(int(at["attempts"]))
                _set_msg("SEM ENTRADAS NESTA SEMANA", true)
            else:
                _set_msg("SEM CONEXAO: nao foi possivel entrar", true)
        "submit":
            if ok:
                _fetch()
    _update_buttons()
    queue_redraw()

func _on_finished(res: Dictionary) -> void:
    _fight = false
    var score: float = float(res.get("score", 0.0))
    var better: bool = GameState.weekly_record(score)
    if OnlineConfig.enabled() and score > 0.0 and better:
        _client.submit(str(GameState.weekly()["pid"]), score)

# ---------------------------------------------------------------- ações
func _on_enter() -> void:
    var reason: String = _reason()
    if reason == "locked":
        _set_msg("Conclua a fase %d para liberar" % Balance.WEEKLY_UNLOCK_STAGE, true)
        return
    if reason == "no_entries":
        _set_msg("SEM ENTRADAS NESTA SEMANA", true)
        return
    if OnlineConfig.enabled():
        _loading = true
        _update_buttons()
        _set_msg("Conectando...")
        _client.start_attempt(str(GameState.weekly()["pid"]), str(GameState.state["profile"]["name"]))
    else:
        if GameState.weekly_begin():
            _start_fight()

func _start_fight() -> void:
    started_requests += 1
    close()
    Events.weekly_requested.emit()

func _on_claim() -> void:
    var w: Dictionary = GameState.weekly()
    var rank := 0
    var total := 0
    if OnlineConfig.enabled():
        if _ov.is_empty() or int(_ov["prev_week"]) != int(w["prev_week"]):
            rank = 0      # servidor não tem posição dessa semana: participação
        else:
            rank = int(_ov["prev_rank"])
            total = int(_ov["prev_total"])
    var r: Dictionary = GameState.weekly_claim(rank, total)
    if r.is_empty():
        return
    _set_msg("%s: +%d GEMAS +%d FRAGMENTOS" % [str(r["label"]), int(r["gems"]), int(r["shards"])])
    _update_buttons()

## Só para o smoke do CI.
func debug_enter() -> bool:
    var before: int = started_requests
    _on_enter()
    return started_requests > before

# ---------------------------------------------------------------- desenho
func _process(delta: float) -> void:
    if not visible:
        return
    _t += delta / maxf(Engine.time_scale, 0.01)
    if _t >= 1.0:
        _t = 0.0
        queue_redraw()    # contagem regressiva da semana

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.68))
    var r: Rect2 = _panel_rect()
    UiTheme.panel(self, r, Color(0.05, 0.02, 0.09, 0.97), Color(0.8, 0.15, 0.2))
    UiIcons.draw(self, "lucifer", Rect2(r.position.x + 20.0, r.position.y + 14.0, 56.0, 56.0))
    PixelFont.draw(self, Vector2(r.position.x + 90.0, r.position.y + 24.0), "BOSS SEMANAL: LUCIFER", 4, Color(1.0, 0.35, 0.3))
    var w: Dictionary = GameState.weekly()
    var x: float = r.position.x + 28.0
    var y: float = r.position.y + 92.0
    var reason: String = _reason()
    if reason == "locked":
        PixelFont.draw(self, Vector2(x, y), "BLOQUEADO: conclua a fase %d" % Balance.WEEKLY_UNLOCK_STAGE, 2, UiTheme.RED)
    else:
        var left: int = WeeklyBoss.entries_left(w)
        PixelFont.draw(self, Vector2(x, y), "ENTRADAS: %d/%d" % [left, Balance.WEEKLY_MAX_ENTRIES], 3, UiTheme.GREEN if left > 0 else UiTheme.RED)
    y += 34.0
    var secs: int = WeeklyBoss.seconds_left(int(Time.get_unix_time_from_system()))
    PixelFont.draw(self, Vector2(x, y), "Nova semana em: %s" % WeeklyBoss.fmt_countdown(secs), 2, UiTheme.TEXT)
    y += 26.0
    PixelFont.draw(self, Vector2(x, y), "Tempo da luta: %s" % WeeklyBoss.fmt_clock(Balance.WEEKLY_TIME_LIMIT), 2, UiTheme.TEXT)
    y += 26.0
    PixelFont.draw(self, Vector2(x, y), "Seu melhor: %s" % ("-" if float(w["best"]) <= 0.0 else WeeklyBoss.fmt_score(float(w["best"]))), 2, UiTheme.GOLD)
    y += 38.0
    PixelFont.draw(self, Vector2(x, y), "Lucifer invoca 1 chefe a cada %d s" % int(Balance.WEEKLY_SUMMON_EVERY), 2, UiTheme.TEXT_DIM)
    y += 30.0
    PixelFont.draw(self, Vector2(x, y), "PRÊMIO POR LUTA (% da vida tirada)", 2, UiTheme.GOLD)
    y += 24.0
    var ms: int = int(GameState.state["max_stage"])
    for t in WeeklyBoss.ATTEMPT_TIERS:
        var rw: Dictionary = WeeklyBoss.tier_reward(t, ms)
        var killed_row: bool = bool(t.get("killed", false))
        PixelFont.draw(self, Vector2(x, y), "%s: %s ouro, %s gemas" % [str(rw["label"]), UiLogic.fmt_short(float(rw["gold"])),
            UiLogic.fmt_int(int(rw["gems"]))], 2, UiTheme.GOLD if killed_row else UiTheme.TEXT_DIM)
        y += 22.0
    PixelFont.draw(self, Vector2(x, y), "Valores da sua fase máxima (%d). + bônus do ranking" % ms, 2, UiTheme.TEXT_DIM)
    # ---- ranking mundial (lado direito) ----
    var rx: float = r.position.x + r.size.x * 0.52
    var ry: float = r.position.y + 92.0
    PixelFont.draw(self, Vector2(rx, ry), "RANKING MUNDIAL", 3, UiTheme.GOLD)
    ry += 40.0
    if not OnlineConfig.enabled():
        PixelFont.draw(self, Vector2(rx, ry), "MODO OFFLINE", 3, UiTheme.RED)
        PixelFont.draw(self, Vector2(rx, ry + 34.0), "Servidor nao configurado", 2, UiTheme.TEXT_DIM)
        PixelFont.draw(self, Vector2(rx, ry + 58.0), "(veja docs/ONLINE.md)", 2, UiTheme.TEXT_DIM)
        PixelFont.draw(self, Vector2(rx, ry + 92.0), "Sua pontuacao fica salva aqui", 2, UiTheme.TEXT_DIM)
    elif _loading and _ov.is_empty():
        PixelFont.draw(self, Vector2(rx, ry), "Carregando...", 2, UiTheme.TEXT_DIM)
    elif _net_fail and _ov.is_empty():
        PixelFont.draw(self, Vector2(rx, ry), "SEM CONEXAO", 3, UiTheme.RED)
    elif not _ov.is_empty():
        var top: Array = _ov["top"]
        if top.is_empty():
            PixelFont.draw(self, Vector2(rx, ry), "Ninguem pontuou ainda", 2, UiTheme.TEXT_DIM)
        for row in top:
            var col: Color = UiTheme.GOLD if int(row["rank"]) <= 3 else UiTheme.TEXT
            PixelFont.draw(self, Vector2(rx, ry), "#%d %s" % [int(row["rank"]), str(row["name"])], 2, col)
            var sc: String = WeeklyBoss.fmt_score(float(row["score"]))
            PixelFont.draw(self, Vector2(r.end.x - 40.0 - float(PixelFont.width(sc, 2)), ry), sc, 2, col)
            ry += 24.0
        ry += 10.0
        var me: String = "VOCE: -" if int(_ov["me_rank"]) <= 0 else "VOCE: #%d de %d" % [int(_ov["me_rank"]), int(_ov["total"])]
        PixelFont.draw(self, Vector2(rx, ry), me, 2, UiTheme.GREEN)
    if _msg != "":
        PixelFont.draw(self, Vector2(r.position.x + 28.0, r.end.y - 128.0), _msg, 2, UiTheme.RED if _msg_warn else UiTheme.GREEN)
