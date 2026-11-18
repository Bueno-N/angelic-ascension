class_name DeathOverlay
extends Control
## Tela de morte: o jogo congela (pausa), o anjo cai com penas, aparece "VOCÊ CAIU" e o jogador TOCA NA TELA
## para voltar à fase anterior. Anima em tempo REAL (ignora o 2x) e continua viva com o jogo em pausa.
## Se houver anúncio premiado pronto (AdsManager), mostra o botão "ASSISTIR ANÚNCIO": quem assiste até o fim
## revive ONDE PAROU, sem reiniciar a fase (sinal ad_revived) em vez de voltar uma. Uma vez por FASE (quem decide é o Main via allow_ad).

signal dismissed
signal ad_revived

const LOCK_SECONDS := 1.2        # toques antes disso são ignorados (evita fechar sem querer)
var _active := false
var _t := 0.0
var _to_stage := 1
var _angel: AngelSprite
var _origin := Vector2.ZERO
var _here_stage := 1
var _ad_used := false            # já tentou o anúncio nesta morte
var _ad_wait := false            # anúncio na tela, esperando o resultado
var _ad_earned := false
var _btn := Rect2()

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    visible = false
    _angel = AngelSprite.new()
    add_child(_angel)

func is_active() -> bool:
    return _active

## world_pos = onde o anjo caiu; to_stage = fase para a qual o jogador volta ao tocar;
## here_stage = fase em que ele está (e continua, do mesmo ponto, se assistir ao anúncio).
## allow_ad = false esconde o botão do anúncio (já reviveu por anúncio nesta fase).
func start(world_pos: Vector2, to_stage: int, here_stage: int = 0, allow_ad: bool = true) -> void:
    _active = true
    _t = 0.0
    _to_stage = to_stage
    _here_stage = here_stage if here_stage > 0 else to_stage
    _ad_used = not allow_ad
    _ad_wait = false
    _ad_earned = false
    _btn = Rect2()
    _origin = world_pos - global_position
    _angel.set_look(int(GameState.state["wings_level"]), int(GameState.state["glow_tier"]), GameState.state["equipped"])
    _angel.position = _origin
    _angel.rotation = 0.0
    _angel.modulate = Color.WHITE
    mouse_filter = Control.MOUSE_FILTER_STOP
    visible = true
    queue_redraw()

func can_dismiss() -> bool:
    return _active and _t >= LOCK_SECONDS

func _close() -> void:
    _active = false
    visible = false
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func _dismiss() -> void:
    _close()
    dismissed.emit()

## O botão do anúncio aparece só se o AdsManager tiver um premiado carregado (no PC nunca aparece).
func ad_offer() -> bool:
    return can_dismiss() and not _ad_used and not _ad_wait and AdsManager.is_rewarded_ready()

func _watch_ad() -> void:
    _ad_used = true
    _ad_wait = true
    _ad_earned = false
    _connect_ads(true)
    if not AdsManager.show_rewarded():
        _ad_end()
    queue_redraw()

func _connect_ads(on: bool) -> void:
    var pairs: Array = [[AdsManager.rewarded_earned, _on_ad_earned], [AdsManager.rewarded_dismissed, _on_ad_closed],
        [AdsManager.rewarded_show_failed, _on_ad_failed]]
    for pr in pairs:
        var sig: Signal = pr[0]
        var cb: Callable = pr[1]
        if on and not sig.is_connected(cb):
            sig.connect(cb)
        elif not on and sig.is_connected(cb):
            sig.disconnect(cb)

func _on_ad_earned(_amount: int, _kind: String) -> void:
    _ad_earned = true

func _on_ad_closed() -> void:
    # em alguns aparelhos o "ganhou" chega logo DEPOIS do "fechou": espera um instante antes de decidir
    get_tree().create_timer(0.4, true, false, true).timeout.connect(_ad_end)

func _on_ad_failed(_message: String) -> void:
    _ad_end()

func _ad_end() -> void:
    if not _ad_wait:
        return
    _ad_wait = false
    _connect_ads(false)
    if _ad_earned and _active:
        _close()
        ad_revived.emit()
    else:
        queue_redraw()     # fechou antes do fim ou falhou: continua na tela de morte (toque volta uma fase)

## Só para o smoke do CI: "toca na tela". Devolve false se ainda estiver travado.
func debug_tap() -> bool:
    if not can_dismiss():
        return false
    _dismiss()
    return true

