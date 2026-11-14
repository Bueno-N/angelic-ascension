class_name UiLogic
extends RefCounted
## Regras de apresentação testáveis (estado de itens, metas, bônus totais, formatação).

const STAT_LABELS := {"attack": "ataque", "hp": "vida", "armor": "armadura",
    "speed": "velocidade", "attack_speed": "vel. de ataque", "aura": "aura"}

static func fmt_int(n: int) -> String:
    var s := str(absi(n))
    var out := ""
    var c := 0
    for i in range(s.length() - 1, -1, -1):
        out = s[i] + out
        c += 1
        if c % 3 == 0 and i > 0:
            out = "." + out
    return ("-" if n < 0 else "") + out

static func pct(x: float) -> String:
    return "%d%%" % int(round(x * 100.0))

## "locked" | "owned" | "equipped"
static func equipment_state(state: Dictionary, cat: String, tier: int) -> String:
    if int(state["equipped"].get(cat, 0)) == tier:
        return "equipped"
    if state["owned_equipment"][cat].has(tier):
        return "owned"
    return "locked"

static func skill_state(state: Dictionary, id: String) -> String:
    if state["skills_equipped"].has(id):
        return "equipped"
    if state["skills_owned"].has(id):
        return "owned"
    return "locked"

## "active" | "superseded" (tier menor que o atual) | "available"
static func glow_state(state: Dictionary, tier: int) -> String:
    var cur: int = int(state["glow_tier"])
    if tier == cur:
        return "active"
    if tier < cur:
        return "superseded"
    return "available"

## Próxima habilidade ainda não comprada (ordem de preço) e quantas gemas faltam.
static func next_skill_goal(state: Dictionary) -> Dictionary:
    for s in SkillsDB.SKILLS:
        if not state["skills_owned"].has(s["id"]):
            return {"id": s["id"], "name": s["name"], "price": int(s["price"]),
                "missing": maxi(0, int(s["price"]) - int(state["gems"]))}
    return {}

static func wings_progress(state: Dictionary) -> Dictionary:
    var lvl: int = int(state["wings_level"])
    var cost: int = WingsDB.shards_for_next(lvl)
    var shards: int = int(state["shards"])
    var maxed: bool = lvl >= WingsDB.MAX_LEVEL
    return {"level": lvl, "max": WingsDB.MAX_LEVEL, "cost": cost, "shards": shards, "maxed": maxed,
        "ready": (not maxed) and shards >= cost,
        "ratio": 1.0 if maxed else clampf(float(shards) / float(maxi(1, cost)), 0.0, 1.0)}

## Bônus % totais por atributo (asas + equipamentos). Só atributos com bônus > 0.
static func total_bonus_pct(state: Dictionary) -> Dictionary:
    var wings: float = WingsDB.bonus_for_level(int(state["wings_level"]))
    var eq: Dictionary = EquipmentDB.bonuses_for(state["equipped"])
    var out := {}
    for a in Balance.ATTRIBUTE_ORDER:
        var t: float = wings + float(eq.get(a, 0.0))
        if t > 0.0:
            out[a] = t
    return out

static func total_bonus_text(state: Dictionary) -> String:
    var b := total_bonus_pct(state)
    var parts: Array = []
    for a in Balance.ATTRIBUTE_ORDER:
        if b.has(a):
            parts.append("%s +%s" % [STAT_LABELS[a], pct(b[a])])
    if parts.is_empty():
        return "Nenhum bônus percentual ativo"
    return ", ".join(parts)

## "Efeitos: Alto/Baixo" (Baixo: sem brasas, faíscas nem explosões de partículas; teto de efeitos menor).
static func fx_enabled(settings: Dictionary) -> bool:
    return not SaveData.as_bool(settings.get("low_fx", false), false)

static func fx_cap(settings: Dictionary) -> int:
    return Balance.FX_CAP_NORMAL if fx_enabled(settings) else Balance.FX_CAP_LOW

static func time_scale(settings: Dictionary) -> float:
    return Balance.FAST_MODE_SCALE if SaveData.as_bool(settings.get("speed_2x", false), false) else 1.0

## Margens (em coordenadas da viewport) para a área segura do aparelho (notch, cantos arredondados).
static func safe_margins(safe_pos: Vector2, safe_size: Vector2, win: Vector2, view: Vector2) -> Dictionary:
    var zero := {"l": 0.0, "t": 0.0, "r": 0.0, "b": 0.0}
    if win.x <= 0.0 or win.y <= 0.0 or safe_size.x <= 0.0 or safe_size.y <= 0.0:
        return zero
    var sx: float = view.x / win.x
    var sy: float = view.y / win.y
    return {
        "l": maxf(0.0, safe_pos.x) * sx,
        "t": maxf(0.0, safe_pos.y) * sy,
        "r": maxf(0.0, win.x - (safe_pos.x + safe_size.x)) * sx,
        "b": maxf(0.0, win.y - (safe_pos.y + safe_size.y)) * sy,
    }

## Paleta do cenário: muda a cada 10 fases (4 paletas em ciclo).
static func stage_palette_index(stage: int) -> int:
    return floori(float(maxi(1, stage) - 1) / 10.0) % 4

static func gems_per_hour(session_gems: int, elapsed_seconds: float) -> float:
    if elapsed_seconds < 60.0:
        return 0.0
    return float(session_gems) / (elapsed_seconds / 3600.0)
