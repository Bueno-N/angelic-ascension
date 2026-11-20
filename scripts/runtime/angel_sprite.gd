class_name AngelSprite
extends Node2D
## Anjo com a arte nova (assets/angel/*.png, recortada de art_source/angel_sheet.jpg): uma imagem por POSE.
## Todas as poses ficam alinhadas pelo peito do anjo (ANCHORS), então trocar de pose não faz o anjo "pular".
##
## Poses normais: idle (parado), cast (conjurando), attack_1 -> attack_2 (disparo de luz).
## Brilho das asas (glow_tier): idle vira glow_1 (tiers 1-3) ou glow_2 (tiers 4+).
## MODO INFERNO (só enquanto a habilidade "A MORTE DO INFERNO" está ativa, ver set_hell):
##   parado = hell_1 <-> hell_2 (fogo em volta), ataque = hell_attack (raio enfeitado), conjuração = hell_cast.
## A arte é fixa: asas e equipamentos não mudam mais o desenho do anjo (continuam valendo nos atributos).

const DIR := "res://assets/angel/"
const SPRITE_SCALE := 0.5          # imagens em alta resolução (~250 px) -> ~125 px na tela (como o anjo antigo)
const CHEST_Y := -6.0              # onde o peito fica em relação à posição do nó
## Ponto do peito em cada imagem (gerado pelo recorte; ver art_source/README.md).
const ANCHORS := {
    "idle": Vector2(122.8, 121.2),
    "cast": Vector2(135.4, 144.0),
    "attack_1": Vector2(137.3, 120.1),
    "attack_2": Vector2(120.9, 120.6),
    "glow_1": Vector2(141.2, 111.9),
    "glow_2": Vector2(148.1, 123.6),
    "hell_1": Vector2(132.8, 213.9),
    "hell_2": Vector2(149.6, 190.3),
    "hell_attack": Vector2(127.7, 166.8),
    "hell_cast": Vector2(131.3, 120.3),
    "folded": Vector2(116.5, 126.8),
}
const ATTACK_FRAME := 0.11         # segundos por quadro do ataque (dividido pela velocidade)
const CAST_TIME := 0.45
const HELL_FPS := 6.0

static var _tex: Dictionary = {}

var _spr: Sprite2D
var _cur := "idle"
var _idle_pose := "idle"
var _hell := false
var _speed := 1.0
var _t := 0.0                      # tempo na animação atual
var _bob := 0.0

## Estágio das asas (0..3) a partir do nível (0..10). Mantido para a lógica/testes (a arte nova não muda com ele).
static func wings_stage(level: int) -> int:
    return clampi(floori(float(level) / 3.0), 0, 3)

static func pose_texture(pose: String) -> Texture2D:
    if not _tex.has(pose):
        var path: String = DIR + pose + ".png"
        _tex[pose] = load(path) if ResourceLoader.exists(path) else null
    return _tex[pose]

## Pose de parado conforme o brilho das asas.
static func idle_pose_for(glow_tier: int) -> String:
    if glow_tier >= 4:
        return "glow_2"
    if glow_tier >= 1:
        return "glow_1"
    return "idle"

## Pose mostrada para uma animação/tempo (lógica pura, testável).
static func pose_for(anim: String, t: float, hell: bool, idle_pose: String, speed: float) -> String:
    var fdur: float = ATTACK_FRAME / clampf(speed, 0.8, 3.0)
    match anim:
        "attack":
            if hell:
                return "hell_attack"
            return "attack_1" if t < fdur else "attack_2"
        "cast":
            return "hell_cast" if hell else "cast"
    if hell:
        return "hell_1" if int(t * HELL_FPS) % 2 == 0 else "hell_2"
    return idle_pose

## Duração de uma animação que volta sozinha para o idle (0 = em laço).
static func anim_length(anim: String, hell: bool, speed: float) -> float:
    var fdur: float = ATTACK_FRAME / clampf(speed, 0.8, 3.0)
    match anim:
        "attack":
            return fdur * (2.6 if hell else 2.0)
        "cast":
            return CAST_TIME
    return 0.0

func _init() -> void:
    _spr = Sprite2D.new()
    _spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    _spr.centered = false
    _spr.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
    add_child(_spr)
    _show(_idle_pose)

func set_look(_wings_level: int, glow_tier: int, _equipped: Dictionary) -> void:
    _idle_pose = idle_pose_for(glow_tier)
    _refresh()

## Liga/desliga o visual da MORTE DO INFERNO (fogo em volta e ataque enfeitado).
func set_hell(on: bool) -> void:
    if on != _hell:
        _hell = on
        _refresh()

func is_hell() -> bool:
    return _hell

func play_anim(anim: String) -> void:
    _cur = anim
    _t = 0.0
    _refresh()

func attack() -> void:
    play_anim("attack")

func cast() -> void:
    play_anim("cast")

## Velocidade das animações (acompanha a velocidade de ataque).
func set_speed(s: float) -> void:
    _speed = clampf(s, 0.8, 3.0)

## Olha para a direita (dir_x >= 0) ou esquerda.
func face(dir_x: float) -> void:
    if absf(dir_x) > 0.01:
        scale.x = absf(scale.x) * (1.0 if dir_x > 0.0 else -1.0)

func current_anim() -> String:
    return _cur

func current_pose() -> String:
    return pose_for(_cur, _t, _hell, _idle_pose, _speed)

func _process(delta: float) -> void:
    _t += delta
    _bob += delta
    var len: float = anim_length(_cur, _hell, _speed)
    if len > 0.0 and _t >= len:
        _cur = "idle"
        _t = 0.0
    _refresh()

func _refresh() -> void:
    _show(current_pose())

func _show(pose: String) -> void:
    var tex: Texture2D = pose_texture(pose)
    if tex == null:
        return
    if _spr.texture != tex:
        _spr.texture = tex
    var a: Vector2 = ANCHORS.get(pose, Vector2(tex.get_width() / 2.0, tex.get_height() / 2.0))
    var bob: float = sin(_bob * 2.4) * 2.5 if _cur == "idle" else 0.0   # flutua de leve quando parado
    _spr.position = Vector2(-a.x * SPRITE_SCALE, -a.y * SPRITE_SCALE + CHEST_Y + bob)
