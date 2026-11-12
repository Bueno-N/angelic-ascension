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
