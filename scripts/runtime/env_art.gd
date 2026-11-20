class_name EnvArt
extends RefCounted
## Arte de cenário em alta resolução (assets/env/): fundo da arena, tochas/braseiros animados e fogueiras.
## Diferente das folhas pixel-art pequenas do SpriteManifest (geradas por tools/art), estas vêm de imagens prontas:
## cada tira tem N quadros lado a lado, todos do mesmo tamanho (recortados de art_source/fire_props_sheet.png).
## São desenhadas REDUZIDAS, com filtro linear (ficam nítidas em telas grandes e sem serrilhado ao diminuir).

const DIR := "res://assets/env/"
## nome -> {frames, fps}
const STRIPS := {
    "brazier": {"frames": 5, "fps": 8.0},        # braseiro de pé
    "torch_wall": {"frames": 7, "fps": 9.0},     # tocha de parede
    "torch_pillar": {"frames": 5, "fps": 8.0},   # pilar com fogo
    "lantern": {"frames": 3, "fps": 5.0},        # lanterna pendurada
}
const GROUND_FIRES := 5                          # ground_fire_0..4.png (variações de fogueira no chão)
const BACKGROUND := "arena_bg.png"

static var _cache: Dictionary = {}

static func texture(file: String) -> Texture2D:
    var path: String = DIR + file
    if ResourceLoader.exists(path):
        return load(path)
    return null

static func background() -> Texture2D:
    return texture(BACKGROUND)

static func frames(strip: String) -> SpriteFrames:
    if _cache.has(strip):
        return _cache[strip]
    if not STRIPS.has(strip):
        return null
    var tex: Texture2D = texture(strip + ".png")
    if tex == null:
        return null
    var n: int = int(STRIPS[strip]["frames"])
    var fw: float = float(tex.get_width()) / float(n)
    var sf := SpriteFrames.new()
    sf.set_animation_speed("default", float(STRIPS[strip]["fps"]))
    sf.set_animation_loop("default", true)
    for i in range(n):
        var at := AtlasTexture.new()
        at.atlas = tex
        at.region = Rect2(fw * float(i), 0.0, fw, float(tex.get_height()))
        sf.add_frame("default", at)
    _cache[strip] = sf
    return sf

## Sprite animado com a BASE no ponto de posição e altura final `height_px` na tela.
static func make(strip: String, height_px: float) -> AnimatedSprite2D:
    var s := AnimatedSprite2D.new()
    s.sprite_frames = frames(strip)
    s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    if s.sprite_frames == null:
        return s
    var tex: Texture2D = s.sprite_frames.get_frame_texture("default", 0)
    var k: float = height_px / float(tex.get_height())
    s.scale = Vector2(k, k)
    s.centered = false
    s.offset = Vector2(-float(tex.get_width()) / 2.0, -float(tex.get_height()))
    s.play("default")
    s.frame = randi() % s.sprite_frames.get_frame_count("default")   # tochas não piscam todas juntas
    return s

## Fogueira de chão (variação 0..4), base no ponto de posição.
static func make_fire(variant: int, height_px: float) -> Sprite2D:
    var s := Sprite2D.new()
    s.texture = texture("ground_fire_%d.png" % clampi(variant, 0, GROUND_FIRES - 1))
    s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    if s.texture == null:
        return s
    var k: float = height_px / float(s.texture.get_height())
    s.scale = Vector2(k, k)
    s.centered = false
    s.offset = Vector2(-float(s.texture.get_width()) / 2.0, -float(s.texture.get_height()))
    return s