func _gui_input(event: InputEvent) -> void:
    if not _active:
        return
    if event is InputEventScreenTouch and event.pressed:
        accept_event()
        if _ad_wait:
            return
        if ad_offer() and _btn.has_point(event.position):
            _watch_ad()
        elif can_dismiss():
            _dismiss()

func _process(delta: float) -> void:
    if not _active:
        return
    _t += delta / maxf(Engine.time_scale, 0.01)
    # queda do anjo: cai e tomba de lado, escurecendo
    var fall: float = clampf((_t - 0.15) / 1.0, 0.0, 1.0)
    var ease_f: float = fall * fall * (3.0 - 2.0 * fall)
    var shake: float = sin(_t * 60.0) * 6.0 * clampf(1.0 - _t / 0.4, 0.0, 1.0)
    _angel.position = _origin + Vector2(shake, 46.0 * ease_f)
    _angel.rotation = 1.45 * ease_f
    var g: float = 1.0 - 0.45 * ease_f
    _angel.modulate = Color(g, g, minf(1.0, g + 0.1), 1.0 - 0.25 * ease_f)
    queue_redraw()

func _draw() -> void:
    if not _active:
        return
    var w: float = size.x
    var h: float = size.y
    # escurece a tela e dá um clarão vermelho no impacto
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.03, minf(0.7, _t * 0.9)))
    if _t < 0.45:
        draw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 0.2, 0.15, 0.45 * (1.0 - _t / 0.45)))
    # penas caindo ao redor de onde o anjo caiu
    for i in range(16):
        var seed_f: float = float(i) * 1.7
        var life: float = fmod(_t * 0.6 + float(i) * 0.13, 1.0)
        var px: float = _origin.x + sin(seed_f * 3.1 + _t * 2.0) * (30.0 + 8.0 * float(i % 5)) + (float(i % 7) - 3.0) * 12.0
        var py: float = _origin.y - 30.0 + life * 150.0
        draw_rect(Rect2(px, py, 6.0, 3.0), Color(1.0, 0.97, 0.9, 0.85 * (1.0 - life)))
    # textos
    if _t > 0.55:
        var a: float = clampf((_t - 0.55) / 0.4, 0.0, 1.0)
        var title := "VOCÊ CAIU"
        PixelFont.draw(self, Vector2((w - float(PixelFont.width(title, 8))) / 2.0, h * 0.14), title, 8, Color(1.0, 0.3, 0.25, a))
    if _t >= LOCK_SECONDS:
        if _ad_wait:
            var wait_txt := "Carregando anúncio..."
            PixelFont.draw(self, Vector2((w - float(PixelFont.width(wait_txt, 3))) / 2.0, h * 0.6), wait_txt, 3, UiTheme.TEXT_DIM)
            return
        var offer: bool = ad_offer()
        if offer:
            var l1 := "ASSISTIR ANÚNCIO"
            var l2 := "Reviver aqui (fase %d)" % _here_stage
            var bw: float = float(maxi(PixelFont.width(l1, 4), PixelFont.width(l2, 3))) + 48.0
            var bh: float = 92.0
            _btn = Rect2((w - bw) / 2.0, h * 0.5, bw, bh)
            var pulse: float = 0.85 + 0.15 * sin(_t * 4.0)
            draw_rect(_btn.grow(4.0), UiTheme.GOLD_D)
            draw_rect(_btn, Color(UiTheme.GREEN_D.r * pulse, UiTheme.GREEN_D.g * pulse, UiTheme.GREEN_D.b * pulse))
            draw_rect(_btn, UiTheme.GOLD, false, 3.0)
            PixelFont.draw(self, Vector2((w - float(PixelFont.width(l1, 4))) / 2.0, _btn.position.y + 18.0), l1, 4, UiTheme.TEXT)
            PixelFont.draw(self, Vector2((w - float(PixelFont.width(l2, 3))) / 2.0, _btn.position.y + 58.0), l2, 3, UiTheme.GOLD)
        else:
            _btn = Rect2()
        var blink: float = 0.55 + 0.45 * sin(_t * 5.0)
        var tip := ("Ou toque fora para voltar à fase %d" if offer else "Toque na tela para voltar à fase %d") % _to_stage
        PixelFont.draw(self, Vector2((w - float(PixelFont.width(tip, 3))) / 2.0, h * 0.82), tip, 3, Color(1.0, 0.95, 0.8, blink))
