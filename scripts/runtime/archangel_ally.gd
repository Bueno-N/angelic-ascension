class_name ArchangelAlly
extends Node2D
## Guerreiro celestial invocado: persegue o inimigo mais próximo e golpeia a cada `tick`.
## Arte nova (assets/skills/army_of_archangels/angel_00..15, olhando para a DIREITA):
##   surgir 00..03 (coluna de luz), parado 04..07 (laço), golpe 08..11, sumir 12..15.
## O dano entra no quadro do corte (10).

const APPEAR := [0, 1, 2, 3]
const IDLE := [4, 5, 6, 7]
const ATTACK := [8, 9, 10, 11]
const VANISH := [12, 13, 14, 15]
const HIT_FRAME := 2              # índice dentro de ATTACK (o corte)
const FPS := 10.0
const SCALE := 1.15               # quadro de 125 px -> ~144 px (guerreiro com ~85 px de altura)
const FEET := Vector2(62.5, 98.0) # pés no quadro

var id := ""
var atk := 0.0
var glow := 1.0
var duration := 5.0
var tick := 2.0
var _age := 0.0
var _cd := 0.0
var _spr: Node2D
var _art := false
var _anim := "appear"
var _at := 0.0
var _target: Variant = null
var _hit_done := false

func _ready() -> void:
    _art = SkillFx.has_art("army_of_archangels")
    if _art:
        var s := Sprite2D.new()
        s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
        s.centered = false
        s.offset = -FEET
        s.scale = Vector2(SCALE, SCALE)
        s.position = Vector2(0.0, 18.0)
        _spr = s
        _show(APPEAR[0])
    else:
        _spr = SpriteLib.make("ally", "walk", 2.0)
    add_child(_spr)

func _show(i: int) -> void:
    (_spr as Sprite2D).texture = SkillFx.tex("army_of_archangels", "angel_%02d" % i)

func _face(left: bool) -> void:
    if _art:
        _spr.scale.x = -SCALE if left else SCALE
    else:
        (_spr as AnimatedSprite2D).flip_h = left

## Quadro (0..15) para a animação e o tempo dela (lógica pura, testável).
static func frame_for(anim: String, t: float) -> int:
    var n := int(t * FPS)
    match anim:
        "appear":
            return APPEAR[mini(n, APPEAR.size() - 1)]
        "attack":
            return ATTACK[mini(n, ATTACK.size() - 1)]
        "vanish":
            return VANISH[mini(n, VANISH.size() - 1)]
    return IDLE[n % IDLE.size()]

func _process(delta: float) -> void:
    _age += delta
    _cd -= delta
    _at += delta
    var vanish_t: float = float(VANISH.size()) / FPS
    if _age >= duration - vanish_t and _anim != "vanish":
        _anim = "vanish"
        _at = 0.0
    if _anim == "vanish":
        if _art:
            _show(frame_for("vanish", _at))
        else:
            _spr.modulate.a = clampf((duration - _age) / 0.5, 0.0, 1.0)
        if _age >= duration:
            queue_free()
        return
    if _anim == "appear":
        if _art:
            _show(frame_for("appear", _at))
        if _at >= float(APPEAR.size()) / FPS:
            _anim = "idle"
            _at = 0.0
        return
    if _anim == "attack":
        if _art:
            _show(frame_for("attack", _at))
        if not _hit_done and int(_at * FPS) >= HIT_FRAME:
            _hit_done = true
            if is_instance_valid(_target):   # o alvo pode ter morrido durante o golpe
                _strike(_target)
        if _at >= float(ATTACK.size()) / FPS:
            _anim = "idle"
            _at = 0.0
        return
    # parado / perseguindo o inimigo mais próximo
    var best: Node2D = null
    var best_d := INF
    for e in get_tree().get_nodes_in_group("enemies"):
        if is_instance_valid(e) and e.hp > 0.0 and e.modulate.a >= 0.5:
            var d: float = e.global_position.distance_to(global_position)
            if d < best_d:
                best_d = d
                best = e
    if _art:
        _show(frame_for("idle", _at))
    if best != null:
        var to_t: Vector2 = best.global_position - global_position
        var reach: float = 34.0 + float(best.radius)
        _face(to_t.x < 0.0)
        if best_d > reach:
            global_position += to_t / maxf(best_d, 0.001) * 420.0 * delta
        elif _cd <= 0.0:
            _cd = tick
            if _art:
                _anim = "attack"
                _at = 0.0
                _target = best
                _hit_done = false
            else:
                _strike(best)

func _strike(t: Variant) -> void:
    if t == null or not is_instance_valid(t) or t.hp <= 0.0:
        return
    SkillCaster.deal_damage(t, id, atk, glow)
    AudioHub.play("ally_strike", 1.0, 0.1)
    var parent := get_parent()
    if parent != null:
        SpriteFx.spawn(parent, "fx_hit", t.global_position, 2.0, Color(1.0, 0.9, 0.5))
