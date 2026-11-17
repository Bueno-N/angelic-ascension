extends Node
## E/S de disco para o jogo: 2 espaços de salvamento por conta + configurações globais (ver SlotStore).

func _ready() -> void:
    SlotStore.migrate_legacy(SlotStore.DEFAULT_DIR)   # save único antigo vira o espaço 1

func save_slot(n: int, state: Dictionary) -> bool:
    return SlotStore.write(SlotStore.DEFAULT_DIR, n, state)

func load_slot(n: int) -> Dictionary:
    return SlotStore.read(SlotStore.DEFAULT_DIR, n)

func delete_slot(n: int) -> void:
    SlotStore.delete(SlotStore.DEFAULT_DIR, n)

func summaries() -> Array:
    return SlotStore.summaries(SlotStore.DEFAULT_DIR)

func load_global() -> Dictionary:
    return SlotStore.read_global(SlotStore.DEFAULT_DIR)

func save_global(g: Dictionary) -> bool:
    return SlotStore.write_global(SlotStore.DEFAULT_DIR, g)
