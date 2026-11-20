extends TestCase
## Arte nova dos mobs (assets/mobs): todo mob comum/especial tem folha com andar e morte, e tamanho parecido com o antigo.

func test_every_mob_type_has_new_art() -> void:
    for t in EnemiesDB.TYPES:
        var sp: String = str(t["sprite"])
        check(MobArt.has(sp), "mob %s tem arte nova" % sp)
        var sf: SpriteFrames = MobArt.frames(sp)
        check(sf != null and sf.has_animation("walk") and sf.get_frame_count("walk") >= 4, "%s: andar com 4+ quadros" % sp)
        check(sf != null and sf.has_animation("die"), "%s: animação de morte" % sp)
        var tex: Texture2D = load(MobArt.DIR + sp + ".png")
        var cell: Vector2i = MobArt.SHEETS[sp]["cell"]
        var total := 0
        for a in MobArt.SHEETS[sp]["anims"]:
            total += MobArt.SHEETS[sp]["anims"][a].size()
        check(tex.get_width() == cell.x * total and tex.get_height() == cell.y, "%s: folha bate com o tamanho do quadro" % sp)

func test_mob_size_on_screen() -> void:
    for sp in MobArt.SHEETS:
        var h: float = float(MobArt.SHEETS[sp]["walk_h"]) * MobArt.scale_for(sp, EnemiesDB.SPRITE_SCALE)
        check(h > 40.0 and h < 80.0, "%s: altura na tela razoável (%d px)" % [sp, int(h)])
        var hm: float = float(MobArt.SHEETS[sp]["walk_h"]) * MobArt.scale_for(sp, Balance.MINI_SCALE)
        check(hm > h * 1.3, "%s: mini-chefe maior que o mob comum" % sp)

func test_specials_have_cast_pose_and_bosses_keep_old_art() -> void:
    for sp in ["caster", "leech"]:
        check(MobArt.frames(sp).has_animation("cast"), "%s: pose de conjuração" % sp)
    for b in EnemiesDB.BOSSES:
        check(not MobArt.has(str(b["sprite"])), "chefe %s continua com a arte própria" % b["id"])

func test_death_animation_spawns_and_skips_unknown() -> void:
    var layer := Node2D.new()
    var d := MobArt.spawn_death(layer, Vector2(10, 20), {"sprite": "imp", "_flip": true})
    check(d != null and d.flip_h and d.animation == "die", "morte do diabinho no lugar certo, virado")
    check(MobArt.spawn_death(layer, Vector2.ZERO, {"sprite": "boss_baal"}) == null, "chefe: sem animação de morte nova")
    layer.free()
