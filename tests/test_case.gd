class_name TestCase
extends RefCounted

var checks := 0
var failures: Array = []
var warnings: Array = []
var current := ""

func check(cond: bool, msg: String) -> void:
    checks += 1
    if not cond:
        failures.append("[%s] %s" % [current, msg])

func check_approx(a: float, b: float, msg: String, eps: float = 0.0001) -> void:
    check(absf(a - b) <= eps, "%s (obtido %s, esperado %s)" % [msg, str(a), str(b)])

## Metas de calibração de design: não reprovam o build, apenas geram aviso no relatório.
func warn_if_not(cond: bool, msg: String) -> void:
    if not cond:
        warnings.append("[%s] %s" % [current, msg])
