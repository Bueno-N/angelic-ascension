extends TestCase
## Boss semanal (Lucifer): semana UTC (segunda), desbloqueio na fase 50, 4 entradas, pontuação, recompensas por posição,
## salvamento, resposta do servidor (parse), habilidades do Lucifer e potência (mais forte que o chefe da fase 300).
## A parte de rede (OnlineClient) NÃO tem teste aqui: precisa de um servidor real.

const MON_2026_11_16 := 1794787200   # 2026-11-16 00:00:00 UTC (segunda)

func test_week_starts_on_monday_utc() -> void:
    check(WeeklyBoss.week_id(MON_2026_11_16) == WeeklyBoss.week_id(MON_2026_11_16 + 6 * 86400 + 86399), "segunda 00:00 até domingo 23:59 = mesma semana")
    check(WeeklyBoss.week_id(MON_2026_11_16 - 1) == WeeklyBoss.week_id(MON_2026_11_16) - 1, "domingo 23:59:59 ainda é a semana anterior")
    check(WeeklyBoss.week_id(MON_2026_11_16 + 7 * 86400) == WeeklyBoss.week_id(MON_2026_11_16) + 1, "a próxima segunda abre outra semana")
    check(WeeklyBoss.seconds_left(MON_2026_11_16) == WeeklyBoss.WEEK_SECONDS, "na virada faltam 7 dias")
    check(WeeklyBoss.seconds_left(MON_2026_11_16 + 7 * 86400 - 1) == 1, "1 s antes da virada")
    check(WeeklyBoss.fmt_countdown(3 * 86400 + 4 * 3600) == "3D 04H" and WeeklyBoss.fmt_countdown(5 * 3600 + 7 * 60) == "5H 07M", "contagem regressiva")
    check(WeeklyBoss.fmt_clock(120.0) == "2:00" and WeeklyBoss.fmt_clock(59.2) == "1:00" and WeeklyBoss.fmt_clock(0.0) == "0:00", "relógio da luta")

func test_unlock_requires_finishing_stage_50() -> void:
    check(Balance.WEEKLY_UNLOCK_STAGE == 50, "libera ao concluir a fase 50")
    check(not WeeklyBoss.is_unlocked(1) and not WeeklyBoss.is_unlocked(50), "na fase 50 (ainda não concluída) está bloqueado")
    check(WeeklyBoss.is_unlocked(51) and WeeklyBoss.is_unlocked(300), "concluiu a 50: liberado")
    var w := WeeklyBoss.default_weekly()
    check(WeeklyBoss.block_reason(w, 50) == "locked", "motivo: bloqueado")
    check(WeeklyBoss.block_reason(w, 51) == "", "liberado e com entradas")

func test_four_entries_per_week_and_reset() -> void:
    check(Balance.WEEKLY_MAX_ENTRIES == 4, "4 entradas por semana")
    var w := WeeklyBoss.default_weekly()
    WeeklyBoss.sync(w, 100)
    for i in range(4):
        check(WeeklyBoss.consume_entry(w), "entrada %d" % (i + 1))
    check(not WeeklyBoss.consume_entry(w) and WeeklyBoss.entries_left(w) == 0, "5ª entrada recusada")
    check(WeeklyBoss.block_reason(w, 60) == "no_entries", "motivo: sem entradas")
    WeeklyBoss.sync(w, 100)
    check(WeeklyBoss.entries_left(w) == 0, "mesma semana: não renova")
    WeeklyBoss.sync(w, 101)
    check(WeeklyBoss.entries_left(w) == 4 and int(w["week"]) == 101, "nova semana: 4 entradas de novo")

