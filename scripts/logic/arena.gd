class_name Arena
extends RefCounted
## MUNDO da partida: um mapa desenhado (ArenaMaps) ampliado por SCALE. A câmera segue o anjo.
## Onde dá para andar vem de uma GRADE (células de CELL px da imagem) montada ao trocar de mapa:
##   andável = dentro dos polígonos "walk", fora dos "block", e a cor da imagem NÃO é lava;
##   só vale o pedaço conectado ao ponto de partida (nada de "ilhas" soltas).
## O anjo nunca sai da área andável (slide); os mobs nascem NA LAVA perto da borda, do lado mais perto do anjo.

const IMAGE_SIZE := Vector2(2000.0, 1125.0)
const SCALE := 1.12
const WORLD := IMAGE_SIZE * SCALE      # 2240 x 1260
const CELL := 8.0                      # px da imagem por célula da grade
const PLAYER_MARGIN := 14.0            # o anjo fica a essa distância (mundo) da borda da área andável
const SPAWN_BAND := Vector2i(3, 70)    # mobs nascem na lava a 3..70 células da área andável (a mais perto do anjo é a escolhida)
const SPAWN_MIN_DIST := 220.0          # não nasce colado no anjo

static var _id := ""
static var _cols := 0
static var _rows := 0
static var _walk := PackedByteArray()  # 1 = andável
static var _lava := PackedByteArray()  # 1 = lava (pela cor)
static var _depth := PackedInt32Array()  # células até a borda (só nas andáveis)
static var _spawns: PackedVector2Array = PackedVector2Array()   # pontos (mundo) na lava para nascer
static var _start := Vector2.ZERO
static var _tex: Texture2D

# ---------------------------------------------------------------- troca de mapa
static func current() -> String:
    _ensure()
    return _id

static func texture() -> Texture2D:
    _ensure()
    return _tex

static func use_map(id: String) -> void:
    if id == _id or not ArenaMaps.MAPS.has(id):
        return
    _build(id)

static func _ensure() -> void:
    if _id == "":
        _build("gate")

static func is_lava_color(c: Color) -> bool:
    return c.r > 0.72 and c.g > 0.3 and c.b < 0.4 and c.r - c.b > 0.45

static func _in_any(p: Vector2, polys: Array) -> bool:
    for poly in polys:
        if Geometry2D.is_point_in_polygon(p, PackedVector2Array(poly)):
            return true
    return false

## Célula inteira (centro e os 4 cantos) dentro do contorno andável e fora de todos os objetos.
static func _cell_inside(ip: Vector2, walk: Array, block: Array) -> bool:
    var h := CELL * 0.5
    for o in [Vector2.ZERO, Vector2(-h, -h), Vector2(h, -h), Vector2(-h, h), Vector2(h, h)]:
        if not _in_any(ip + o, walk) or _in_any(ip + o, block):
            return false
    return true

static func _build(id: String) -> void:
    var m: Dictionary = ArenaMaps.MAPS[id]
    _id = id
    _tex = load(str(m["image"])) if ResourceLoader.exists(str(m["image"])) else null
    var img: Image = _tex.get_image() if _tex != null else null
    if img != null and img.is_compressed():
        img.decompress()
    _cols = int(ceil(IMAGE_SIZE.x / CELL))
    _rows = int(ceil(IMAGE_SIZE.y / CELL))
    var n := _cols * _rows
    _walk = PackedByteArray(); _walk.resize(n)
    _lava = PackedByteArray(); _lava.resize(n)
    var raw := PackedByteArray(); raw.resize(n)
    for r in _rows:
        for c in _cols:
            var ip := Vector2((c + 0.5) * CELL, (r + 0.5) * CELL)
            var i := r * _cols + c
            var lava := false
            if img != null:
                # 5 amostras por célula: se qualquer uma for lava, a célula é lava
                for o in [Vector2.ZERO, Vector2(-3, -3), Vector2(3, -3), Vector2(-3, 3), Vector2(3, 3)]:
                    var q: Vector2 = (ip + o).clamp(Vector2.ZERO, IMAGE_SIZE - Vector2.ONE)
                    if is_lava_color(img.get_pixelv(Vector2i(q))):
                        lava = true
                        break
            _lava[i] = 1 if lava else 0
            if not lava and _cell_inside(ip, m["walk"], m["block"]):
                raw[i] = 1
    # só a parte conectada ao ponto de partida
    var sc := _cell_of_img(m["start"])
    var q2: Array = [sc.y * _cols + sc.x]
    if raw[q2[0]] == 1:
        _walk[q2[0]] = 1
    while not q2.is_empty():
        var i: int = q2.pop_back()
        var cx := i % _cols
        for d in [-1, 1, -_cols, _cols]:
            var j: int = i + d
            if j < 0 or j >= n or (d == -1 and cx == 0) or (d == 1 and cx == _cols - 1):
                continue
            if raw[j] == 1 and _walk[j] == 0:
                _walk[j] = 1
                q2.append(j)
    # profundidade (células até a borda) e distância de fora até a área andável
    _depth = PackedInt32Array(); _depth.resize(n); _depth.fill(-1)
    var out_d := PackedInt32Array(); out_d.resize(n); out_d.fill(-1)
    var qa: Array = []
    var qb: Array = []
    for i in n:
        if _walk[i] == 0:
            _depth[i] = 0
            qa.append(i)
        else:
            out_d[i] = 0
            qb.append(i)
    _bfs(qa, _depth)
    _bfs(qb, out_d)
    _spawns = PackedVector2Array()
    for i in n:
        if _lava[i] == 1 and out_d[i] >= SPAWN_BAND.x and out_d[i] <= SPAWN_BAND.y:
            _spawns.append(_world_of_cell(i))
    _start = Vector2(m["start"]) * SCALE

