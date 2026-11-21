class_name BossFx
extends RefCounted
## Efeitos das habilidades dos chefes com arte nova (assets/bosses/<chefe>/fx/).
## Cada quadro de um efeito fica no MESMO tamanho com o ponto de referência no centro (bola de fogo: o centro da bola).
##   Mordath: bola de fogo roxa (fireball_0..2 voando, boom = explosão, smoke = fumaça sumindo)
##            e o portal de invocação (portal_0..2) onde cada demônio surge.
##   Azazel:  orbe de alma (orb_0..1 surgindo, orb_fly voando com rastro, orb_boom/orb_fade ao acertar)
##            e o portal de sombra do passo sombrio (shadow_0..5: abre no destino durante o aviso, explode ao chegar).
##   Lucifer: almas (soul_0 surge, soul_3..4 voando, soul_hit), explosões da tempestade (boom_0..5),
##            raio do abismo (beam_0..5, origem no centro do quadro, para a DIREITA), anel da nova (ring_0..5)
##            e o portal de invocação dos chefes (portal_0..5).
##   Ignarr:  sopro de fogo (breath_0..5, ponta do cone no centro do quadro, apontando para a DIREITA)
##            e o meteoro (meteor_0 brilho no chão, 1..2 caindo, 3..5 impacto/explosão/fumaça; referência = ponto de impacto).

const DIR := "res://assets/bosses/"
const FIREBALL_FRAMES := ["fireball_0", "fireball_1", "fireball_2"]
const FIREBALL_NATIVE_ANGLE := 2.4   # na imagem a bola vai para baixo-esquerda (cauda para cima-direita): ~137°
const FIREBALL_SCALE := 0.36         # quadros de 220 px -> bola de ~40 px na tela
## Projétil desenhado de cada chefe: quadros ao sair, quadros voando, ângulo em que a arte "aponta", escala, explosão e fumaça.
const PROJECTILES := {
    "mordath": {"launch": ["fireball_0", "fireball_1", "fireball_2"], "fly": ["fireball_1", "fireball_2"],
        "angle": FIREBALL_NATIVE_ANGLE, "scale": FIREBALL_SCALE, "boom": "boom", "smoke": "smoke"},
    # orbe de alma: surge 1 -> 2 -> 3, volta ao 2 e persegue o anjo nele; some = "vanish" (estrela), acerta = "hit" (fumaça)
    "lucifer": {"launch": ["soul_0"], "fly": ["soul_3", "soul_4"], "angle": -0.55, "scale": 0.45,
        "vanish": "soul_hit", "hit": "soul_hit"},   # alma flamejante: cabeça para cima-direita, rastro para baixo-esquerda
    "azazel": {"launch": ["soul_1", "soul_2", "soul_3"], "fly": ["soul_2"], "rotate": false,
        "angle": 0.0, "scale": 0.55, "vanish": "soul_vanish", "hit": "soul_hit"},
}
const SHADOW_FRAMES := ["shadow_0", "shadow_1", "shadow_2", "shadow_3"]
const SHADOW_SCALE := 1.0            # portal de ~260 px (recortado a 0,7) = diâmetro da explosão de 130 px de raio
const PORTAL_FRAMES := ["portal_0", "portal_1", "portal_2"]
const PORTAL_SCALE := 0.36           # portal de ~250 px -> ~90 px de largura na tela
const PORTAL_FRAME_TIME := 0.12
const PORTAL_HOLD := 0.35
const PORTAL_FADE := 0.3

const BREATH_FRAMES := ["breath_0", "breath_1", "breath_2", "breath_3", "breath_4", "breath_5"]
const BREATH_NATIVE_LEN := 408.0    # comprimento do maior quadro do sopro (px da imagem)
const BREATH_TIME := 0.55
const METEOR_SCALE := 0.75          # explosão de ~220 px -> ~165 px (cobre o raio de dano de 75 px)
const METEOR_FALL := 0.38           # segundos caindo antes de bater no chão
const METEOR_FROM := Vector2(150.0, -260.0)   # de onde o meteoro vem (cima-direita), relativo ao ponto de impacto
const METEOR_BOOM := [0.08, 0.16, 0.3]        # duração dos quadros 3, 4 e 5 (impacto, explosão, fumaça)

