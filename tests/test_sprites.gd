extends TestCase
## Arte: manifesto, PNGs, animações e montagem dos SpriteFrames / camadas do anjo.

const FX_SHEETS := ["fx_aura", "fx_hit", "fx_burst", "fx_strike", "fx_shield", "fx_poof", "fx_fireball"]

func _needed() -> Array:
    var names: Array = ["angel_body", "angel_armor", "angel_boots", "angel_gloves",
        "angel_wings_0", "angel_wings_1", "angel_wings_2", "angel_wings_3",
        "ally", "sword_orbit", "torch", "ground", "fx_flame", "ui_icons", "avatars"]
    names.append_array(FX_SHEETS)
    for t in EnemiesDB.TYPES:
        names.append(t["sprite"])
    for b in EnemiesDB.BOSSES:
        names.append(b["sprite"])
    return names

func test_manifest_has_every_sheet_the_game_uses() -> void:
    for n in _needed():
        check(SpriteManifest.DATA.has(n), "manifesto tem a folha " + str(n))

func test_png_files_match_manifest_dimensions() -> void:
    for n in SpriteManifest.DATA.keys():
        var m: Dictionary = SpriteManifest.DATA[n]
        var path: String = "res://assets/sprites/%s.png" % n
        check(FileAccess.file_exists(path), "arquivo existe: " + path)
        var img := Image.load_from_file(ProjectSettings.globalize_path(path))
        check(img != null, "PNG legível: " + path)
        if img != null:
            check(img.get_width() == int(m["fw"]) * int(m["frames"]), "%s: largura = fw*quadros" % n)
            check(img.get_height() == int(m["fh"]), "%s: altura = fh" % n)

func test_animation_ranges_are_valid() -> void:
    for n in SpriteManifest.DATA.keys():
        var m: Dictionary = SpriteManifest.DATA[n]
        check(int(m["frames"]) >= 1, n + ": ao menos 1 quadro")
        for a in m["anims"].keys():
            var d: Dictionary = m["anims"][a]
            check(int(d["start"]) >= 0 and int(d["count"]) >= 1, "%s/%s: início e contagem" % [n, a])
            check(int(d["start"]) + int(d["count"]) <= int(m["frames"]), "%s/%s: dentro da folha" % [n, a])
            check(float(d["fps"]) > 0.0, "%s/%s: fps > 0" % [n, a])

func test_angel_layers_are_aligned() -> void:
    var ref: Dictionary = SpriteManifest.DATA["angel_body"]
    for n in ["angel_armor", "angel_boots", "angel_gloves", "angel_wings_0", "angel_wings_1", "angel_wings_2", "angel_wings_3"]:
        var m: Dictionary = SpriteManifest.DATA[n]
        check(int(m["fw"]) == int(ref["fw"]) and int(m["fh"]) == int(ref["fh"]), n + ": mesmo tamanho de quadro")
        check(int(m["frames"]) == int(ref["frames"]), n + ": mesma quantidade de quadros")
    for a in ["idle", "attack", "cast"]:
        check(ref["anims"].has(a), "anjo tem a animação " + a)
    check(not ref["anims"]["attack"]["loop"] and not ref["anims"]["cast"]["loop"], "ataque e conjuração não repetem")
    check(ref["anims"]["idle"]["loop"], "idle repete")

func test_angel_is_imposing_and_aligned_to_layers() -> void:
    var a: Dictionary = SpriteManifest.DATA["angel_body"]
    check(int(a["fw"]) >= 64 and int(a["fh"]) >= 64, "anjo em alta resolução (>= 64x64 por quadro)")
    for t in EnemiesDB.TYPES:
        check(int(a["fh"]) > int(SpriteManifest.DATA[t["sprite"]]["fh"]), "anjo é maior que " + str(t["id"]))

func test_enemies_and_bosses_have_animations() -> void:
    for t in EnemiesDB.TYPES:
        check(SpriteManifest.DATA[t["sprite"]]["anims"].has("walk"), "%s anda" % t["id"])
    for b in EnemiesDB.BOSSES:
        var an: Dictionary = SpriteManifest.DATA[b["sprite"]]["anims"]
        check(an.has("walk") and an.has("cast"), "chefe %s tem walk e cast" % b["id"])
        check(int(SpriteManifest.DATA[b["sprite"]]["fw"]) >= 64, "chefe %s é grande" % b["id"])
    check(SpriteManifest.DATA["caster"]["anims"].has("cast"), "conjurador tem pose de conjuração")

