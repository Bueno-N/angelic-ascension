class_name BossFx
extends RefCounted
## Efeitos das habilidades dos chefes com arte nova (assets/bosses/<chefe>/fx/).
## Cada quadro de um efeito fica no MESMO tamanho com o ponto de referência no centro (bola de fogo: o centro da bola).
##   Mordath: bola de fogo roxa (fireball_0..2 voando, boom = explosão, smoke = fumaça sumindo)
##            e o portal de invocação (portal_0..2) onde cada demônio surge.

const DIR := "res://assets/bosses/"
const FIREBALL_FRAMES := ["fireball_0", "fireball_1", "fireball_2"]
const FIREBALL_NATIVE_ANGLE := 2.4   # na imagem a bola vai para baixo-esquerda (cauda para cima-direita): ~137°
const FIREBALL_SCALE := 0.36         # quadros de 220 px -> bola de ~40 px na tela
const PORTAL_FRAMES := ["portal_0", "portal_1", "portal_2"]
const PORTAL_SCALE := 0.36           # portal de ~250 px -> ~90 px de largura na tela
const PORTAL_FRAME_TIME := 0.12
const PORTAL_HOLD := 0.35
const PORTAL_FADE := 0.3

static var _cache: Dictionary = {}

static func tex(boss_dir: String, name: String) -> Texture2D:
    var p: String = DIR + boss_dir + "/fx/" + name + ".png"
    if not _cache.has(p):
        _cache[p] = load(p) if ResourceLoader.exists(p) else null
    return _cache[p]

static func has_fireball(boss_dir: String) -> bool:
    return tex(boss_dir, "fireball_0") != null

## Sprite animado da bola de fogo voando (cresce nos 3 quadros e fica pulsando entre os 2 maiores).
static func fireball(boss_dir: String) -> AnimatedSprite2D:
    var sf := SpriteFrames.new()
    sf.remove_animation("default")
    sf.add_animation("launch")
    sf.set_animation_speed("launch", 14.0)
    sf.set_animation_loop("launch", false)
    for f in FIREBALL_FRAMES:
        sf.add_frame("launch", tex(boss_dir, f))
    sf.add_animation("fly")
    sf.set_animation_speed("fly", 8.0)
    sf.add_frame("fly", tex(boss_dir, "fireball_1"))
    sf.add_frame("fly", tex(boss_dir, "fireball_2"))
    var s := AnimatedSprite2D.new()
    s.sprite_frames = sf
    s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    s.scale = Vector2(FIREBALL_SCALE, FIREBALL_SCALE)
    s.animation_finished.connect(func(): s.play("fly"))
    s.play("launch")
    return s

## Explosão roxa onde a bola de fogo acertou (ou sumiu): explosão e depois a fumaça.
static func explode(parent: Node, pos: Vector2, boss_dir: String) -> Node2D:
    var n := Node2D.new()
    n.position = pos
    n.z_index = 5
    var s := Sprite2D.new()
    s.texture = tex(boss_dir, "boom")
    s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    s.scale = Vector2(FIREBALL_SCALE, FIREBALL_SCALE) * 0.8
    n.add_child(s)
    parent.add_child(n)
    var tw := n.create_tween()
    tw.tween_property(s, "scale", s.scale * 1.35, 0.12)
    tw.tween_callback(func(): s.texture = tex(boss_dir, "smoke"))
    tw.tween_property(s, "modulate:a", 0.0, 0.3)
    tw.tween_callback(n.queue_free)
    return n

## Portal de invocação no chão (abre em 3 quadros, segura e some). Fica atrás dos inimigos.
static func portal(parent: Node, pos: Vector2, boss_dir: String) -> Sprite2D:
    var s := Sprite2D.new()
    s.texture = tex(boss_dir, PORTAL_FRAMES[0])
    s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    s.scale = Vector2(PORTAL_SCALE, PORTAL_SCALE)
    s.position = pos + Vector2(0.0, 12.0)    # no chão, um pouco abaixo do centro do demônio
    s.z_index = -1
    parent.add_child(s)
    var tw := s.create_tween()
    for i in range(1, PORTAL_FRAMES.size()):
        tw.tween_interval(PORTAL_FRAME_TIME)
        var f: String = PORTAL_FRAMES[i]
        tw.tween_callback(func(): s.texture = tex(boss_dir, f))
    tw.tween_interval(PORTAL_HOLD)
    tw.tween_property(s, "modulate:a", 0.0, PORTAL_FADE)
    tw.tween_callback(s.queue_free)
    return s
