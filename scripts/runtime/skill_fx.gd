class_name SkillFx
extends Sprite2D
## Efeitos desenhados das habilidades (assets/skills/<habilidade>/*.png, de art_source/skills/).
##   Chuva de Luz: cada projétil CAI do céu (fall_0..3), clareia no chão (flash) e abre o anel de impacto (impact_0..4).
##               O dano entra quando ele toca o chão (sinal `landed`).
##   Escudo Sagrado: ativação (shield_00..05, cresce até o raio da explosão), escudo em volta do anjo
##               (shield_06..11 em laço enquanto houver absorção) e quebra (shield_12..15).
## As texturas são carregadas uma vez (cache estático).

signal landed(at: Vector2)

const DIR := "res://assets/skills/"
# Chuva de Luz
const FALL_FRAMES := ["fall_0", "fall_1", "fall_2", "fall_3"]
const IMPACT_FRAMES := ["impact_0", "impact_1", "impact_2", "impact_3", "impact_4"]
const FALL_FROM := Vector2(0.0, -300.0)  # de onde o projétil cai (acima do alvo)
const FALL_TIME := 0.18
const FLASH_TIME := 0.06
const IMPACT_FPS := 14.0
const IMPACT_CENTER := Vector2(120.0, 111.0)   # centro do anel no quadro de impacto (px do quadro)
const IMPACT_RING_R := 84.0                     # raio do anel no quadro, sem escala (~ raio do dano de 80)
# Escudo Sagrado
const SHIELD_OPEN := ["shield_00", "shield_01", "shield_02", "shield_03", "shield_04", "shield_05"]
const SHIELD_LOOP := ["shield_06", "shield_07", "shield_08", "shield_09", "shield_10", "shield_11"]
const SHIELD_BREAK := ["shield_12", "shield_13", "shield_14", "shield_15"]
const SHIELD_RING_D := 250.0     # diâmetro do anel no quadro (px)
const SHIELD_AROUND_R := 78.0    # raio do escudo em volta do anjo

static var _tex: Dictionary = {}

var _seq: Array = []
var _fps := 12.0
var _t := 0.0
var _i := 0
var _mode := ""                  # "rain_fall", "rain_impact", "shield_open", "shield_loop", "shield_break", "once"
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _owner_buffs: BuffState
var _loop_scale := 1.0

static func tex(skill: String, name: String) -> Texture2D:
    var p := DIR + skill + "/" + name + ".png"
    if not _tex.has(p):
        _tex[p] = load(p) if ResourceLoader.exists(p) else null
    return _tex[p]

static func has_art(skill: String) -> bool:
    match skill:
        "rain_of_light":
            return tex(skill, "fall_0") != null and tex(skill, "impact_0") != null
        "holy_shield":
            return tex(skill, "shield_00") != null
    return false

func _make(skill: String) -> void:
    centered = true
    texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    set_meta("skill", skill)

func _set_frame(name: String) -> void:
    texture = tex(str(get_meta("skill")), name)

# ---------------------------------------------------------------- Chuva de Luz
## Projétil que cai em `at` (coordenadas do `parent`); emite `landed` ao tocar o chão.
static func rain_drop(parent: Node, at: Vector2, scale_k: float = 0.6) -> SkillFx:
    var s := SkillFx.new()
    s._make("rain_of_light")
    s._mode = "rain_fall"
    s._from = at + FALL_FROM
    s._to = at
    s.position = s._from
    s.centered = false
    s._set_frame(FALL_FRAMES[0])
    var t := s.texture
    s.offset = Vector2(-t.get_width() / 2.0, -t.get_height()) if t != null else Vector2.ZERO   # ponta embaixo
    s.scale = Vector2(scale_k, scale_k) / 0.6
    s.z_index = 6
    parent.add_child(s)
    return s

# ---------------------------------------------------------------- Escudo Sagrado
## Ativação + escudo em laço em volta do anjo enquanto `buffs.absorb() > 0` + quebra. `blast_r` = raio da explosão.
static func shield(player: Node2D, buffs: BuffState, blast_r: float) -> SkillFx:
    var old := player.get_node_or_null("HolyShieldFx")
    if old != null:
        old.free()
    var s := SkillFx.new()
    s.name = "HolyShieldFx"
    s._make("holy_shield")
    s._owner_buffs = buffs
    s._seq = SHIELD_OPEN
    s._fps = 18.0
    s._mode = "shield_open"
    var k: float = blast_r * 2.0 / SHIELD_RING_D
    s.scale = Vector2(k, k)
    s._loop_scale = SHIELD_AROUND_R * 2.0 / SHIELD_RING_D
    s.z_index = 2
    s._set_frame(SHIELD_OPEN[0])
    player.add_child(s)
    return s

func current_mode() -> String:
    return _mode

func _process(delta: float) -> void:
    _t += delta
    match _mode:
        "rain_fall":
            var k: float = clampf(_t / FALL_TIME, 0.0, 1.0)
            position = _from.lerp(_to, k)
            _set_frame(FALL_FRAMES[mini(int(k * FALL_FRAMES.size()), FALL_FRAMES.size() - 1)])
            if k >= 1.0:
                landed.emit(_to)
                _mode = "rain_flash"
                _t = 0.0
                centered = true
                offset = Vector2.ZERO
                _set_frame("flash")
        "rain_flash":
            if _t >= FLASH_TIME:
                _mode = "once"
                _t = 0.0
                _i = -1
                _seq = IMPACT_FRAMES
                _fps = IMPACT_FPS
                centered = false
                offset = -IMPACT_CENTER
        "shield_loop":
            var n: int = int(_t * _fps) % SHIELD_LOOP.size()
            _set_frame(SHIELD_LOOP[n])
            scale = scale.lerp(Vector2(_loop_scale, _loop_scale), minf(1.0, delta * 10.0))
            if _owner_buffs == null or _owner_buffs.absorb() <= 0.0:
                _mode = "once"
                _t = 0.0
                _i = -1
                _seq = SHIELD_BREAK
                _fps = 12.0
    if _mode == "once" or _mode == "shield_open":
        var f: int = int(_t * _fps)
        if f != _i:
            _i = f
            if f >= _seq.size():
                if _mode == "shield_open":
                    _mode = "shield_loop"
                    _t = 0.0
                else:
                    queue_free()
                return
            _set_frame(_seq[f])
