class_name BuffState
extends RefCounted
## Buffs temporários do anjo (lógica pura). Mesmo id = renova (não empilha).

var _buffs := {}   # id -> {"t": segundos restantes, "mods": {atributo: bônus}, "absorb": fração}

func add(id: String, duration: float, mods: Dictionary, absorb: float = 0.0) -> void:
    _buffs[id] = {"t": duration, "mods": mods, "absorb": absorb}

func tick(delta: float) -> void:
    for id in _buffs.keys():
        _buffs[id]["t"] = float(_buffs[id]["t"]) - delta
        if float(_buffs[id]["t"]) <= 0.0:
            _buffs.erase(id)

## Multiplicador do atributo: 1 + soma dos bônus ativos. "all" vale para todos exceto "hp".
func multiplier(stat: String) -> float:
    var m := 1.0
    for b in _buffs.values():
        m += float(b["mods"].get(stat, 0.0))
        if stat != "hp":
            m += float(b["mods"].get("all", 0.0))
    return m

func absorb() -> float:
    var a := 0.0
    for b in _buffs.values():
        a += float(b["absorb"])
    return minf(SkillsDB.ABSORB_CAP, a)

func is_active(id: String) -> bool:
    return _buffs.has(id)

func remaining(id: String) -> float:
    return float(_buffs[id]["t"]) if _buffs.has(id) else 0.0

func clear() -> void:
    _buffs.clear()
