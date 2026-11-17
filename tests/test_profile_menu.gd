extends TestCase
## Perfil (nome/avatar/status) e modelo do menu (abas, linhas, ações, textos desenháveis).

func test_clean_name() -> void:
    check(ProfileLogic.clean_name("") == "Anjo", "vazio vira Anjo")
    check(ProfileLogic.clean_name("   ") == "Anjo", "só espaços vira Anjo")
    check(ProfileLogic.clean_name(null) == "Anjo" and ProfileLogic.clean_name(42) == "Anjo", "tipo inválido vira Anjo")
    check(ProfileLogic.clean_name("  Ana  ") == "Ana", "remove bordas")
    check(ProfileLogic.clean_name("João") == "João", "mantém acentos que a fonte desenha")
    check(ProfileLogic.clean_name("A@B~C") == "ABC", "remove caracteres que a fonte não desenha")
    check(ProfileLogic.clean_name("ABCDEFGHIJKLMNOPQRSTUVWXYZ").length() == ProfileLogic.MAX_NAME, "limita o tamanho")
    check(ProfileLogic.clean_name("A\nB\tC") == "ABC", "sem caracteres de controle")

func test_profile_saved_and_sanitized() -> void:
    var st := SaveData.default_state()
    check(st["profile"]["name"] == "Anjo" and int(st["profile"]["avatar"]) == 0, "perfil padrão")
    st["profile"]["name"] = "Seraphim"
    st["profile"]["avatar"] = 5
    var back := SaveData.from_json(SaveData.to_json(st))
    check(back["profile"]["name"] == "Seraphim" and int(back["profile"]["avatar"]) == 5, "perfil sobrevive ao save")
    var junk := SaveData.sanitize({"profile": {"name": 123, "avatar": "x"}})
    check(junk["profile"]["name"] == "Anjo" and int(junk["profile"]["avatar"]) == 0, "lixo vira padrão")
    var big := SaveData.sanitize({"profile": {"name": "Ok", "avatar": 999}})
    check(int(big["profile"]["avatar"]) == ProfileLogic.AVATAR_COUNT - 1, "avatar limitado ao máximo")
    var neg := SaveData.sanitize({"profile": {"avatar": -4}})
    check(int(neg["profile"]["avatar"]) == 0, "avatar negativo vira 0")
    check(ProfileLogic.AVATAR_COUNT == 8, "8 avatares disponíveis")

func test_stat_rows_show_everything() -> void:
    var st := SaveData.default_state()
    var rows := ProfileLogic.stat_rows(st, StatsCalc.compute(st))
    check(rows.size() >= 12, "pelo menos 12 status")
    var labels := []
    for r in rows:
        check(r["kind"] == "stat" and str(r["title"]) != "" and str(r["value"]) != "", "linha completa")
        labels.append(r["title"])
    for need in ["Ataque", "Vida máxima", "Armadura", "Velocidade", "Aura", "Ouro", "Gemas", "Fragmentos de asa", "Fase atual"]:
        check(labels.has(need), "mostra " + need)
    st["upgrades"]["attack"] = 5
    var r2 := ProfileLogic.stat_rows(st, StatsCalc.compute(st))
    check(str(r2[0]["value"]) == "20.0", "ataque reflete upgrades (10 + 2*5)")

func test_menu_tabs() -> void:
    var t := MenuModel.tabs(false)
    check(t.size() == 4, "4 abas sem modo de teste")
    var ids := []
    for x in t:
        ids.append(x["id"])
    for need in ["attrs", "skills", "wings", "equip"]:
        check(ids.has(need), "aba " + need)
    check(MenuModel.tabs(true).size() == 5, "5 abas com modo de teste")
    check(MenuModel.tab_has_preview("wings") and MenuModel.tab_has_preview("equip") and not MenuModel.tab_has_preview("attrs"), "prévia só em asas/equip.")

func _rich_state() -> Dictionary:
    var st := SaveData.default_state()
    st["gold"] = 1000000000
    st["gems"] = 1000000000
    st["shards"] = 100000
    return st

