extends TestCase
## Menu inicial: 2 espaços de salvamento, nome obrigatório, migração do save antigo e opções globais.

const DIR := "user://_slot_test/"

func _clean() -> void:
    for n in range(1, 4):
        SlotStore.delete(DIR, n)
    for f in ["save.json", "save.migrated.json", "settings.json", "write.tmp"]:
        if FileAccess.file_exists(DIR + f):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(DIR + f))

func test_name_validation() -> void:
    check(SlotLogic.name_valid("Ana"), "nome normal")
    check(not SlotLogic.name_valid(""), "vazio inválido")
    check(not SlotLogic.name_valid("    "), "só espaços inválido")
    check(not SlotLogic.name_valid("@@@"), "só símbolos que a fonte não desenha inválido")
    check(SlotLogic.name_valid(" Zé "), "acentos valem")
    check(SlotLogic.clean_new_name("  Ana  ") == "Ana", "nome limpo")
    check(SlotLogic.clean_new_name("ABCDEFGHIJKLMNOPQRST").length() <= ProfileLogic.MAX_NAME, "limite de letras")

func test_summary() -> void:
    var empty := SlotLogic.summary(1, {})
    check(not bool(empty["exists"]) and str(empty["name"]) == "Vazio", "espaço vazio")
    var st := SaveData.default_state()
    st["profile"]["name"] = "Mika"
    st["stage"] = 12
    st["max_stage"] = 15
    st["wings_level"] = 3
    var s := SlotLogic.summary(2, st)
    check(bool(s["exists"]) and str(s["name"]) == "Mika" and int(s["stage"]) == 12 and int(s["slot"]) == 2, "resumo do jogo")
    check(str(s["text1"]).contains("12") and str(s["text1"]).contains("15"), "texto com fase e recorde")

func test_two_slots_roundtrip_and_independent() -> void:
    _clean()
    check(SlotStore.COUNT == 2 and SlotLogic.MAX_SLOTS == 2, "máximo de 2 jogos por conta")
    check(not SlotStore.exists(DIR, 1) and not SlotStore.exists(DIR, 2), "começa vazio")
    var a := SaveData.default_state()
    a["profile"]["name"] = "Um"
    a["gold"] = 111
    var b := SaveData.default_state()
    b["profile"]["name"] = "Dois"
    b["gold"] = 222
    check(SlotStore.write(DIR, 1, a) and SlotStore.write(DIR, 2, b), "grava os dois")
    check(int(SlotStore.read(DIR, 1)["gold"]) == 111 and int(SlotStore.read(DIR, 2)["gold"]) == 222, "independentes")
    check(str(SlotStore.read(DIR, 2)["profile"]["name"]) == "Dois", "nome do espaço 2")
    var sums := SlotStore.summaries(DIR)
    check(sums.size() == 2 and bool(sums[0]["exists"]) and bool(sums[1]["exists"]), "resumos dos dois")
    check(not SlotStore.write(DIR, 3, a) and not SlotStore.exists(DIR, 3), "não existe 3º espaço")
    check(SlotStore.read(DIR, 3).is_empty() and SlotStore.read(DIR, 0).is_empty(), "leitura fora da faixa = vazio")
    SlotStore.delete(DIR, 1)
    check(not SlotStore.exists(DIR, 1) and SlotStore.exists(DIR, 2), "apagar só o espaço 1")
    check(not bool(SlotStore.summaries(DIR)[0]["exists"]), "resumo do espaço apagado = vazio")
    _clean()

func test_corrupt_slot_is_ignored() -> void:
    _clean()
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
    var f := FileAccess.open(SlotStore.path(DIR, 1), FileAccess.WRITE)
    f.store_string("{isso nao e json")
    f.close()
    check(SlotStore.read(DIR, 1).is_empty(), "arquivo corrompido = vazio, sem travar")
    _clean()

func test_legacy_save_migrates_to_slot_1() -> void:
    _clean()
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
    var old := SaveData.default_state()
    old["gold"] = 999
    var f := FileAccess.open(DIR + "save.json", FileAccess.WRITE)
    f.store_string(SaveData.to_json(old))
    f.close()
    check(SlotStore.migrate_legacy(DIR), "migra o save antigo")
    check(int(SlotStore.read(DIR, 1)["gold"]) == 999, "virou o espaço 1")
    check(not FileAccess.file_exists(DIR + "save.json"), "arquivo antigo renomeado")
    check(not SlotStore.migrate_legacy(DIR), "não migra de novo")
    _clean()

func test_global_settings_roundtrip() -> void:
    _clean()
    check(SlotStore.read_global(DIR).is_empty(), "sem arquivo = vazio")
    check(SlotStore.write_global(DIR, {"volume": 30, "low_fx": true}), "grava")
    var g := SlotStore.read_global(DIR)
    check(int(g["volume"]) == 30 and bool(g["low_fx"]), "volta igual")
    var junk := OptionsLogic.sanitize_global({"volume": "x", "low_fx": "y"})
    check(int(junk["volume"]) == OptionsLogic.DEFAULT_VOLUME and not bool(junk["low_fx"]), "lixo vira padrão")
    check(int(OptionsLogic.sanitize_global({"volume": 900})["volume"]) == 100, "limita a 100")
    _clean()
