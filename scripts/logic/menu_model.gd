class_name MenuModel
extends RefCounted
## Modelo do menu (lógica pura): quais abas existem, as linhas de cada aba e as ações de compra.
## A tela (UiList) só desenha estas linhas; as ações são strings como "attr|attack" ou "equip_buy|sword|3".
## IMPORTANTE: só usar caracteres que a fonte pixel desenha (veja SpriteManifest.FONT_CHARS).

const ATTR_ICONS := {"attack": "sword", "hp": "heart", "armor": "shield", "speed": "boot", "attack_speed": "bolt", "aura": "aura"}
const CAT_ICONS := {"sword": "sword", "armor": "armor", "boots": "boot", "gloves": "glove"}
const DEBUG_ACTIONS := [
    ["+1.000 ouro", "gold", 1000], ["+100.000 ouro", "gold", 100000],
    ["+1.000 gemas", "gems", 1000], ["+100.000 gemas", "gems", 100000], ["+2.000.000 gemas", "gems", 2000000],
    ["+10 fragmentos de asa", "shards", 10], ["+100 fragmentos de asa", "shards", 100],
    ["Ir para a fase 9", "stage", 9], ["Ir para a fase 10 (chefe)", "stage", 10], ["Ir para a fase 5 (mini-chefe)", "stage", 5],
    ["Fase +10", "stage_add", 10], ["Curar totalmente", "heal", 0], ["Zerar recargas", "cooldowns", 0],
    ["Desbloquear tudo", "unlock_all", 0],
]

static func tabs(debug: bool) -> Array:
    var t: Array = [
        {"id": "shop", "name": "Loja", "icon": "shop"},
        {"id": "attrs", "name": "Atributos", "icon": "sword"},
        {"id": "skills", "name": "Habilidades", "icon": "skills"},
        {"id": "wings", "name": "Asas", "icon": "wings"},
        {"id": "equip", "name": "Equipamentos", "icon": "armor"},
    ]
    t.append({"id": "options", "name": "Opções", "icon": "gear"})
    if debug:
        t.append({"id": "debug", "name": "Teste", "icon": "fx"})
    return t

static func tab_has_preview(tab: String) -> bool:
    return tab == "wings" or tab == "equip"

## ctx: {"cooldowns": {id: segundos}, "reset_armed": bool, "shop": contexto da loja paga (ver ShopLogic.rows)}
static func rows(tab: String, state: Dictionary, stats: Dictionary, ctx: Dictionary) -> Array:
    match tab:
        "attrs":
            return _attrs(state, stats)
        "skills":
            return _skills(state, ctx.get("cooldowns", {}))
        "wings":
            return _wings(state)
        "equip":
            return _equip(state)
        "options":
            return _options(state["settings"], bool(ctx.get("in_game", true)))
        "debug":
            return _debug(bool(ctx.get("reset_armed", false)))
        "shop":
            return ShopLogic.rows(ctx.get("shop", {}))   # loja paga: ctx["shop"] vem do ShopManager
    return []

static func _header(text: String) -> Dictionary:
    return {"kind": "header", "title": text}

static func _info(text: String) -> Dictionary:
    return {"kind": "info", "sub": text}

static func _item(icon: String, title: String, sub: String, button: String, cost: int, cost_icon: String,
        action: String, tone: String, enabled: bool, poor: bool = false) -> Dictionary:
    return {"kind": "item", "icon": icon, "title": title, "sub": sub, "button": button, "cost": cost,
        "cost_icon": cost_icon, "action": action, "tone": tone, "enabled": enabled, "poor": poor}

# ---------------------------------------------------------------- atributos (ouro)
static func _attrs(state: Dictionary, stats: Dictionary) -> Array:
    var out: Array = [_header("Melhorias com ouro")]
    for attr in Balance.ATTRIBUTE_ORDER:
        var d: Dictionary = Balance.ATTRIBUTES[attr]
        var lvl: int = Shop.upgrade_level(state, attr)
        var cost: int = StatsCalc.upgrade_cost(attr, lvl)
        var cur: float = float(stats[attr])
        var cur_txt: String = "%.2f" % cur if attr == "attack_speed" else "%.1f" % cur
        var afford: bool = int(state["gold"]) >= cost
        if lvl >= StatsCalc.max_level(attr):
            out.append(_item(ATTR_ICONS[attr], "%s  Nv %d/%d" % [d["name"], lvl, StatsCalc.max_level(attr)],
                "Atual %s  |  nível máximo" % cur_txt, "MÁXIMO", 0, "", "", "active", false))
            continue
        var lvl_txt: String = "%d" % lvl if StatsCalc.max_level(attr) > 100000 else "%d/%d" % [lvl, StatsCalc.max_level(attr)]
        out.append(_item(ATTR_ICONS[attr], "%s  Nv %s" % [d["name"], lvl_txt],
            "Atual %s  |  +%s por nível" % [cur_txt, str(d["per_level"])], "UPAR", cost, "coin", "attr|" + str(attr),
            "buy", afford, not afford))
    return out