func test_every_tab_builds_valid_rows() -> void:
    var st := _rich_state()
    var stats := StatsCalc.compute(st)
    for t in MenuModel.tabs(true):
        var rows := MenuModel.rows(str(t["id"]), st, stats, {"cooldowns": {}, "reset_armed": false})
        check(rows.size() > 0, "aba %s tem linhas" % t["id"])
        for r in rows:
            check(["header", "info", "item", "stat"].has(str(r["kind"])), "tipo válido")
            if r["kind"] == "item":
                check(str(r["title"]) != "", "item com título")
                check(str(r["button"]) != "", "item com botão")
                check(r.has("enabled") and r.has("tone"), "item com estado")
    check(MenuModel.rows("inexistente", st, stats, {}).is_empty(), "aba desconhecida = vazio")

func test_every_buy_action_is_valid_and_works() -> void:
    for t in ["attrs", "skills", "wings", "equip"]:
        var st := _rich_state()
        var rows := MenuModel.rows(t, st, StatsCalc.compute(st), {"cooldowns": {}})
        var n := 0
        for r in rows:
            if r["kind"] == "item" and str(r["action"]) != "" and bool(r["enabled"]):
                var copy := st.duplicate(true)
                check(MenuModel.perform(copy, str(r["action"])), "ação válida: " + str(r["action"]))
                n += 1
        check(n > 0, "aba %s tem ações" % t)

func test_perform_matches_shop() -> void:
    var st := SaveData.default_state()
    st["gold"] = 10
    check(MenuModel.perform(st, "attr|attack"), "comprar atributo")
    check(int(st["gold"]) == 0 and Shop.upgrade_level(st, "attack") == 1, "gastou ouro e subiu nível")
    check(not MenuModel.perform(st, "attr|attack"), "sem ouro não compra")
    st["gems"] = 5000
    check(MenuModel.perform(st, "skill_buy|celestial_lance"), "comprar habilidade")
    check(MenuModel.perform(st, "skill_equip|celestial_lance"), "equipar")
    check(MenuModel.perform(st, "skill_unequip|celestial_lance"), "remover")
    check(MenuModel.perform(st, "equip_buy|sword|1"), "comprar espada")
    check(int(st["equipped"]["sword"]) == 1, "auto-equipa")
    check(MenuModel.perform(st, "equip_set|sword|0"), "remover espada")
    check(MenuModel.perform(st, "glow|2"), "comprar brilho")
    st["shards"] = 2
    check(MenuModel.perform(st, "wings_evolve"), "evoluir asas")
    for bad in ["", "xyz", "attr", "attr|nope", "equip_buy|sword", "glow", "skill_buy|nope"]:
        check(not MenuModel.perform(st.duplicate(true), bad), "ação inválida recusada: '%s'" % bad)

func _find_skill_row(rows: Array, id: String) -> Dictionary:
    for r in rows:
        if r["kind"] == "item" and str(r.get("abbr", "")) == SkillsDB.abbr(id):
            return r
    return {}

func test_skill_row_states() -> void:
    var st := SaveData.default_state()
    st["gems"] = 1000
    Shop.buy_skill(st, "celestial_lance")
    Shop.equip_skill(st, "celestial_lance")
    var ready := MenuModel.rows("skills", st, {}, {"cooldowns": {"celestial_lance": 0.0}})
    var r1 := _find_skill_row(ready, "celestial_lance")
    check(str(r1["button"]) == "REMOVER" and bool(r1["enabled"]), "pronta: pode remover")
    var cd := MenuModel.rows("skills", st, {}, {"cooldowns": {"celestial_lance": 3.2}})
    var r2 := _find_skill_row(cd, "celestial_lance")
    check(str(r2["button"]).begins_with("RECARGA") and not bool(r2["enabled"]) and str(r2["action"]) == "", "em recarga: bloqueada, sem ação")
    var locked := _find_skill_row(ready, "holy_shield")
    check(str(locked["button"]) == "COMPRAR" and str(locked["action"]) == "skill_buy|holy_shield", "bloqueada: comprar")

func test_debug_rows_and_reset_confirmation() -> void:
    var a := MenuModel.rows("debug", SaveData.default_state(), {}, {"reset_armed": false})
    var b := MenuModel.rows("debug", SaveData.default_state(), {}, {"reset_armed": true})
    check(str(a[a.size() - 1]["title"]) == "Resetar progresso", "reset normal")
    check(str(b[b.size() - 1]["title"]).begins_with("TOQUE DE NOVO"), "reset armado pede confirmação")
    var acts := 0
    for r in a:
        if r["kind"] == "item":
            check(str(r["action"]).begins_with("debug|"), "ações do teste")
            acts += 1
    check(acts >= 10, "várias ações de teste")