static var _cache: Dictionary = {}

static func tex(boss_dir: String, name: String) -> Texture2D:
    var p: String = DIR + boss_dir + "/fx/" + name + ".png"
    if not _cache.has(p):
        _cache[p] = load(p) if ResourceLoader.exists(p) else null
    return _cache[p]

static func has_fireball(boss_dir: String) -> bool:
    return PROJECTILES.has(boss_dir) and tex(boss_dir, PROJECTILES[boss_dir]["launch"][0]) != null

## Ângulo para onde a arte do projétil aponta (para girar na direção do voo).
static func proj_rotates(boss_dir: String) -> bool:
    return bool(PROJECTILES.get(boss_dir, {}).get("rotate", true))

static func proj_angle(boss_dir: String) -> float:
    return float(PROJECTILES[boss_dir]["angle"]) if PROJECTILES.has(boss_dir) else FIREBALL_NATIVE_ANGLE

## Sprite animado da bola de fogo voando (cresce nos 3 quadros e fica pulsando entre os 2 maiores).
static func fireball(boss_dir: String) -> AnimatedSprite2D:
    var sf := SpriteFrames.new()
    sf.remove_animation("default")
    var cfg: Dictionary = PROJECTILES[boss_dir]
    sf.add_animation("launch")
    sf.set_animation_speed("launch", 14.0)
    sf.set_animation_loop("launch", false)
    for f in cfg["launch"]:
        sf.add_frame("launch", tex(boss_dir, f))
    sf.add_animation("fly")
    sf.set_animation_speed("fly", 8.0)
    for f in cfg["fly"]:
        sf.add_frame("fly", tex(boss_dir, f))
    var s := AnimatedSprite2D.new()
    s.sprite_frames = sf
    s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    var k: float = float(cfg["scale"])
    s.scale = Vector2(k, k)
    s.animation_finished.connect(func(): s.play("fly"))
    s.play("launch")
    return s

## Explosão roxa onde a bola de fogo acertou (ou sumiu): explosão e depois a fumaça.
## hit = acertou o anjo (false = sumiu no fim da vida). Chefes com "hit"/"vanish" usam 1 quadro próprio para cada caso.
static func explode(parent: Node, pos: Vector2, boss_dir: String, hit: bool = true) -> Node2D:
    var n := Node2D.new()
    n.position = pos
    n.z_index = 5
    var s := Sprite2D.new()
    var cfg: Dictionary = PROJECTILES[boss_dir]
    if cfg.has("hit"):
        s.texture = tex(boss_dir, str(cfg["hit"] if hit else cfg["vanish"]))
        s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
        s.scale = Vector2(float(cfg["scale"]), float(cfg["scale"]))
        n.add_child(s)
        parent.add_child(n)
        var tw0 := n.create_tween()
        tw0.tween_property(s, "scale", s.scale * 1.25, 0.15)
        tw0.parallel().tween_property(s, "modulate:a", 0.0, 0.35).set_delay(0.1)
        tw0.tween_callback(n.queue_free)
        return n
    s.texture = tex(boss_dir, str(cfg["boom"]))
    s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    s.scale = Vector2(float(cfg["scale"]), float(cfg["scale"])) * 0.8
    n.add_child(s)
    parent.add_child(n)
    var tw := n.create_tween()
    tw.tween_property(s, "scale", s.scale * 1.35, 0.12)
    tw.tween_callback(func(): s.texture = tex(boss_dir, str(cfg["smoke"])))
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

static func has_breath(boss_dir: String) -> bool:
    return tex(boss_dir, "breath_0") != null

static func has_meteor(boss_dir: String) -> bool:
    return tex(boss_dir, "meteor_0") != null

