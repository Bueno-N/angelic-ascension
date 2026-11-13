class_name DebugTools
extends RefCounted
## Ferramentas de teste (lógica pura). Só ficam ativas se Balance.DEBUG_TOOLS = true E o build for de debug
## (templates de release retornam false em OS.is_debug_build(), então somem sozinhas no APK final).

static func enabled() -> bool:
    return Balance.DEBUG_TOOLS and OS.is_debug_build()

## key: "gold", "gems" ou "shards".
static func add(state: Dictionary, key: String, amount: int) -> void:
    if key == "gold" or key == "gems" or key == "shards":
        state[key] = maxi(0, int(state[key]) + amount)

## Compra tudo de graça: todas as habilidades, equipamentos (equipa o melhor), asas e brilho no máximo.
static func unlock_all(state: Dictionary) -> void:
    for id in SkillsDB.ids():
        if not state["skills_owned"].has(id):
            state["skills_owned"].append(id)
    for id in state["skills_owned"]:
        if state["skills_equipped"].size() >= SkillsDB.MAX_EQUIPPED:
            break
        if not state["skills_equipped"].has(id):
            state["skills_equipped"].append(id)
    for cat in EquipmentDB.CATEGORIES:
        for tier in range(1, EquipmentDB.TIER_COUNT + 1):
            if not state["owned_equipment"][cat].has(tier):
                state["owned_equipment"][cat].append(tier)
        state["equipped"][cat] = EquipmentDB.TIER_COUNT
    state["wings_level"] = WingsDB.MAX_LEVEL
    state["glow_tier"] = WingsDB.GLOW.size()
