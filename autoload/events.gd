extends Node
## Barramento global de sinais (desacopla UI, combate e economia).

signal state_changed
signal stage_changed(stage: int)
signal player_hp_changed(hp: float, max_hp: float)
signal player_died
signal boss_hp_changed(hp: float, max_hp: float)
signal enemy_died(pos: Vector2, def: Dictionary, is_boss: bool, gold: int)
signal stage_cleared(stage: int, seconds: float)
signal debug_goto_stage(stage: int)
signal debug_heal
signal debug_reset_cooldowns
signal goto_stage_requested(stage: int)   # menu "Fases": ir para um andar já alcançado
signal request_next_stage
signal repeat_mode_changed(on: bool)
signal stage_progress(killed: int, total: int, label: String)
signal boss_warning(boss_name: String, is_mini: bool)
signal ability_cast(id: String)
signal pause_started                    # menu/perfil abriu: o jogo entrou em pausa
signal boss_defeated(stage: int, gems: int, shards: int)
signal audio_changed                    # opções de som mudaram (música liga/desliga, volumes)
signal weekly_started                   # luta do boss semanal começou
signal weekly_timer(seconds_left: float) # tempo restante da luta semanal
signal weekly_finished(result: Dictionary) # {score, killed, reason: "killed"|"timeout"|"died", pct, reward: {gold, gems, label}}
signal weekly_requested                 # painel pediu para começar a luta
