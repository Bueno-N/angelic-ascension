class_name SpriteFx
extends AnimatedSprite2D
## Efeito de sprite de uso único (some quando a animação termina). Respeita o teto de efeitos do jogo.

## pivot: ponto da imagem (em pixels) que fica em `pos` (ex.: base do raio de luz). INF = centro.
static func spawn(parent: Node, sheet: String, pos: Vector2, scale: float, tint: Color, rot: float = 0.0,
        additive: bool = true, pivot: Vector2 = Vector2.INF) -> SpriteFx:
    if parent == null or parent.get_child_count() > UiLogic.fx_cap(GameState.state["settings"]):
        return null
    var frames := SpriteLib.frames(sheet)
    if frames == null or not frames.has_animation("play"):
        return null
    var f := SpriteFx.new()
    f.sprite_frames = frames
    f.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    f.position = pos
    f.rotation = rot
    f.scale = Vector2(scale, scale)
    f.modulate = tint
    if additive:
        f.material = SpriteLib.additive()
    if pivot != Vector2.INF:
        f.centered = false
        f.offset = -pivot
    parent.add_child(f)
    f.animation = "play"
    f.play("play")
    f.animation_finished.connect(f.queue_free)
    return f
