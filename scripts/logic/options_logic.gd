class_name OptionsLogic
extends RefCounted
## Opções do jogo (lógica pura): volume, gráficos alto/baixo e regra de pausa.
## Ações do menu: "opt|fx|0" (alterna efeitos) e "opt|vol|+10" / "opt|vol|-10" (volume em passos).

const VOLUME_STEP := 10
const DEFAULT_VOLUME := 80
const DEFAULT_MUSIC_VOL := 60      # a música fica um pouco abaixo dos efeitos por padrão
const DEFAULT_SFX_VOL := 100
## Opções que valem para o aparelho inteiro (qualquer jogo salvo): ficam em settings.json.
const GLOBAL_KEYS := ["volume", "low_fx", "music_on", "music_vol", "sfx_vol"]

static func volume(settings: Dictionary) -> int:
    return clampi(SaveData.as_int(settings.get("volume", DEFAULT_VOLUME), DEFAULT_VOLUME), 0, 100)

static func volume_linear(settings: Dictionary) -> float:
    return float(volume(settings)) / 100.0

## Volume do barramento principal em dB (mudo = -80).
static func volume_db(settings: Dictionary) -> float:
    var v: float = volume_linear(settings)
    return -80.0 if v <= 0.0 else linear_to_db(v)

static func _vol(settings: Dictionary, key: String, default: int) -> int:
    return clampi(SaveData.as_int(settings.get(key, default), default), 0, 100)

static func _db(v: int) -> float:
    return -80.0 if v <= 0 else linear_to_db(float(v) / 100.0)

static func music_enabled(settings: Dictionary) -> bool:
    return SaveData.as_bool(settings.get("music_on", true), true) and music_vol(settings) > 0

static func music_on(settings: Dictionary) -> bool:
    return SaveData.as_bool(settings.get("music_on", true), true)

static func music_vol(settings: Dictionary) -> int:
    return _vol(settings, "music_vol", DEFAULT_MUSIC_VOL)

static func sfx_vol(settings: Dictionary) -> int:
    return _vol(settings, "sfx_vol", DEFAULT_SFX_VOL)

static func music_db(settings: Dictionary) -> float:
    return _db(music_vol(settings))

static func sfx_db(settings: Dictionary) -> float:
    return _db(sfx_vol(settings))

static func step_volume(settings: Dictionary, delta: int) -> int:
    return clampi(volume(settings) + delta, 0, 100)

static func gfx_label(settings: Dictionary) -> String:
    return "Efeitos: Alto" if UiLogic.fx_enabled(settings) else "Efeitos: Baixo"

## O jogo fica em pausa com o PERFIL (ícone do jogador), o MAPA das fases (tela cheia) ou a tela de MORTE abertos.
## O menu NÃO pausa.
static func should_pause(profile_open: bool, dead: bool = false, map_open: bool = false) -> bool:
    return profile_open or dead or map_open

## Aplica uma ação "opt|..." nas configurações. Devolve true se algo mudou.
static func apply(settings: Dictionary, parts: PackedStringArray) -> bool:
    if parts.size() < 2:
        return false
    match parts[1]:
        "fx":
            settings["low_fx"] = UiLogic.fx_enabled(settings)
            return true
        "vol":
            if parts.size() < 3:
                return false
            var nv: int = step_volume(settings, int(parts[2]))
            var changed: bool = nv != volume(settings)
            settings["volume"] = nv
            return changed
        "music":
            settings["music_on"] = not music_on(settings)
            return true
        "mvol":
            return _step_key(settings, "music_vol", DEFAULT_MUSIC_VOL, parts)
        "svol":
            return _step_key(settings, "sfx_vol", DEFAULT_SFX_VOL, parts)
    return false

static func _step_key(settings: Dictionary, key: String, default: int, parts: PackedStringArray) -> bool:
    if parts.size() < 3:
        return false
    var cur: int = _vol(settings, key, default)
    var nv: int = clampi(cur + int(parts[2]), 0, 100)
    settings[key] = nv
    return nv != cur

## Configurações do aparelho (valem para qualquer jogo salvo): volume geral, gráficos, música e efeitos sonoros.
static func default_global() -> Dictionary:
    return {"volume": DEFAULT_VOLUME, "low_fx": false, "music_on": true, "music_vol": DEFAULT_MUSIC_VOL, "sfx_vol": DEFAULT_SFX_VOL}

static func sanitize_global(raw: Dictionary) -> Dictionary:
    return {"volume": _vol(raw, "volume", DEFAULT_VOLUME),
        "low_fx": SaveData.as_bool(raw.get("low_fx", false), false),
        "music_on": SaveData.as_bool(raw.get("music_on", true), true),
        "music_vol": _vol(raw, "music_vol", DEFAULT_MUSIC_VOL),
        "sfx_vol": _vol(raw, "sfx_vol", DEFAULT_SFX_VOL)}

## Copia as opções do aparelho para um dicionário de configurações (jogo carregado).
static func copy_globals(src: Dictionary, dst: Dictionary) -> void:
    var g := sanitize_global(src)
    for k in GLOBAL_KEYS:
        dst[k] = g[k]
