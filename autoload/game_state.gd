extends Node
## Dono do estado persistente em runtime. UI e combate leem daqui e pedem compras por aqui.

var state: Dictionary = {}
var stats: Dictionary = {}
var rng := RandomNumberGenerator.new()
var session_start_msec := 0
var session_gems := 0
const TITLE_SCENE := "res://scenes/title.tscn"
const GAME_SCENE := "res://scenes/main.tscn"
var slot := 0                      # espaço de salvamento em uso (1..2); 0 = nenhum (menu inicial / smoke: não grava)
var global_settings: Dictionary = OptionsLogic.default_global()   # volume e efeitos: valem para todos os jogos
var _global_known := false
var title_ok := false              # smoke: a tela inicial foi percorrida sem erro

func _ready() -> void:
    rng.randomize()
    session_start_msec = Time.get_ticks_msec()
    state = SaveData.default_state()   # o jogo real só carrega um espaço quando o jogador escolhe no menu inicial
    stats = StatsCalc.compute(state)
    var g: Dictionary = SaveManager.load_global()
    if not g.is_empty():
        global_settings = g
        _global_known = true
    apply_speed()
    apply_audio()
    if not OS.get_cmdline_user_args().has("--smoke"):
        Engine.max_fps = Balance.MAX_FPS
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
    if slot > 0:
        SaveManager.save_slot(slot, state)

## Começa um jogo NOVO no espaço `n` com o nome escolhido (sobrescreve o que houver lá).
func new_game(n: int, pname: String) -> bool:
    if not SlotStore.valid_slot(n):
        return false
    var st := SaveData.default_state()
    st["profile"]["name"] = ProfileLogic.clean_name(pname)
    _begin(st, n)
    return true

## Carrega o jogo salvo do espaço `n` (false se vazio).
func load_game(n: int) -> bool:
    var st: Dictionary = SaveManager.load_slot(n)
    if st.is_empty():
        return false
    _begin(st, n)
    return true

## Só para o smoke do CI: jogo novo SEM espaço (nada é gravado no disco).
func start_unsaved() -> void:
    _begin(SaveData.default_state(), 0)

func _begin(st: Dictionary, n: int) -> void:
    state = st
    slot = n
    if _global_known:
        OptionsLogic.copy_globals(global_settings, state["settings"])
    else:
        global_settings = OptionsLogic.sanitize_global(state["settings"])
    session_gems = 0
    session_start_msec = Time.get_ticks_msec()
    stats = StatsCalc.compute(state)
    apply_speed()
    apply_audio()
    save()

## Opção alterada no MENU INICIAL (sem jogo carregado): ações "opt|fx|0" e "opt|vol|±10".
func set_global_option(parts: PackedStringArray) -> bool:
    var changed := OptionsLogic.apply(global_settings, parts)
    if changed:
        _global_known = true
        SaveManager.save_global(global_settings)
        apply_audio()
        AudioHub.play("ui_click")   # dá para ouvir o efeito ao mexer nos volumes
    return changed

func go_to_title() -> void:
    save()
    slot = 0           # evita que um salvamento automático recrie um jogo apagado no menu inicial
    get_tree().paused = false
    Engine.time_scale = 1.0
    _drop_scene_connections()
    get_tree().change_scene_to_file.call_deferred(TITLE_SCENE)

## Remove as conexões do barramento Events feitas pela cena de jogo que vai ser descartada (só as do próprio GameState ficam).
func _drop_scene_connections() -> void:
    for sig in Events.get_signal_list():
        for c in Events.get_signal_connection_list(sig["name"]):
            var cb: Callable = c["callable"]
            if cb.get_object() != self and cb.get_object() != AudioHub:
                Events.disconnect(sig["name"], cb)

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
    if skill_remaining(id) > 0.0:
        return false   # trava: não dá para trocar habilidade em recarga
    return _commit(Shop.unequip_skill(state, id))

func session_gems_per_hour() -> float:
    return UiLogic.gems_per_hour(session_gems, float(Time.get_ticks_msec() - session_start_msec) / 1000.0)

func toggle_slot_auto(i: int) -> void:
    if Shop.toggle_slot_auto(state, i):
        save()
        Events.state_changed.emit()

func toggle_low_fx() -> void:
    state["settings"]["low_fx"] = not bool(state["settings"].get("low_fx", false))
    save()
    Events.state_changed.emit()

