class_name AbilityCooldowns
extends RefCounted
## Recargas das habilidades de UM inimigo (lógica pura). A ordem da lista define a prioridade.

var _cd := {}

func setup(ids: Array, config: Dictionary, initial_fraction: float) -> void:
    _cd.clear()
    for id in ids:
        _cd[id] = float(config[id]["cooldown"]) * initial_fraction

func tick(delta: float) -> void:
    for id in _cd.keys():
        _cd[id] = maxf(0.0, float(_cd[id]) - delta)

func next_ready(config: Dictionary, dist: float) -> String:
    for id in _cd.keys():
        if float(_cd[id]) <= 0.0 and in_range(config[id], dist):
            return id
    return ""

func start(id: String, config: Dictionary) -> void:
    _cd[id] = float(config[id]["cooldown"])

func remaining(id: String) -> float:
    return float(_cd.get(id, 0.0))

func is_empty() -> bool:
    return _cd.is_empty()

static func in_range(cfg: Dictionary, dist: float) -> bool:
    return dist >= float(cfg["min_range"]) and dist <= float(cfg["max_range"])
