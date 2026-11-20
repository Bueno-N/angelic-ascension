class_name MobArt
extends RefCounted
## Arte nova dos MOBS (assets/mobs/<sprite>.png, recortada de art_source/mobs_sheet.webp).
## Cada folha é uma tira de quadros do mesmo tamanho (cell), com os PÉS alinhados embaixo; a arte olha para a DIREITA.
## Animações: walk (laço), attack (golpe corpo a corpo), cast (pose de habilidade), die (morte, tocada no fx_layer).
## Os nomes são os mesmos campos "sprite" de EnemiesDB.TYPES (sons e o resto do jogo continuam iguais).
## Chefes, Lucifer e invocações de chefe continuam com as folhas antigas do SpriteManifest.

const DIR := "res://assets/mobs/"
## Gerado pelo recorte: tamanho do quadro, altura média andando (px da imagem) e quadros de cada animação.
const SHEETS := {
    "imp": {"cell": Vector2i(196, 106), "walk_h": 95, "anims": {"attack":[5,6],"cast":[7],"die":[8,9],"walk":[0,1,2,3,4]}},
    "warrior": {"cell": Vector2i(148, 106), "walk_h": 99, "anims": {"attack":[4,5],"cast":[6],"die":[7],"walk":[0,1,2,3]}},
    "shadow": {"cell": Vector2i(144, 98), "walk_h": 81, "anims": {"attack":[4,5],"die":[6],"walk":[0,1,2,3]}},
    "hound": {"cell": Vector2i(192, 118), "walk_h": 105, "anims": {"attack":[4,5],"die":[6],"walk":[0,1,2,3]}},
    "caster": {"cell": Vector2i(156, 106), "walk_h": 86, "anims": {"cast":[5,6],"die":[7,8],"walk":[0,1,2,3,4]}},
    "leech": {"cell": Vector2i(108, 98), "walk_h": 81, "anims": {"attack":[5],"cast":[6],"die":[7],"walk":[0,1,2,3,4]}},
}
const BASE_HEIGHT := 56.0          # altura na tela andando, na escala normal de mob (EnemiesDB.SPRITE_SCALE)
const HEIGHT_MULT := {"imp": 1.0, "warrior": 1.12, "shadow": 1.0, "hound": 1.2, "caster": 1.05, "leech": 0.9}
const FPS := {"walk": 8.0, "attack": 12.0, "cast": 6.0, "die": 9.0}
const LOOP := {"walk": true, "attack": false, "cast": true, "die": false}
const DEATH_FADE := 0.45           # segundos parado no chão sumindo, depois da animação de morte

static var _cache: Dictionary = {}

static func has(sprite: String) -> bool:
    return SHEETS.has(sprite) and ResourceLoader.exists(DIR + sprite + ".png")

static func frames(sprite: String) -> SpriteFrames:
    if _cache.has(sprite):
        return _cache[sprite]
    if not has(sprite):
        return null
    var tex: Texture2D = load(DIR + sprite + ".png")
    var m: Dictionary = SHEETS[sprite]
    var cell: Vector2i = m["cell"]
    var sf := SpriteFrames.new()
    sf.remove_animation("default")
    for anim in m["anims"]:
        sf.add_animation(anim)
        sf.set_animation_speed(anim, float(FPS.get(anim, 8.0)))
        sf.set_animation_loop(anim, bool(LOOP.get(anim, true)))
        for i in m["anims"][anim]:
            var at := AtlasTexture.new()
            at.atlas = tex
            at.region = Rect2(float(int(i) * cell.x), 0.0, float(cell.x), float(cell.y))
            sf.add_frame(anim, at)
    _cache[sprite] = sf
    return sf

## Escala para a altura alvo. sprite_scale = a escala que o jogo pedia para a folha antiga (mob 2.0, mini-chefe 3.0...).
static func scale_for(sprite: String, sprite_scale: float) -> float:
    var m: Dictionary = SHEETS[sprite]
    var target: float = BASE_HEIGHT * float(HEIGHT_MULT.get(sprite, 1.0)) * sprite_scale / EnemiesDB.SPRITE_SCALE
    return target / float(m["walk_h"])

## Deslocamento (px da imagem) que põe o CENTRO do corpo na posição do nó (como nas folhas antigas).
static func body_offset(sprite: String) -> Vector2:
    var m: Dictionary = SHEETS[sprite]
    var cell: Vector2i = m["cell"]
    var body_y: float = float(cell.y) - 3.0 - float(m["walk_h"]) / 2.0
    return Vector2(0.0, -(body_y - float(cell.y) / 2.0))

static func make(sprite: String, sprite_scale: float, anim: String = "walk") -> AnimatedSprite2D:
    var s := AnimatedSprite2D.new()
    s.sprite_frames = frames(sprite)
    s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    var k: float = scale_for(sprite, sprite_scale)
    s.scale = Vector2(k, k)
    s.offset = body_offset(sprite)
    if s.sprite_frames != null and s.sprite_frames.has_animation(anim):
        s.play(anim)
    return s

## Animação de morte no lugar do mob (o nó do inimigo já foi removido). Some sozinha.
static func spawn_death(layer: Node, pos: Vector2, def: Dictionary) -> AnimatedSprite2D:
    var sprite: String = str(def.get("sprite", ""))
    if not has(sprite) or not SHEETS[sprite]["anims"].has("die"):
        return null
    var scale_req: float = Balance.MINI_SCALE if bool(def.get("mini", false)) else EnemiesDB.SPRITE_SCALE
    var s := make(sprite, scale_req, "die")
    s.position = pos
    s.flip_h = bool(def.get("_flip", false))
    if bool(def.get("summon", false)):
        s.modulate = Color(0.8, 0.6, 1.0, 0.9)
    s.z_index = -1
    layer.add_child(s)
    var tw := s.create_tween()
    var n: int = s.sprite_frames.get_frame_count("die")
    tw.tween_interval(float(n) / float(FPS["die"]))
    tw.tween_property(s, "modulate:a", 0.0, DEATH_FADE)
    tw.tween_callback(s.queue_free)
    return s
