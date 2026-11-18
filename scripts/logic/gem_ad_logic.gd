class_name GemAdLogic
extends RefCounted
## Gemas por anúncio premiado (botão redondo ao lado do MENU): LÓGICA PURA, sem relógio nem autoloads.
## Regras: o PRIMEIRO anúncio do dia dá 500 gemas e está liberado assim que o dia começa (meia-noite no fuso do aparelho);
## depois dele, um anúncio a cada 30 minutos, 100 gemas cada. O "dia" é o número de dias desde 1970 no horário local.

const FIRST_REWARD := 500
const REPEAT_REWARD := 100
const COOLDOWN_SECONDS := 30 * 60
const DAY_SECONDS := 86400

## Estado salvo em state["ad_gems"]: day = dia do último anúncio assistido; last = unix desse anúncio.
static func default_state() -> Dictionary:
    return {"day": -1, "last": 0}

static func _int(v: Variant, default: int) -> int:
    if v is int:
        return v
    if v is float and is_finite(v):
        return int(v)
    return default

static func sanitize(raw: Variant) -> Dictionary:
    var s := default_state()
    if raw is Dictionary:
        s["day"] = maxi(-1, _int(raw.get("day", -1), -1))
        s["last"] = maxi(0, _int(raw.get("last", 0), 0))
    return s

## Dia local: bias_minutes = Time.get_time_zone_from_system()["bias"] (ex.: -180 no horário de Brasília).
static func day_id(unix: int, bias_minutes: int) -> int:
    return floori(float(unix + bias_minutes * 60) / float(DAY_SECONDS))

static func is_first_of_day(s: Dictionary, day: int) -> bool:
    return int(s["day"]) != day

## Gemas que o PRÓXIMO anúncio vai dar.
static func next_reward(s: Dictionary, day: int) -> int:
    return FIRST_REWARD if is_first_of_day(s, day) else REPEAT_REWARD

## Segundos até liberar o próximo anúncio (0 = liberado). O primeiro do dia nunca espera.
## Relógio voltado para trás (now < last): espera no máximo os 30 min, nunca mais que isso.
static func seconds_left(s: Dictionary, now: int, day: int) -> int:
    if is_first_of_day(s, day):
        return 0
    var elapsed: int = now - int(s["last"])
    if elapsed < 0:
        return COOLDOWN_SECONDS
    return maxi(0, COOLDOWN_SECONDS - elapsed)

static func is_available(s: Dictionary, now: int, day: int) -> bool:
    return seconds_left(s, now, day) == 0

## Registra o anúncio assistido e devolve as gemas ganhas (0 se ainda não estava liberado).
static func claim(s: Dictionary, now: int, day: int) -> int:
    if not is_available(s, now, day):
        return 0
    var gems: int = next_reward(s, day)
    s["day"] = day
    s["last"] = now
    return gems

## Relógio que voltou para trás: traz o "last" para agora, para a espera não ficar travada além dos 30 min.
static func fix_clock(s: Dictionary, now: int) -> void:
    if int(s["last"]) > now:
        s["last"] = now

## "29:59" para o contador do botão.
static func format_left(secs: int) -> String:
    secs = maxi(0, secs)
    return "%d:%02d" % [secs / 60, secs % 60]