# ---------------------------------------------------------------- habilidades (gemas)
static func _skills(state: Dictionary, cooldowns: Dictionary) -> Array:
    var out: Array = []
    var goal := UiLogic.next_skill_goal(state)
    var head := "Equipadas %d/%d" % [state["skills_equipped"].size(), SkillsDB.MAX_EQUIPPED]
    if not goal.is_empty():
        head += "  |  Próxima: %s (faltam %s)" % [goal["name"], UiLogic.fmt_int(int(goal["missing"]))]
    out.append(_header("Habilidades"))
    out.append(_info(head + "\nSó dá para remover uma habilidade que não está em recarga."))
    for s in SkillsDB.SKILLS:
        var id: String = s["id"]
        var extra := ""
        if float(s["duration"]) > 0.0:
            extra = "  |  Duração %ds" % int(s["duration"])
        var sub := "%s  |  Dano %d%%  |  Recarga %ds%s\n%s\nAuto: %s" % [s["rarity"], int(round(float(s["damage_pct"]) * 100.0)),
            int(s["cooldown"]), extra, s["desc"], AutoCast.rule_text(id)]
        var row: Dictionary
        match UiLogic.skill_state(state, id):
            "locked":
                var afford: bool = int(state["gems"]) >= int(s["price"])
                row = _item("", s["name"], sub, "COMPRAR", int(s["price"]), "gem", "skill_buy|" + id, "buy", afford, not afford)
            "owned":
                var full: bool = state["skills_equipped"].size() >= SkillsDB.MAX_EQUIPPED
                row = _item("", s["name"], sub, "CHEIO" if full else "EQUIPAR", 0, "", "" if full else "skill_equip|" + id,
                    "locked" if full else "ok", not full)
            _:
                var rem: float = float(cooldowns.get(id, 0.0))
                if rem > 0.0:
                    row = _item("", s["name"], sub, "RECARGA %ds" % int(ceil(rem)), 0, "", "", "locked", false)
                else:
                    row = _item("", s["name"], sub, "REMOVER", 0, "", "skill_unequip|" + id, "active", true)
        row["abbr"] = SkillsDB.abbr(id)
        row["icon"] = SkillsDB.icon(id)
        row["rarity"] = s["rarity"]
        out.append(row)
    return out

# ---------------------------------------------------------------- asas e brilho
static func _wings(state: Dictionary) -> Array:
    var out: Array = [_header("Asas (fragmentos de chefe)")]
    var w := UiLogic.wings_progress(state)
    var sub := "+%s em TODOS os atributos\nFragmentos %d%s" % [UiLogic.pct(WingsDB.bonus_for_level(int(w["level"]))), w["shards"],
        "" if w["maxed"] else " de %d para o próximo nível" % int(w["cost"])]
    var row: Dictionary
    if w["maxed"]:
        row = _item("wings", "Asas Nv %d/%d" % [w["level"], w["max"]], sub, "MÁXIMO", 0, "", "", "active", false)
    else:
        row = _item("wings", "Asas Nv %d/%d" % [w["level"], w["max"]], sub, "EVOLUIR", int(w["cost"]), "shard", "wings_evolve", "buy",
            bool(w["ready"]), not bool(w["ready"]))
    row["ratio"] = float(w["ratio"])
    out.append(row)
    out.append(_header("Brilho das asas (gemas)"))
    out.append(_info("Aumenta o poder de TODAS as habilidades."))
    for t in range(1, WingsDB.GLOW.size() + 1):
        var g: Dictionary = WingsDB.GLOW[t - 1]
        var gsub := "+%s nas habilidades" % UiLogic.pct(float(g["bonus"]))
        match UiLogic.glow_state(state, t):
            "active":
                out.append(_item("glow", g["name"], gsub, "ATIVO", 0, "", "", "active", false))
            "superseded":
                out.append(_item("glow", g["name"], gsub, "SUPERADO", 0, "", "", "locked", false))
            _:
                var afford: bool = int(state["gems"]) >= int(g["price"])
                out.append(_item("glow", g["name"], gsub, "COMPRAR", int(g["price"]), "gem", "glow|%d" % t, "buy", afford, not afford))
    return out

