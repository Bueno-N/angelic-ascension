class_name WeeklyBoss
extends RefCounted
## Boss semanal (Lucifer): LÓGICA PURA (não usa autoloads; testável). Semana, entradas, pontuação, recompensas por posição.
## A semana começa na SEGUNDA 00:00 UTC (a época Unix, 1970-01-01, foi uma quinta: segunda = +4 dias).
## Estado por conta em state["weekly"]: {pid, week, entries, best, prev_week, prev_best, claimed}.

const WEEK_SECONDS := 604800
const MONDAY_OFFSET := 4 * 86400

# Recompensas por posição no ranking mundial da semana ANTERIOR (valores são PALPITE; ver docs/ONLINE.md).
# Faixas por posição absoluta, depois por percentil, depois participação.
const REWARD_RANKS := [
    {"max_rank": 1, "gems": 600, "shards": 25, "label": "1O LUGAR"},
    {"max_rank": 2, "gems": 400, "shards": 18, "label": "2O LUGAR"},
    {"max_rank": 3, "gems": 300, "shards": 14, "label": "3O LUGAR"},
    {"max_rank": 10, "gems": 180, "shards": 8, "label": "TOP 10"},
    {"max_rank": 50, "gems": 100, "shards": 4, "label": "TOP 50"},
    {"max_rank": 100, "gems": 70, "shards": 3, "label": "TOP 100"},
    {"max_rank": 500, "gems": 40, "shards": 2, "label": "TOP 500"},
]
const REWARD_PERCENTILES := [
    {"max_pct": 0.10, "gems": 30, "shards": 1, "label": "TOP 10%"},
    {"max_pct": 0.50, "gems": 20, "shards": 0, "label": "TOP 50%"},
]
const REWARD_PARTICIPATION := {"gems": 10, "shards": 0, "label": "PARTICIPACAO"}

# ---------------------------------------------------------------- semana
static func week_id(unix: int) -> int:
    return floori(float(unix - MONDAY_OFFSET) / float(WEEK_SECONDS))

## Segundos até a próxima segunda 00:00 UTC.
static func seconds_left(unix: int) -> int:
    var next_start: int = (week_id(unix) + 1) * WEEK_SECONDS + MONDAY_OFFSET
    return next_start - unix

static func is_unlocked(max_stage: int) -> bool:
    return max_stage > Balance.WEEKLY_UNLOCK_STAGE    # "ao concluir a fase 50": o recorde passou da 50

# ---------------------------------------------------------------- estado salvo
static func default_weekly() -> Dictionary:
    return {"pid": "", "week": 0, "entries": 0, "best": 0.0, "prev_week": 0, "prev_best": 0.0, "claimed": 0}

static func _int(v: Variant) -> int:
    if v is int:
        return v
    if v is float and is_finite(v):
        return int(v)
    return 0

static func _num(v: Variant) -> float:
    if (v is int or v is float) and is_finite(float(v)):
        return maxf(0.0, float(v))
    return 0.0

static func sanitize(raw: Variant) -> Dictionary:
    var w := default_weekly()
    if not (raw is Dictionary):
        return w
    if raw.get("pid") is String and valid_pid(str(raw["pid"])):
        w["pid"] = str(raw["pid"])
    w["week"] = maxi(0, _int(raw.get("week", 0)))
    w["entries"] = clampi(_int(raw.get("entries", 0)), 0, Balance.WEEKLY_MAX_ENTRIES)
    w["best"] = _num(raw.get("best", 0.0))
    w["prev_week"] = maxi(0, _int(raw.get("prev_week", 0)))
    w["prev_best"] = _num(raw.get("prev_best", 0.0))
    w["claimed"] = maxi(0, _int(raw.get("claimed", 0)))
    return w

static func valid_pid(p: String) -> bool:
    if p.length() != 36:
        return false
    for i in range(36):
        var c: String = p[i]
        if i == 8 or i == 13 or i == 18 or i == 23:
            if c != "-":
                return false
        elif not "0123456789abcdef".contains(c):
            return false
    return true

## Identificador anônimo do jogador (formato UUID v4) para o ranking.
static func make_pid(rng: RandomNumberGenerator) -> String:
    var hex := "0123456789abcdef"
    var out := ""
    for i in range(36):
        if i == 8 or i == 13 or i == 18 or i == 23:
            out += "-"
        elif i == 14:
            out += "4"
        elif i == 19:
            out += hex[8 + rng.randi_range(0, 3)]
        else:
            out += hex[rng.randi_range(0, 15)]
    return out

## Muda de semana: guarda a pontuação da semana que acabou (para a recompensa) e zera entradas/melhor.
static func sync(w: Dictionary, week: int) -> void:
    if int(w["week"]) == week:
        return
    if float(w["best"]) > 0.0 and int(w["week"]) > 0:
        w["prev_week"] = int(w["week"])
        w["prev_best"] = float(w["best"])
    w["week"] = week
    w["entries"] = 0
    w["best"] = 0.0

static func entries_left(w: Dictionary) -> int:
    return maxi(0, Balance.WEEKLY_MAX_ENTRIES - int(w["entries"]))

