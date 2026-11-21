class_name LavaPortal
extends AnimatedSprite2D
## Portal de lava de onde os mobs nascem (assets/env/portal/portal_00..11.png, de art_source/lava_portal_sheet.webp).
## Abre (rachaduras -> redemoinho -> erupção), o mob surge na erupção e o portal se fecha.
## Leve: os quadros (SpriteFrames) são carregados UMA vez e compartilhados; no máximo MAX_ACTIVE portais ao mesmo tempo
## (passou disso, o mob só aparece com o fade, sem portal).

const DIR := "res://assets/env/portal/"
const FRAMES := 12
const FPS := 16.0                    # ~0,75 s no total
const ERUPT_FRAME := 6               # quadro da erupção (o mob aparece)
const SIZE := 78.0                   # largura na tela (mob comum ~56 px)
const MAX_ACTIVE := 8
const MOB_FADE := 0.35

static var _frames: SpriteFrames
static var active := 0

static func frames() -> SpriteFrames:
    if _frames == null:
        _frames = SpriteFrames.new()
        _frames.set_animation_loop("default", false)
        _frames.set_animation_speed("default", FPS)
        for i in FRAMES:
            var p := DIR + "portal_%02d.png" % i
            if ResourceLoader.exists(p):
                _frames.add_frame("default", load(p))
    return _frames

## Abre um portal em `pos` (no `parent`) e faz o mob `mob` surgir dele. `big` = chefe (portal maior).
static func open(parent: Node, pos: Vector2, mob: Node2D, big: bool = false) -> LavaPortal:
    if mob != null:
        mob.modulate.a = 0.0
        var tw := mob.create_tween()
        tw.tween_interval(float(ERUPT_FRAME) / FPS)
        tw.tween_property(mob, "modulate:a", 1.0, MOB_FADE)
    if active >= MAX_ACTIVE or frames().get_frame_count("default") == 0:
        return null
    var p := LavaPortal.new()
    p.sprite_frames = frames()
    p.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    var tex: Texture2D = p.sprite_frames.get_frame_texture("default", 0)
    var k: float = SIZE * (1.9 if big else 1.0) / float(tex.get_width())
    p.scale = Vector2(k, k)
    p.position = pos + Vector2(0.0, 10.0)
    p.z_index = -1
    parent.add_child(p)
    active += 1
    p.animation_finished.connect(p._done)
    p.play("default")
    return p

func _done() -> void:
    var tw := create_tween()
    tw.tween_property(self, "modulate:a", 0.0, 0.2)
    tw.tween_callback(queue_free)

func _notification(what: int) -> void:
    if what == NOTIFICATION_PREDELETE:
        active = maxi(0, active - 1)   # saiu do jogo (fechou, troca de fase ou fim da partida)
