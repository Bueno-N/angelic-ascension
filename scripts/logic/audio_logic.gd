class_name AudioLogic
extends RefCounted
## Áudio (lógica pura + barramentos): qual música toca em cada fase, qual efeito vai com cada habilidade/inimigo,
## volumes e o limitador de repetição (50 mobs não podem virar uma parede de ruído).
## Os arquivos são gerados por tools/audio/generate_audio.py (data/audio_manifest.gd lista tudo).

const DIR := "res://assets/audio/"
const BUS_MUSIC := "Musica"
const BUS_SFX := "Efeitos"
const BOSS_TRACK := "music_boss"
const STAGE_TRACKS := ["music_1", "music_2", "music_3"]   # 2 dificuldades por trilha: Fácil+Normal, Difícil+Pesadelo, Infernal+Abismal
const TITLE_TRACK := "music_1"
const DEFAULT_GAIN_DB := -6.0

# Ganho (dB) de cada efeito. Os arquivos são normalizados no mesmo pico; aqui fica o equilíbrio entre eles.
const GAIN_DB := {
    "atk": -12.0, "hurt": -6.0, "die": -2.0, "stage_up": -9.0, "ui_click": -12.0, "ui_buy": -8.0, "mob_hit": -20.0,
    "sk_rain_hit": -16.0, "sk_celestial_lance": -6.0, "mob_shoot": -12.0, "mob_drain": -12.0, "warn": -10.0,
    "boss_roar": -2.0, "mini_roar": -4.0, "boss_die": -2.0, "mini_die": -4.0, "ally_strike": -16.0,
}
# Intervalo mínimo (s, tempo real) entre dois disparos do mesmo efeito.
const MIN_GAP := {
    "atk": 0.05, "hurt": 0.15, "mob_hit": 0.06, "sk_rain_hit": 0.05, "ally_strike": 0.12, "mob_shoot": 0.15,
    "mob_drain": 0.2, "warn": 0.5, "stage_up": 1.0, "ui_click": 0.04,
}
const MOB_GAP := 0.3        # ataque/morte de mobs comuns (por tipo)
const MOB_DIE_GAP := 0.06
const ABILITY_SFX := {
    "area_slam": "ab_area_slam", "charge": "ab_charge", "summon_demons": "ab_summon_demons",
    "hellfire_projectiles": "ab_hellfire_projectiles", "meteor_rain": "ab_meteor_rain", "flame_breath": "ab_flame_breath",
    "shadow_step": "ab_shadow_step", "soul_orbs": "ab_soul_orbs", "fire_bolt": "mob_shoot", "life_steal": "mob_drain",
}
const SPRITES := ["imp", "warrior", "shadow", "hound", "caster", "leech"]

# ---------------------------------------------------------------- música
## Trilha da fase: fase de CHEFE usa a trilha do chefe; as demais dependem da dificuldade (a cada 50 fases muda de degrau).
static func music_for(stage: int) -> String:
    if StageLogic.is_boss_stage(stage):
        return BOSS_TRACK
    var tier: int = StageLogic.tier_index(stage)
    return str(STAGE_TRACKS[clampi(floori(float(tier) / 2.0), 0, STAGE_TRACKS.size() - 1)])

static func all_tracks() -> Array:
    var out: Array = STAGE_TRACKS.duplicate()
    out.append(BOSS_TRACK)
    return out

static func track_path(track: String) -> String:
    return DIR + track + ".ogg"

# ---------------------------------------------------------------- efeitos
static func sfx_path(id: String) -> String:
    return DIR + "sfx_" + id + ".wav"

static func has_sfx(id: String) -> bool:
    return AudioManifest.SFX.has(id)

static func skill_sfx(skill_id: String) -> String:
    return "sk_" + skill_id

static func ability_sfx(ability_id: String) -> String:
    return str(ABILITY_SFX.get(ability_id, ""))

static func mob_atk_sfx(sprite: String) -> String:
    return "mob_%s_atk" % sprite if SPRITES.has(sprite) else "mob_imp_atk"