# ---------------------------------------------------------------- equipamentos (gemas)
static func _equip(state: Dictionary) -> Array:
    var out: Array = [_info("Bônus totais: " + UiLogic.total_bonus_text(state))]
    for cat in EquipmentDB.CATEGORIES:
        out.append(_header(str(EquipmentDB.ITEMS[cat]["label"])))
        for tier in range(1, EquipmentDB.TIER_COUNT + 1):
            var item := EquipmentDB.get_item(cat, tier)
            var stats_txt: Array = []
            for st in item["stats"]:
                stats_txt.append(UiLogic.STAT_LABELS[st])
            var sub := "[%s]  +%s %s" % [item["rarity"], UiLogic.pct(float(item["bonus"])), " e ".join(stats_txt)]
            var row: Dictionary
            match UiLogic.equipment_state(state, cat, tier):
                "locked":
                    var afford: bool = int(state["gems"]) >= int(item["price"])
                    row = _item(CAT_ICONS[cat], str(item["name"]), sub, "COMPRAR", int(item["price"]), "gem", "equip_buy|%s|%d" % [cat, tier], "buy", afford, not afford)
                "owned":
                    row = _item(CAT_ICONS[cat], str(item["name"]), sub, "EQUIPAR", 0, "", "equip_set|%s|%d" % [cat, tier], "ok", true)
                _:
                    row = _item(CAT_ICONS[cat], str(item["name"]), sub, "REMOVER", 0, "", "equip_set|%s|0" % cat, "active", true)
            row["tint"] = AngelDraw.tier_color(tier)
            out.append(row)
    return out

# ---------------------------------------------------------------- opções
static func _options(settings: Dictionary, in_game: bool = true) -> Array:
    var vol: int = OptionsLogic.volume(settings)
    var mvol: int = OptionsLogic.music_vol(settings)
    var svol: int = OptionsLogic.sfx_vol(settings)
    var step: int = OptionsLogic.VOLUME_STEP
    var out: Array = [
        _header("Gráficos"),
        _item("fx", OptionsLogic.gfx_label(settings), "Baixo reduz partículas e efeitos: economiza bateria e ajuda em aparelhos fracos.",
            "ALTERAR", 0, "", "opt|fx|0", "ok", true),
        _header("Som"),
    ]
    out.append_array(_volume_rows("Volume do jogo", "Controla o volume geral (música e efeitos).", vol, "vol", step))
    var mon: bool = OptionsLogic.music_on(settings)
    out.append(_item("speaker", "Música: Ligada" if mon else "Música: Desligada", "Liga ou desliga só a trilha sonora (os efeitos continuam).",
        "DESLIGAR" if mon else "LIGAR", 0, "", "opt|music|0", "ok", true))
    out.append_array(_volume_rows("Volume da música", "Volume da trilha sonora.", mvol, "mvol", step))
    out.append_array(_volume_rows("Efeitos sonoros", "Ataques, habilidades, dano, mobs e chefes. No mudo, o jogo fica só com a música.", svol, "svol", step))
    out.append(_info("Mais opções virão em breve."))
    if in_game:
        out.append(_header("Jogo"))
        out.append(_item("back", "Menu inicial", "Salva o jogo e volta ao menu inicial (para trocar de jogo salvo).", "SAIR", 0, "", "opt|title|0", "ok", true))
    return out

## Duas linhas (AUMENTAR / DIMINUIR) para um volume em passos.
static func _volume_rows(label: String, sub: String, value: int, key: String, step: int) -> Array:
    var txt := "%s  %d%%" % [label, value] if value > 0 else "%s  MUDO" % label
    return [
        _item("speaker", txt, sub, "AUMENTAR" if value < 100 else "MÁXIMO", 0, "", "opt|%s|%d" % [key, step], "ok" if value < 100 else "locked", value < 100),
        _item("speaker", txt, "", "DIMINUIR" if value > 0 else "MÍNIMO", 0, "", "opt|%s|-%d" % [key, step], "ok" if value > 0 else "locked", value > 0),
    ]

# ---------------------------------------------------------------- modo de teste
static func _debug(reset_armed: bool) -> Array:
    var out: Array = [_header("Modo de teste"), _info("Só existe em builds de debug. As alterações são salvas: use o reset no fim.")]
    for d in DEBUG_ACTIONS:
        out.append(_item("fx", str(d[0]), "", "USAR", 0, "", "debug|%s|%d" % [d[1], d[2]], "ok", true))
    out.append(_item("close", "TOQUE DE NOVO PARA CONFIRMAR" if reset_armed else "Resetar progresso", "", "RESETAR", 0, "", "debug|reset|0",
        "buy" if reset_armed else "locked", true))
    return out

# ---------------------------------------------------------------- ações
static func perform(state: Dictionary, action: String) -> bool:
    var p := action.split("|")
    if p.size() < 1:
        return false
    match p[0]:
        "attr":
            return p.size() > 1 and Shop.buy_upgrade(state, p[1])
        "skill_buy":
            return p.size() > 1 and Shop.buy_skill(state, p[1])
        "skill_equip":
            return p.size() > 1 and Shop.equip_skill(state, p[1])
        "skill_unequip":
            return p.size() > 1 and Shop.unequip_skill(state, p[1])
        "wings_evolve":
            return Shop.evolve_wings(state)
        "glow":
            return p.size() > 1 and Shop.buy_glow(state, int(p[1]))
        "equip_buy":
            return p.size() > 2 and Shop.buy_equipment(state, p[1], int(p[2]))
        "equip_set":
            return p.size() > 2 and Shop.equip_equipment(state, p[1], int(p[2]))
        "opt":
            return OptionsLogic.apply(state["settings"], p)
    return false
