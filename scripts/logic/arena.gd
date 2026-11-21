class_name Arena
extends RefCounted
## Tamanho do MUNDO da partida (maior que a tela; a câmera segue o anjo).
## O chão de pedra fica no meio; em volta há uma faixa de LAVA que delimita o mapa:
## o anjo nunca entra na lava, e os mobs nascem nela (do lado mais perto do anjo) e caminham até o chão.

const WORLD := Vector2(2240.0, 1260.0)
const LAVA := 210.0                  # largura da faixa de lava em volta do chão
const PLAYER_MARGIN := 34.0          # o anjo fica a essa distância da beira da lava
const SPAWN_DEPTH := Vector2(40.0, 150.0)   # quão dentro da lava o mob nasce (a partir da beira do chão)
const SPAWN_MIN_DIST := 220.0        # não nasce colado no anjo

static func world_rect() -> Rect2:
    return Rect2(Vector2.ZERO, WORLD)

static func floor_rect() -> Rect2:
    return Rect2(Vector2(LAVA, LAVA), WORLD - Vector2(LAVA, LAVA) * 2.0)

static func center() -> Vector2:
    return WORLD / 2.0

## Ponto mais próximo dentro do chão, a `margin` px da lava.
static func clamp_floor(p: Vector2, margin: float = PLAYER_MARGIN) -> Vector2:
    var f := floor_rect().grow(-margin)
    return p.clamp(f.position, f.end)

static func on_floor(p: Vector2, margin: float = 0.0) -> bool:
    return floor_rect().grow(-margin).has_point(p)

static func clamp_world(p: Vector2, margin: float = 20.0) -> Vector2:
    var w := world_rect().grow(-margin)
    return p.clamp(w.position, w.end)

## Ponto NA LAVA de onde um mob nasce: sorteia vários pontos na faixa e fica com um dos mais próximos do anjo
## (se o anjo está perto da lava, eles saem dali; se está no meio, saem da beira mais próxima).
static func lava_spawn(near: Vector2, rng: RandomNumberGenerator) -> Vector2:
    var f := floor_rect()
    var cands: Array = []
    for i in 14:
        var side := rng.randi_range(0, 3)
        var depth := rng.randf_range(SPAWN_DEPTH.x, SPAWN_DEPTH.y)
        var p := Vector2.ZERO
        match side:
            0: p = Vector2(rng.randf_range(f.position.x, f.end.x), f.position.y - depth)
            1: p = Vector2(rng.randf_range(f.position.x, f.end.x), f.end.y + depth)
            2: p = Vector2(f.position.x - depth, rng.randf_range(f.position.y, f.end.y))
            _: p = Vector2(f.end.x + depth, rng.randf_range(f.position.y, f.end.y))
        cands.append(p)
    var far: Array = cands.filter(func(q: Vector2) -> bool: return q.distance_to(near) >= SPAWN_MIN_DIST)
    if not far.is_empty():
        cands = far
    cands.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_to(near) < b.distance_to(near))
    return cands[rng.randi_range(0, mini(3, cands.size() - 1))]

static func in_lava(p: Vector2) -> bool:
    return world_rect().has_point(p) and not floor_rect().has_point(p)