## Sopro de fogo saindo de `from` na direção `dir`, com o comprimento do cone de dano (`length`).
static func breath(parent: Node, from: Vector2, dir: Vector2, length: float, boss_dir: String) -> Sprite2D:
    var s := Sprite2D.new()
    s.texture = tex(boss_dir, BREATH_FRAMES[0])
    s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    var k: float = length / BREATH_NATIVE_LEN
    s.scale = Vector2(k, k)
    s.position = from
    s.rotation = dir.angle()
    s.z_index = 2
    parent.add_child(s)
    var tw := s.create_tween()
    var step: float = BREATH_TIME / float(BREATH_FRAMES.size())
    for i in range(1, BREATH_FRAMES.size()):
        tw.tween_interval(step)
        var f: String = BREATH_FRAMES[i]
        tw.tween_callback(func(): s.texture = tex(boss_dir, f))
    tw.tween_interval(step)
    tw.tween_property(s, "modulate:a", 0.0, 0.15)
    tw.tween_callback(s.queue_free)
    return s

## Meteoro que BATE NO CHÃO em `pos` daqui a `land_in` s: brilho no chão (aviso), cai do céu, explode e vira fumaça.
static func meteor(parent: Node, pos: Vector2, land_in: float, boss_dir: String) -> Sprite2D:
    var s := Sprite2D.new()
    s.texture = tex(boss_dir, "meteor_0")
    s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    s.scale = Vector2(METEOR_SCALE, METEOR_SCALE)
    s.position = pos
    s.z_index = 2
    parent.add_child(s)
    var tw := s.create_tween()
    tw.tween_interval(maxf(0.0, land_in - METEOR_FALL))
    tw.tween_callback(func(): s.texture = tex(boss_dir, "meteor_1"); s.position = pos + METEOR_FROM)
    tw.tween_property(s, "position", pos + METEOR_FROM * 0.35, METEOR_FALL * 0.6)
    tw.tween_callback(func(): s.texture = tex(boss_dir, "meteor_2"); s.position = pos)   # quadro 2: sombra no ponto de impacto
    tw.tween_interval(METEOR_FALL * 0.4)
    for i in 3:
        var f: String = "meteor_%d" % (i + 3)
        tw.tween_callback(func(): s.texture = tex(boss_dir, f))
        tw.tween_interval(METEOR_BOOM[i])
    tw.tween_property(s, "modulate:a", 0.0, 0.25)
    tw.tween_callback(s.queue_free)
    return s

static func has_shadow_portal(boss_dir: String) -> bool:
    return tex(boss_dir, "shadow_0") != null

## Portal de sombra no DESTINO do passo sombrio: abre durante o aviso, explode (shadow_4) quando o chefe chega e vira fumaça.
static func shadow_portal(parent: Node, pos: Vector2, land_in: float, boss_dir: String) -> Sprite2D:
    var s := Sprite2D.new()
    s.texture = tex(boss_dir, SHADOW_FRAMES[0])
    s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    s.scale = Vector2(SHADOW_SCALE, SHADOW_SCALE)
    s.position = pos
    s.z_index = -1
    parent.add_child(s)
    var tw := s.create_tween()
    var step: float = land_in / float(SHADOW_FRAMES.size())
    for i in range(1, SHADOW_FRAMES.size()):
        tw.tween_interval(step)
        var f: String = SHADOW_FRAMES[i]
        tw.tween_callback(func(): s.texture = tex(boss_dir, f))
    tw.tween_interval(step)
    tw.tween_callback(func(): s.texture = tex(boss_dir, "shadow_4"); s.z_index = 2)
    tw.tween_interval(0.18)
    tw.tween_callback(func(): s.texture = tex(boss_dir, "shadow_5"))
    tw.tween_property(s, "modulate:a", 0.0, 0.4)
    tw.tween_callback(s.queue_free)
    return s