func test_fx_sheets_have_play_animation() -> void:
    for n in FX_SHEETS:
        check(SpriteManifest.DATA[n]["anims"].has("play"), n + " tem 'play'")
    check(SpriteManifest.DATA["fx_aura"]["anims"]["play"]["loop"], "aura repete")
    check(SpriteManifest.DATA["fx_shield"]["anims"]["play"]["loop"], "escudo repete")

func test_sprite_frames_build_for_every_sheet() -> void:
    for n in SpriteManifest.DATA.keys():
        var sf := SpriteLib.frames(n)
        check(sf != null, "SpriteFrames montado: " + str(n))
        if sf != null:
            var m: Dictionary = SpriteManifest.DATA[n]
            for a in m["anims"].keys():
                check(sf.has_animation(a), "%s/%s existe" % [n, a])
                check(sf.get_frame_count(a) == int(m["anims"][a]["count"]), "%s/%s: quadros" % [n, a])

func test_wings_stage_mapping() -> void:
    check(AngelSprite.wings_stage(0) == 0 and AngelSprite.wings_stage(2) == 0, "nv 0-2 = estágio 0")
    check(AngelSprite.wings_stage(3) == 1 and AngelSprite.wings_stage(5) == 1, "nv 3-5 = estágio 1")
    check(AngelSprite.wings_stage(6) == 2 and AngelSprite.wings_stage(8) == 2, "nv 6-8 = estágio 2")
    check(AngelSprite.wings_stage(9) == 3 and AngelSprite.wings_stage(WingsDB.MAX_LEVEL) == 3, "nv 9-10 = estágio 3")

func test_angel_sprite_can_be_built_and_animated() -> void:
    var a := AngelSprite.new()
    a.set_look(10, 6, {"sword": 6, "armor": 3, "boots": 1, "gloves": 2})
    check(a.current_anim() == "idle", "começa em idle")
    a.attack()
    check(a.current_anim() == "attack", "ataque")
    a.cast()
    check(a.current_anim() == "cast", "conjuração")
    a.play_anim("idle")
    a.set_speed(2.0)
    a.face(-1.0)
    check(a.scale.x == -1.0, "vira para a esquerda")
    a.face(1.0)
    check(a.scale.x == 1.0, "vira para a direita")
    a.set_look(0, 0, {})
    a.free()

func test_new_angel_art_poses() -> void:
    for pose in AngelSprite.ANCHORS:
        var t: Texture2D = AngelSprite.pose_texture(pose)
        check(t != null, "pose %s carrega" % pose)
        if t != null:
            var an: Vector2 = AngelSprite.ANCHORS[pose]
            check(an.x > 0.0 and an.y > 0.0 and an.x < t.get_width() and an.y < t.get_height(), "âncora de %s dentro da imagem" % pose)
    for f in AngelSprite.IDLE_FRAMES + AngelSprite.FLY_FRAMES + AngelSprite.TRANSFORM_FRAMES:
        check(AngelSprite.ANCHORS.has(f), "quadro %s tem âncora" % f)
    check(AngelSprite.glow_alpha(0) == 0.0 and AngelSprite.glow_alpha(2) > 0.0 and AngelSprite.glow_alpha(6) > AngelSprite.glow_alpha(2), "brilho das asas: contorno mais forte a cada tier")

func test_idle_loops_all_frames() -> void:
    var seen := {}
    for i in range(40):
        seen[AngelSprite.pose_for("idle", 0.0, false, false, 1.0, float(i) * 0.05)] = true
    check(seen.size() == AngelSprite.IDLE_FRAMES.size(), "parado: passa pelos %d quadros (asas batendo)" % AngelSprite.IDLE_FRAMES.size())

func test_flying_frames_when_moving() -> void:
    var seen := {}
    for i in range(20):
        seen[AngelSprite.pose_for("idle", 0.0, false, true, 1.0, float(i) * 0.05)] = true
    check(seen.size() == AngelSprite.FLY_FRAMES.size(), "andando: passa pelos quadros de voo")
    for p in seen.keys():
        check(str(p).begins_with("fly_"), "andando usa só quadros de voo (%s)" % p)
    check(AngelSprite.pose_for("attack", 0.0, false, true, 1.0) == "atk_release", "ataque tem prioridade sobre o voo")
    var a := AngelSprite.new()
    a.set_moving(true)
    check(a.is_moving() and a.current_pose().begins_with("fly_"), "sprite voando ao andar")
    a.set_moving(false)
    check(a.current_pose().begins_with("idle_"), "parou: volta ao idle")
    a.free()

