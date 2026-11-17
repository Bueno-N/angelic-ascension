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
signal request_next_stage
signal repeat_mode_changed(on: bool)
signal stage_progress(killed: int, total: int, label: String)
signal boss_warning(boss_name: String, is_mini: bool)
signal ability_cast(id: String)
signal boss_defeated(stage: int, gems: int, shards: int)
