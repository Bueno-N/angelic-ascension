extends Node
## Dono do estado persistente em runtime. UI e combate leem daqui e pedem compras por aqui.

var state: Dictionary = {}
var stats: Dictionary = {}
var rng := RandomNumberGenerator.new()
var session_start_msec := 0
var session_gems := 0

func _ready() -> void:
    rng.randomize()
    session_start_msec = Time.get_ticks_msec()
    state = SaveManager.load_state()
    stats = StatsCalc.compute(state)
    Events.enemy_died.connect(_on_enemy_died)
    var t := Timer.new()
    t.wait_time = Balance.AUTOSAVE_SECONDS
    t.autostart = true
    t.timeout.connect(save)
    add_child(t)

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST \
            or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
        save()

func save() -> void:
    SaveManager.save_state(state)

func recalc() -> void:
    stats = StatsCalc.compute(state)
    Events.state_changed.emit()

func _commit(ok: bool) -> bool:
    if ok:
        recalc()
        save()
    return ok

func buy_upgrade(attr: String) -> bool:
    return _commit(Shop.buy_upgrade(state, attr))

func buy_equipment(cat: String, tier: int) -> bool:
    return _commit(Shop.buy_equipment(state, cat, tier))

func equip_equipment(cat: String, tier: int) -> bool:
    return _commit(Shop.equip_equipment(state, cat, tier))

func evolve_wings() -> bool:
    return _commit(Shop.evolve_wings(state))

func buy_glow(tier: int) -> bool:
    return _commit(Shop.buy_glow(state, tier))

func buy_skill(id: String) -> bool:
    return _commit(Shop.buy_skill(state, id))

func equip_skill(id: String) -> bool:
    return _commit(Shop.equip_skill(state, id))

func unequip_skill(id: String) -> bool:
    return _commit(Shop.unequip_skill(state, id))

func session_gems_per_hour() -> float:
    return UiLogic.gems_per_hour(session_gems, float(Time.get_ticks_msec() - session_start_msec) / 1000.0)

func toggle_auto_skills() -> void:
    state["settings"]["auto_skills"] = not bool(state["settings"].get("auto_skills", true))
    save()
    Events.state_changed.emit()

## Ações do modo de teste (ignoradas fora de builds de debug).
func debug_apply(action: String, arg: int) -> void:
    if not DebugTools.enabled():
        return
    match action:
        "gold", "gems", "shards":
            DebugTools.add(state, action, arg)
        "unlock_all":
            DebugTools.unlock_all(state)
        "stage":
            Events.debug_goto_stage.emit(maxi(1, arg))
        "stage_add":
            Events.debug_goto_stage.emit(maxi(1, int(state["stage"]) + arg))
        "heal":
            Events.debug_heal.emit()
        "cooldowns":
            Events.debug_reset_cooldowns.emit()
        "reset":
            state = SaveData.default_state()
            Events.debug_goto_stage.emit(1)
            Events.debug_heal.emit()
    recalc()
    save()

func set_stage(stage: int) -> void:
    state["stage"] = stage
    state["max_stage"] = maxi(int(state["max_stage"]), stage)

func _on_enemy_died(_pos: Vector2, def: Dictionary, is_boss: bool, gold: int) -> void:
    var stage: int = int(state["stage"])
    state["gold"] = int(state["gold"]) + gold
    if is_boss:
        var g: int = StageLogic.boss_gems(stage, rng)
        var sh: int = StageLogic.boss_shards(stage)
        state["gems"] = int(state["gems"]) + g
        session_gems += g
        state["shards"] = int(state["shards"]) + sh
        Events.boss_defeated.emit(stage, g, sh)
        save()
    else:
        var dg: int = DropLogic.roll_gems(def, rng)
        state["gems"] = int(state["gems"]) + dg
        session_gems += dg
    Events.state_changed.emit()