static func _bfs(queue: Array, dist: PackedInt32Array) -> void:
    var head := 0
    var n := dist.size()
    while head < queue.size():
        var i: int = queue[head]
        head += 1
        var cx := i % _cols
        for d in [-1, 1, -_cols, _cols]:
            var j: int = i + d
            if j < 0 or j >= n or (d == -1 and cx == 0) or (d == 1 and cx == _cols - 1):
                continue
            if dist[j] == -1:
                dist[j] = dist[i] + 1
                queue.append(j)

static func _cell_of_img(ip: Vector2) -> Vector2i:
    return Vector2i(clampi(int(ip.x / CELL), 0, _cols - 1), clampi(int(ip.y / CELL), 0, _rows - 1))

static func _index(p: Vector2) -> int:
    var c := _cell_of_img(p / SCALE)
    return c.y * _cols + c.x

static func _world_of_cell(i: int) -> Vector2:
    return Vector2((i % _cols + 0.5) * CELL, (i / _cols + 0.5) * CELL) * SCALE

# ---------------------------------------------------------------- consultas (mundo)
static func world_rect() -> Rect2:
    return Rect2(Vector2.ZERO, WORLD)

static func center() -> Vector2:
    _ensure()
    return _start

static func start_point() -> Vector2:
    return center()

## Está numa célula andável a pelo menos `margin` px (mundo) da borda?
static func on_floor(p: Vector2, margin: float = 0.0) -> bool:
    _ensure()
    if not world_rect().has_point(p):
        return false
    var i := _index(p)
    return _walk[i] == 1 and float(_depth[i]) * CELL * SCALE >= margin

static func in_lava(p: Vector2) -> bool:
    _ensure()
    return world_rect().has_point(p) and _lava[_index(p)] == 1

static func clamp_world(p: Vector2, margin: float = 20.0) -> Vector2:
    var w := world_rect().grow(-margin)
    return p.clamp(w.position, w.end)

## Ponto andável mais próximo (o próprio ponto se já for).
static func clamp_floor(p: Vector2, margin: float = PLAYER_MARGIN) -> Vector2:
    _ensure()
    if on_floor(p, margin):
        return p
    var c0 := _cell_of_img(clamp_world(p, 1.0) / SCALE)
    var need := int(ceil(margin / (CELL * SCALE)))
    for rad in range(1, maxi(_cols, _rows)):
        var best := -1
        var best_d := INF
        for dy in range(-rad, rad + 1):
            for dx in [-rad, rad] if absi(dy) != rad else range(-rad, rad + 1):
                var cx: int = c0.x + dx
                var cy: int = c0.y + dy
                if cx < 0 or cy < 0 or cx >= _cols or cy >= _rows:
                    continue
                var i := cy * _cols + cx
                if _walk[i] == 1 and _depth[i] >= need:
                    var dd: float = _world_of_cell(i).distance_squared_to(p)
                    if dd < best_d:
                        best_d = dd
                        best = i
        if best >= 0:
            return _world_of_cell(best)
    return _start

## Movimento do anjo: vai até `to` se puder; senão desliza num eixo; senão fica onde está.
static func slide(from: Vector2, to: Vector2, margin: float = PLAYER_MARGIN) -> Vector2:
    if on_floor(to, margin):
        return to
    if not on_floor(from, margin):
        return clamp_floor(from, margin)
    var a := Vector2(to.x, from.y)
    if a != from and on_floor(a, margin):
        return a
    var b := Vector2(from.x, to.y)
    if b != from and on_floor(b, margin):
        return b
    # parede inclinada: tenta escorregar na diagonal ao longo dela (mesma velocidade)
    var step := to - from
    var len := step.length()
    if len > 0.0:
        for ang in [0.6, -0.6, 1.1, -1.1]:
            var t: Vector2 = from + step.rotated(ang) * 0.9
            if on_floor(t, margin):
                return t
        # quina/degrau no contorno: anda e afasta um pouco da parede (perpendicular), o mínimo necessário
        var side := Vector2(-step.y, step.x).normalized()
        var push := maxf(len, 2.0)
        for k in [1.0, 2.0, 3.0, 4.0, 5.0]:
            for sgn in [1.0, -1.0]:
                var t2: Vector2 = to + side * sgn * push * k
                if on_floor(t2, margin):
                    return t2
    return from

## Ponto NA LAVA de onde um mob nasce, perto da borda e do lado mais perto do anjo.
static func lava_spawn(near: Vector2, rng: RandomNumberGenerator) -> Vector2:
    _ensure()
    if _spawns.is_empty():
        return clamp_world(near + Vector2.from_angle(rng.randf() * TAU) * 700.0, 10.0)
    var cands: Array = []
    for k in 18:
        cands.append(_spawns[rng.randi_range(0, _spawns.size() - 1)])
    var far: Array = cands.filter(func(q: Vector2) -> bool: return q.distance_to(near) >= SPAWN_MIN_DIST)
    if not far.is_empty():
        cands = far
    cands.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_to(near) < b.distance_to(near))
    return cands[rng.randi_range(0, mini(3, cands.size() - 1))]

## Para testes/ferramentas.
static func spawn_points() -> PackedVector2Array:
    _ensure()
    return _spawns

static func walkable_cells() -> int:
    _ensure()
    var k := 0
    for v in _walk:
        k += v
    return k

static func cell_size_world() -> float:
    return CELL * SCALE