func test_death_of_hell_power_form() -> void:
    for anim in ["idle", "attack", "cast"]:
        for t in [0.0, 0.05, 0.2, 0.5]:
            var p: String = AngelSprite.pose_for(anim, t, false, false, 1.0, t)
            check(not (p in ["surge_1", "surge_2", "surge_3"]) and not p.begins_with("power_"), "sem a Morte do Inferno nunca usa quadro de poder (%s)" % p)
            if anim == "idle":
                check(AngelSprite.pose_for(anim, t, true, false, 1.0, t).begins_with("power_idle_"), "Morte do Inferno parado: forma de poder animada")
                check(AngelSprite.pose_for(anim, t, true, true, 1.0, t).begins_with("power_fly_"), "Morte do Inferno andando: voo da forma de poder")
    var tr: Array = []
    for i in range(AngelSprite.TRANSFORM_FRAMES.size()):
        tr.append(AngelSprite.pose_for("transform", (float(i) + 0.5) * AngelSprite.TRANSFORM_FRAME, true, false, 1.0))
    check(tr == AngelSprite.TRANSFORM_FRAMES, "transformação do Power Surge toca os quadros em ordem")
    var a := AngelSprite.new()
    a.set_hell(true)
    check(a.current_anim() == "transform" and a.get_child_count() >= 3, "ligar a Morte do Inferno: transformação + redemoinho")
    a.attack()
    check(a.current_anim() == "transform", "ataque não corta a transformação")
    a._process(1.0)
    check(a.current_pose().begins_with("power_idle_"), "depois da transformação: forma de poder")
    a.attack()
    check(a.current_pose() == "power_atk_1", "golpe na forma de poder: braço estendido")
    a._process(AngelSprite.ATTACK_FRAME * 1.5)
    check(a.current_pose() == "power_atk_2", "golpe continua")
    a._process(1.0)
    check(a.current_pose().begins_with("power_idle_"), "volta para a forma de poder")
    check(is_equal_approx(AngelSprite.scale_of("power_idle_0"), AngelSprite.SPRITE_SCALE * AngelSprite.POWER_SCALE) and AngelSprite.scale_of("idle_0") == AngelSprite.SPRITE_SCALE, "forma de poder desenhada no mesmo tamanho do anjo")
    var hh: Vector2 = a.hand_local()
    a.set_hell(false)
    check(a.current_anim() == "idle" and a.current_pose().begins_with("idle_"), "acabou a habilidade: volta ao normal")
    a.attack()
    var hn: Vector2 = a.hand_local()
    check(hn.x > 20.0 and hh.x > 10.0 and absf(hn.y) < 40.0, "o disparo sai da frente do anjo")
    a.free()

func test_attack_shots() -> void:
    for n in AngelShot.PIVOTS:
        check(AngelShot.tex(n) != null, "imagem do disparo %s" % n)
    for pose in AngelSprite.HANDS:
        check(AngelSprite.ANCHORS.has(pose) and AngelSprite.pose_texture(pose) != null, "pose de ataque %s" % pose)
    var parent := Node2D.new()
    var b := AngelShot.bolt(parent, Vector2.ZERO, Vector2(0.0, 300.0))
    check(absf(b.rotation - PI / 2.0) < 0.01, "cometa mira para baixo quando o inimigo está embaixo")
    check(parent.get_child_count() == 1, "ataque normal: um cometa")
    b._process(10.0)
    check(parent.get_child_count() == 2 and (parent.get_child(1) as AngelShot).kind == "pop", "cometa estoura em luz ao chegar")
    var h := AngelShot.hell_shot(parent, Vector2.ZERO, Vector2(-400.0, 0.0))
    check(h.kind == "hbolt" and absf(absf(h.rotation) - PI) < 0.01, "projétil da Morte do Inferno mira para a esquerda")
    check(parent.get_child_count() == 5, "Morte do Inferno: esfera + estrela na mão + projétil")
    check(h.current_frame() == "hp_bolt_0", "projétil começa no 1º quadro")
    h._process(h._dur * 0.5)
    check(h.current_frame() == "hp_bolt_1", "muda de quadro enquanto voa")
    h._process(h._dur * 0.45)
    check(h.current_frame() == "hp_bolt_2", "chega com o quadro de pontas")
    h._process(10.0)
    var kinds: Array = []
    for c in parent.get_children():
        kinds.append((c as AngelShot).kind)
    check(kinds.has("hfade"), "o golpe se desfaz em penas no alvo")
    check(AngelShot.hbolt_frame(0.0) == "hp_bolt_0" and AngelShot.hbolt_frame(1.0) == "hp_bolt_2", "quadros do projétil em ordem")
    parent.free()

