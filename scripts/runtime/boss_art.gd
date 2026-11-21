class_name BossArt
extends RefCounted
## Arte nova dos CHEFES (assets/bosses/<chefe>/<quadro>.png, recortada de art_source/<chefe>/).
## Cada quadro é uma imagem própria, todas do MESMO tamanho (cell) com os PÉS no mesmo ponto (feet); a arte olha para a DIREITA.
## Animações comuns: walk (laço), attack (golpe corpo a corpo), die (morte, tocada no fx_layer).
## Cada habilidade pode ter 2 animações (ABILITY_ANIMS): "wind" durante o aviso (telegraph) e "hit" quando dispara.
## Chefes sem arte nova aqui continuam com as folhas antigas do SpriteManifest.
## Para trocar a arte: substitua os PNGs da pasta mantendo os nomes, tamanho do quadro e a posição dos pés.

const DIR := "res://assets/bosses/"
const SHEETS := {
    "boss_baal": {"dir": "baal", "cell": Vector2i(380, 232), "feet": Vector2(190.0, 216.0), "walk_h": 206.0,
        "anims": {
            "walk": ["walk_0", "walk_1", "walk_2", "walk_3", "walk_4", "walk_5"],
            "attack": ["melee_0", "melee_1", "melee_2", "melee_3", "melee_4"],   # golpe corpo a corpo: ergue e gira a maça
            "slam_wind": ["slam_0", "slam_1"],          # Pancada em área: ergue a maça (aviso)
            "slam_hit": ["slam_2", "slam_3"],           # esmaga o chão (onda vermelha) e se recompõe
            "charge_wind": ["prep_0", "prep_1"],        # Investida: se prepara agachado (aviso)
            "dash": ["run_0", "run_1", "run_2", "run_3", "run_4", "run_5"],   # correndo na investida
            "die": ["death_0", "death_1", "death_2", "death_3", "death_4", "death_5"],
        }},
    "boss_mordath": {"dir": "mordath", "cell": Vector2i(218, 285), "feet": Vector2(109.0, 223.0), "walk_h": 195.0,
        "hand": Vector2(65.0, -155.0),               # mão que lança os projéteis (px do quadro, a partir dos pés)
        "anims": {
            "walk": ["walk_0", "walk_1", "walk_2", "walk_3", "walk_4", "walk_5"],   # flutuando
            "attack": ["cast_3", "cast_4"],             # golpe básico à distância: braço estendido soltando 1 bola de fogo
            "proj_wind": ["cast_0", "cast_1"],          # Projéteis infernais: junta a energia (aviso)
            "proj_hit": ["cast_3", "cast_4"],           # lança o leque de bolas de fogo
            "summon_wind": ["summon_0", "summon_1"],    # Invocação: ergue os braços (aviso)
            "summon_hit": ["summon_2"],                 # círculo de runas no chão (os portais surgem nos demônios)
            "die": ["death_0", "death_1", "death_2", "death_3", "death_4", "death_5"],
        }},
    "boss_ignarr": {"dir": "ignarr", "cell": Vector2i(588, 340), "feet": Vector2(294.0, 298.0), "walk_h": 210.0,
        "height": 125.0,                             # quadrúpede: mais baixo e comprido que os outros
        "hand": Vector2(126.0, -83.0),               # boca (de onde sai o sopro)
        "anims": {
            "walk": ["walk_0", "walk_1", "walk_2", "walk_3", "walk_4", "walk_5"],
            "attack": ["atk_0", "atk_1", "atk_2"],      # golpe corpo a corpo: ergue a pata e arranha com fogo
            "breath_wind": ["breath_0", "breath_1"],    # Sopro flamejante: ruge e abre a boca (aviso)
            "breath_hit": ["breath_2", "breath_3", "breath_4"],   # sopra (o fogo é um efeito à parte, BossFx.breath)
            "roar_wind": ["roar_0", "roar_1", "roar_2"],  # Chuva de meteoros: empina e ruge para o céu (aviso)
            "roar_hit": ["roar_3", "roar_4"],           # anéis de fogo nos pés enquanto os meteoros caem
            "die": ["death_0", "death_1", "death_2", "death_3", "death_4", "death_5"],
        }},
    "boss_azazel": {"dir": "azazel", "cell": Vector2i(320, 300), "feet": Vector2(160.0, 256.0), "walk_h": 205.0,
        "hand": Vector2(62.0, -150.0),               # mão que arremessa o orbe (golpe à distância)
        "anims": {
            "walk": ["walk_0", "walk_1", "walk_2", "walk_3", "walk_4", "walk_5"],   # voando
            "attack": ["atk_3", "atk_4", "atk_5"],      # golpe à distância: estende o braço e arremessa 1 orbe
            "orbs_wind": ["orbs_0", "orbs_1", "orbs_2"],  # Orbes de almas: ergue o orbe e abre o anel (aviso)
            "orbs_hit": ["orbs_3", "orbs_4"],           # solta os orbes (os de verdade perseguem o anjo)
            "step_wind": ["depart_0", "depart_1", "depart_2", "depart_3", "depart_4"],   # Passo sombrio: afunda no portal
            "step_hit": ["arrive_0", "arrive_1", "arrive_2", "arrive_3", "arrive_4"],    # surge do portal perto do anjo
            "die": ["death_0", "death_1", "death_2", "death_3", "death_4", "death_5"],
        }},
}
## habilidade -> [animação do aviso, animação do golpe]
const ABILITY_ANIMS := {
    "boss_baal": {"area_slam": ["slam_wind", "slam_hit"], "charge": ["charge_wind", "dash"]},
    "boss_mordath": {"summon_demons": ["summon_wind", "summon_hit"], "hellfire_projectiles": ["proj_wind", "proj_hit"]},
    "boss_ignarr": {"meteor_rain": ["roar_wind", "roar_hit"], "flame_breath": ["breath_wind", "breath_hit"]},
    "boss_azazel": {"shadow_step": ["step_wind", "step_hit"], "soul_orbs": ["orbs_wind", "orbs_hit"]},
}
const FPS := {"walk": 8.0, "attack": 10.0, "slam_wind": 3.0, "slam_hit": 5.0, "charge_wind": 3.0, "dash": 14.0, "die": 6.0,
    "proj_wind": 3.0, "proj_hit": 5.0, "summon_wind": 3.0, "summon_hit": 2.0,
    "breath_wind": 2.4, "breath_hit": 6.0, "roar_wind": 2.2, "roar_hit": 3.0,
    "orbs_wind": 3.2, "orbs_hit": 4.0, "step_wind": 5.6, "step_hit": 9.0}