static func mob_die_sfx(sprite: String) -> String:
    return "mob_%s_die" % sprite if SPRITES.has(sprite) else "mob_imp_die"

## Som de morte de um inimigo (def vem do sinal Events.enemy_died). Invocações de chefe morrem quietas.
static func death_sfx(def: Dictionary, is_boss: bool) -> String:
    if is_boss:
        return "boss_die"
    if bool(def.get("summon", false)):
        return ""
    if bool(def.get("mini", false)):
        return "mini_die"
    return mob_die_sfx(str(def.get("sprite", "imp")))

static func gain_db(id: String) -> float:
    if GAIN_DB.has(id):
        return float(GAIN_DB[id])
    if id.begins_with("mob_"):
        return -12.0
    if id.begins_with("sk_") or id.begins_with("ab_"):
        return -4.0
    return DEFAULT_GAIN_DB

static func min_gap(id: String) -> float:
    if MIN_GAP.has(id):
        return float(MIN_GAP[id])
    if id.begins_with("mob_") and id.ends_with("_die"):
        return MOB_DIE_GAP
    if id.begins_with("mob_") and id.ends_with("_atk"):
        return MOB_GAP
    return 0.0

## 2 = nunca é cortado (habilidades, chefes, morte), 1 = normal, 0 = pode ser descartado se faltar voz.
static func priority(id: String) -> int:
    if id == "sk_rain_hit" or id == "ally_strike" or id.begins_with("mob_"):
        return 0
    if id.begins_with("sk_") or id.begins_with("ab_") or id.begins_with("boss_") or id == "die" or id == "mini_roar" or id == "mini_die":
        return 2
    return 1

## Limitador: devolve true (e registra o instante) se o efeito pode tocar agora.
static func allow(last: Dictionary, id: String, now: float) -> bool:
    var gap: float = min_gap(id)
    if gap > 0.0 and last.has(id) and now - float(last[id]) < gap:
        return false
    last[id] = now
    return true

## Escolha da voz a sacrificar quando todas estão ocupadas: a de menor prioridade (e a mais antiga). -1 = não toca.
## voices: [{"priority": int, "start": float}]
static func pick_voice(voices: Array, new_priority: int) -> int:
    var best := -1
    for i in range(voices.size()):
        var v: Dictionary = voices[i]
        if best < 0:
            best = i
            continue
        var b: Dictionary = voices[best]
        if int(v["priority"]) < int(b["priority"]) or (int(v["priority"]) == int(b["priority"]) and float(v["start"]) < float(b["start"])):
            best = i
    if best >= 0 and int(voices[best]["priority"]) > new_priority:
        return -1
    return best

# ---------------------------------------------------------------- barramentos (Master / Música / Efeitos)
static func ensure_bus(bus_name: String) -> int:
    var i: int = AudioServer.get_bus_index(bus_name)
    if i >= 0:
        return i
    AudioServer.add_bus()
    i = AudioServer.bus_count - 1
    AudioServer.set_bus_name(i, bus_name)
    AudioServer.set_bus_send(i, "Master")
    return i

## Aplica as opções de som: volume geral (Master), música (liga/desliga + volume) e efeitos (volume; 0 = sem efeitos).
static func apply_buses(settings: Dictionary) -> void:
    var master_db: float = OptionsLogic.volume_db(settings)
    AudioServer.set_bus_volume_db(0, master_db)
    AudioServer.set_bus_mute(0, master_db <= -80.0)
    var m := ensure_bus(BUS_MUSIC)
    var mdb: float = OptionsLogic.music_db(settings)
    AudioServer.set_bus_volume_db(m, maxf(mdb, -80.0))
    AudioServer.set_bus_mute(m, not OptionsLogic.music_enabled(settings))
    var s := ensure_bus(BUS_SFX)
    var sdb: float = OptionsLogic.sfx_db(settings)
    AudioServer.set_bus_volume_db(s, maxf(sdb, -80.0))
    AudioServer.set_bus_mute(s, sdb <= -80.0)
