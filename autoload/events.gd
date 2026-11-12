extends Node
## Barramento global de sinais (desacopla UI, combate e economia).

signal state_changed
signal stage_changed(stage: int)
signal player_hp_changed(hp: float, max_hp: float)
signal player_died
signal boss_hp_changed(hp: float, max_hp: float)
signal enemy_died(pos: Vector2, def: Dictionary, is_boss: bool, gold: int)
signal stage_cleared(stage: int, seconds: float)
signal boss_defeated(stage: int, gems: int, shards: int)
