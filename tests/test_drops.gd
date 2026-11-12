extends TestCase
## Simulação estatística com semente fixa e tolerância larga (±20% do esperado).

func test_common_drop_rate() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 12345
    var def := EnemiesDB.TYPES[0]
    var n := 200000
    var total := 0
    for i in range(n):
        total += DropLogic.roll_gems(def, rng)
    var expected := float(n) * Balance.GEM_CHANCE_COMMON
    check(float(total) >= expected * 0.8 and float(total) <= expected * 1.2, "comum ~0,5%% (obtido %d, esperado ~%.0f)" % [total, expected])

func test_special_drop_rate_and_amount() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 999
    var def := EnemiesDB.TYPES[4]
    check(def["special"], "tipo 4 é especial")
    var n := 100000
    var events := 0
    var gems := 0
    for i in range(n):
        var g := DropLogic.roll_gems(def, rng)
        if g > 0:
            events += 1
            check(g >= 1 and g <= 3, "especial dropa 1..3")
        gems += g
    var expected := float(n) * Balance.GEM_CHANCE_SPECIAL
    check(float(events) >= expected * 0.8 and float(events) <= expected * 1.2, "especial ~2%% (eventos %d, esperado ~%.0f)" % [events, expected])
    check(float(gems) / maxf(1.0, float(events)) > 1.5, "média por drop especial perto de 2")