func test_best_score_and_previous_week_kept_for_reward() -> void:
    var w := WeeklyBoss.default_weekly()
    WeeklyBoss.sync(w, 10)
    check(WeeklyBoss.record(w, 500.0) and not WeeklyBoss.record(w, 400.0) and WeeklyBoss.record(w, 900.0), "só o melhor vale")
    check(float(w["best"]) == 900.0, "melhor = 900")
    check(not WeeklyBoss.claimable(w), "nada a resgatar na mesma semana")
    WeeklyBoss.sync(w, 11)
    check(int(w["prev_week"]) == 10 and float(w["prev_best"]) == 900.0 and float(w["best"]) == 0.0, "a semana que acabou vira 'anterior'")
    check(WeeklyBoss.claimable(w), "há prêmio da semana passada")
    var r: Dictionary = WeeklyBoss.claim(w, 1, 50)
    check(int(r["gems"]) == 600 and int(w["claimed"]) == 10, "1º lugar resgatado")
    check(not WeeklyBoss.claimable(w) and WeeklyBoss.claim(w, 1, 50).is_empty(), "não resgata duas vezes")
    var w2 := WeeklyBoss.default_weekly()
    WeeklyBoss.sync(w2, 10)
    WeeklyBoss.sync(w2, 11)
    check(not WeeklyBoss.claimable(w2), "quem não jogou não tem prêmio")

func test_rewards_by_rank() -> void:
    var prev_gems := 1.0e9
    for rk in [1, 2, 3, 5, 10, 30, 50, 80, 100, 300, 500]:
        var g: int = int(WeeklyBoss.reward_for(rk, 100000)["gems"])
        check(g > 0 and float(g) <= prev_gems, "prêmio nunca aumenta com a posição (#%d)" % rk)
        prev_gems = float(g)
    check(WeeklyBoss.reward_for(1, 10000)["label"] == "1O LUGAR" and int(WeeklyBoss.reward_for(1, 10000)["shards"]) > int(WeeklyBoss.reward_for(2, 10000)["shards"]), "1º ganha mais que o 2º")
    check(WeeklyBoss.reward_for(900, 10000)["label"] == "TOP 10%", "posição 900 de 10000 = top 10%")
    check(WeeklyBoss.reward_for(4000, 10000)["label"] == "TOP 50%", "4000 de 10000 = top 50%")
    check(WeeklyBoss.reward_for(9000, 10000)["label"] == "PARTICIPACAO", "o resto recebe participação")
    check(WeeklyBoss.reward_for(0, 0)["label"] == "PARTICIPACAO" and int(WeeklyBoss.reward_for(0, 0)["gems"]) > 0, "offline: participação")
    check(int(WeeklyBoss.REWARD_RANKS[0]["gems"]) <= 1000, "prêmio máximo moderado perto da economia (~6,5 mil gemas até a fase 300)")

func test_score() -> void:
    var hp: float = WeeklyBoss.lucifer_hp()
    check_approx(WeeklyBoss.compute_score(hp * 0.3, hp, false, 40.0), hp * 0.3, "sem matar: dano causado", hp * 1.0e-6)
    check(WeeklyBoss.compute_score(hp * 5.0, hp, false, 0.0) <= hp, "dano limitado à vida")
    check(WeeklyBoss.compute_score(0.0, hp, false, 0.0) == 0.0, "zero dano = zero")
    var fast: float = WeeklyBoss.compute_score(hp, hp, true, 100.0)
    var slow: float = WeeklyBoss.compute_score(hp, hp, true, 5.0)
    check(fast > slow and slow > hp, "matar vale mais que qualquer dano; sobrar tempo vale mais")
    check(fast <= hp * 1.25 + 1.0, "bônus máximo de 25%")

func test_lucifer_is_stronger_than_the_last_stage_boss() -> void:
    check(WeeklyBoss.lucifer_hp() > StageLogic.boss_hp(Balance.MAX_STAGE) * 4.0, "vida muito acima do chefe da fase 300")
    check(WeeklyBoss.lucifer_dmg() > StageLogic.boss_dmg(Balance.MAX_STAGE), "dano acima do chefe da fase 300")
    check(WeeklyBoss.summon_hp() < WeeklyBoss.lucifer_hp() and WeeklyBoss.summon_hp() > 0.0, "chefe invocado é bem mais fraco")
    check(Balance.WEEKLY_TIME_LIMIT == 120.0 and Balance.WEEKLY_SUMMON_EVERY == 20.0, "2 min e invocação a cada 20 s")
    check(EnemiesDB.ABILITIES["summon_boss"]["cooldown"] == Balance.WEEKLY_SUMMON_EVERY, "a habilidade de invocar recarrega em 20 s")

