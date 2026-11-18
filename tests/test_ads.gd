extends TestCase
## Anúncios (AdMob): só a lógica pura (IDs de teste x real, estados, plataforma). O plugin e o SDK nativo NÃO são testáveis aqui:
## dependem de um aparelho Android (ver docs/ADMOB.md).

const REAL_OK := "ca-app-pub-1234567890123456/1234567890"

func test_test_ids_are_the_official_google_ones() -> void:
    check(AdsConfig.TEST_REWARDED_ANDROID == "ca-app-pub-3940256099942544/5224354917", "ID de teste premiado (Android)")
    check(AdsConfig.TEST_APP_ID_ANDROID == "ca-app-pub-3940256099942544~3347511713", "App ID de teste (Android)")
    check(AdsLogic.is_test_id(AdsConfig.TEST_REWARDED_ANDROID) and not AdsLogic.is_test_id(REAL_OK), "reconhece ID de teste")

func test_unit_id_validation() -> void:
    check(AdsLogic.is_valid_unit_id(REAL_OK), "ID real válido")
    for bad in ["", "abc", "ca-app-pub-123/456", "ca-app-pub-1234567890123456~1234567890", "ca-app-pub-123456789012345x/1234567890", "ca-app-pub-1234567890123456/12"]:
        check(not AdsLogic.is_valid_unit_id(bad), "ID inválido recusado: '%s'" % bad)

func test_debug_build_never_uses_real_ads() -> void:
    check(AdsLogic.rewarded_unit_id(true, true, REAL_OK) == AdsConfig.TEST_REWARDED_ANDROID, "debug + real ligado: continua no teste")
    check(AdsLogic.rewarded_unit_id(true, false, REAL_OK) == AdsConfig.TEST_REWARDED_ANDROID, "debug: teste")
    check(AdsLogic.rewarded_unit_id(false, false, REAL_OK) == AdsConfig.TEST_REWARDED_ANDROID, "release com USE_REAL_ADS=false: teste")
    check(AdsLogic.rewarded_unit_id(false, true, "") == AdsConfig.TEST_REWARDED_ANDROID, "release sem ID real: cai no teste")
    check(AdsLogic.rewarded_unit_id(false, true, "lixo") == AdsConfig.TEST_REWARDED_ANDROID, "release com ID inválido: teste")
    check(AdsLogic.rewarded_unit_id(false, true, REAL_OK) == REAL_OK, "release com tudo certo usa o ID real")

func test_repo_ships_with_test_ads_only() -> void:
    check(not AdsConfig.USE_REAL_ADS, "o repositório entrega USE_REAL_ADS = false")
    check(AdsConfig.REAL_REWARDED_ANDROID == "" or AdsLogic.is_valid_unit_id(AdsConfig.REAL_REWARDED_ANDROID), "ID real vazio ou válido")
    check(AdsLogic.release_blocker(false, "") != "" and AdsLogic.release_blocker(true, "") != "", "avisa o que falta para produção")
    check(AdsLogic.release_blocker(true, REAL_OK) == "", "tudo certo = sem bloqueio")
    check(AdsLogic.release_blocker(true, AdsConfig.TEST_REWARDED_ANDROID) != "", "ID de teste não conta como produção")

func test_states_and_platform() -> void:
    check(AdsLogic.can_load(AdsLogic.STATE_IDLE, true, true), "carrega quando ocioso, com plugin e SDK")
    check(not AdsLogic.can_load(AdsLogic.STATE_IDLE, false, true) and not AdsLogic.can_load(AdsLogic.STATE_IDLE, true, false), "sem plugin ou sem SDK: não carrega")
    for st in [AdsLogic.STATE_LOADING, AdsLogic.STATE_READY, AdsLogic.STATE_SHOWING]:
        check(not AdsLogic.can_load(st, true, true), "não carrega de novo em " + st)
    check(AdsLogic.can_show(AdsLogic.STATE_READY) and not AdsLogic.can_show(AdsLogic.STATE_IDLE) and not AdsLogic.can_show(AdsLogic.STATE_LOADING), "só mostra com anúncio pronto")
    check(AdsLogic.platform_supported("Android", "Android") or AdsLogic.platform_supported("Android", "mobile"), "Android real suportado")
    check(not AdsLogic.platform_supported("Android", "headless") and not AdsLogic.platform_supported("Linux", "x11") and not AdsLogic.platform_supported("Windows", "windows"), "headless/PC: inerte")

func test_only_known_ad_fields_in_the_game_state() -> void:
    var st := SaveData.default_state()
    for k in st.keys():
        if str(k) == "ad_gems":
            continue    # gemas por anúncio (GemAdLogic, ver test_gem_ads.gd)
        check(not str(k).contains("ad_") and not str(k).contains("reward"), "campo de anúncio/recompensa inesperado no save: " + str(k))
