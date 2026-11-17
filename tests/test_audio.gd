extends TestCase
## Áudio: arquivos x manifesto, qual música toca em cada fase, mapeamento de efeitos, limitador e opções de som.

const GENERIC_IDS := ["atk", "hurt", "die", "stage_up", "ui_click", "ui_buy", "mob_hit", "warn", "boss_roar", "mini_roar", "boss_die",
    "mini_die", "ally_strike", "sk_rain_hit", "mob_shoot", "mob_drain"]

func test_every_sfx_file_loads_with_the_manifest_length() -> void:
    check(AudioManifest.SFX.size() >= 40, "manifesto com os efeitos (%d)" % AudioManifest.SFX.size())
    for id in AudioManifest.SFX.keys():
        var st = load(AudioLogic.sfx_path(str(id)))
        check(st is AudioStreamWAV, "efeito carrega como WAV: " + str(id))
        if st is AudioStreamWAV:
            check(absf(st.get_length() - float(AudioManifest.SFX[id])) < 0.06, "duração de %s bate com o manifesto" % str(id))

func test_every_music_file_loads() -> void:
    for t in AudioLogic.all_tracks():
        check(AudioManifest.MUSIC.has(t), "manifesto tem a música " + str(t))
        var st = load(AudioLogic.track_path(str(t)))
        check(st is AudioStreamOggVorbis, "música carrega como OGG: " + str(t))
        if st is AudioStreamOggVorbis:
            check(st.get_length() > 20.0, "trilha com mais de 20 s: " + str(t))
            check(absf(st.get_length() - float(AudioManifest.MUSIC[t])) < 0.5, "duração de %s bate com o manifesto" % str(t))
            st.loop = true
            check(st.loop, "a música pode repetir em laço: " + str(t))

func test_music_for_stage() -> void:
    check(AudioLogic.music_for(1) == "music_1" and AudioLogic.music_for(49) == "music_1", "Fácil: trilha 1")
    check(AudioLogic.music_for(51) == "music_1" and AudioLogic.music_for(99) == "music_1", "Normal: trilha 1")
    check(AudioLogic.music_for(101) == "music_2" and AudioLogic.music_for(199) == "music_2", "Difícil e Pesadelo: trilha 2")
    check(AudioLogic.music_for(201) == "music_3" and AudioLogic.music_for(299) == "music_3", "Infernal e Abismal: trilha 3")
    for st in [10, 20, 100, 150, 300]:
        check(AudioLogic.music_for(st) == AudioLogic.BOSS_TRACK, "fase de chefe %d usa a trilha do chefe" % st)
    check(AudioLogic.music_for(5) == "music_1" and AudioLogic.music_for(15) == "music_1", "mini-chefe mantém a trilha da fase")
    var seen := {}
    for st in range(1, Balance.MAX_STAGE + 1):
        var t: String = AudioLogic.music_for(st)
        check(AudioLogic.all_tracks().has(t), "trilha válida na fase %d" % st)
        seen[t] = true
    check(seen.size() == 4, "as 4 trilhas são usadas")

func test_every_referenced_sfx_exists_in_the_manifest() -> void:
    for id in GENERIC_IDS:
        check(AudioLogic.has_sfx(id), "efeito existe: " + id)
    for s in SkillsDB.SKILLS:
        check(AudioLogic.has_sfx(AudioLogic.skill_sfx(str(s["id"]))), "efeito da habilidade " + str(s["id"]))
    for ab in EnemiesDB.ABILITIES.keys():
        var id: String = AudioLogic.ability_sfx(str(ab))
        check(id != "" and AudioLogic.has_sfx(id), "efeito da habilidade inimiga " + str(ab))
    for t in EnemiesDB.TYPES:
        var sp: String = str(t["sprite"])
        check(AudioLogic.SPRITES.has(sp), "sprite com som próprio: " + sp)
        check(AudioLogic.has_sfx(AudioLogic.mob_atk_sfx(sp)) and AudioLogic.has_sfx(AudioLogic.mob_die_sfx(sp)), "sons de ataque e morte de " + sp)
    check(AudioLogic.mob_atk_sfx("desconhecido") == "mob_imp_atk" and AudioLogic.mob_die_sfx("x") == "mob_imp_die", "desconhecido cai no demônio comum")

