class_name SkillFx
extends Sprite2D
## Efeitos desenhados das habilidades (assets/skills/<habilidade>/*.png, de art_source/skills/).
##   Chuva de Luz: cada projétil CAI do céu (fall_0..3), clareia no chão (flash) e abre o anel de impacto (impact_0..4).
##               O dano entra quando ele toca o chão (sinal `landed`).
##   Julgamento Divino: selo no alvo (judgment_00..03, segue o alvo), raio do céu (04..09; o dano entra no 1º quadro
##               do raio, sinal `landed`) e dissipar (10..13).
##   Asas da Redenção: asas de luz se abrem atrás do anjo (wings_0..6) + onda de cura (ring_0..4) do tamanho da área.
##   Fúria Celestial: explosão de fogo (burst_0..6) do tamanho da área + anel de fogo em volta do anjo
##               (aura_0..5 em laço) enquanto o buff durar.
##   Apocalipse Sagrado: selo de runas se abre no chão (seal_0..6); ao terminar (`finished`) sai a explosão
##               dourada (blast_0..5) e um pilar de luz (pillar_0..4) em cada inimigo.
##   A MORTE DO INFERNO: explosão de ativação (hell_0..8), anel de chamas e penas douradas saindo do anjo
##               até cobrir a tela (a maior de todas).
##   Escudo Sagrado: ativação (shield_00..05, cresce até o raio da explosão), escudo em volta do anjo
##               (shield_06..11 em laço enquanto houver absorção) e quebra (shield_12..15).
## As texturas são carregadas uma vez (cache estático).

signal landed(at: Vector2)
signal finished

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

# Julgamento Divino
const JUDGMENT_FRAMES := 14
const JUDGMENT_BEAM := 4          # 1º quadro do raio (o dano entra aqui)
const JUDGMENT_FPS := 14.0
const JUDGMENT_SCALE := 2.1
const JUDGMENT_RING_AT := Vector2(71.5, 73.0)   # centro do selo (quadros 0..3)
const JUDGMENT_BASE_AT := Vector2(71.5, 92.0)   # base do raio no chão (quadros 4..13)

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
var _follow: Node2D
var _landed_sent := false

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
        "divine_judgment":
            return tex(skill, "judgment_00") != null
        "swords_of_paradise":
            return tex(skill, "sword_00") != null
        "wings_of_redemption":
            return tex(skill, "wings_0") != null and tex(skill, "ring_0") != null
        "army_of_archangels":
            return tex(skill, "angel_00") != null
        "celestial_fury":
            return tex(skill, "burst_0") != null and tex(skill, "aura_0") != null
        "holy_apocalypse":
            return tex(skill, "seal_0") != null and tex(skill, "blast_0") != null and tex(skill, "pillar_0") != null
        "death_of_hell":
            return tex(skill, "burst_0") != null
    return false

func _make(skill: String) -> void:
    centered = true
    texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    set_meta("skill", skill)

func _set_frame(name: String) -> void:
    texture = tex(str(get_meta("skill")), name)
    if str(get_meta("skill")) == "divine_judgment":
        offset = -(JUDGMENT_RING_AT if int(name.right(2)) < JUDGMENT_BEAM else JUDGMENT_BASE_AT)

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

# ---------------------------------------------------------------- Julgamento Divino
## Selo sobre `target` (acompanha o alvo), raio do céu e dissipar. `landed` sai no 1º quadro do raio.
static func judgment(parent: Node, target: Node2D) -> SkillFx:
    var s := SkillFx.new()
    s._make("divine_judgment")
    s.centered = false
    s._follow = target
    s._mode = "judgment"
    s._fps = JUDGMENT_FPS
    s._seq = []
    for i in JUDGMENT_FRAMES:
        s._seq.append("judgment_%02d" % i)
    s.scale = Vector2(JUDGMENT_SCALE, JUDGMENT_SCALE)
    s.position = target.global_position
    s.z_index = 6
    s._set_frame(s._seq[0])
    parent.add_child(s)
    return s

# ---------------------------------------------------------------- Asas da Redenção
const WINGS_FRAMES := ["wings_0", "wings_1", "wings_2", "wings_3", "wings_4", "wings_5", "wings_6"]
const RING_FRAMES := ["ring_0", "ring_1", "ring_2", "ring_3", "ring_4"]
const RING_D := 165.0            # diâmetro do anel no quadro maior (px)

## Sequência simples de quadros que some no fim (presa ao `parent`, na posição `pos`).
static func play_once(parent: Node, skill: String, frames: Array, fps: float, pos: Vector2, sc: float, z: int) -> SkillFx:
    var s := SkillFx.new()
    s._make(skill)
    s._mode = "once"
    s._seq = frames
    s._fps = fps
    s._i = 0
    s.position = pos
    s.scale = Vector2(sc, sc)
    s.z_index = z
    s._set_frame(frames[0])
    parent.add_child(s)
    return s

## Asas atrás do anjo (acompanham ele) + onda de cura em volta, com o raio da área.
static func redemption(player: Node2D, radius: float) -> void:
    play_once(player, "wings_of_redemption", WINGS_FRAMES, 12.0, Vector2(0.0, -26.0), 0.95, -1)
    play_once(player, "wings_of_redemption", RING_FRAMES, 10.0, Vector2.ZERO, radius * 2.0 / RING_D, 1)