## Motivo de não poder entrar: "" (pode), "locked" ou "no_entries".
static func block_reason(w: Dictionary, max_stage: int) -> String:
    if not is_unlocked(max_stage):
        return "locked"
    if entries_left(w) <= 0:
        return "no_entries"
    return ""

static func consume_entry(w: Dictionary) -> bool:
    if entries_left(w) <= 0:
        return false
    w["entries"] = int(w["entries"]) + 1
    return true

## Guarda a pontuação; devolve true se for recorde da semana.
static func record(w: Dictionary, score: float) -> bool:
    if score > float(w["best"]):
        w["best"] = score
        return true
    return false

# ---------------------------------------------------------------- Lucifer e pontuação
static func lucifer_hp() -> float:
    return StageLogic.boss_hp(Balance.MAX_STAGE) * Balance.WEEKLY_HP_MULT

static func lucifer_dmg() -> float:
    return StageLogic.boss_dmg(Balance.MAX_STAGE) * Balance.WEEKLY_DMG_MULT

## Chefe invocado: equivalente ao chefe do andar 290 (no semanal; na fase 300, frac = LUCIFER_STAGE_SUMMON_FRAC).
static func summon_hp(frac: float = 1.0) -> float:
    return StageLogic.boss_hp(Balance.WEEKLY_SUMMON_STAGE) * frac

static func summon_dmg(frac: float = 1.0) -> float:
    return StageLogic.boss_dmg(Balance.WEEKLY_SUMMON_STAGE) * frac

## Pontuação = dano causado ao Lucifer. Se ele morrer, ganha bônus de até +25% da vida dele pelo tempo que sobrou.
static func compute_score(dealt: float, max_hp: float, killed: bool, secs_left: float) -> float:
    var s: float = clampf(dealt, 0.0, max_hp)
    if killed:
        s = max_hp + max_hp * 0.25 * clampf(secs_left / Balance.WEEKLY_TIME_LIMIT, 0.0, 1.0)
    return s

# ---------------------------------------------------------------- recompensa POR LUTA (% da vida do Lucifer tirada)
# Paga ao fim de CADA luta (4 por semana), na hora. Escala com a FASE MÁXIMA do jogador, porque o ouro por fase cresce 10%
# a cada fase (um valor fixo seria enorme na fase 50 e nada na 250):
#   ouro  = "fases de ouro" x o ouro de uma fase inteira na fase máxima do jogador
#   gemas = "chefes" x as gemas médias de um chefe na fase máxima do jogador
# A melhor faixa é MATAR o Lucifer (bem acima de 75%+, para valer o esforço). Abaixo de 1% não há prêmio.
const ATTEMPT_TIERS := [
    {"min_pct": 1.00, "killed": true, "gold_stages": 6.0, "boss_gems": 12.0, "label": "LUCIFER DERROTADO"},
    {"min_pct": 0.75, "gold_stages": 4.0, "boss_gems": 7.0, "label": "75% OU MAIS"},
    {"min_pct": 0.50, "gold_stages": 3.0, "boss_gems": 5.0, "label": "50% OU MAIS"},
    {"min_pct": 0.25, "gold_stages": 2.0, "boss_gems": 3.0, "label": "25% OU MAIS"},
    {"min_pct": 0.10, "gold_stages": 1.0, "boss_gems": 2.0, "label": "10% OU MAIS"},
    {"min_pct": 0.01, "gold_stages": 0.5, "boss_gems": 1.0, "label": "1% OU MAIS"},
]
const ATTEMPT_MIN_GEMS := 10        # piso de gemas por faixa (fase máxima baixa)
const MOB_GOLD_AVG := 3.0           # ouro base médio de um mob comum (mistura dos 4 tipos), para estimar o ouro de uma fase

## Ouro de uma fase inteira (mobs) nesta fase: referência para o prêmio.
static func stage_gold(stage: int) -> int:
    var st: int = clampi(stage, 1, Balance.MAX_STAGE)
    return StageLogic.enemy_gold(MOB_GOLD_AVG, st) * StageLogic.enemy_count(st)

## Gemas médias do chefe da fase (média da faixa [min, max]).
static func boss_gems_avg(stage: int) -> float:
    var r: Array = StageLogic.boss_gem_range(clampi(stage, 1, Balance.MAX_STAGE))
    return (float(r[0]) + float(r[1])) / 2.0

## Faixa atingida ({} = nenhuma). pct = fração da vida do Lucifer tirada (0..1).
static func attempt_tier(pct: float, killed: bool) -> Dictionary:
    for t in ATTEMPT_TIERS:
        if bool(t.get("killed", false)):
            if killed:
                return t
            continue
        if pct >= float(t["min_pct"]):
            return t
    return {}

## Prêmio de uma faixa na fase máxima do jogador: {"gold", "gems", "label"}.
static func tier_reward(t: Dictionary, max_stage: int) -> Dictionary:
    if t.is_empty():
        return {"gold": 0, "gems": 0, "label": ""}
    var gold: int = int(round(float(stage_gold(max_stage)) * float(t["gold_stages"])))
    var gems: int = maxi(ATTEMPT_MIN_GEMS, int(round(boss_gems_avg(max_stage) * float(t["boss_gems"]))))
    return {"gold": gold, "gems": gems, "label": str(t["label"])}