func test_each_boss_and_mini_ability_has_its_own_sound() -> void:
    var ids := {}
    for b in EnemiesDB.BOSSES:
        for a in b["abilities"]:
            var id: String = AudioLogic.ability_sfx(str(a))
            check(not ids.has(id), "som de habilidade de chefe repetido: " + id)
            ids[id] = true
    for m in EnemiesDB.MINIS:
        for a in m["abilities"]:
            check(AudioLogic.ability_sfx(str(a)) != "", "mini-chefe com som: " + str(a))
    var skills := {}
    for s in SkillsDB.SKILLS:
        var sid: String = AudioLogic.skill_sfx(str(s["id"]))
        check(not skills.has(sid), "cada habilidade do anjo tem som próprio: " + sid)
        skills[sid] = true

func test_death_sfx() -> void:
    check(AudioLogic.death_sfx({}, true) == "boss_die", "chefe")
    check(AudioLogic.death_sfx({"summon": true, "sprite": "imp"}, false) == "", "invocação morre quieta")
    check(AudioLogic.death_sfx({"mini": true, "sprite": "hound"}, false) == "mini_die", "mini-chefe")
    check(AudioLogic.death_sfx({"sprite": "hound"}, false) == "mob_hound_die", "mob comum por sprite")
    check(AudioLogic.death_sfx({}, false) == "mob_imp_die", "sem sprite = demônio comum")

func test_gain_gap_and_priority_tables() -> void:
    for id in AudioManifest.SFX.keys():
        var g: float = AudioLogic.gain_db(str(id))
        check(g <= 0.0 and g >= -30.0, "ganho razoável: %s (%.1f dB)" % [str(id), g])
        check(AudioLogic.min_gap(str(id)) >= 0.0, "intervalo >= 0: " + str(id))
        check(AudioLogic.priority(str(id)) >= 0 and AudioLogic.priority(str(id)) <= 2, "prioridade 0..2: " + str(id))
    check(AudioLogic.priority("sk_holy_apocalypse") == 2 and AudioLogic.priority("boss_roar") == 2 and AudioLogic.priority("die") == 2, "habilidades, chefe e morte nunca são cortados")
    check(AudioLogic.priority("mob_hit") == 0 and AudioLogic.priority("mob_imp_die") == 0 and AudioLogic.priority("sk_rain_hit") == 0, "ruído de fundo é descartável")
    check(AudioLogic.gain_db("mob_hit") < AudioLogic.gain_db("sk_divine_judgment"), "bater em mob é mais baixo que habilidade")

func test_rate_limiter() -> void:
    var last := {}
    check(AudioLogic.allow(last, "mob_hit", 1.0), "primeiro toca")
    check(not AudioLogic.allow(last, "mob_hit", 1.02), "dentro do intervalo não toca")
    check(AudioLogic.allow(last, "mob_hit", 1.07), "depois do intervalo toca")
    check(AudioLogic.allow(last, "sk_holy_shield", 2.0) and AudioLogic.allow(last, "sk_holy_shield", 2.0), "habilidades sem intervalo")
    check(AudioLogic.allow(last, "mob_imp_atk", 5.0) and not AudioLogic.allow(last, "mob_imp_atk", 5.1), "ataque de mob: 1 a cada 0,3 s por tipo")
    check(AudioLogic.allow(last, "mob_hound_atk", 5.1), "outro tipo de mob não é bloqueado")

