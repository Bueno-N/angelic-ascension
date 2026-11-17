class_name SlotLogic
extends RefCounted
## Regras puras da tela inicial: resumo de um jogo salvo e validação do nome.

const MAX_SLOTS := 2

## O nome é obrigatório e só vale com ao menos 1 caractere que a fonte desenha.
static func name_valid(text: String) -> bool:
    var kept := ""
    for i in range(text.length()):
        if SpriteManifest.FONT_CHARS.contains(text[i]):
            kept += text[i]
    return kept.strip_edges() != ""

static func clean_new_name(text: String) -> String:
    return ProfileLogic.clean_name(text)

## state vazio ({}) = espaço vazio.
static func summary(slot: int, state: Dictionary) -> Dictionary:
    if state.is_empty():
        return {"slot": slot, "exists": false, "name": "Vazio", "avatar": 0, "stage": 0, "max_stage": 0, "wings": 0,
            "text1": "Nenhum jogo salvo", "text2": ""}
    var nm: String = str(state["profile"]["name"])
    var stg: int = int(state["stage"])
    var mx: int = int(state["max_stage"])
    return {"slot": slot, "exists": true, "name": nm, "avatar": int(state["profile"]["avatar"]), "stage": stg,
        "max_stage": mx, "wings": int(state["wings_level"]),
        "text1": "Fase %d  (recorde %d)" % [stg, mx],
        "text2": "Asas Nv %d  |  Habilidades %d" % [int(state["wings_level"]), state["skills_owned"].size()]}
