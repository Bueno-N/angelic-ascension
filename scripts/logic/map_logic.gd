class_name MapLogic
extends RefCounted
## Mapa das 300 fases (lógica pura): posição dos nós, tipo (chefe/mini/normal), cor do fundo por dificuldade,
## toque em nós e o texto/estado do painel de informação.

const SPACING := 120.0          # distância horizontal entre nós
const X0 := 90.0                # x do nó da fase 1
const RADIUS_NORMAL := 22.0
const RADIUS_MINI := 28.0
const RADIUS_BOSS := 34.0
# Fundo do mapa por dificuldade: quanto mais difícil, mais vermelho (Fácil = azul-noite ... Abismal = vermelho vivo).
const TIER_BG := [
    Color(0.05, 0.10, 0.22), Color(0.14, 0.09, 0.20), Color(0.24, 0.08, 0.16),
    Color(0.36, 0.07, 0.10), Color(0.50, 0.06, 0.06), Color(0.66, 0.05, 0.04),
]

static func total_width() -> float:
    return X0 * 2.0 + float(Balance.MAX_STAGE - 1) * SPACING

static func node_x(stage: int) -> float:
    return X0 + float(StageLogic.clamp_stage(stage) - 1) * SPACING

## Caminho sinuoso: o y oscila ao redor do meio da área do mapa (coordenadas do conteúdo, sem rolagem).
static func node_pos(stage: int, map_top: float, map_h: float) -> Vector2:
    var s: float = float(StageLogic.clamp_stage(stage) - 1)
    var amp: float = map_h * 0.24
    var wave: float = sin(s * 0.5) + 0.25 * sin(s * 1.3 + 1.0)
    return Vector2(node_x(stage), map_top + map_h / 2.0 + wave * amp)

## "boss" (caveira) | "mini" (espada) | "normal" (bolinha)
static func node_kind(stage: int) -> String:
    if StageLogic.is_boss_stage(stage):
        return "boss"
    if StageLogic.is_mini_stage(stage):
        return "mini"
    return "normal"

static func node_radius(kind: String) -> float:
    match kind:
        "boss":
            return RADIUS_BOSS
        "mini":
            return RADIUS_MINI
    return RADIUS_NORMAL

## Fase tocada (0 = nenhuma). `pos` em coordenadas do conteúdo.
static func hit(pos: Vector2, map_top: float, map_h: float, reach: float) -> int:
    var guess: int = int(round((pos.x - X0) / SPACING)) + 1
    var best := 0
    var best_d := reach
    for s in range(guess - 1, guess + 2):
        if s < 1 or s > Balance.MAX_STAGE:
            continue
        var d: float = node_pos(s, map_top, map_h).distance_to(pos)
        if d <= best_d:
            best = s
            best_d = d
    return best

## Cor do fundo numa posição fracionária (fase 1.0 = nó 1). Bloco por dificuldade, com transição suave perto da divisa.
static func bg_color(stage_pos: float) -> Color:
    var t: float = (stage_pos - 1.0) / float(Balance.TIER_SIZE)
    var idx: int = clampi(floori(t), 0, TIER_BG.size() - 1)
    var nxt: int = mini(idx + 1, TIER_BG.size() - 1)
    var frac: float = clampf(t - float(idx), 0.0, 1.0)
    return TIER_BG[idx].lerp(TIER_BG[nxt], smoothstep(0.82, 1.0, frac))

## Cor de destaque da dificuldade (botões e faixas): do azul claro ao vermelho vivo.
static func tier_accent(tier: int) -> Color:
    var t: float = float(clampi(tier, 0, TIER_BG.size() - 1)) / float(TIER_BG.size() - 1)
    return Color(0.45, 0.62, 1.0).lerp(Color(1.0, 0.3, 0.25), t)

## Rolagem que deixa a fase no centro da tela (limitada ao tamanho do mapa).
static func scroll_for(stage: int, view_w: float) -> float:
    return clampf(node_x(stage) - view_w / 2.0, 0.0, maxf(0.0, total_width() - view_w))

## Painel de baixo: textos + estado do botão. state: "current" | "go" | "locked".
static func info(stage: int, current: int, max_stage: int) -> Dictionary:
    var st: int = StageLogic.clamp_stage(stage)
    var p := StageLogic.projection(st)
    var gains := "Ouro %s  |  Gemas %s" % [UiLogic.fmt_short(float(p["gold"])), UiLogic.fmt_short(float(p["gems"]))]
    var title := "Fase %d" % st
    var line1: String
    var line2: String = gains
    if bool(p["boss"]):
        title += " - Chefe"
        line1 = "Chefe: %s" % str(EnemiesDB.boss_for(st)["name"])
        line2 += "  |  Frag. %d" % int(p["shards"])
    elif bool(p["mini"]):
        title += " - Mini-chefe"
        line1 = "%d mobs + %s" % [int(p["mobs"]) - 1, str(EnemiesDB.mini_for(st)["name"])]
    else:
        line1 = "%d mobs" % int(p["mobs"])
    var state := "locked"
    var button := "BLOQUEADA"
    if st == current:
        state = "current"
        button = "FASE ATUAL"
    elif StageLogic.can_enter(current, max_stage, st):
        state = "go"
        button = "IR PARA A FASE"
    return {"stage": st, "title": title, "tag": "Dificuldade: %s" % StageLogic.tier_name(st), "line1": line1, "line2": line2,
        "state": state, "button": button, "enabled": state == "go"}
