class_name PixelFont
extends RefCounted
## Fonte pixel ORIGINAL (5x7, com acentos) desenhada a partir do atlas assets/sprites/font.png.
## `pos` é o TOPO das letras maiúsculas. Use escala inteira (2 = texto normal, 3-5 = títulos).

const SHEET := "res://assets/sprites/font.png"
static var _tex: Texture2D
static var _idx: Dictionary = {}

static func _ensure() -> void:
    if _tex == null:
        _tex = load(SHEET)
    if _idx.is_empty():
        var chars: String = SpriteManifest.FONT_CHARS
        for i in range(chars.length()):
            _idx[chars[i]] = i

static func glyph_index(ch: String) -> int:
    _ensure()
    return int(_idx.get(ch, _idx.get("?", 0)))

static func char_width(ch: String, scale: int) -> int:
    return int(SpriteManifest.FONT_ADV[glyph_index(ch)]) * scale

static func width(text: String, scale: int) -> int:
    var w := 0
    for i in range(text.length()):
        w += char_width(text[i], scale)
    return w

static func draw(ci: CanvasItem, pos: Vector2, text: String, scale: int, color: Color, shadow: bool = true) -> void:
    _ensure()
    if _tex == null:
        return
    var cw: int = SpriteManifest.FONT_CW
    var chh: int = SpriteManifest.FONT_CH
    var cols: int = SpriteManifest.FONT_COLS
    var passes: Array = [Color(0.0, 0.0, 0.0, 0.6), color] if shadow else [color]
    for pi in range(passes.size()):
        var off: float = float(scale) if (shadow and pi == 0) else 0.0
        var x: float = pos.x + off
        var y: float = pos.y - 2.0 * float(scale) + off
        for i in range(text.length()):
            var ch: String = text[i]
            var gi: int = glyph_index(ch)
            if ch != " ":
                ci.draw_texture_rect_region(_tex, Rect2(x, y, float(cw * scale), float(chh * scale)),
                    Rect2(float((gi % cols) * cw), float(floori(float(gi) / float(cols)) * chh), float(cw), float(chh)), passes[pi])
            x += float(int(SpriteManifest.FONT_ADV[gi]) * scale)

## Quebra o texto em linhas que cabem em max_w pixels. "\n" força quebra.
static func wrap(text: String, max_w: int, scale: int) -> Array:
    var lines: Array = []
    for para in text.split("\n"):
        var cur := ""
        for word in para.split(" "):
            var trial: String = word if cur == "" else cur + " " + word
            if cur != "" and width(trial, scale) > max_w:
                lines.append(cur)
                cur = word
            else:
                cur = trial
        lines.append(cur)
    return lines
