class_name AngelSprite
extends Node2D
## Anjo com a arte nova (assets/angel/*.png, recortada de art_source/angel_v2_b.webp): um quadro por imagem.
## Todos os quadros ficam alinhados pelo ROSTO do capuz (ANCHORS), então trocar de quadro não faz o anjo "pular".
##
## Normal:  parado = idle_0..6 em laço (asas batendo); andando = fly_1..4 em laço (voo inclinado com rastro de luz);
##          ataque = atk_release -> atk_follow (o disparo é um AngelShot); conjuração = atk_charge -> surge_0.
## Brilho das asas (glow_tier): um contorno dourado aditivo atrás do anjo, mais forte a cada tier.
## A MORTE DO INFERNO (set_hell): ao ligar, transformação do Power Surge (surge_0..3: brilho, esfera de luz, chamas)
##          e depois a FORMA DE PODER, animada (art_source/angel_power_*.jpg): parado = power_idle_0..4, andando =
##          power_fly_0..4, golpe = power_atk_1..4 (braço estendido), disparando o projétil de penas e luz (AngelShot.hell_shot) da mão.
##          Esses quadros foram desenhados maiores: POWER_SCALE iguala o tamanho do rosto aos demais.
## ASAS: até o nível 6 o anjo usa a versão com 2 asas (arquivos *_2w, de art_source/angel_v2_2wings.webp);
## a partir do nível 7 (WINGS_FULL_LEVEL) troca para as 4 asas. Equipamentos não mudam o desenho.

const DIR := "res://assets/angel/"
const SPRITE_SCALE := 0.9          # quadros com ~135 px de altura -> ~122 px na tela
const CHEST_Y := -18.0             # onde o rosto fica em relação à posição do nó (o corpo fica centrado no nó)
## Centro do rosto em cada imagem (gerado pelo recorte; ver art_source/README.md).
const ANCHORS := {
    "idle_0": Vector2(65.3, 48.2), "idle_1": Vector2(77.8, 46.7), "idle_2": Vector2(68.0, 42.3),
    "idle_3": Vector2(71.6, 39.0), "idle_4": Vector2(71.6, 38.7), "idle_5": Vector2(68.9, 36.1), "idle_6": Vector2(72.8, 39.3),
    "atk_charge": Vector2(76.8, 50.0), "atk_release": Vector2(75.5, 48.6), "atk_follow": Vector2(68.4, 52.8),
    "fly_1": Vector2(80.4, 55.2), "fly_2": Vector2(96.8, 58.3), "fly_3": Vector2(93.4, 54.3), "fly_4": Vector2(96.4, 60.1),
    "surge_0": Vector2(73.8, 51.5), "surge_1": Vector2(73.5, 53.7), "surge_2": Vector2(89.4, 73.2),
    "surge_3": Vector2(80.0, 64.0),
    "power_idle_0": Vector2(98.8, 90.4), "power_idle_1": Vector2(96.0, 90.5), "power_idle_2": Vector2(103.8, 89.5),
    "power_idle_3": Vector2(105.6, 91.2), "power_idle_4": Vector2(103.2, 91.4),
    "power_fly_0": Vector2(122.2, 90.3), "power_fly_1": Vector2(132.1, 94.2), "power_fly_2": Vector2(143.3, 87.4),
    "power_fly_3": Vector2(141.6, 89.0), "power_fly_4": Vector2(132.4, 85.2),
    "power_atk_1": Vector2(132.8, 93.9), "power_atk_2": Vector2(137.0, 96.0), "power_atk_3": Vector2(133.6, 97.5),
    "power_atk_4": Vector2(101.1, 99.7),
}
## De onde sai o disparo (pixels da imagem): a mão nas poses de ataque; na forma de poder, à frente do peito.
const HANDS := {
    "atk_release": Vector2(117.0, 59.0),
    "atk_follow": Vector2(109.0, 54.0),
    "surge_3": Vector2(118.0, 62.0),
    "power_atk_1": Vector2(165.0, 113.0),
}
## Versão com 2 asas (nível de asas < 7): centro do rosto e mão em cada imagem *_2w.
const WINGS_FULL_LEVEL := 7
const ANCHORS_2W := {
    "idle_0_2w": Vector2(64.3, 47.9), "idle_1_2w": Vector2(77.6, 46.7), "idle_2_2w": Vector2(67.8, 42.1),
    "idle_3_2w": Vector2(71.2, 37.6), "idle_4_2w": Vector2(70.6, 37.7), "idle_5_2w": Vector2(68.8, 35.6), "idle_6_2w": Vector2(73.7, 38.2),
    "atk_charge_2w": Vector2(76.2, 54.8), "atk_release_2w": Vector2(74.4, 48.5),
    "fly_1_2w": Vector2(80.7, 53.3), "fly_2_2w": Vector2(96.9, 58.2), "fly_3_2w": Vector2(93.6, 52.5), "fly_4_2w": Vector2(96.5, 56.3),
    "surge_0_2w": Vector2(73.8, 51.7), "surge_1_2w": Vector2(73.4, 56.6), "surge_2_2w": Vector2(89.5, 73.0),
    "surge_3_2w": Vector2(82.0, 66.0),
    "power_idle_0_2w": Vector2(98.8, 90.5), "power_idle_1_2w": Vector2(95.9, 91.7), "power_idle_2_2w": Vector2(103.9, 90.1),
    "power_idle_3_2w": Vector2(106.5, 91.2), "power_idle_4_2w": Vector2(103.0, 91.4),
    "power_fly_0_2w": Vector2(123.6, 90.5), "power_fly_1_2w": Vector2(132.1, 95.2), "power_fly_2_2w": Vector2(143.4, 87.5),
    "power_fly_3_2w": Vector2(141.6, 88.9), "power_fly_4_2w": Vector2(132.4, 85.2),
    "power_atk_1_2w": Vector2(149.8, 95.3), "power_atk_2_2w": Vector2(138.6, 96.8), "power_atk_3_2w": Vector2(133.9, 99.8),
    "power_atk_4_2w": Vector2(101.0, 99.8),
}
const HANDS_2W := {
    "atk_release_2w": Vector2(106.0, 60.0),
    "surge_3_2w": Vector2(115.0, 62.0),
    "power_atk_1_2w": Vector2(182.0, 114.4),
}
## Na folha de 2 asas o "acompanhar" do ataque não tem um quadro limpo: usa o de carregar (faísca na mão).
const ALIAS_2W := {"atk_follow": "atk_charge"}
const IDLE_FRAMES := ["idle_0", "idle_1", "idle_2", "idle_3", "idle_4", "idle_5", "idle_6"]
const IDLE_FPS := 7.0
const FLY_FRAMES := ["fly_1", "fly_2", "fly_3", "fly_4"]
const FLY_FPS := 10.0
const TRANSFORM_FRAMES := ["surge_0", "surge_1", "surge_2", "surge_3"]
const TRANSFORM_FRAME := 0.1       # segundos por quadro da transformação
const ATTACK_FRAME := 0.11         # segundos por quadro do ataque (dividido pela velocidade)
const HELL_ATTACK := ["power_atk_1", "power_atk_2", "power_atk_3", "power_atk_4"]   # golpe na forma de poder (um quadro por ATTACK_FRAME)
const POWER_IDLE := ["power_idle_0", "power_idle_1", "power_idle_2", "power_idle_3", "power_idle_4"]
const POWER_FLY := ["power_fly_0", "power_fly_1", "power_fly_2", "power_fly_3", "power_fly_4"]
const POWER_SCALE := 0.7           # quadros power_* desenhados maiores (rosto 26 px vs 18 px)
const CAST_TIME := 0.45

