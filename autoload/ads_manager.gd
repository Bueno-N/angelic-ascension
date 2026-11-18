extends Node
## AdsManager (autoload): ÚNICO ponto de contato do jogo com o AdMob (plugin Poing Studios). Só infraestrutura:
## carregar e exibir anúncios PREMIADOS e avisar por sinais. Nenhuma recompensa é dada aqui (reviver/gemas virão depois),
## e nada no jogador, combate ou interface depende deste arquivo.
##
## O plugin NÃO é referenciado em tempo de compilação: as classes dele (RewardedAdLoader, MobileAds...) são buscadas
## por nome em execução. Sem o plugin (PC, CI de verificação, APK sem AdMob) este autoload fica inerte e o jogo roda normal.
## Os nomes de classes/propriedades vêm da documentação oficial do plugin; NUNCA foram executados num aparelho (ver docs/ADMOB.md).

signal sdk_ready(ok: bool)
signal rewarded_loaded
signal rewarded_load_failed(message: String)
signal rewarded_earned(amount: int, reward_type: String)
signal rewarded_dismissed
signal rewarded_show_failed(message: String)

const REQUIRED_CLASSES := ["MobileAds", "AdRequest", "RewardedAdLoader", "RewardedAdLoadCallback", "FullScreenContentCallback", "OnUserEarnedRewardListener"]

var plugin_ok := false        # o plugin está no projeto
var supported := false        # Android real (não headless)
var sdk_initialized := false
var state := AdsLogic.STATE_IDLE
var last_error := ""
var reload_after_dismiss := true
var _ad: Object = null
var _keep: Array = []         # referências dos callbacks (senão o Godot os libera)
var _classes: Dictionary = {}

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    plugin_ok = _all_classes_present(REQUIRED_CLASSES)
    supported = AdsLogic.platform_supported(OS.get_name(), DisplayServer.get_name())
    if plugin_ok and supported and not OS.get_cmdline_user_args().has("--smoke"):
        start()

# ---------------------------------------------------------------- API pública
func unit_id() -> String:
    return AdsLogic.rewarded_unit_id(OS.is_debug_build(), AdsConfig.USE_REAL_ADS, AdsConfig.REAL_REWARDED_ANDROID)

func is_available() -> bool:
    return plugin_ok and supported

func is_rewarded_ready() -> bool:
    return AdsLogic.can_show(state) and _ad != null

## Consentimento (UMP) e depois inicialização do SDK. Chame uma vez (o próprio _ready já chama no Android).
func start() -> void:
    if not is_available() or sdk_initialized:
        return
    _request_consent()

func load_rewarded() -> bool:
    if not AdsLogic.can_load(state, plugin_ok, sdk_initialized):
        return false
    var cb: Object = _make("RewardedAdLoadCallback")
    var loader: Object = _make("RewardedAdLoader")
    var req: Object = _make("AdRequest")
    if cb == null or loader == null or req == null:
        return false
    cb.set("on_ad_loaded", Callable(self, "_on_loaded"))
    cb.set("on_ad_failed_to_load", Callable(self, "_on_load_failed"))
    _keep = [cb, loader, req]
    state = AdsLogic.STATE_LOADING
    loader.call("load", unit_id(), req, cb)
    return true

## Mostra o anúncio já carregado. A RECOMPENSA chega pelo sinal rewarded_earned (quem pediu o anúncio decide o que dar).
func show_rewarded() -> bool:
    if not is_rewarded_ready():
        return false
    var fsc: Object = _make("FullScreenContentCallback")
    var listener: Object = _make("OnUserEarnedRewardListener")
    if fsc == null or listener == null:
        return false
    fsc.set("on_ad_dismissed_full_screen_content", Callable(self, "_on_dismissed"))
    fsc.set("on_ad_failed_to_show_full_screen_content", Callable(self, "_on_show_failed"))
    listener.set("on_user_earned_reward", Callable(self, "_on_earned"))
    _keep.append(fsc)
    _keep.append(listener)
    _ad.set("full_screen_content_callback", fsc)
    state = AdsLogic.STATE_SHOWING
    _ad.call("show", listener)
    return true

## Verificação do smoke (CI, sem plugin): inerte, só IDs de teste, nada carrega nem mostra.
func smoke_ok() -> bool:
    return AdsLogic.is_test_id(unit_id()) and not is_rewarded_ready() and not load_rewarded() and not show_rewarded() \
        and (plugin_ok or not is_available())

# ---------------------------------------------------------------- callbacks do plugin
func _on_loaded(ad: Object) -> void:
    _ad = ad
    state = AdsLogic.STATE_READY
    rewarded_loaded.emit()