func test_lucifer_abilities() -> void:
    var ab: Array = EnemiesDB.LUCIFER["abilities"]
    check(ab.size() == 5 and ab.has("summon_boss"), "4 habilidades + invocar chefe")
    var own := 0
    for a in ab:
        check(EnemiesDB.ABILITIES.has(a), "habilidade definida: " + str(a))
        check(AudioLogic.ability_sfx(str(a)) != "" and AudioLogic.has_sfx(AudioLogic.ability_sfx(str(a))), "som da habilidade " + str(a))
        for b in EnemiesDB.BOSSES:
            check(not b["abilities"].has(a), "%s não é de outro chefe (%s)" % [a, b["id"]])
        own += 1
    check(own == 5, "5 habilidades exclusivas")
    check(EnemiesDB.LUCIFER["abilities"][0] == "summon_boss", "invocação tem prioridade (sai a cada ~20 s)")
    for b in EnemiesDB.BOSSES:
        check(EnemiesDB.LUCIFER["id"] != b["id"], "Lucifer é único (fora da lista de chefes de fase)")
    check(EnemiesDB.BOSSES.size() == 4, "chefes de fase continuam 4")
    check(SpriteManifest.DATA.has(EnemiesDB.LUCIFER["sprite"]) and SpriteManifest.DATA[EnemiesDB.LUCIFER["sprite"]]["anims"].has("cast"), "sprite do Lucifer")
    check(SpriteManifest.ICON_NAMES.has("lucifer"), "ícone do Lucifer")
    var nova: Dictionary = EnemiesDB.ABILITIES["hell_nova"]
    check(float(nova["inner"]) < float(nova["radius"]), "nova infernal tem zona segura no centro")

func test_save_roundtrip_and_garbage() -> void:
    var st := SaveData.default_state()
    check(st.has("weekly") and st["weekly"] is Dictionary, "estado padrão tem 'weekly'")
    var r := RandomNumberGenerator.new()
    r.seed = 7
    st["weekly"]["pid"] = WeeklyBoss.make_pid(r)
    st["weekly"]["week"] = 2900
    st["weekly"]["entries"] = 3
    st["weekly"]["best"] = 1.5e18
    var back: Dictionary = SaveData.from_json(SaveData.to_json(st))
    check(back["weekly"]["pid"] == st["weekly"]["pid"] and int(back["weekly"]["entries"]) == 3 and float(back["weekly"]["best"]) == 1.5e18, "ida e volta pelo JSON")
    check(SaveData.from_json("{\"weekly\": 5}")["weekly"]["entries"] == 0, "lixo no lugar do dicionário vira padrão")
    var bad: Dictionary = WeeklyBoss.sanitize({"pid": "xx", "entries": 99, "best": -5, "week": "a", "claimed": -3})
    check(bad["pid"] == "" and int(bad["entries"]) == 4 and float(bad["best"]) == 0.0 and int(bad["week"]) == 0 and int(bad["claimed"]) == 0, "valores inválidos são limpos")
    check(WeeklyBoss.sanitize({"best": NAN})["best"] == 0.0, "NaN vira 0")
    check(SaveData.default_state()["version"] == st["version"], "versão do save mantida")

func test_pid_format() -> void:
    var r := RandomNumberGenerator.new()
    r.seed = 1
    var a: String = WeeklyBoss.make_pid(r)
    var b: String = WeeklyBoss.make_pid(r)
    check(WeeklyBoss.valid_pid(a) and WeeklyBoss.valid_pid(b) and a != b, "UUID v4 válido e diferente")
    check(not WeeklyBoss.valid_pid("") and not WeeklyBoss.valid_pid("ABCDEFGH-1111-4111-8111-111111111111"), "recusa vazio e maiúsculas")

