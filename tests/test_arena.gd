extends TestCase
## Mundo maior que a tela: chão no meio, lava em volta, anjo nunca na lava, mobs nascendo da lava perto do anjo.

func test_world_bigger_than_screen() -> void:
    var f := Arena.floor_rect()
    check(Arena.WORLD.x > 1280.0 * 1.5 and Arena.WORLD.y > 720.0 * 1.5, "mundo bem maior que a tela")
    check(f.size.x > 1280.0 and f.size.y > 720.0, "chão jogável maior que a tela")
    check(Arena.world_rect().encloses(f) and f.position.x == Arena.LAVA, "lava em volta do chão")

func test_player_never_on_lava() -> void:
    for p in [Vector2(-500, -500), Vector2(5000, 300), Vector2(100, 2000), Vector2(Arena.LAVA + 1.0, Arena.LAVA + 1.0)]:
        var q := Arena.clamp_floor(p)
        check(Arena.on_floor(q, Arena.PLAYER_MARGIN - 0.01), "ponto %s vira %s, fora da lava" % [p, q])
    check(Arena.clamp_floor(Arena.center()) == Arena.center(), "no meio do chão não mexe")

func test_mobs_spawn_from_lava_near_angel() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 7
    var f := Arena.floor_rect()
    var near_left := Vector2(f.position.x + 60.0, Arena.center().y)
    var left := 0
    for i in 60:
        var p := Arena.lava_spawn(near_left, rng)
        check(Arena.in_lava(p), "nasce na lava")
        check(p.distance_to(near_left) >= Arena.SPAWN_MIN_DIST - 0.01, "não nasce colado no anjo")
        if p.x < f.position.x:
            left += 1
    check(left >= 30, "anjo perto da lava da esquerda: a maioria sai de lá (%d/60)" % left)
    var mid := Arena.center()
    for i in 20:
        check(Arena.in_lava(Arena.lava_spawn(mid, rng)), "anjo no meio: ainda nasce na lava")

func test_boss_pointer_edge() -> void:
    var r := Rect2(0, 0, 100, 50)
    check(BossPointer.edge_point(r, Vector2(500, 25)) == Vector2(100, 25), "chefe à direita: seta na borda direita")
    check(BossPointer.edge_point(r, Vector2(50, -300)).y == 0.0, "chefe em cima: seta na borda de cima")
    check(BossPointer.edge_point(r, Vector2(60, 30)) == Vector2(60, 30), "dentro do retângulo: o próprio ponto")
