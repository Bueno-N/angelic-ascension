extends SceneTree
## Uso: godot --headless --path . --script res://tests/run_tests.gd
## Sai com código 1 se qualquer verificação falhar.

const SUITES := [
    "res://tests/test_stats.gd",
    "res://tests/test_skills.gd",
    "res://tests/test_economy.gd",
    "res://tests/test_progression.gd",
    "res://tests/test_save.gd",
    "res://tests/test_drops.gd",
    "res://tests/test_ui_logic.gd",
    "res://tests/test_skill_runtime.gd",
    "res://tests/test_debug_tools.gd",
    "res://tests/test_auto_slots.gd",
    "res://tests/test_enemy_abilities.gd",
]

func _initialize() -> void:
    var total_checks := 0
    var tests_run := 0
    var failures: Array = []
    var warnings: Array = []
    for path in SUITES:
        var script = load(path)
        if script == null:
            failures.append("Não foi possível carregar a suíte " + path)
            continue
        var suite = script.new()
        for m in suite.get_method_list():
            var mname: String = m["name"]
            if mname.begins_with("test_"):
                suite.current = path.get_file() + "::" + mname
                suite.call(mname)
                tests_run += 1
        total_checks += suite.checks
        failures.append_array(suite.failures)
        warnings.append_array(suite.warnings)

    print("==== RESUMO DOS TESTES ====")
    print("testes executados: %d | verificações: %d | falhas: %d | avisos de calibração: %d" % [tests_run, total_checks, failures.size(), warnings.size()])
    for f in failures:
        print("FALHA: " + f)
    for w in warnings:
        print("AVISO: " + w)

    var report := {"tests": tests_run, "checks": total_checks, "failures": failures, "warnings": warnings}
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build"))
    var fa := FileAccess.open(ProjectSettings.globalize_path("res://build/test_report.json"), FileAccess.WRITE)
    if fa != null:
        fa.store_string(JSON.stringify(report, "  "))
        fa.close()
    quit(1 if failures.size() > 0 else 0)