func test_voice_stealing() -> void:
    var v: Array = []
    for i in range(4):
        v.append({"priority": 1, "start": float(i)})
    check(AudioLogic.pick_voice(v, 1) == 0, "empate: corta a mais antiga")
    v[2]["priority"] = 0
    check(AudioLogic.pick_voice(v, 1) == 2, "corta a de menor prioridade")
    check(AudioLogic.pick_voice(v, 0) == 2, "prioridade 0 pode cortar prioridade 0")
    var strong: Array = [{"priority": 2, "start": 0.0}, {"priority": 2, "start": 1.0}]
    check(AudioLogic.pick_voice(strong, 0) == -1, "efeito fraco não corta os fortes")
    check(AudioLogic.pick_voice(strong, 2) == 0, "forte corta forte (a mais antiga)")
    v[1]["priority"] = -1
    check(AudioLogic.pick_voice(v, 0) == 1, "voz livre tem preferência")
    check(AudioLogic.pick_voice([], 1) == -1, "sem vozes")

func test_music_and_sfx_options() -> void:
    var s: Dictionary = SaveData.default_state()["settings"]
    check(OptionsLogic.music_on(s) and OptionsLogic.music_vol(s) == 60 and OptionsLogic.sfx_vol(s) == 100, "padrões: música ligada a 60%, efeitos a 100%")
    check(OptionsLogic.apply(s, PackedStringArray(["opt", "music", "0"])), "alterna música")
    check(not OptionsLogic.music_on(s) and not OptionsLogic.music_enabled(s), "música desligada")
    OptionsLogic.apply(s, PackedStringArray(["opt", "music", "0"]))
    check(OptionsLogic.music_on(s) and OptionsLogic.music_enabled(s), "música ligada de novo")
    s["music_vol"] = 0
    check(OptionsLogic.music_on(s) and not OptionsLogic.music_enabled(s), "volume 0 = sem música")
    check(OptionsLogic.music_db(s) <= -80.0, "música mudo em dB")
    s["music_vol"] = 60
    check(OptionsLogic.apply(s, PackedStringArray(["opt", "svol", "-10"])) and OptionsLogic.sfx_vol(s) == 90, "efeitos 100 -> 90")
    for i in range(12):
        OptionsLogic.apply(s, PackedStringArray(["opt", "svol", "-10"]))
    check(OptionsLogic.sfx_vol(s) == 0 and OptionsLogic.sfx_db(s) <= -80.0, "efeitos no mudo")
    check(not OptionsLogic.apply(s, PackedStringArray(["opt", "svol", "-10"])), "no piso não muda")
    check(OptionsLogic.apply(s, PackedStringArray(["opt", "svol", "10"])) and OptionsLogic.sfx_vol(s) == 10, "sobe de novo")
    check(OptionsLogic.apply(s, PackedStringArray(["opt", "mvol", "-10"])) and OptionsLogic.music_vol(s) == 50, "volume da música")
    check(not OptionsLogic.apply(s, PackedStringArray(["opt", "mvol"])) and not OptionsLogic.apply(s, PackedStringArray(["opt", "svol"])), "ação incompleta é ignorada")
    check(OptionsLogic.music_vol({"music_vol": 900}) == 100 and OptionsLogic.sfx_vol({"sfx_vol": -5}) == 0, "valores fora da faixa")
    check(OptionsLogic.music_on({"music_on": "lixo"}), "valor inválido = padrão (ligada)")

