class_name SpriteLib
extends RefCounted
## Carrega as folhas de sprites (assets/sprites/*.png) descritas em SpriteManifest e monta SpriteFrames.
## Toda a arte é original (veja assets/LICENSE.txt).

const DIR := "res://assets/sprites/"
static var _cache: Dictionary = {}
static var _additive: CanvasItemMaterial

static func has_sheet(sheet: String) -> bool:
    return SpriteManifest.DATA.has(sheet)

static func frames(sheet: String) -> SpriteFrames:
    if _cache.has(sheet):
        return _cache[sheet]
    if not SpriteManifest.DATA.has(sheet):
        push_warning("SpriteLib: folha desconhecida " + sheet)
        return null
    var m: Dictionary = SpriteManifest.DATA[sheet]
    var tex = load(DIR + sheet + ".png")
    if tex == null:
        push_warning("SpriteLib: textura ausente " + sheet)
        return null
    var sf := SpriteFrames.new()
    if sf.has_animation("default"):
        sf.remove_animation("default")
    var fw: int = int(m["fw"])
    var fh: int = int(m["fh"])
    for aname in m["anims"].keys():
        var a: Dictionary = m["anims"][aname]
        sf.add_animation(aname)
        sf.set_animation_speed(aname, float(a["fps"]))
        sf.set_animation_loop(aname, SaveData.as_bool(a["loop"], false))
        for k in range(int(a["count"])):
            var at := AtlasTexture.new()
            at.atlas = tex
            at.region = Rect2(float((int(a["start"]) + k) * fw), 0.0, float(fw), float(fh))
            sf.add_frame(aname, at)
    _cache[sheet] = sf
    return sf

## Material de mistura aditiva (brilhos). Uma instância compartilhada.
static func additive() -> CanvasItemMaterial:
    if _additive == null:
        _additive = CanvasItemMaterial.new()
        _additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
    return _additive

static func make(sheet: String, anim: String, scale: float) -> AnimatedSprite2D:
    var s := AnimatedSprite2D.new()
    s.sprite_frames = frames(sheet)
    s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    s.scale = Vector2(scale, scale)
    if s.sprite_frames != null and s.sprite_frames.has_animation(anim):
        s.animation = anim
        s.play(anim)
    return s
