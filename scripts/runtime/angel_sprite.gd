class_name AngelSprite
extends Node2D
## Anjo com a arte nova (assets/angel/*.png, recortada de art_source/angel_v2_b.webp): um quadro por imagem.
## Todos os quadros ficam alinhados pelo ROSTO do capuz (ANCHORS), então trocar de quadro não faz o anjo "pular".
##
## Parado = idle_0..6 em laço (asas batendo); andando = fly_1..4 em laço (voo inclinado com rastro de luz);
## ataque = atk_release -> atk_follow (o disparo é um AngelShot); conjuração = atk_charge -> surge_0.
## Brilho das asas (glow_tier): um contorno dourado aditivo atrás do anjo, mais forte a cada tier.
## A MORTE DO INFERNO (set_hell) NÃO muda o corpo: o anjo continua igual e só o disparo muda
## (a esfera de poder, AngelShot.sphere, no lugar do cometa — escolhido pelo Player).
## A arte é fixa: o nível das asas e os equipamentos não mudam o desenho (continuam valendo nos atributos).

const DIR := "res://assets/angel/"
const SPRITE_SCALE := 0.9          # quadros com ~135 px de altura -> ~122 px na tela
const CHEST_Y := -18.0             # onde o rosto fica em relação à posição do nó (o corpo fica centrado no nó)
## Centro do rosto em cada imagem (gerado pelo recorte; ver art_source/README.md).
const ANCHORS := {
    "idle_0": Vector2(65.3, 48.2), "idle_1": Vector2(77.8, 46.7), "idle_2": Vector2(68.0, 42.3),
    "idle_3": Vector2(71.6, 39.0), "idle_4": Vector2(71.6, 38.7), "idle_5": Vector2(68.9, 36.1), "idle_6": Vector2(72.8, 39.3),
    "atk_charge": Vector2(76.8, 50.0), "atk_release": Vector2(75.5, 48.6), "atk_follow": Vector2(68.4, 52.8),
    "surge_0": Vector2(73.8, 51.5),
    "fly_1": Vector2(80.4, 55.2), "fly_2": Vector2(96.8, 58.3), "fly_3": Vector2(93.4, 54.3), "fly_4": Vector2(96.4, 60.1),
}
## Mão de onde sai o disparo (pixels da imagem), nas poses de ataque.
const HANDS := {
    "atk_release": Vector2(117.0, 59.0),
    "atk_follow": Vector2(109.0, 54.0),
}
const IDLE_FRAMES := ["idle_0", "idle_1", "idle_2", "idle_3", "idle_4", "idle_5", "idle_6"]
const IDLE_FPS := 7.0
const FLY_FRAMES := ["fly_1", "fly_2", "fly_3", "fly_4"]
const FLY_FPS := 10.0
const ATTACK_FRAME := 0.11         # segundos por quadro do ataque (dividido pela velocidade)
const CAST_TIME := 0.45

static var _tex: Dictionary = {}

var _glow: Sprite2D                # contorno dourado (brilho das asas / poder)
var _spr: Sprite2D
var _cur := "idle"
var _glow_tier := 0
var _hell := false
var _moving := false
var _speed := 1.0
var _t := 0.0                      # tempo na animação atual
var _clock := 0.0                  # relógio contínuo (laço do idle, flutuar, pulsar)

## Estágio das asas (0..3) a partir do nível (0..10). Mantido para a lógica/testes (a arte não muda com ele).
static func wings_stage(level: int) -> int:
    return clampi(floori(float(level) / 3.0), 0, 3)

static func pose_texture(pose: String) -> Texture2D:
    if not _tex.has(pose):
        var path: String = DIR + pose + ".png"
        _tex[pose] = load(path) if ResourceLoader.exists(path) else null
    return _tex[pose]

## Intensidade (0..1) do contorno dourado para o brilho das asas.
static func glow_alpha(glow_tier: int) -> float:
    return 0.0 if glow_tier <= 0 else minf(0.75, 0.2 + 0.09 * float(glow_tier))

## Quadro mostrado para uma animação/tempo (lógica pura, testável).
## `clock` é o relógio contínuo (laços do idle e do voo). A Morte do Inferno não muda o corpo.
static func pose_for(anim: String, t: float, moving: bool, speed: float, clock: float = 0.0) -> String:
    var fdur: float = ATTACK_FRAME / clampf(speed, 0.8, 3.0)
    match anim:
        "attack":
            return "atk_release" if t < fdur else "atk_follow"
        "cast":
            return "atk_charge" if t < CAST_TIME * 0.45 else "surge_0"
    if moving:
        return FLY_FRAMES[int(clock * FLY_FPS) % FLY_FRAMES.size()]
    return IDLE_FRAMES[int(clock * IDLE_FPS) % IDLE_FRAMES.size()]

## Duração de uma animação que volta sozinha para o idle (0 = em laço).
static func anim_length(anim: String, speed: float) -> float:
    var fdur: float = ATTACK_FRAME / clampf(speed, 0.8, 3.0)
    match anim:
        "attack":
            return fdur * 2.0
        "cast":
            return CAST_TIME
    return 0.0

func _init() -> void:
    _glow = _make_layer()
    _glow.material = SpriteLib.additive()
    _glow.visible = false
    _spr = _make_layer()
    _show(current_pose())

func _make_layer() -> Sprite2D:
    var s := Sprite2D.new()
    s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    s.centered = false
    s.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
    add_child(s)
    return s

func set_look(_wings_level: int, glow_tier: int, _equipped: Dictionary) -> void:
    _glow_tier = glow_tier
    _refresh()

## Marca A MORTE DO INFERNO ativa (o Player troca o disparo pela esfera de poder; o corpo não muda).
func set_hell(on: bool) -> void:
    _hell = on

func is_hell() -> bool:
    return _hell

## Andando: usa os quadros de voo.
func set_moving(on: bool) -> void:
    if on != _moving:
        _moving = on
        _refresh()

func is_moving() -> bool:
    return _moving

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

## Ponto da mão (coordenadas locais deste nó, já com o espelhamento do face()) no 1º quadro do ataque.
func hand_local() -> Vector2:
    var pose := "atk_release"
    var h: Vector2 = HANDS[pose]
    var a: Vector2 = ANCHORS[pose]
    return Vector2((h.x - a.x) * SPRITE_SCALE, (h.y - a.y) * SPRITE_SCALE + CHEST_Y)

func current_pose() -> String:
    return pose_for(_cur, _t, _moving, _speed, _clock)

func _process(delta: float) -> void:
    _t += delta
    _clock += delta
    var len: float = anim_length(_cur, _speed)
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
    var a: Vector2 = ANCHORS.get(pose, Vector2(tex.get_width() / 2.0, tex.get_height() / 2.0))
    var bob: float = sin(_clock * 2.4) * 2.5 if _cur == "idle" and not _moving else 0.0   # flutua de leve quando parado
    var pos := Vector2(0.0, CHEST_Y + bob)
    for s in [_spr, _glow]:
        if s.texture != tex:
            s.texture = tex
        s.offset = -a
        s.position = pos
    # contorno dourado: brilho das asas
    var ga: float = glow_alpha(_glow_tier)
    var gs: float = 1.06
    _glow.visible = ga > 0.0
    _glow.modulate = Color(1.0, 0.85, 0.45, ga)
    _glow.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE) * gs