func test_parse_server_overview() -> void:
    check(not WeeklyBoss.parse_overview(null)["ok"] and not WeeklyBoss.parse_overview("x")["ok"] and not WeeklyBoss.parse_overview([1])["ok"], "resposta inválida")
    var good := {"week": 2900, "attempts": 2, "total": 321, "top": [{"rank": 1, "name": "Ana", "score": 1.0e18}, {"rank": 2, "name": "Bô", "score": 5.0e17}],
        "me": {"rank": 17, "score": 2.0e17}, "prev": {"week": 2899, "rank": 4, "total": 300}}
    var o: Dictionary = WeeklyBoss.parse_overview(good)
    check(o["ok"] and o["week"] == 2900 and o["attempts"] == 2 and o["total"] == 321 and o["me_rank"] == 17 and o["prev_rank"] == 4 and o["prev_total"] == 300, "campos lidos")
    check(o["top"].size() == 2 and o["top"][0]["name"] == "Ana", "ranking lido")
    var weird: Dictionary = WeeklyBoss.parse_overview({"attempts": 99, "top": [{"rank": "x", "name": "中文abc", "score": "1"}, 5], "me": 3})
    check(weird["attempts"] == 4 and weird["top"].size() == 1 and weird["top"][0]["name"].begins_with("??abc"), "tolera lixo; letras fora da fonte viram '?'")
    var many: Array = []
    for i in range(30):
        many.append({"rank": i + 1, "name": "N", "score": 1.0})
    check(WeeklyBoss.parse_overview({"top": many})["top"].size() == 10, "no máximo 10 linhas")
    check(WeeklyBoss.parse_attempt({"ok": true, "attempts": 3, "week": 5})["ok"] and not WeeklyBoss.parse_attempt({"ok": false, "attempts": 4})["ok"], "resposta de entrada")
    check(not WeeklyBoss.parse_attempt(null)["net"] and WeeklyBoss.parse_attempt({"ok": false})["net"], "diferencia falha de rede de 'sem entradas'")

func test_offline_by_default_and_texts_fit_the_font() -> void:
    check(not OnlineConfig.enabled() or (OnlineConfig.URL.begins_with("https://") and OnlineConfig.ANON_KEY.length() > 20), "sem servidor = offline; com servidor = https e chave")
    var texts := ["BOSS", "SEMANAL", "BOSS SEMANAL: LUCIFER", "BLOQUEADO: conclua a fase ", "ENTRADAS: ", "Nova semana em: ", "Tempo da luta: ", "Seu melhor: ",
        "Lucifer invoca 1 chefe a cada ", " s", "PREMIOS (ranking da semana)", " gemas, ", " frag.", "Demais: top 10% e participacao", "RANKING MUNDIAL",
        "MODO OFFLINE", "Servidor nao configurado", "(veja docs/ONLINE.md)", "Sua pontuacao fica salva aqui", "Carregando...", "SEM CONEXAO",
        "Ninguem pontuou ainda", "VOCE: ", " de ", "ENTRAR", "RESGATAR PREMIO", "ATUALIZAR", "SEM ENTRADAS NESTA SEMANA", "SEM CONEXAO: nao foi possivel entrar",
        "Conectando...", "O SEU TEMPO ACABOU", "LUCIFER DERROTADO!", "VOCE CAIU", "Pontos: ", "TEMPO ", "Conclua a fase ", " para liberar", "GEMAS", "FRAGMENTOS",
        "1O LUGAR", "2O LUGAR", "3O LUGAR", "TOP 10", "TOP 50", "TOP 100", "TOP 500", "TOP 10%", "TOP 50%", "PARTICIPACAO", "TEMPO", "Lucifer, o Caído"]
    for t in texts:
        for i in range(t.length()):
            check(SpriteManifest.FONT_CHARS.contains(t[i]), "caractere '%s' de \"%s\" existe na fonte pixel" % [t[i], t])
    for t in [WeeklyBoss.fmt_score(1.234e18), WeeklyBoss.fmt_score(0.0), WeeklyBoss.fmt_countdown(100000), WeeklyBoss.fmt_clock(75.0)]:
        for i in range(t.length()):
            check(SpriteManifest.FONT_CHARS.contains(t[i]), "texto formatado '%s' cabe na fonte" % t)

