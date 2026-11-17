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

func test_art_license_notice_exists() -> void:
    check(FileAccess.file_exists("res://assets/LICENSE.txt"), "aviso de licença da arte")
