class_name DeathOverlay
extends Control
## Tela de morte: o jogo congela (pausa), o anjo cai com penas, aparece "VOCÊ CAIU" e o jogador TOCA NA TELA
## para voltar à fase anterior. Anima em tempo REAL (ignora o 2x) e continua viva com o jogo em pausa.

signal dismissed

const LOCK_SECONDS := 1.2        # toques antes disso são ignorados (evita fechar sem querer)
var _active := false
var _t := 0.0
var _to_stage := 1
var _angel: AngelSprite
var _origin := Vector2.ZERO

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    visible = false
    _angel = AngelSprite.new()
    add_child(_angel)

func is_active() -> bool:
    return _active

## world_pos = onde o anjo caiu; to_stage = fase para a qual o jogador volta ao tocar.
func start(world_pos: Vector2, to_stage: int) -> void:
    _active = true
    _t = 0.0
    _to_stage = to_stage
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

func _dismiss() -> void:
    _active = false
    visible = false
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    dismissed.emit()

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
        if can_dismiss():
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
        var blink: float = 0.55 + 0.45 * sin(_t * 5.0)
        var tip := "Toque na tela para voltar à fase %d" % _to_stage
        PixelFont.draw(self, Vector2((w - float(PixelFont.width(tip, 3))) / 2.0, h * 0.82), tip, 3, Color(1.0, 0.95, 0.8, blink))
