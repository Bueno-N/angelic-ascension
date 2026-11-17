class_name UiTheme
extends RefCounted
## Cores e molduras do tema "inferno celestial" (azul-noite, dourado e branco).

const BG := Color(0.06, 0.04, 0.12, 0.95)
const BG2 := Color(0.12, 0.09, 0.22, 0.97)
const GOLD := Color(0.93, 0.72, 0.25)
const GOLD_D := Color(0.5, 0.35, 0.12)
const TEXT := Color(0.97, 0.96, 1.0)
const TEXT_DIM := Color(0.72, 0.7, 0.88)
const GREEN := Color(0.3, 0.85, 0.35)
const GREEN_D := Color(0.14, 0.5, 0.2)
const RED := Color(0.95, 0.3, 0.3)
const BLUE := Color(0.4, 0.62, 1.0)

## Moldura em pixel art: sombra, borda, fundo, brilho no topo e cantos dourados.
static func panel(ci: CanvasItem, r: Rect2, fill: Color, border: Color) -> void:
    ci.draw_rect(Rect2(r.position + Vector2(3.0, 4.0), r.size), Color(0, 0, 0, 0.45))
    ci.draw_rect(r, border)
    ci.draw_rect(r.grow(-3.0), fill)
    ci.draw_rect(Rect2(r.position + Vector2(3.0, 3.0), Vector2(r.size.x - 6.0, 2.0)), Color(1, 1, 1, 0.1))
    var k := 5.0
    for c in [r.position, r.position + Vector2(r.size.x - k, 0.0), r.position + Vector2(0.0, r.size.y - k), r.position + r.size - Vector2(k, k)]:
        ci.draw_rect(Rect2(c, Vector2(k, k)), border.lightened(0.25))
