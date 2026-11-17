class_name OptionsLogic
extends RefCounted
## Opções do jogo (lógica pura): volume, gráficos alto/baixo e regra de pausa.
## Ações do menu: "opt|fx|0" (alterna efeitos) e "opt|vol|+10" / "opt|vol|-10" (volume em passos).

const VOLUME_STEP := 10
const DEFAULT_VOLUME := 80

static func volume(settings: Dictionary) -> int:
    return clampi(SaveData.as_int(settings.get("volume", DEFAULT_VOLUME), DEFAULT_VOLUME), 0, 100)

static func volume_linear(settings: Dictionary) -> float:
    return float(volume(settings)) / 100.0

## Volume do barramento principal em dB (mudo = -80).
static func volume_db(settings: Dictionary) -> float:
    var v: float = volume_linear(settings)
    return -80.0 if v <= 0.0 else linear_to_db(v)

static func step_volume(settings: Dictionary, delta: int) -> int:
    return clampi(volume(settings) + delta, 0, 100)

static func gfx_label(settings: Dictionary) -> String:
    return "Efeitos: Alto" if UiLogic.fx_enabled(settings) else "Efeitos: Baixo"

## O jogo só fica em pausa com o PERFIL (ícone do jogador) aberto. O menu NÃO pausa.
static func should_pause(profile_open: bool) -> bool:
    return profile_open

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
    return false

## Configurações do aparelho (valem para qualquer jogo salvo): só volume e efeitos.
static func default_global() -> Dictionary:
    return {"volume": DEFAULT_VOLUME, "low_fx": false}

static func sanitize_global(raw: Dictionary) -> Dictionary:
    return {"volume": clampi(SaveData.as_int(raw.get("volume", DEFAULT_VOLUME), DEFAULT_VOLUME), 0, 100),
        "low_fx": SaveData.as_bool(raw.get("low_fx", false), false)}
