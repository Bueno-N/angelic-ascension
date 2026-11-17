class_name ProfileLogic
extends RefCounted
## Perfil do jogador (nome + avatar) e a lista de status mostrada ao tocar no avatar.

const MAX_NAME := 14
const DEFAULT_NAME := "Anjo"
const AVATAR_COUNT := SpriteManifest.AVATAR_COUNT

## Nome seguro: só caracteres que a fonte do jogo desenha, sem bordas, máx. 14. Vazio vira "Anjo".
static func clean_name(v) -> String:
    if not (v is String):
        return DEFAULT_NAME
    var out := ""
    for i in range(v.length()):
        var ch: String = v[i]
        if SpriteManifest.FONT_CHARS.contains(ch):
            out += ch
    out = out.strip_edges()
    if out.length() > MAX_NAME:
        out = out.substr(0, MAX_NAME).strip_edges()
    return out if out != "" else DEFAULT_NAME

static func _row(icon: String, label: String, value: String) -> Dictionary:
    return {"kind": "stat", "icon": icon, "title": label, "value": value}

## Todos os status do anjo, prontos para exibir (ícone, nome, valor).
static func stat_rows(state: Dictionary, stats: Dictionary) -> Array:
    var rows: Array = []
    var armor: float = float(stats["armor"])
    var reduction: int = int(round((1.0 - Balance.ARMOR_K / (Balance.ARMOR_K + maxf(0.0, armor))) * 100.0))
    var owned_eq := 0
    for cat in EquipmentDB.CATEGORIES:
        owned_eq += state["owned_equipment"][cat].size()
    rows.append(_row("sword", "Ataque", "%.1f" % float(stats["attack"])))
    rows.append(_row("heart", "Vida máxima", "%.0f" % float(stats["hp"])))
    rows.append(_row("shield", "Armadura", "%.1f (-%d%% dano)" % [armor, reduction]))
    rows.append(_row("boot", "Velocidade", "%.0f" % float(stats["speed"])))
    rows.append(_row("bolt", "Vel. de ataque", "%.2f por s" % float(stats["attack_speed"])))
    rows.append(_row("aura", "Aura", "%.1f por s" % float(stats["aura"])))
    rows.append(_row("skills", "Poder das habilidades", "+%s" % UiLogic.pct(float(stats["skill_power_mult"]) - 1.0)))
    rows.append(_row("wings", "Asas", "Nv %d/%d (+%s)" % [int(state["wings_level"]), WingsDB.MAX_LEVEL, UiLogic.pct(WingsDB.bonus_for_level(int(state["wings_level"])))]))
    rows.append(_row("armor", "Equipamentos", "%d/%d comprados" % [owned_eq, EquipmentDB.CATEGORIES.size() * EquipmentDB.TIER_COUNT]))
    rows.append(_row("skills", "Habilidades", "%d/%d desbloqueadas" % [state["skills_owned"].size(), SkillsDB.SKILLS.size()]))
    rows.append(_row("next", "Fase atual", "%d (recorde %d)" % [int(state["stage"]), int(state["max_stage"])]))
    rows.append(_row("coin", "Ouro", UiLogic.fmt_int(int(state["gold"]))))
    rows.append(_row("gem", "Gemas", UiLogic.fmt_int(int(state["gems"]))))
    rows.append(_row("shard", "Fragmentos de asa", UiLogic.fmt_int(int(state["shards"]))))
    return rows
