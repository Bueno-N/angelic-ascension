class_name SkillSlots
extends RefCounted
## Cooldowns e uso de habilidades equipadas (lógica pura; efeitos visuais ficam no runtime).

var equipped: Array = []
var cooldowns := {}

func load_from_state(state: Dictionary) -> void:
    equipped = state["skills_equipped"].duplicate()
    cooldowns.clear()
    for id in equipped:
        cooldowns[id] = 0.0

## Atualiza os slots mantendo as recargas das que continuam equipadas.
## Habilidade recém-equipada começa com SkillsDB.EQUIP_DELAY de recarga.
func sync(state: Dictionary) -> void:
    var new_eq: Array = state["skills_equipped"].duplicate()
    var new_cd := {}
    for id in new_eq:
        new_cd[id] = float(cooldowns[id]) if cooldowns.has(id) else SkillsDB.EQUIP_DELAY
    equipped = new_eq
    cooldowns = new_cd

func reset_cooldowns() -> void:
    for id in cooldowns.keys():
        cooldowns[id] = 0.0

func tick(delta: float) -> void:
    for id in cooldowns.keys():
        cooldowns[id] = maxf(0.0, float(cooldowns[id]) - delta)

func can_use(id: String) -> bool:
    return equipped.has(id) and float(cooldowns.get(id, 0.0)) <= 0.0

func use(id: String) -> bool:
    if not can_use(id):
        return false
    cooldowns[id] = float(SkillsDB.get_skill(id)["cooldown"])
    return true

func remaining(id: String) -> float:
    return float(cooldowns.get(id, 0.0))