# ---------------------------------------------------------------- Fúria Celestial
const BURST_FRAMES := ["burst_0", "burst_1", "burst_2", "burst_3", "burst_4", "burst_5", "burst_6"]
const AURA_FRAMES := ["aura_0", "aura_1", "aura_2", "aura_3", "aura_4", "aura_5"]
const BURST_D := 180.0           # diâmetro do anel no quadro maior
const AURA_D := 190.0
const AURA_SCREEN_D := 135.0     # anel de fogo em volta do anjo

## Explosão do tamanho da área + anel de fogo em laço em volta do anjo enquanto `buffs` tiver a Fúria.
static func fury(player: Node2D, buffs: BuffState, radius: float) -> void:
    var b := play_once(player, "celestial_fury", BURST_FRAMES, 16.0, Vector2.ZERO, radius * 2.0 / BURST_D, 2)
    b.material = SpriteLib.additive()   # só soma luz (os últimos quadros são acinzentados e escureceriam a tela)
    var old := player.get_node_or_null("FuryAuraFx")
    if old != null:
        old.free()
    var a := SkillFx.new()
    a.name = "FuryAuraFx"
    a._make("celestial_fury")
    a._mode = "aura_loop"
    a._owner_buffs = buffs
    a._fps = 12.0
    var k: float = AURA_SCREEN_D / AURA_D
    a.scale = Vector2(k, k)
    a.position = Vector2(0.0, 6.0)
    a.z_index = -1
    a._set_frame(AURA_FRAMES[0])
    player.add_child(a)

# ---------------------------------------------------------------- A MORTE DO INFERNO
const HELL_FRAMES := ["burst_0", "burst_1", "burst_2", "burst_3", "burst_4", "burst_5", "burst_6", "burst_7", "burst_8"]
const HELL_D := 187.0            # diâmetro do anel no quadro maior (burst_6)
const HELL_SCREEN_D := 1050.0    # no auge cobre a tela inteira (1280x720)

## Explosão de ativação presa ao anjo (mistura normal: mantém o dourado/laranja da arte; com soma de luz estourava em branco).
static func hell_burst(player: Node2D) -> SkillFx:
    var b := play_once(player, "death_of_hell", HELL_FRAMES, 14.0, Vector2(0.0, -10.0), HELL_SCREEN_D / HELL_D, 2)
    return b

# ---------------------------------------------------------------- Apocalipse Sagrado
const SEAL_FRAMES := ["seal_0", "seal_1", "seal_2", "seal_3", "seal_4", "seal_5", "seal_6"]
const BLAST_FRAMES := ["blast_0", "blast_1", "blast_2", "blast_3", "blast_4", "blast_5"]
const PILLAR_FRAMES := ["pillar_0", "pillar_1", "pillar_2", "pillar_3", "pillar_4"]
const SEAL_SCREEN_D := 560.0
const SEAL_D := 205.0
const BLAST_SCREEN_D := 900.0
const BLAST_D := 190.0
const PILLAR_BASE := Vector2(128.0, 214.0)   # base do pilar no quadro
const PILLAR_SCALE := 1.25

## Selo sob o anjo; quando termina emite `finished` (aí entram a explosão, os pilares e o dano).
static func apocalypse_seal(player: Node2D) -> SkillFx:
    return play_once(player, "holy_apocalypse", SEAL_FRAMES, 18.0, Vector2(0.0, 8.0), SEAL_SCREEN_D / SEAL_D, -1)

static func apocalypse_blast(parent: Node, at: Vector2) -> void:
    var s := play_once(parent, "holy_apocalypse", BLAST_FRAMES, 14.0, at, BLAST_SCREEN_D / BLAST_D, 6)
    s.material = SpriteLib.additive()   # só soma luz (não escurece a tela no fim)

static func apocalypse_pillar(parent: Node, at: Vector2) -> SkillFx:
    var s := play_once(parent, "holy_apocalypse", PILLAR_FRAMES, 14.0, at + Vector2(0.0, 12.0), PILLAR_SCALE, 6)
    s.centered = false
    s.offset = -PILLAR_BASE
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
        "judgment":
            var f: int = int(_t * _fps)
            if f < JUDGMENT_BEAM and is_instance_valid(_follow):
                position = _follow.global_position + Vector2(0.0, 14.0)   # o selo fica sob os pés do alvo
            if f >= JUDGMENT_BEAM and not _landed_sent:
                _landed_sent = true
                landed.emit(position)
            if f >= _seq.size():
                queue_free()
                return
            if f != _i:
                _i = f
                _set_frame(_seq[f])
        "aura_loop":
            _set_frame(AURA_FRAMES[int(_t * _fps) % AURA_FRAMES.size()])
            rotation += delta * 0.6
            var on: bool = _owner_buffs != null and _owner_buffs.is_active("celestial_fury")
            modulate.a = minf(1.0, _t / 0.2) if on else modulate.a - delta * 4.0
            if not on and modulate.a <= 0.0:
                queue_free()
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
                    finished.emit()
                    queue_free()
                return
            _set_frame(_seq[f])
