class_name SlotStore
extends RefCounted
## Disco dos jogos salvos (2 espaços por conta) + configurações globais do aparelho.
## Tudo recebe `dir` (padrão "user://") para os testes poderem usar uma pasta temporária.
## Escrita atômica (tmp -> rename) com backup do arquivo anterior.

const COUNT := 2
const DEFAULT_DIR := "user://"
const LEGACY_FILE := "save.json"

static func _abs(p: String) -> String:
    return ProjectSettings.globalize_path(p)

static func path(dir: String, n: int) -> String:
    return "%ssave_%d.json" % [dir, n]

static func backup_path(dir: String, n: int) -> String:
    return "%ssave_%d.bak.json" % [dir, n]

static func valid_slot(n: int) -> bool:
    return n >= 1 and n <= COUNT

static func exists(dir: String, n: int) -> bool:
    return valid_slot(n) and (FileAccess.file_exists(path(dir, n)) or FileAccess.file_exists(backup_path(dir, n)))

static func _read_dict(p: String) -> Variant:
    if not FileAccess.file_exists(p):
        return null
    var f := FileAccess.open(p, FileAccess.READ)
    if f == null:
        return null
    var txt := f.get_as_text()
    f.close()
    return SaveData.parse_dict(txt)

static func _write_atomic(dir: String, file: String, text: String, keep_backup: String = "") -> bool:
    DirAccess.make_dir_recursive_absolute(_abs(dir))
    var tmp := dir + "write.tmp"
    var f := FileAccess.open(tmp, FileAccess.WRITE)
    if f == null:
        return false
    f.store_string(text)
    f.close()
    var dest := dir + file
    if keep_backup != "" and FileAccess.file_exists(dest):
        DirAccess.copy_absolute(_abs(dest), _abs(keep_backup))
    return DirAccess.rename_absolute(_abs(tmp), _abs(dest)) == OK

static func write(dir: String, n: int, state: Dictionary) -> bool:
    if not valid_slot(n):
        return false
    return _write_atomic(dir, "save_%d.json" % n, SaveData.to_json(state), backup_path(dir, n))

## Estado salvo (sanitizado) ou {} se o espaço está vazio/ilegível.
static func read(dir: String, n: int) -> Dictionary:
    if not valid_slot(n):
        return {}
    for p in [path(dir, n), backup_path(dir, n)]:
        var parsed = _read_dict(p)
        if parsed is Dictionary:
            return SaveData.sanitize(parsed)
    return {}

static func delete(dir: String, n: int) -> void:
    if not valid_slot(n):
        return
    for p in [path(dir, n), backup_path(dir, n)]:
        if FileAccess.file_exists(p):
            DirAccess.remove_absolute(_abs(p))

## Um item por espaço: {slot, exists, name, avatar, stage, max_stage, wings, text1, text2}.
static func summaries(dir: String) -> Array:
    var out: Array = []
    for n in range(1, COUNT + 1):
        var st: Dictionary = read(dir, n)
        out.append(SlotLogic.summary(n, st))
    return out

## Save único antigo (user://save.json) vira o espaço 1, se o espaço 1 ainda estiver vazio.
static func migrate_legacy(dir: String) -> bool:
    var old := dir + LEGACY_FILE
    if not FileAccess.file_exists(old) or exists(dir, 1):
        return false
    var parsed = _read_dict(old)
    if not (parsed is Dictionary):
        return false
    if not write(dir, 1, SaveData.sanitize(parsed)):
        return false
    DirAccess.rename_absolute(_abs(old), _abs(dir + "save.migrated.json"))
    return true

# ---------------------------------------------------------------- configurações globais (volume, efeitos)
static func read_global(dir: String) -> Dictionary:
    var parsed = _read_dict(dir + "settings.json")
    if not (parsed is Dictionary):
        return {}
    return OptionsLogic.sanitize_global(parsed)

static func write_global(dir: String, g: Dictionary) -> bool:
    return _write_atomic(dir, "settings.json", JSON.stringify(OptionsLogic.sanitize_global(g)))