func test_two_wings_until_level_7() -> void:
    check(AngelSprite.uses_two_wings(0) and AngelSprite.uses_two_wings(6), "níveis 0-6: 2 asas")
    check(not AngelSprite.uses_two_wings(7) and not AngelSprite.uses_two_wings(WingsDB.MAX_LEVEL), "nível 7+: 4 asas")
    # toda pose usada tem a versão de 2 asas (com imagem e âncora)
    var poses: Array = AngelSprite.IDLE_FRAMES + AngelSprite.FLY_FRAMES + AngelSprite.TRANSFORM_FRAMES + AngelSprite.HELL_ATTACK + AngelSprite.POWER_IDLE + AngelSprite.POWER_FLY + ["atk_release", "atk_follow", "atk_charge"]
    for pose in poses:
        var f: String = AngelSprite.file_for(pose, true)
        check(f.ends_with("_2w") and AngelSprite.ANCHORS_2W.has(f) and AngelSprite.pose_texture(f) != null, "2 asas: %s -> %s" % [pose, f])
        var t: Texture2D = AngelSprite.pose_texture(f)
        if t != null:
            var an: Vector2 = AngelSprite.anchor_of(f)
            check(an.x > 0.0 and an.y > 0.0 and an.x < t.get_width() and an.y < t.get_height(), "âncora de %s dentro da imagem" % f)
    for f in AngelSprite.HANDS_2W:
        check(AngelSprite.ANCHORS_2W.has(f), "mão de %s tem âncora" % f)
    var a := AngelSprite.new()
    a.set_look(0, 0, {})
    check(a.has_two_wings() and a.current_file().ends_with("_2w"), "começa com 2 asas")
    a.attack()
    var h2: Vector2 = a.hand_local()
    check(a.current_file() == "atk_release_2w" and h2.x > 20.0, "ataque com 2 asas sai da mão")
    a.set_look(7, 0, {})
    check(not a.has_two_wings() and a.current_file() == "atk_release", "asa nv 7: troca para 4 asas")
    a.set_look(6, 0, {})
    a.set_hell(true)
    a._process(1.0)
    check(a.current_file().begins_with("power_idle_") and a.current_file().ends_with("_2w"), "Morte do Inferno também respeita as 2 asas")
    a.free()

func test_celestial_lance_animation() -> void:
    for f in LanceFx.PIVOTS:
        var t: Texture2D = LanceFx.tex(f)
        check(t != null, "lança: %s carrega" % f)
        if t != null:
            var pv: Vector2 = LanceFx.PIVOTS[f]
            check(pv.x >= 0.0 and pv.y >= 0.0 and pv.x <= t.get_width() and pv.y <= t.get_height(), "lança: referência de %s dentro da imagem" % f)
    var parent := Node2D.new()
    var target := Node2D.new()
    target.position = Vector2(300.0, 0.0)
    parent.add_child(target)
    var l := LanceFx.spawn(parent, Vector2.ZERO, target)
    var hits: Array = []
    l.hit.connect(func(at: Vector2): hits.append(at))
    check(l.phase == "summon" and l.current_frame() == "frame_1", "lança surge (quadro 1)")
    l._process(LanceFx.T_SUMMON + 0.01)
    check(l.phase == "charge" and l.current_frame() == "frame_2", "lança carrega (quadro 2)")
    l._process(LanceFx.T_CHARGE + 0.01)
    check(l.phase == "flight" and l.current_frame() == "frame_3", "lança dispara (quadro 3)")
    check(absf(l.rotation - (Vector2(300.0, 0.0) - LanceFx.SUMMON_OFFSET).angle()) < 0.01, "lança mira no alvo")
    check(hits.is_empty(), "sem dano antes de chegar")
    l._process(0.1)
    check(l.current_frame() == "frame_4", "voando (quadro 4)")
    l._process(1.0)
    check(hits.size() == 1 and l.phase == "impact" and l.current_frame() == "frame_5", "impacto: dano + quadro 5")
    l._process(LanceFx.T_IMPACT + 0.01)
    check(l.phase == "fade" and l.current_frame() == "frame_6", "luz se desfaz (quadro 6)")
    parent.free()