## Ações do menu (ver MenuModel): compra/equipa/evolui. Debug passa pelo debug_apply.
func menu_action(action: String) -> bool:
    if action == "opt|title|0":
        go_to_title()
        return true
    var p := action.split("|")
    if p[0] == "debug" and p.size() > 2:
        debug_apply(p[1], int(p[2]))
        return true
    if p[0] == "skill_unequip" and p.size() > 1 and skill_remaining(p[1]) > 0.0:
        return false   # trava: não dá para trocar habilidade em recarga
    var ok := _commit(MenuModel.perform(state, action))
    if ok:
        AudioHub.play("ui_buy" if ["attr", "skill_buy", "wings_evolve", "glow", "equip_buy"].has(p[0]) else "ui_click")
    if ok and p[0] == "opt":
        global_settings = OptionsLogic.sanitize_global(state["settings"])   # opções valem para todos os jogos
        _global_known = true
        SaveManager.save_global(global_settings)
        apply_audio()
    return ok

func set_profile(pname: String, avatar: int) -> void:
    state["profile"]["name"] = ProfileLogic.clean_name(pname)
    state["profile"]["avatar"] = clampi(avatar, 0, ProfileLogic.AVATAR_COUNT - 1)
    save()
    Events.state_changed.emit()

## Aplica as opções de som: volume geral (Master), música (liga/desliga + volume) e efeitos (volume).
func apply_audio() -> void:
    AudioLogic.apply_buses(global_settings)
    Events.audio_changed.emit()

func apply_speed() -> void:
    Engine.time_scale = UiLogic.time_scale(state["settings"])

func toggle_speed() -> void:
    state["settings"]["speed_2x"] = not bool(state["settings"].get("speed_2x", false))
    apply_speed()
    save()
    Events.state_changed.emit()

## Fornecido pelo SkillCaster: segundos de recarga restantes de uma habilidade equipada.
var cooldown_provider := Callable()

func skill_remaining(id: String) -> float:
    if cooldown_provider.is_valid():
        return float(cooldown_provider.call(id))
    return 0.0

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

# ---------------------------------------------------------------- boss semanal (lógica em WeeklyBoss)
func weekly() -> Dictionary:
    return state["weekly"]

## Semana atual segundo o relógio do aparelho (online, o servidor é quem manda: ver WeeklyPanel).
func weekly_sync(week: int = -1) -> void:
    var w: Dictionary = state["weekly"]
    if week < 0:
        week = WeeklyBoss.week_id(int(Time.get_unix_time_from_system()))
    WeeklyBoss.sync(w, week)
    if str(w["pid"]) == "":
        var r := RandomNumberGenerator.new()
        r.randomize()
        w["pid"] = WeeklyBoss.make_pid(r)

## Gasta 1 entrada (local). Devolve false se bloqueado ou sem entradas.
func weekly_begin() -> bool:
    weekly_sync()
    if WeeklyBoss.block_reason(state["weekly"], int(state["max_stage"])) != "":
        return false
    var ok: bool = WeeklyBoss.consume_entry(state["weekly"])
    if ok:
        save()
    return ok

## Online: o servidor contou as tentativas; alinha o contador local (nunca diminui).
func weekly_set_entries(n: int) -> void:
    var w: Dictionary = state["weekly"]
    w["entries"] = clampi(maxi(int(w["entries"]), n), 0, Balance.WEEKLY_MAX_ENTRIES)
    save()

func weekly_record(score: float) -> bool:
    var is_best: bool = WeeklyBoss.record(state["weekly"], score)
    save()
    return is_best

## Resgata a recompensa da semana passada (gemas e fragmentos). Devolve a recompensa ({} se não havia).
func weekly_claim(rank: int, total: int) -> Dictionary:
    var r: Dictionary = WeeklyBoss.claim(state["weekly"], rank, total)
    if not r.is_empty():
        state["gems"] = int(state["gems"]) + int(r["gems"])
        state["shards"] = int(state["shards"]) + int(r["shards"])
        save()
        Events.state_changed.emit()
    return r

func set_stage(stage: int) -> void:
    state["stage"] = StageLogic.clamp_stage(stage)
    state["max_stage"] = maxi(int(state["max_stage"]), int(state["stage"]))

func _on_enemy_died(_pos: Vector2, def: Dictionary, is_boss: bool, gold: int) -> void:
    if def.get("summon", false) or def.get("weekly", false):
        return   # invocações de chefes e o Lucifer não dão recompensa de fase (a recompensa do semanal vem do ranking)
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
    elif def.get("mini", false):
        var mg: int = StageLogic.mini_gems(rng)   # mini-chefe: ouro alto + 1-2 gemas, sem fragmentos de asa
        state["gems"] = int(state["gems"]) + mg
        session_gems += mg
        save()
    else:
        var dg: int = DropLogic.roll_gems(def, rng)
        state["gems"] = int(state["gems"]) + dg
        session_gems += dg
    Events.state_changed.emit()
