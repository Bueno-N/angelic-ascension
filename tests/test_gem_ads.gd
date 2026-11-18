extends TestCase
## Gemas por anúncio (botão redondo ao lado do MENU): 500 no primeiro do dia, depois 100 a cada 30 minutos.

const BIAS_BR := -180      # horário de Brasília (UTC-3)
const T0 := 1_800_000_000  # um instante qualquer

func test_first_ad_of_day_gives_500_right_away() -> void:
    var s := GemAdLogic.default_state()
    var day: int = GemAdLogic.day_id(T0, BIAS_BR)
    check(GemAdLogic.is_available(s, T0, day), "jogo novo: o anúncio já está liberado")
    check(GemAdLogic.next_reward(s, day) == 500, "primeiro do dia = 500")
    check(GemAdLogic.claim(s, T0, day) == 500, "resgate dá 500")

func test_after_first_one_every_30_minutes_for_100() -> void:
    var s := GemAdLogic.default_state()
    var day: int = GemAdLogic.day_id(T0, BIAS_BR)
    GemAdLogic.claim(s, T0, day)
    check(not GemAdLogic.is_available(s, T0 + 1, day), "logo depois: bloqueado")
    check(GemAdLogic.seconds_left(s, T0 + 60, day) == 29 * 60, "faltam 29 min depois de 1 min")
    check(GemAdLogic.claim(s, T0 + 29 * 60, day) == 0, "antes dos 30 min não dá nada")
    check(GemAdLogic.next_reward(s, day) == 100, "os seguintes valem 100")
    check(GemAdLogic.claim(s, T0 + 30 * 60, day) == 100, "aos 30 min: +100")
    check(GemAdLogic.claim(s, T0 + 45 * 60, day) == 0, "o tempo conta a partir do último anúncio")
    check(GemAdLogic.claim(s, T0 + 60 * 60, day) == 100, "mais 30 min: +100")

func test_new_day_resets_to_500_without_waiting() -> void:
    var s := GemAdLogic.default_state()
    var day: int = GemAdLogic.day_id(T0, BIAS_BR)
    GemAdLogic.claim(s, T0, day)
    check(GemAdLogic.is_available(s, T0 + 10, day + 1), "virou o dia: liberado mesmo sem 30 min")
    check(GemAdLogic.claim(s, T0 + 10, day + 1) == 500, "primeiro do dia novo = 500")

func test_day_follows_local_midnight() -> void:
    var midnight_utc: int = GemAdLogic.day_id(T0, 0) * GemAdLogic.DAY_SECONDS   # 00:00 UTC
    check(GemAdLogic.day_id(midnight_utc + 2 * 3600, BIAS_BR) == GemAdLogic.day_id(midnight_utc - 3600, 0),
        "02:00 UTC ainda é o dia anterior em Brasília")
    check(GemAdLogic.day_id(midnight_utc + 3 * 3600, BIAS_BR) == GemAdLogic.day_id(midnight_utc, 0), "03:00 UTC = meia-noite em Brasília")

func test_clock_moved_back_never_locks_more_than_30_min() -> void:
    var s := GemAdLogic.default_state()
    var day: int = GemAdLogic.day_id(T0, BIAS_BR)
    GemAdLogic.claim(s, T0, day)
    check(GemAdLogic.seconds_left(s, T0 - 5000, day) == GemAdLogic.COOLDOWN_SECONDS, "relógio para trás: espera os 30 min")
    GemAdLogic.fix_clock(s, T0 - 5000)
    check(GemAdLogic.is_available(s, T0 - 5000 + 30 * 60, day), "e libera 30 min depois")

func test_sanitize_and_format() -> void:
    check(GemAdLogic.sanitize(null) == GemAdLogic.default_state(), "sem dado: padrão")
    check(GemAdLogic.sanitize({"day": "x", "last": -5}) == GemAdLogic.default_state(), "lixo: padrão")
    check(GemAdLogic.sanitize({"day": 20000.0, "last": 123.0}) == {"day": 20000, "last": 123}, "números do JSON (float) viram int")
    check(SaveData.default_state().has("ad_gems"), "save novo tem ad_gems")
    var round_trip: Dictionary = SaveData.from_json(SaveData.to_json({"ad_gems": {"day": 7, "last": 99}}))
    check(round_trip["ad_gems"] == {"day": 7, "last": 99}, "ad_gems sobrevive ao salvar/carregar")
    check(SaveData.from_json("{}")["ad_gems"] == GemAdLogic.default_state(), "save antigo sem ad_gems: padrão")
    check(GemAdLogic.format_left(1799) == "29:59" and GemAdLogic.format_left(0) == "0:00", "contador mm:ss")
