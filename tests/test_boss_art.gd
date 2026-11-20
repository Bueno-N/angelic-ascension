extends TestCase
## Arte nova dos chefes (BossArt): quadros, animações das habilidades e morte.

func test_baal_frames_load_and_match_cell() -> void:
    check(BossArt.has("boss_baal"), "Baal tem arte nova")
    check(not BossArt.has("boss_mordath"), "Mordath ainda usa a folha antiga")
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
    check(BossArt.ability_anim("boss_mordath", "summon_demons", 0) == "", "chefe sem arte nova: pose padrão")

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
