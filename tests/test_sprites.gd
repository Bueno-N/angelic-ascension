extends TestCase
## Arte: manifesto, PNGs, animações e montagem dos SpriteFrames / camadas do anjo.

const FX_SHEETS := ["fx_aura", "fx_slash", "fx_hit", "fx_burst", "fx_strike", "fx_shield", "fx_poof", "fx_fireball"]

func _needed() -> Array:
    var names: Array = ["angel_body", "angel_armor", "angel_boots", "angel_gloves", "angel_sword",
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
    for n in ["angel_armor", "angel_boots", "angel_gloves", "angel_sword", "angel_wings_0", "angel_wings_1", "angel_wings_2", "angel_wings_3"]:
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
    check(not SpriteManifest.DATA["fx_slash"]["anims"]["play"]["loop"], "golpe toca uma vez")

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
    check(AngelSprite.idle_pose_for(0) == "idle" and AngelSprite.idle_pose_for(2) == "glow_1" and AngelSprite.idle_pose_for(6) == "glow_2", "brilho das asas muda a pose parada")

func test_fire_frames_only_with_death_of_hell() -> void:
    var normal: Array = []
    for anim in ["idle", "attack", "cast"]:
        for t in [0.0, 0.05, 0.12, 0.2, 0.4, 0.9]:
            normal.append(AngelSprite.pose_for(anim, t, false, "glow_2", 1.0))
    for p in normal:
        check(not str(p).begins_with("hell"), "sem a Morte do Inferno nunca usa quadro de fogo (%s)" % p)
    check(AngelSprite.pose_for("attack", 0.0, false, "idle", 1.0) == "attack_1" and AngelSprite.pose_for("attack", 0.15, false, "idle", 1.0) == "attack_2", "ataque normal: 2 quadros")
    check(AngelSprite.pose_for("attack", 0.0, true, "idle", 1.0) == "hell_attack", "Morte do Inferno: ataque enfeitado")
    var idle_hell := {}
    for t in [0.0, 0.1, 0.2, 0.3]:
        idle_hell[AngelSprite.pose_for("idle", t, true, "idle", 1.0)] = true
    check(idle_hell.has("hell_1") and idle_hell.has("hell_2") and idle_hell.size() == 2, "Morte do Inferno: parado alterna os 2 quadros com fogo")
    check(AngelSprite.pose_for("cast", 0.0, true, "idle", 1.0) == "hell_cast", "Morte do Inferno: conjuração com fogo")
    var a := AngelSprite.new()
    a.set_hell(true)
    a.attack()
    check(a.is_hell() and a.current_pose() == "hell_attack", "sprite no modo inferno")
    a.set_hell(false)
    check(a.current_pose() == "attack_1", "acabou a habilidade: volta ao normal")
    a.free()

func test_art_license_notice_exists() -> void:
    check(FileAccess.file_exists("res://assets/LICENSE.txt"), "aviso de licença da arte")