static var _tex: Dictionary = {}

var _glow: Sprite2D                # contorno dourado (brilho das asas / poder)
var _spr: Sprite2D
var _cur := "idle"
var _glow_tier := 0
var _two_wings := true             # começa com 2 asas; 4 asas a partir do nível 7
var _hell := false
var _moving := false
var _speed := 1.0
var _t := 0.0                      # tempo na animação atual
var _clock := 0.0                  # relógio contínuo (laços, flutuar, pulsar)

## Estágio das asas (0..3) a partir do nível (0..10). Mantido para a lógica/testes (a arte não muda com ele).
static func wings_stage(level: int) -> int:
    return clampi(floori(float(level) / 3.0), 0, 3)

## 2 asas até o nível 6; 4 asas a partir do 7.
static func uses_two_wings(wings_level: int) -> bool:
    return wings_level < WINGS_FULL_LEVEL

## Arquivo (sem .png) usado para uma pose, com ou sem a versão de 2 asas.
static func file_for(pose: String, two_wings: bool) -> String:
    return (ALIAS_2W.get(pose, pose) + "_2w") if two_wings else pose

## Escala de desenho de um arquivo (os power_* são desenhados maiores).
static func scale_of(file: String) -> float:
    return SPRITE_SCALE * (POWER_SCALE if file.begins_with("power_") else 1.0)

static func anchor_of(file: String) -> Vector2:
    return ANCHORS_2W[file] if ANCHORS_2W.has(file) else ANCHORS[file]

static func pose_texture(pose: String) -> Texture2D:
    if not _tex.has(pose):
        var path: String = DIR + pose + ".png"
        _tex[pose] = load(path) if ResourceLoader.exists(path) else null
    return _tex[pose]

## Intensidade (0..1) do contorno dourado para o brilho das asas.
static func glow_alpha(glow_tier: int) -> float:
    return 0.0 if glow_tier <= 0 else minf(0.75, 0.2 + 0.09 * float(glow_tier))

