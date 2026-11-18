class_name AdsLogic
extends RefCounted
## Anúncios: LÓGICA PURA (sem autoloads, sem o plugin). Escolha de ID (teste x real) e regras de estado.
## NÃO há aqui nenhuma mecânica de recompensa (reviver, gemas): isso virá depois, por cima do AdsManager.

const STATE_IDLE := "idle"
const STATE_LOADING := "loading"
const STATE_READY := "ready"
const STATE_SHOWING := "showing"

static func is_test_id(id: String) -> bool:
    return id.begins_with(AdsConfig.TEST_PREFIX)

## Formato de um ID de unidade real: ca-app-pub-<16 dígitos>/<10 dígitos>.
static func is_valid_unit_id(id: String) -> bool:
    var parts: PackedStringArray = id.split("/")
    if parts.size() != 2 or not parts[0].begins_with("ca-app-pub-") or parts[1].length() < 8:
        return false
    var pub: String = parts[0].substr(11)
    return pub.length() == 16 and pub.is_valid_int() and parts[1].is_valid_int()

## ID da unidade premiada. Debug SEMPRE usa o de teste; release só usa o real se USE_REAL_ADS e o ID for válido (senão cai no de teste).
static func rewarded_unit_id(debug_build: bool, use_real: bool, real_id: String) -> String:
    if debug_build or not use_real or not is_valid_unit_id(real_id) or is_test_id(real_id):
        return AdsConfig.TEST_REWARDED_ANDROID
    return real_id

## Alerta para o lançamento: devolve o motivo de os anúncios REAIS não estarem ativos ("" = prontos para produção).
static func release_blocker(use_real: bool, real_id: String) -> String:
    if not use_real:
        return "USE_REAL_ADS está false"
    if not is_valid_unit_id(real_id) or is_test_id(real_id):
        return "ID real da unidade premiada inválido ou vazio"
    return ""

static func platform_supported(os_name: String, display_name: String) -> bool:
    return os_name == "Android" and display_name != "headless"

static func can_load(state: String, plugin_ok: bool, sdk_ready: bool) -> bool:
    return plugin_ok and sdk_ready and state == STATE_IDLE

static func can_show(state: String) -> bool:
    return state == STATE_READY