const LOOP := {"walk": true, "dash": true}
const BASE_HEIGHT := 150.0         # altura do chefe andando na tela, na escala normal (EnemiesDB.SPRITE_SCALE)
const DEATH_HOLD := 0.6            # segundos caído no chão antes de sumir
const DEATH_FADE := 0.6

static var _cache: Dictionary = {}

static func has(sprite: String) -> bool:
    return SHEETS.has(sprite) and ResourceLoader.exists(DIR + str(SHEETS[sprite]["dir"]) + "/walk_0.png")

static func frames(sprite: String) -> SpriteFrames:
    if _cache.has(sprite):
        return _cache[sprite]
    if not has(sprite):
        return null
    var m: Dictionary = SHEETS[sprite]
    var sf := SpriteFrames.new()
    sf.remove_animation("default")
    for anim in m["anims"]:
        sf.add_animation(anim)
        sf.set_animation_speed(anim, float(FPS.get(anim, 8.0)))
        sf.set_animation_loop(anim, bool(LOOP.get(anim, false)))
        for f in m["anims"][anim]:
            sf.add_frame(anim, load(DIR + str(m["dir"]) + "/" + str(f) + ".png"))
    _cache[sprite] = sf
    return sf

## Animação do aviso (i = 0) ou do golpe (i = 1) de uma habilidade; "" se o chefe não tiver.
static func ability_anim(sprite: String, ability: String, i: int) -> String:
    var m: Dictionary = ABILITY_ANIMS.get(sprite, {})
    return str(m[ability][i]) if m.has(ability) else ""

static func scale_for(sprite: String, sprite_scale: float) -> float:
    var m: Dictionary = SHEETS[sprite]
    return float(m.get("height", BASE_HEIGHT)) * sprite_scale / EnemiesDB.SPRITE_SCALE / float(m["walk_h"])

## Posição da mão (relativa ao nó, já na escala e no lado para onde o chefe olha); Vector2.ZERO se não houver.
static func hand_offset(sprite: String, sprite_scale: float, flip: bool) -> Vector2:
    var m: Dictionary = SHEETS.get(sprite, {})
    if not m.has("hand"):
        return Vector2.ZERO
    var h: Vector2 = m["hand"]
    var rel := Vector2(h.x, h.y + float(m["walk_h"]) / 2.0) * scale_for(sprite, sprite_scale)   # relativo ao centro do corpo
    return Vector2(-rel.x if flip else rel.x, rel.y)

## Deslocamento que põe o CENTRO do corpo (meia altura acima dos pés) na posição do nó.
static func body_offset(sprite: String) -> Vector2:
    var m: Dictionary = SHEETS[sprite]
    var cell: Vector2i = m["cell"]
    var feet: Vector2 = m["feet"]
    var body := Vector2(feet.x, feet.y - float(m["walk_h"]) / 2.0)
    return Vector2(cell.x / 2.0, cell.y / 2.0) - body

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

## Animação de morte no lugar do chefe (o nó já foi removido). Fica caído um pouco e some.
static func spawn_death(layer: Node, pos: Vector2, def: Dictionary) -> AnimatedSprite2D:
    var sprite: String = str(def.get("sprite", ""))
    if not has(sprite):
        return null
    var s := make(sprite, EnemiesDB.SPRITE_SCALE, "die")
    s.position = pos
    s.flip_h = bool(def.get("_flip", false))
    if bool(def.get("summon", false)):
        s.modulate = Color(0.85, 0.6, 1.0, 0.95)
    s.z_index = -1
    layer.add_child(s)
    var tw := s.create_tween()
    var n: int = s.sprite_frames.get_frame_count("die")
    tw.tween_interval(float(n) / float(FPS["die"]) + DEATH_HOLD)
    tw.tween_property(s, "modulate:a", 0.0, DEATH_FADE)
    tw.tween_callback(s.queue_free)
    return s
