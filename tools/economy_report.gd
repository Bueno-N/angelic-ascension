extends SceneTree
## Projeção (NÃO medição) do tempo para comprar cada habilidade, segundo o modelo em Balance.
## Uso: godot --headless --path . --script res://tools/economy_report.gd

func _initialize() -> void:
    print("Modelo: fase(h) = %.1f * h^%.2f | %.1f h/dia | crescimento gemas/chefe x%.2f" % [
        Balance.MODEL_STAGES_PER_HOUR, Balance.MODEL_PACE_EXPONENT, Balance.MODEL_HOURS_PER_DAY, Balance.BOSS_GEM_GROWTH])
    for s in SkillsDB.SKILLS:
        var r := EconomyModel.time_to_accumulate(float(s["price"]))
        if r.is_empty():
            print("%-26s %9d gemas -> fora do alcance do modelo" % [s["name"], int(s["price"])])
        else:
            var h: float = float(r["hours"])
            var farm: String = "  (repetindo a fase %d)" % int(r["stage"]) if bool(r.get("farming", false)) else ""
            print("%-26s %9d gemas -> fase %5d | %9.1f h | %8.1f dias%s" % [s["name"], int(s["price"]), int(r["stage"]), h, h / Balance.MODEL_HOURS_PER_DAY, farm])
    quit(0)
