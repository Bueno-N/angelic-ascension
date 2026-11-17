class_name UiIcons
extends RefCounted
## Ícones 24x24 (assets/sprites/ui_icons.png) e avatares 32x32 (avatars.png).

static var _icons: Texture2D
static var _avatars: Texture2D

static func draw(ci: CanvasItem, icon_name: String, rect: Rect2, tint: Color = Color.WHITE) -> void:
    if _icons == null:
        _icons = load("res://assets/sprites/ui_icons.png")
    var i: int = SpriteManifest.ICON_NAMES.find(icon_name)
    if _icons == null or i < 0:
        return
    ci.draw_texture_rect_region(_icons, rect, Rect2(float(i * 24), 0.0, 24.0, 24.0), tint)

static func draw_avatar(ci: CanvasItem, index: int, rect: Rect2) -> void:
    if _avatars == null:
        _avatars = load("res://assets/sprites/avatars.png")
    var i: int = clampi(index, 0, SpriteManifest.AVATAR_COUNT - 1)
    if _avatars == null:
        return
    ci.draw_texture_rect_region(_avatars, rect, Rect2(float(i * 32), 0.0, 32.0, 32.0))