## Prêmio de uma luta: pct = dano causado / vida máxima do Lucifer.
static func attempt_reward(pct: float, killed: bool, max_stage: int) -> Dictionary:
    var r := tier_reward(attempt_tier(clampf(pct, 0.0, 1.0), killed), max_stage)
    r["pct"] = 1.0 if killed else clampf(pct, 0.0, 1.0)
    return r

# ---------------------------------------------------------------- recompensas do RANKING (semana anterior)
## rank <= 0 = sem ranking online (modo offline): só participação.
static func reward_for(rank: int, total: int) -> Dictionary:
    if rank > 0:
        for r in REWARD_RANKS:
            if rank <= int(r["max_rank"]):
                return {"gems": int(r["gems"]), "shards": int(r["shards"]), "label": str(r["label"])}
        if total > 0:
            var pct: float = float(rank) / float(total)
            for p in REWARD_PERCENTILES:
                if pct <= float(p["max_pct"]):
                    return {"gems": int(p["gems"]), "shards": int(p["shards"]), "label": str(p["label"])}
    return REWARD_PARTICIPATION.duplicate()

## Há recompensa da semana passada para resgatar?
static func claimable(w: Dictionary) -> bool:
    return int(w["prev_week"]) > 0 and float(w["prev_best"]) > 0.0 and int(w["prev_week"]) > int(w["claimed"])

## Marca como resgatada e devolve a recompensa ({} se não havia).
static func claim(w: Dictionary, rank: int, total: int) -> Dictionary:
    if not claimable(w):
        return {}
    w["claimed"] = int(w["prev_week"])
    return reward_for(rank, total)

# ---------------------------------------------------------------- textos (só caracteres da fonte pixel)
static func fmt_clock(secs: float) -> String:
    var s: int = maxi(0, int(ceil(secs)))
    return "%d:%02d" % [floori(float(s) / 60.0), s % 60]

static func fmt_countdown(secs: int) -> String:
    var s: int = maxi(0, secs)
    var d: int = floori(float(s) / 86400.0)
    var h: int = floori(float(s % 86400) / 3600.0)
    var m: int = floori(float(s % 3600) / 60.0)
    if d > 0:
        return "%dD %02dH" % [d, h]
    return "%dH %02dM" % [h, m]

# ---------------------------------------------------------------- online (parse puro; a rede fica em OnlineClient)
## Normaliza a resposta da função weekly_overview do servidor (ver docs/weekly_ranking.sql). Aceita lixo sem quebrar.
static func parse_overview(data: Variant) -> Dictionary:
    var out := {"ok": false, "week": 0, "attempts": 0, "total": 0, "top": [], "me_rank": 0, "me_score": 0.0,
        "prev_week": 0, "prev_rank": 0, "prev_total": 0}
    if not (data is Dictionary):
        return out
    out["ok"] = true
    out["week"] = maxi(0, _int(data.get("week", 0)))
    out["attempts"] = clampi(_int(data.get("attempts", 0)), 0, Balance.WEEKLY_MAX_ENTRIES)
    out["total"] = maxi(0, _int(data.get("total", 0)))
    var top: Array = []
    if data.get("top") is Array:
        for row in data["top"]:
            if row is Dictionary and top.size() < 10:
                top.append({"rank": maxi(1, _int(row.get("rank", 0))), "name": clean_display(str(row.get("name", "?"))),
                    "score": _num(row.get("score", 0.0))})
    out["top"] = top
    if data.get("me") is Dictionary:
        out["me_rank"] = maxi(0, _int(data["me"].get("rank", 0)))
        out["me_score"] = _num(data["me"].get("score", 0.0))
    if data.get("prev") is Dictionary:
        out["prev_week"] = maxi(0, _int(data["prev"].get("week", 0)))
        out["prev_rank"] = maxi(0, _int(data["prev"].get("rank", 0)))
        out["prev_total"] = maxi(0, _int(data["prev"].get("total", 0)))
    return out

## Troca por "?" o que a fonte pixel não desenha (nomes vêm de outros jogadores) e limita o tamanho.
static func clean_display(txt: String) -> String:
    var out := ""
    for i in range(mini(txt.length(), 12)):
        var c: String = txt[i]
        out += c if SpriteManifest.FONT_CHARS.contains(c) else "?"
    return out

## Resposta de start_attempt: {"ok": bool, "attempts": int, "week": int}.
static func parse_attempt(data: Variant) -> Dictionary:
    if not (data is Dictionary):
        return {"ok": false, "attempts": Balance.WEEKLY_MAX_ENTRIES, "week": 0, "net": false}
    return {"ok": bool(data.get("ok", false)), "attempts": clampi(_int(data.get("attempts", 0)), 0, Balance.WEEKLY_MAX_ENTRIES),
        "week": maxi(0, _int(data.get("week", 0))), "net": true}

## Texto de pontuação (curto, caracteres da fonte): 1,23T
static func fmt_score(v: float) -> String:
    return UiLogic.fmt_short(v)