func test_global_settings_carry_the_new_options() -> void:
    var g := OptionsLogic.sanitize_global({"volume": 50, "music_on": false, "music_vol": 30, "sfx_vol": 0, "low_fx": true})
    check(int(g["volume"]) == 50 and not bool(g["music_on"]) and int(g["music_vol"]) == 30 and int(g["sfx_vol"]) == 0 and bool(g["low_fx"]), "sanitize mantém tudo")
    var old := OptionsLogic.sanitize_global({"volume": 70})
    check(bool(old["music_on"]) and int(old["music_vol"]) == 60 and int(old["sfx_vol"]) == 100, "arquivo antigo ganha os padrões")
    var st := SaveData.default_state()
    OptionsLogic.copy_globals(g, st["settings"])
    check(not bool(st["settings"]["music_on"]) and int(st["settings"]["music_vol"]) == 30 and int(st["settings"]["sfx_vol"]) == 0, "copia para o jogo")
    var back := SaveData.from_json(SaveData.to_json(st))
    check(not bool(back["settings"]["music_on"]) and int(back["settings"]["sfx_vol"]) == 0, "salvar e carregar mantém")
    var legacy := SaveData.sanitize({"settings": {"volume": 40}})
    check(bool(legacy["settings"]["music_on"]) and int(legacy["settings"]["sfx_vol"]) == 100, "save antigo sem as opções novas")
    check(OptionsLogic.default_global().size() == OptionsLogic.GLOBAL_KEYS.size(), "chaves globais completas")

func test_options_rows_offer_music_and_sfx_controls() -> void:
    var st := SaveData.default_state()
    var rows := MenuModel.rows("options", st, StatsCalc.compute(st), {})
    var actions := []
    var titles := []
    for r in rows:
        if r["kind"] == "item":
            actions.append(str(r["action"]))
            titles.append(str(r["title"]))
    for a in ["opt|music|0", "opt|mvol|10", "opt|mvol|-10", "opt|svol|10", "opt|svol|-10", "opt|vol|10", "opt|vol|-10", "opt|fx|0"]:
        check(actions.has(a), "ação nas opções: " + a)
    check(titles.has("Música: Ligada") and titles.has("Efeitos sonoros  100%"), "textos das opções")
    st["settings"]["music_on"] = false
    st["settings"]["sfx_vol"] = 0
    var rows2 := MenuModel.rows("options", st, StatsCalc.compute(st), {})
    var t2 := []
    for r in rows2:
        if r["kind"] == "item":
            t2.append(str(r["title"]))
    check(t2.has("Música: Desligada") and t2.has("Efeitos sonoros  MUDO"), "desligada e mudo aparecem")

func test_buses_follow_the_options() -> void:
    var g := OptionsLogic.default_global()
    g["music_on"] = false
    g["sfx_vol"] = 0
    AudioLogic.apply_buses(g)
    var m: int = AudioServer.get_bus_index(AudioLogic.BUS_MUSIC)
    var s: int = AudioServer.get_bus_index(AudioLogic.BUS_SFX)
    check(m >= 0 and s >= 0, "barramentos Música e Efeitos existem")
    check(AudioServer.is_bus_mute(m) and AudioServer.is_bus_mute(s), "música desligada e efeitos no mudo")
    g["music_on"] = true
    g["sfx_vol"] = 100
    AudioLogic.apply_buses(g)
    check(not AudioServer.is_bus_mute(m) and not AudioServer.is_bus_mute(s), "voltam a tocar")
    check_approx(AudioServer.get_bus_volume_db(s), 0.0, "efeitos a 100% = 0 dB", 0.01)
    check(AudioServer.get_bus_volume_db(m) < AudioServer.get_bus_volume_db(s), "música abaixo dos efeitos por padrão")
    var count: int = AudioServer.bus_count
    AudioLogic.apply_buses(g)
    check(AudioServer.bus_count == count, "aplicar de novo não cria barramentos repetidos")
    AudioLogic.apply_buses(OptionsLogic.default_global())

func test_skill_icons_exist() -> void:
    for s in SkillsDB.SKILLS:
        check(SpriteManifest.ICON_NAMES.has(SkillsDB.icon(str(s["id"]))), "ícone da habilidade " + str(s["id"]))
    var st := SaveData.default_state()
    var rows := MenuModel.rows("skills", st, StatsCalc.compute(st), {"cooldowns": {}})
    var with_icon := 0
    for r in rows:
        if r["kind"] == "item" and str(r.get("icon", "")).begins_with("sk_"):
            with_icon += 1
    check(with_icon == 10, "as 10 linhas de habilidade mostram o ícone (%d)" % with_icon)