func test_pause_with_weekly_panel() -> void:
    check(OptionsLogic.should_pause(false, false, false, true), "painel do boss semanal pausa o jogo")
    check(not OptionsLogic.should_pause(false, false, false, false), "sem painéis: não pausa")
    check(OptionsLogic.should_pause(true) and OptionsLogic.should_pause(false, true) and OptionsLogic.should_pause(false, false, true), "perfil, morte e mapa continuam pausando")

func test_lucifer_is_the_stage_300_boss() -> void:
    check(EnemiesDB.boss_for(Balance.MAX_STAGE)["id"] == "lucifer", "chefe da fase 300 = Lucifer")
    check(EnemiesDB.boss_for(290)["id"] != "lucifer", "outros chefes continuam no ciclo")
    var plain_hp: float = StageLogic.enemy_hp(float(EnemiesDB.BOSS_BASE["hp"]), Balance.MAX_STAGE) * Balance.BOSS_HP_MULT
    var plain_dmg: float = StageLogic.enemy_dmg(float(EnemiesDB.BOSS_BASE["dmg"]), Balance.MAX_STAGE) * Balance.BOSS_DMG_MULT
    check_approx(StageLogic.boss_hp(Balance.MAX_STAGE), plain_hp * Balance.LUCIFER_STAGE_MULT, "vida +30% na fase 300", plain_hp * 1.0e-6)
    check_approx(StageLogic.boss_dmg(Balance.MAX_STAGE), plain_dmg * Balance.LUCIFER_STAGE_MULT, "dano +30% na fase 300", plain_dmg * 1.0e-6)
    check(StageLogic.boss_hp(299) < StageLogic.boss_hp(Balance.MAX_STAGE), "fase 300 é o chefe mais forte")
    check(WeeklyBoss.lucifer_hp() > StageLogic.boss_hp(Balance.MAX_STAGE) * 5.0, "semanal tem bem mais vida que o da fase 300")
    check(WeeklyBoss.lucifer_dmg() > StageLogic.boss_dmg(Balance.MAX_STAGE) * 1.2, "semanal tem mais dano que o da fase 300")
    check_approx(WeeklyBoss.summon_hp(), StageLogic.boss_hp(290), "invocações do semanal = chefe do andar 290", StageLogic.boss_hp(290) * 1.0e-6)
    check_approx(WeeklyBoss.summon_dmg(), StageLogic.boss_dmg(290), "dano das invocações = andar 290", StageLogic.boss_dmg(290) * 1.0e-6)
    check(WeeklyBoss.summon_hp(Balance.LUCIFER_STAGE_SUMMON_FRAC) < WeeklyBoss.summon_hp(), "na fase 300 as invocações são mais fracas que no semanal")

func test_speed_upgrades_capped_at_50() -> void:
    check(StatsCalc.max_level("speed") == 50 and StatsCalc.max_level("attack") > 1000000, "só a velocidade tem teto (50)")
    var st := SaveData.default_state()
    st["gold"] = 1000000000000
    var bought := 0
    for i in range(80):
        if Shop.buy_upgrade(st, "speed"):
            bought += 1
    check(bought == 50 and int(st["upgrades"]["speed"]) == 50, "compra só 50 melhorias de velocidade (%d)" % bought)
    check(Shop.buy_upgrade(st, "attack"), "os outros atributos seguem sem teto")
    var raw: Dictionary = {"upgrades": {"speed": 999}}
    check(int(SaveData.sanitize(raw)["upgrades"]["speed"]) == 50, "save com mais de 50 é limitado")
    var stats: Dictionary = StatsCalc.compute(st)
    check_approx(float(stats["speed"]), 220.0 + 4.0 * 50.0, "velocidade máxima = 420 sem bônus")
    var rows: Array = MenuModel.rows("attrs", st, stats, {})
    var found := false
    for r in rows:
        if r.get("kind", "") == "item" and str(r.get("title", "")).begins_with("Velocidade"):
            found = true
            check(r["button"] == "MÁXIMO" and not r["enabled"], "linha da velocidade mostra MÁXIMO e fica desligada")
    check(found, "linha da velocidade existe")
