class_name BossPointer
extends Control
## Seta na BEIRA DA TELA apontando para cada chefe/mini-chefe que está fora de vista (o mundo é maior que a tela).
## Fica no HUD (CanvasLayer); converte a posição do chefe no mundo para a tela pela câmera.

const MARGIN := 46.0                 # distância da seta até a borda da tela
const SIZE := 30.0
const TOP_RESERVED := 150.0          # não cobre a barra de vida/HUD de cima
const BOTTOM_RESERVED := 130.0       # nem os botões de habilidade embaixo

var _targets: Array = []             # [{pos: Vector2 (tela), ang: float, lucifer: bool}]
var _t := 0.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_preset(Control.PRESET_FULL_RECT)

## Ponto na borda do retângulo `r` na direção de `target` a partir do centro (lógica pura, testável).
static func edge_point(r: Rect2, target: Vector2) -> Vector2:
    var c := r.get_center()
    var d := target - c
    if d.length() < 0.001:
        return c
    var half := r.size / 2.0
    var k: float = minf(half.x / maxf(absf(d.x), 0.001), half.y / maxf(absf(d.y), 0.001))
    return c + d * minf(k, 1.0)

func _process(delta: float) -> void:
    _t += delta
    _targets.clear()
    var vp := get_viewport_rect()
    var screen := Rect2(vp.position + Vector2(MARGIN, maxf(MARGIN, TOP_RESERVED)), vp.size - Vector2(MARGIN * 2.0, maxf(MARGIN, TOP_RESERVED) + BOTTOM_RESERVED))
    for e in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(e) or not (e.is_boss or e.is_mini) or e.is_summon:
            continue
        var sp: Vector2 = e.get_global_transform_with_canvas().origin
        if vp.grow(-10.0).has_point(sp):
            continue   # chefe visível: sem seta
        var p := edge_point(screen, sp)
        _targets.append({"pos": p, "ang": (sp - p).angle(), "lucifer": str(e.def.get("id", "")) == "lucifer"})
    visible = not _targets.is_empty()
    queue_redraw()

func _draw() -> void:
    var pulse: float = 0.75 + 0.25 * sin(_t * 6.0)
    for t in _targets:
        var p: Vector2 = t["pos"]
        var a: float = t["ang"]
        var col := Color(1.0, 0.3, 0.2, pulse)
        # seta (triângulo) apontando para o chefe, com fundo escuro e o ícone de caveira
        var tip := p + Vector2.from_angle(a) * SIZE
        var l := p + Vector2.from_angle(a + 2.4) * SIZE * 0.6
        var r := p + Vector2.from_angle(a - 2.4) * SIZE * 0.6
        draw_circle(p, SIZE * 0.78, Color(0.08, 0.02, 0.04, 0.8))
        draw_arc(p, SIZE * 0.78, 0.0, TAU, 24, col, 3.0)
        draw_colored_polygon(PackedVector2Array([tip, l, r]), col)
        UiIcons.draw(self, "lucifer" if t["lucifer"] else "skull", Rect2(p - Vector2(13, 13), Vector2(26, 26)))
