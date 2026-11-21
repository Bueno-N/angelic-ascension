extends TestCase
## Arte nova dos chefes (BossArt): quadros, animações das habilidades e morte.

func test_baal_frames_load_and_match_cell() -> void:
    check(BossArt.has("boss_baal"), "Baal tem arte nova")
    check(not BossArt.has("boss_ignarr"), "Ignarr ainda usa a folha antiga")
    var m: Dictionary = BossArt.SHEETS["boss_baal"]
    var sf := BossArt.frames("boss_baal")
    check(sf != null, "SpriteFrames do Baal")
    for anim in m["anims"]:
        check(sf.has_animation(anim) and sf.get_frame_count(anim) == m["anims"][anim].size(), "Baal/%s: quadros" % anim)
        for i in sf.get_frame_count(anim):
            var t: Texture2D = sf.get_frame_texture(anim, i)
            check(t != null and t.get_size() == Vector2(m["cell"]), "Baal/%s/%d: mesmo tamanho de quadro (pés alinhados)" % [anim, i])
    check(sf.get_animation_loop("walk") and sf.get_animation_loop("dash"), "andar e correr em laço")
    check(not sf.get_animation_loop("slam_hit") and not sf.get_animation_loop("die") and not sf.get_animation_loop("attack"), "golpes e morte tocam uma vez")

func test_baal_ability_animations() -> void:
    for ab in EnemiesDB.BOSSES[0]["abilities"]:
        var wind := BossArt.ability_anim("boss_baal", ab, 0)
        var hit := BossArt.ability_anim("boss_baal", ab, 1)
        check(wind != "" and hit != "", "Baal: %s tem aviso e golpe animados" % ab)
        check(BossArt.frames("boss_baal").has_animation(wind) and BossArt.frames("boss_baal").has_animation(hit), "Baal: animações de %s existem" % ab)
    check(BossArt.ability_anim("boss_baal", "meteor_rain", 0) == "", "habilidade sem arte: usa a pose padrão")
    check(BossArt.ability_anim("boss_ignarr", "meteor_rain", 0) == "", "chefe sem arte nova: pose padrão")

func test_baal_size_and_death() -> void:
    var s := BossArt.make("boss_baal", EnemiesDB.SPRITE_SCALE)
    var h: float = float(BossArt.SHEETS["boss_baal"]["walk_h"]) * s.scale.y
    check(absf(h - BossArt.BASE_HEIGHT) < 0.5, "Baal com ~%d px de altura andando" % int(BossArt.BASE_HEIGHT))
    check(s.animation == "walk", "começa andando")
    s.free()
    var layer := Node2D.new()
    var d := BossArt.spawn_death(layer, Vector2(10, 20), {"sprite": "boss_baal", "_flip": true})
    check(d != null and d.animation == "die" and d.flip_h and d.position == Vector2(10, 20), "animação de morte do Baal no lugar dele")
    check(BossArt.spawn_death(layer, Vector2.ZERO, {"sprite": "boss_ignarr"}) == null, "chefe sem arte nova: sem animação de morte")
    layer.free()

func test_mordath_frames_and_abilities() -> void:
    check(BossArt.has("boss_mordath"), "Mordath tem arte nova")
    var m: Dictionary = BossArt.SHEETS["boss_mordath"]
    var sf := BossArt.frames("boss_mordath")
    for anim in m["anims"]:
        check(sf.has_animation(anim) and sf.get_frame_count(anim) == m["anims"][anim].size(), "Mordath/%s: quadros" % anim)
        for i in sf.get_frame_count(anim):
            var t: Texture2D = sf.get_frame_texture(anim, i)
            check(t != null and t.get_size() == Vector2(m["cell"]), "Mordath/%s/%d: mesmo tamanho de quadro" % [anim, i])
    check(sf.get_frame_count("summon_wind") + sf.get_frame_count("summon_hit") == 3, "invocação usa só os 3 primeiros quadros")
    for ab in EnemiesDB.BOSSES[1]["abilities"]:
        check(BossArt.ability_anim("boss_mordath", ab, 0) != "" and BossArt.ability_anim("boss_mordath", ab, 1) != "", "Mordath: %s animada" % ab)
    var hr := BossArt.hand_offset("boss_mordath", EnemiesDB.SPRITE_SCALE, false)
    var hl := BossArt.hand_offset("boss_mordath", EnemiesDB.SPRITE_SCALE, true)
    check(hr.x > 0.0 and is_equal_approx(hl.x, -hr.x) and hr.y < 0.0, "mão à frente e acima do centro, espelhada ao virar")
    check(BossArt.hand_offset("boss_baal", 2.0, false) == Vector2.ZERO, "chefe sem mão marcada: sai do centro")

func test_mordath_fireball_and_portal() -> void:
    check(BossFx.has_fireball("mordath") and not BossFx.has_fireball("baal"), "só o Mordath tem bola de fogo desenhada")
    for f in BossFx.FIREBALL_FRAMES + BossFx.PORTAL_FRAMES + ["boom", "smoke"]:
        check(BossFx.tex("mordath", f) != null, "Mordath fx: %s" % f)
    var parent := Node2D.new()
    var p := EnemyProjectile.new()
    p.art = "mordath"
    p.velocity = Vector2(0.0, 200.0)
    parent.add_child(p)
    p._ready()
    check(p._spr is AnimatedSprite2D and p._spr.sprite_frames.has_animation("fly"), "projétil do Mordath usa a bola desenhada")
    check(absf(p._spr.rotation - (PI / 2.0 - BossFx.FIREBALL_NATIVE_ANGLE)) < 0.01, "bola girada para a direção do voo")
    p.life = 0.0
    p._process(0.01)
    var exploded := false
    for c in parent.get_children():
        if c != p and c is Node2D and c.get_child_count() > 0 and c.get_child(0) is Sprite2D:
            exploded = true
    check(exploded, "a bola explode ao sumir")
    var por := BossFx.portal(parent, Vector2(5, 5), "mordath")
    check(por.texture == BossFx.tex("mordath", "portal_0") and por.z_index < 0, "portal abre no chão, atrás dos demônios")
    parent.free()

func test_mordath_ranged_basic_attack() -> void:
    check(str(EnemiesDB.BOSSES[1].get("basic", "")) == "ranged_orb", "Mordath: golpe básico à distância")
    for b in [EnemiesDB.BOSSES[0], EnemiesDB.BOSSES[2], EnemiesDB.BOSSES[3]]:
        check(not b.has("basic"), "%s continua corpo a corpo" % b["id"])
    var c: Dictionary = EnemiesDB.BASIC_ATTACKS["ranged_orb"]
    for k in ["range", "hold", "cooldown", "speed", "dmg_mult", "hit_radius"]:
        check(c.has(k), "golpe à distância tem %s" % k)
    check(float(c["hold"]) < float(c["range"]), "fica dentro do alcance para conseguir atirar")
    check(float(c["cooldown"]) >= 1.0, "1 bola por vez, sem metralhar")
    check(BossArt.SHEETS["boss_mordath"]["anims"]["attack"][0] == "cast_3", "animação do golpe: braço estendido")
