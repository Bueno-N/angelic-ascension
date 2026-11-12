extends Node
## E/S de disco. Escrita atômica (tmp -> rename) com backup do save anterior.

const SAVE_PATH := "user://save.json"
const BACKUP_PATH := "user://save.bak.json"
const TMP_PATH := "user://save.tmp"

func save_state(state: Dictionary) -> bool:
    var f := FileAccess.open(TMP_PATH, FileAccess.WRITE)
    if f == null:
        push_warning("SaveManager: não foi possível abrir o arquivo temporário")
        return false
    f.store_string(SaveData.to_json(state))
    f.close()
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE_PATH), ProjectSettings.globalize_path(BACKUP_PATH))
    var err := DirAccess.rename_absolute(ProjectSettings.globalize_path(TMP_PATH), ProjectSettings.globalize_path(SAVE_PATH))
    return err == OK

func load_state() -> Dictionary:
    for path in [SAVE_PATH, BACKUP_PATH]:
        if FileAccess.file_exists(path):
            var f := FileAccess.open(path, FileAccess.READ)
            if f != null:
                var txt := f.get_as_text()
                f.close()
                var parsed = JSON.parse_string(txt)
                if parsed is Dictionary:
                    return SaveData.sanitize(parsed)
    return SaveData.default_state()
