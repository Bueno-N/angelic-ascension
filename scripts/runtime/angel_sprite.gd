class_name AngelSprite
extends Node2D
## Anjo animado em CAMADAS alinhadas: asas (4 estágios) / corpo / botas / armadura / luvas / espada.
## As camadas de equipamento são claras e TINGIDAS pela cor do tier. Animações: idle, attack, cast.

const SCALE := 2.0
const LAYERS := ["wings", "body", "boots", "armor", "gloves", "sword"]
const EQUIP_LAYERS := ["boots", "armor", "gloves", "sword"]   # nomes = categorias de equipamento
var _layers := {}
var _wings_stage := -1
var _cur := "idle"

## Estágio das asas (0..3) a partir do nível (0..10).
static func wings_stage(level: int) -> int:
    return clampi(floori(float(level) / 3.0), 0, 3)

func _init() -> void:
    for n in LAYERS:
        var s := AnimatedSprite2D.new()
        s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        s.scale = Vector2(SCALE, SCALE)
        add_child(s)
        _layers[n] = s
    for n in ["body", "boots", "armor", "gloves", "sword"]:
        _layers[n].sprite_frames = SpriteLib.frames("angel_" + n)
    _layers["body"].animation_finished.connect(_on_finished)
    set_look(0, 0, {})
    play_anim("idle")

func set_look(wings_level: int, glow_tier: int, equipped: Dictionary) -> void:
    var st: int = wings_stage(wings_level)
    var w: AnimatedSprite2D = _layers["wings"]
    if st != _wings_stage:
        _wings_stage = st
        w.sprite_frames = SpriteLib.frames("angel_wings_%d" % st)
        _play_layer(w, _cur)
        w.frame = _layers["body"].frame
    w.modulate = Color(1, 1, 1).lerp(Color(1.0, 0.93, 0.62), clampf(float(glow_tier) / 6.0, 0.0, 1.0) * 0.75)
    for cat in EQUIP_LAYERS:
        var tier: int = int(equipped.get(cat, 0))
        if cat == "sword":
            _layers[cat].visible = true   # o anjo sempre empunha uma espada: aço no tier 0, cor do tier depois
            _layers[cat].modulate = AngelDraw.tier_color(tier) if tier > 0 else Color(0.78, 0.85, 1.0)
        else:
            _layers[cat].visible = tier > 0
            if tier > 0:
                _layers[cat].modulate = AngelDraw.tier_color(tier)

func _play_layer(layer: AnimatedSprite2D, anim: String) -> void:
    if layer.sprite_frames != null and layer.sprite_frames.has_animation(anim):
        layer.play(anim)

func play_anim(anim: String) -> void:
    _cur = anim
    for n in LAYERS:
        _play_layer(_layers[n], anim)

func attack() -> void:
    play_anim("attack")

func cast() -> void:
    play_anim("cast")

## Velocidade das animações (acompanha a velocidade de ataque).
func set_speed(s: float) -> void:
    for n in LAYERS:
        _layers[n].speed_scale = clampf(s, 0.8, 3.0)

## Olha para a direita (dir_x >= 0) ou esquerda.
func face(dir_x: float) -> void:
    if absf(dir_x) > 0.01:
        scale.x = 1.0 if dir_x > 0.0 else -1.0

func current_anim() -> String:
    return _cur

func _on_finished() -> void:
    if _cur != "idle":
        play_anim("idle")
