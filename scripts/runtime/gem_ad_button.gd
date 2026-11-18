class_name GemAdButton
extends UiButton
## Botão REDONDO ao lado do MENU: assistir a um anúncio premiado em troca de gemas (regras em GemAdLogic).
## Liberado: gema dourada + "+500"/"+100". Esperando: gema apagada + contador "mm:ss".
## Quem resgata é o HUD (GameState.gem_ad_claim); aqui só o desenho e o estado.

var reward := GemAdLogic.FIRST_REWARD
var seconds_left := 0
var waiting := false           # anúncio na tela
var _t := 0.0
var _poll := 0.0

func _process(delta: float) -> void:
    _t += delta
    _poll -= delta
    if _poll <= 0.0:
        _poll = 0.5
        refresh()
    elif seconds_left == 0 and not waiting:
        queue_redraw()        # animação do brilho

func refresh() -> void:
    var st: Dictionary = GameState.gem_ad_status()
    reward = int(st["reward"])
    seconds_left = int(st["seconds_left"])
    queue_redraw()

func ready_to_watch() -> bool:
    return seconds_left == 0 and not waiting

func _draw() -> void:
    var r: float = minf(size.x, size.y - 22.0) / 2.0 - 2.0
    var c := Vector2(size.x / 2.0, r + 2.0)
    var live: bool = ready_to_watch()
    var fill: Color = UiTheme.BG2.lightened(0.2) if _down else UiTheme.BG2
    var border: Color = UiTheme.GOLD if live else Color(0.32, 0.32, 0.4)
    if live:
        var glow: float = 0.25 + 0.2 * sin(_t * 4.0)
        draw_circle(c, r + 5.0, Color(UiTheme.GOLD.r, UiTheme.GOLD.g, UiTheme.GOLD.b, glow))
    draw_circle(c, r, fill)
    draw_arc(c, r, 0.0, TAU, 40, border, 3.0)
    var isz: float = r * 1.1
    UiIcons.draw(self, "gem", Rect2(c.x - isz / 2.0, c.y - isz / 2.0 - 4.0, isz, isz), Color.WHITE if live else Color(0.45, 0.45, 0.5))
    var tag := "AD"
    PixelFont.draw(self, Vector2(c.x - float(PixelFont.width(tag, 2)) / 2.0, c.y + r * 0.42), tag, 2, UiTheme.GOLD if live else UiTheme.TEXT_DIM)
    var label: String
    if waiting:
        label = "..."
    elif live:
        label = "+%d" % reward
    else:
        label = GemAdLogic.format_left(seconds_left)
    PixelFont.draw(self, Vector2((size.x - float(PixelFont.width(label, 2))) / 2.0, size.y - 16.0), label, 2, UiTheme.TEXT if live else UiTheme.TEXT_DIM)