func _on_load_failed(error: Object) -> void:
    last_error = _error_text(error)
    _clear_ad()
    rewarded_load_failed.emit(last_error)

func _on_earned(item: Object) -> void:
    var amount := 0
    var kind := ""
    if item != null:
        amount = int(item.get("amount"))
        kind = str(item.get("type"))
    rewarded_earned.emit(amount, kind)

func _on_dismissed() -> void:
    _clear_ad()
    rewarded_dismissed.emit()
    if reload_after_dismiss:
        load_rewarded()

func _on_show_failed(error: Object) -> void:
    last_error = _error_text(error)
    _clear_ad()
    rewarded_show_failed.emit(last_error)

func _clear_ad() -> void:
    if _ad != null and is_instance_valid(_ad) and _ad.has_method("destroy"):
        _ad.call("destroy")
    _ad = null
    _keep.clear()
    state = AdsLogic.STATE_IDLE

func _error_text(error: Object) -> String:
    if error == null:
        return "erro desconhecido"
    var m: Variant = error.get("message")
    return str(m) if m != null else "erro desconhecido"

# ---------------------------------------------------------------- consentimento (UMP) e SDK
func _request_consent() -> void:
    var ump: Object = _find("UserMessagingPlatform")
    var info: Object = ump.get("consent_information") if ump != null else null
    var params: Object = _make("ConsentRequestParameters")
    if info == null or params == null:
        push_warning("AdsManager: API de consentimento (UMP) indisponível; inicializando o SDK sem formulário.")
        _init_sdk()
        return
    params.set("tag_for_under_age_of_consent", false)
    info.call("update", params, Callable(self, "_on_consent_updated"), Callable(self, "_on_consent_failed"))

func _on_consent_updated() -> void:
    var ump: Object = _find("UserMessagingPlatform")
    var info: Object = ump.get("consent_information") if ump != null else null
    if info != null and info.call("get_is_consent_form_available"):
        ump.call("load_consent_form", Callable(self, "_on_form_loaded"), Callable(self, "_on_form_failed"))
    else:
        _init_sdk()

func _on_consent_failed(_error: Object) -> void:
    _init_sdk()    # sem rede/erro: o SDK decide o que pode exibir

func _on_form_loaded(form: Object) -> void:
    var info: Object = _find("UserMessagingPlatform").get("consent_information")
    var required: Variant = _enum_value("ConsentInformation", "ConsentStatus", "REQUIRED")
    if required != null and info.call("get_consent_status") == required:
        form.call("show", Callable(self, "_on_form_dismissed"))
    else:
        _init_sdk()

func _on_form_failed(_error: Object) -> void:
    _init_sdk()

func _on_form_dismissed(_error: Object) -> void:
    _init_sdk()

func _init_sdk() -> void:
    if sdk_initialized:
        return
    var ads: Object = _find("MobileAds")
    if ads == null:
        _sdk_failed()
        return
    ads.call("initialize")
    sdk_initialized = true
    sdk_ready.emit(true)
    load_rewarded()

func _sdk_failed() -> void:
    sdk_ready.emit(false)

# ---------------------------------------------------------------- busca dinâmica das classes do plugin
func _global_class_path(cname: String) -> String:
    for c in ProjectSettings.get_global_class_list():
        if str(c.get("class", "")) == cname:
            return str(c.get("path", ""))
    return ""

func _all_classes_present(names: Array) -> bool:
    for n in names:
        if _global_class_path(str(n)) == "" and not ClassDB.class_exists(str(n)) and not Engine.has_singleton(str(n)):
            return false
    return true

## Objeto "estático" da classe (o script, para chamar funções estáticas/ler variáveis estáticas) ou o singleton.
func _find(cname: String) -> Object:
    if _classes.has(cname):
        return _classes[cname]
    var obj: Object = null
    var path: String = _global_class_path(cname)
    if path != "":
        obj = load(path) as Object
    elif Engine.has_singleton(cname):
        obj = Engine.get_singleton(cname)
    _classes[cname] = obj
    return obj

func _make(cname: String) -> Object:
    var path: String = _global_class_path(cname)
    if path != "":
        var sc = load(path)
        return sc.new() if sc != null else null
    if ClassDB.class_exists(cname) and ClassDB.can_instantiate(cname):
        return ClassDB.instantiate(cname)
    return null

func _enum_value(cname: String, enum_name: String, key: String) -> Variant:
    var path: String = _global_class_path(cname)
    if path == "":
        return null
    var sc: Script = load(path) as Script
    if sc == null:
        return null
    var consts: Dictionary = sc.get_script_constant_map()
    if consts.has(enum_name) and consts[enum_name] is Dictionary:
        return consts[enum_name].get(key)
    return null