func test_rain_and_shield_art() -> void:
    check(SkillFx.has_art("rain_of_light") and SkillFx.has_art("holy_shield"), "arte da Chuva de Luz e do Escudo Sagrado")
    for n in SkillFx.FALL_FRAMES + SkillFx.IMPACT_FRAMES + ["flash"]:
        check(SkillFx.tex("rain_of_light", n) != null, "chuva: %s" % n)
    for n in SkillFx.SHIELD_OPEN + SkillFx.SHIELD_LOOP + SkillFx.SHIELD_BREAK:
        check(SkillFx.tex("holy_shield", n) != null, "escudo: %s" % n)
    var parent := Node2D.new()
    var d := SkillFx.rain_drop(parent, Vector2(100, 100))
    var hits: Array = []
    d.landed.connect(func(at: Vector2): hits.append(at))
    check(d.position == Vector2(100, 100) + SkillFx.FALL_FROM and hits.is_empty(), "projétil começa no alto, sem dano")
    d._process(SkillFx.FALL_TIME + 0.01)
    check(hits == [Vector2(100, 100)], "dano quando toca o chão")
    var pl := Node2D.new()
    var buffs := BuffState.new()
    buffs.add("holy_shield", 3.0, {}, 0.4)
    var sh := SkillFx.shield(pl, buffs, 170.0)
    check(sh.current_mode() == "shield_open" and is_equal_approx(sh.scale.x, 340.0 / SkillFx.SHIELD_RING_D), "ativação do tamanho da explosão")
    sh._process(1.0)
    check(sh.current_mode() == "shield_loop", "depois vira o escudo em volta do anjo")
    buffs.tick(5.0)
    sh._process(0.016)
    check(sh.current_mode() == "once", "acabou a absorção: escudo quebra")
    parent.free()
    pl.free()

func test_swords_and_judgment_art() -> void:
    check(SkillFx.has_art("swords_of_paradise") and SkillFx.has_art("divine_judgment"), "arte das Espadas e do Julgamento")
    for n in OrbitSwords.APPEAR + OrbitSwords.LOOP + OrbitSwords.VANISH:
        check(SkillFx.tex("swords_of_paradise", n) != null, "espada: %s" % n)
    check(OrbitSwords.frame_for(0.0, 4.0) == "sword_00", "espadas surgem")
    check(OrbitSwords.LOOP.has(OrbitSwords.frame_for(2.0, 4.0)), "espadas brilham em laço")
    check(OrbitSwords.frame_for(3.99, 4.0) == "sword_11", "espadas se desfazem no fim")
    for i in SkillFx.JUDGMENT_FRAMES:
        check(SkillFx.tex("divine_judgment", "judgment_%02d" % i) != null, "julgamento: quadro %d" % i)
    var parent := Node2D.new()
    var target := Node2D.new()
    parent.add_child(target)
    target.position = Vector2(300, 200)
    var j := SkillFx.judgment(parent, target)
    var hits: Array = []
    j.landed.connect(func(at: Vector2): hits.append(at))
    j._process(0.1)
    check(hits.is_empty(), "sem dano durante o selo")
    j._process(float(SkillFx.JUDGMENT_BEAM) / SkillFx.JUDGMENT_FPS)
    check(hits.size() == 1, "dano quando o raio cai")
    parent.free()

func test_wings_and_archangels_art() -> void:
    check(SkillFx.has_art("wings_of_redemption") and SkillFx.has_art("army_of_archangels"), "arte das Asas e dos Arcanjos")
    for n in SkillFx.WINGS_FRAMES + SkillFx.RING_FRAMES:
        check(SkillFx.tex("wings_of_redemption", n) != null, "asas: %s" % n)
    for i in 16:
        check(SkillFx.tex("army_of_archangels", "angel_%02d" % i) != null, "arcanjo: quadro %d" % i)
    check(ArchangelAlly.frame_for("appear", 0.0) == 0 and ArchangelAlly.frame_for("vanish", 9.0) == 15, "arcanjo surge e some")
    check(ArchangelAlly.frame_for("attack", float(ArchangelAlly.HIT_FRAME) / ArchangelAlly.FPS) == 10, "quadro do corte")
    check(ArchangelAlly.IDLE.has(ArchangelAlly.frame_for("idle", 3.3)), "parado em laço")
    var pl := Node2D.new()
    SkillFx.redemption(pl, 280.0)
    check(pl.get_child_count() == 2, "asas + onda de cura")
    var ring: SkillFx = pl.get_child(1)
    check(is_equal_approx(ring.scale.x, 560.0 / SkillFx.RING_D), "onda do tamanho da área")
    pl.free()

func test_art_license_notice_exists() -> void:
    check(FileAccess.file_exists("res://assets/LICENSE.txt"), "aviso de licença da arte")