## Quadro mostrado para uma animação/tempo (lógica pura, testável). `clock` = relógio contínuo (laços).
static func pose_for(anim: String, t: float, hell: bool, moving: bool, speed: float, clock: float = 0.0) -> String:
    var fdur: float = ATTACK_FRAME / clampf(speed, 0.8, 3.0)
    if anim == "transform":
        return TRANSFORM_FRAMES[clampi(int(t / TRANSFORM_FRAME), 0, TRANSFORM_FRAMES.size() - 1)]
    if hell:
        if anim == "attack":
            return HELL_ATTACK[clampi(int(t / fdur), 0, HELL_ATTACK.size() - 1)]
        if moving and anim != "cast":
            return POWER_FLY[int(clock * FLY_FPS) % POWER_FLY.size()]
        return POWER_IDLE[int(clock * IDLE_FPS) % POWER_IDLE.size()]
    match anim:
        "attack":
            return "atk_release" if t < fdur else "atk_follow"
        "cast":
            return "atk_charge" if t < CAST_TIME * 0.45 else "surge_0"
    if moving:
        return FLY_FRAMES[int(clock * FLY_FPS) % FLY_FRAMES.size()]
    return IDLE_FRAMES[int(clock * IDLE_FPS) % IDLE_FRAMES.size()]

## Duração de uma animação que volta sozinha para o idle (0 = em laço).
static func anim_length(anim: String, hell: bool, speed: float) -> float:
    var fdur: float = ATTACK_FRAME / clampf(speed, 0.8, 3.0)
    match anim:
        "attack":
            return fdur * (float(HELL_ATTACK.size()) if hell else 2.0)
        "cast":
            return CAST_TIME
        "transform":
            return TRANSFORM_FRAME * float(TRANSFORM_FRAMES.size())
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

func set_look(wings_level: int, glow_tier: int, _equipped: Dictionary) -> void:
    _glow_tier = glow_tier
    _two_wings = uses_two_wings(wings_level)
    _refresh()

## Liga/desliga A MORTE DO INFERNO: ao ligar, toca a transformação do Power Surge e um redemoinho de luz.
func set_hell(on: bool) -> void:
    if on == _hell:
        return
    _hell = on
    if on:
        play_anim("transform")
        AngelShot.burst(self, Vector2(0.0, CHEST_Y + 14.0))
    elif _cur == "transform" or _cur == "attack" or _cur == "cast":
        play_anim("idle")
    _refresh()

func is_hell() -> bool:
    return _hell

## Andando: usa os quadros de voo (fora da Morte do Inferno).
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
    if _cur == "transform":
        return                     # não corta a transformação (o disparo sai do mesmo jeito)
    play_anim("attack")

func cast() -> void:
    if _cur == "transform":
        return
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

## Ponto de onde sai o disparo (coordenadas locais deste nó, já com o espelhamento do face()).
func hand_local() -> Vector2:
    var file: String = file_for("power_atk_1" if _hell else "atk_release", _two_wings)
    var h: Vector2 = HANDS_2W[file] if _two_wings else HANDS[file]
    var a: Vector2 = anchor_of(file)
    var k: float = scale_of(file)
    return Vector2((h.x - a.x) * k, (h.y - a.y) * k + CHEST_Y)

func has_two_wings() -> bool:
    return _two_wings

## Arquivo realmente mostrado agora (pose + versão de asas).
func current_file() -> String:
    return file_for(current_pose(), _two_wings)

func current_pose() -> String:
    return pose_for(_cur, _t, _hell, _moving, _speed, _clock)

func _process(delta: float) -> void:
    _t += delta
    _clock += delta
    var len: float = anim_length(_cur, _hell, _speed)
    if len > 0.0 and _t >= len:
        _cur = "idle"
        _t = 0.0
    _refresh()

func _refresh() -> void:
    _show(current_pose())

func _show(pose: String) -> void:
    var file: String = file_for(pose, _two_wings)
    var tex: Texture2D = pose_texture(file)
    if tex == null:
        return
    var a: Vector2 = anchor_of(file)
    var k: float = scale_of(file)
    var floating: bool = _cur == "idle" and not _moving
    var bob: float = sin(_clock * 2.4) * 2.5 if floating else 0.0   # flutua de leve quando parado
    var pos := Vector2(0.0, CHEST_Y + bob)
    for s in [_spr, _glow]:
        if s.texture != tex:
            s.texture = tex
        s.offset = -a
        s.position = pos
    _spr.scale = Vector2(k, k)
    # contorno dourado: brilho das asas; na forma de poder pulsa, e dá um clarão a cada golpe
    var ga: float = glow_alpha(_glow_tier)
    var gs: float = 1.06
    if _hell:
        ga = 0.4 + 0.15 * sin(_clock * 6.0)
        gs = 1.07 + 0.02 * sin(_clock * 6.0)
        if _cur == "attack":
            var f: float = 1.0 - clampf(_t / anim_length("attack", true, _speed), 0.0, 1.0)
            ga += 0.45 * f
            gs += 0.05 * f
    _glow.visible = ga > 0.0
    _glow.modulate = Color(1.0, 0.85, 0.45, minf(1.0, ga))
    _glow.scale = Vector2(k, k) * gs
