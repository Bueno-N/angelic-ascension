extends TestCase
## Mapas desenhados (ArenaMaps): o anjo nunca anda na lava nem atravessa objetos; mobs nascem na lava.

func test_maps_exist_and_rotate_by_stage() -> void:
    for id in ArenaMaps.ids():
        check(ResourceLoader.exists(str(ArenaMaps.MAPS[id]["image"])), "imagem do mapa %s" % id)
    check(ArenaMaps.for_stage(10) == "forge" and ArenaMaps.for_stage(300) == "forge", "fases de chefe na forja")
    check(ArenaMaps.for_stage(1, true) == "forge", "boss semanal na forja")
    check(ArenaMaps.for_stage(3) == "gate" and ArenaMaps.for_stage(13) == "graveyard" and ArenaMaps.for_stage(23) == "gate", "portão/cemitério alternam a cada 10 fases")
    check(Arena.WORLD.x > 1280.0 * 1.5 and Arena.WORLD.y > 720.0 * 1.5, "mundo maior que a tela")

func test_walkable_never_lava_or_block() -> void:
    for id in ArenaMaps.ids():
        Arena.use_map(id)
        var m: Dictionary = ArenaMaps.MAPS[id]
        var img: Image = Arena.texture().get_image()
        if img.is_compressed():
            img.decompress()
        check(Arena.walkable_cells() > 4000, "%s: área andável grande" % id)
        check(Arena.on_floor(Arena.start_point(), Arena.PLAYER_MARGIN), "%s: ponto de partida andável" % id)
        var bad_lava := 0
        var bad_block := 0
        var bad_out := 0
        for y in range(4, 1125, 6):
            for x in range(4, 2000, 6):
                var ip := Vector2(x, y)
                if not Arena.on_floor(ip * Arena.SCALE, 0.0):
                    continue
                if Arena.is_lava_color(img.get_pixel(x, y)):
                    bad_lava += 1
                for b in m["block"]:
                    if Geometry2D.is_point_in_polygon(ip, PackedVector2Array(b)):
                        bad_block += 1
                var inside := false
                for w in m["walk"]:
                    if Geometry2D.is_point_in_polygon(ip, PackedVector2Array(w)):
                        inside = true
                if not inside:
                    bad_out += 1
        check(bad_lava <= 6, "%s: andável quase sem pixel de lava (%d, só bordas de célula)" % [id, bad_lava])
        check(bad_block <= 6 and bad_out <= 6, "%s: andável fora de objetos (%d) e dentro do contorno (%d)" % [id, bad_block, bad_out])
    Arena.use_map("gate")

func test_angel_cannot_leave_walkable() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 11
    for id in ArenaMaps.ids():
        Arena.use_map(id)
        var p := Arena.start_point()
        var outside := 0
        for i in 6000:   # passeio aleatório forçando as bordas
            var dir := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(4.0, 14.0)
            p = Arena.slide(p, p + dir)
            if not Arena.on_floor(p, Arena.PLAYER_MARGIN - 0.01):
                outside += 1
        check(outside == 0, "%s: anjo nunca sai da área andável (%d)" % [id, outside])
        for far in [Vector2(-500, -500), Vector2(5000, 300), Vector2(100, 2000)]:
            check(Arena.on_floor(Arena.clamp_floor(far), Arena.PLAYER_MARGIN - 0.01), "%s: ponto fora volta para o chão" % id)
    Arena.use_map("gate")

func test_mobs_spawn_from_lava() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 7
    for id in ArenaMaps.ids():
        Arena.use_map(id)
        check(Arena.spawn_points().size() > 200, "%s: vários pontos de nascimento na lava" % id)
        for i in 30:
            var p := Arena.lava_spawn(Arena.start_point(), rng)
            check(Arena.in_lava(p) and not Arena.on_floor(p), "%s: nasce na lava" % id)
    Arena.use_map("gate")

func test_boss_pointer_edge() -> void:
    var r := Rect2(0, 0, 100, 50)
    check(BossPointer.edge_point(r, Vector2(500, 25)) == Vector2(100, 25), "chefe à direita: seta na borda direita")
    check(BossPointer.edge_point(r, Vector2(50, -300)).y == 0.0, "chefe em cima: seta na borda de cima")
    check(BossPointer.edge_point(r, Vector2(60, 30)) == Vector2(60, 30), "dentro do retângulo: o próprio ponto")

func test_lava_portal_light_and_capped() -> void:
    check(LavaPortal.frames().get_frame_count("default") == LavaPortal.FRAMES, "portal: 12 quadros")
    check(LavaPortal.frames() == LavaPortal.frames(), "quadros carregados uma vez e compartilhados")
    var parent := Node2D.new()
    var root := Engine.get_main_loop() as SceneTree
    root.root.add_child(parent)
    LavaPortal.active = 0
    var mob := Node2D.new()
    parent.add_child(mob)
    var p := LavaPortal.open(parent, Vector2(10, 10), mob)
    check(p != null and p.sprite_frames == LavaPortal.frames() and mob.modulate.a == 0.0, "portal abre e o mob começa invisível")
    var made := 1
    for i in 20:
        if LavaPortal.open(parent, Vector2.ZERO, null) != null:
            made += 1
    check(made == LavaPortal.MAX_ACTIVE and LavaPortal.active == LavaPortal.MAX_ACTIVE, "no máximo %d portais ao mesmo tempo" % LavaPortal.MAX_ACTIVE)
    parent.free()
    check(LavaPortal.active == 0, "contagem volta a zero quando os portais saem")