# ---------------- Lucifer
const BEAM_NATIVE_LEN := 380.0       # comprimento do raio no quadro mais longo (px do quadro)
const BEAM_NATIVE_W := 70.0          # espessura do núcleo do raio
const RING_NATIVE_D := 400.0         # diâmetro do anel de fogo no quadro maior
const BOOM_SCALE := 0.8              # explosão de ~220 px -> ~175 px (cobre o raio de 80 px)

static func has_lucifer_fx(boss_dir: String) -> bool:
    return tex(boss_dir, "beam_0") != null and tex(boss_dir, "ring_0") != null

## Sequência de quadros num Sprite2D: `times` = segundos de cada quadro; some no final.
static func _frames(parent: Node, pos: Vector2, boss_dir: String, names: Array, times: Array, sc: Vector2, z: int, fade: float = 0.25) -> Sprite2D:
    var s := Sprite2D.new()
    s.texture = tex(boss_dir, names[0])
    s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    s.scale = sc
    s.position = pos
    s.z_index = z
    parent.add_child(s)
    var tw := s.create_tween()
    for i in range(names.size()):
        if i > 0:
            var f: String = names[i]
            tw.tween_callback(func(): s.texture = tex(boss_dir, f))
        tw.tween_interval(float(times[i]))
    tw.tween_property(s, "modulate:a", 0.0, fade)
    tw.tween_callback(s.queue_free)
    return s

## Raio do abismo saindo de `from` na direção `dir`, com o comprimento e a espessura da área de dano.
static func abyss_beam(parent: Node, from: Vector2, dir: Vector2, length: float, width: float, boss_dir: String) -> Sprite2D:
    var sc := Vector2(length / BEAM_NATIVE_LEN, maxf(0.8, width / BEAM_NATIVE_W))
    var s := _frames(parent, from, boss_dir, ["beam_0", "beam_1", "beam_2", "beam_3", "beam_4", "beam_5"],
        [0.06, 0.06, 0.08, 0.14, 0.14, 0.12], sc, 2)
    s.rotation = dir.angle()
    return s

## Anel de fogo da Nova infernal: cresce durante o aviso (quadros 0..2), explode quando o dano entra (3..4) e vira fumaça (5).
static func hell_ring(parent: Node, pos: Vector2, land_in: float, radius: float, boss_dir: String) -> Sprite2D:
    var k: float = radius * 2.0 / RING_NATIVE_D
    var step: float = land_in / 3.0
    return _frames(parent, pos, boss_dir, ["ring_0", "ring_1", "ring_2", "ring_3", "ring_4", "ring_5"],
        [step, step, step, 0.14, 0.18, 0.3], Vector2(k, k), -1, 0.35)

## Explosão da Tempestade infernal que estoura em `pos` daqui a `land_in` s (o aviso fica no chão até lá).
static func storm_boom(parent: Node, pos: Vector2, land_in: float, boss_dir: String) -> Node2D:
    var n := Node2D.new()
    n.position = pos
    parent.add_child(n)
    var tw := n.create_tween()
    tw.tween_interval(maxf(0.0, land_in - 0.08))
    tw.tween_callback(func():
        _frames(n, Vector2.ZERO, boss_dir, ["boom_0", "boom_1", "boom_2", "boom_3", "boom_4", "boom_5"],
            [0.05, 0.06, 0.08, 0.12, 0.2, 0.22], Vector2(BOOM_SCALE, BOOM_SCALE), 2))
    tw.tween_interval(1.2)
    tw.tween_callback(n.queue_free)
    return n

## Portal de onde sai o chefe invocado (círculo de runas, coluna de sombra e fumaça).
static func summon_portal(parent: Node, pos: Vector2, boss_dir: String) -> Sprite2D:
    return _frames(parent, pos, boss_dir, ["portal_0", "portal_1", "portal_2", "portal_3", "portal_4", "portal_5"],
        [0.08, 0.1, 0.12, 0.2, 0.25, 0.25], Vector2(0.9, 0.9), -1, 0.3)
