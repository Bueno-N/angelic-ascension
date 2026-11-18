extends Node
## ShopManager (autoload): ÚNICO ponto de contato do jogo com o Google Play Billing (plugin oficial
## godot-sdk-integrations/godot-google-play-billing, pasta addons/GodotGooglePlayBilling). Regras e catálogo em ShopLogic.
##
## Como o AdsManager, o plugin NÃO é referenciado em tempo de compilação: a classe BillingClient é buscada pelo nome em execução.
## Sem o plugin (PC, CI, APK sem billing) este autoload fica inerte. Em build de DEBUG sem a loja do Google, as compras são
## SIMULADAS (sem cobrança) para testar a aba Loja. Em release isso nunca acontece.
##
## Fluxo de uma compra (API do plugin conferida na documentação oficial, nunca executada num aparelho — ver docs/LOJA.md):
##   start_connection -> connected -> query_product_details (preços) + query_purchases (compras não finalizadas)
##   purchase(id) -> on_purchase_updated -> entrega (ShopLogic.deliver, grava o livro) -> consume_purchase (consumível)
##                                                                                      ou acknowledge_purchase (Pacote Lendário)
## Compra entregue e não consumida (app fechou no meio) volta no query_purchases da próxima abertura: o livro impede entregar 2x.

signal shop_changed                      # preços/estado mudaram: redesenhar a aba Loja
signal purchase_done(text: String)       # entregue: "+5.000 GEMAS"
signal purchase_failed(message: String)  # cancelada / erro / indisponível
signal purchase_pending(message: String) # pagamento pendente (boleto, etc.)

const CLIENT_CLASS := "BillingClient"
const LEDGER_FILE := "user://iap_ledger.json"
const RESPONSE_OK := 0
const RESPONSE_USER_CANCELED := 1
const RESPONSE_ITEM_ALREADY_OWNED := 7

var plugin_ok := false
var supported := false                   # Android real (não headless)
var connected := false
var connecting := false
var last_error := ""
var prices: Dictionary = {}              # id -> "R$ 2,99" (vindo do Google)
var busy := false                        # fluxo de pagamento aberto
var pending_msg := ""
var legend_google := false               # o Google diz que a conta já tem o Pacote Lendário
var ledger: Dictionary = ShopLogic.default_ledger()
var simulated := 0                       # compras simuladas (debug)
var _client: Object = null
var _queue: Array = []                   # compras pagas esperando um jogo aberto: [{id, token, quantity, consumable, ack}]
var _smoke := false
var _poll := 0.0
var _flash := ""                         # último aviso (aparece no topo da aba Loja por alguns segundos)
var _flash_until := 0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _smoke = OS.get_cmdline_user_args().has("--smoke")
    if not _smoke:
        ledger = _load_ledger()
    plugin_ok = _global_class_path(CLIENT_CLASS) != ""
    supported = AdsLogic.platform_supported(OS.get_name(), DisplayServer.get_name())
    if plugin_ok and supported and not _smoke:
        _start()

func _process(delta: float) -> void:
    if _flash != "" and Time.get_ticks_msec() >= _flash_until:
        _flash = ""
        shop_changed.emit()
    _poll -= delta
    if _poll > 0.0 or _queue.is_empty():
        return
    _poll = 0.5
    _flush_queue()

# ---------------------------------------------------------------- API pública
func is_available() -> bool:
    return plugin_ok and supported and _client != null

func is_ready() -> bool:
    return is_available() and connected

## Simulação: só em build de debug e só quando a loja de verdade não está pronta.
func simulating() -> bool:
    return OS.is_debug_build() and not (is_ready() and not prices.is_empty())

## Contexto para MenuModel.rows("shop").
func menu_ctx() -> Dictionary:
    return {"prices": prices, "status": status_text(), "max_stage": int(GameState.state.get("max_stage", 1)),
        "ledger": ledger, "legend_google": legend_google, "busy": busy}

func status_text() -> String:
    if _flash != "" and Time.get_ticks_msec() < _flash_until:
        return _flash
    if busy:
        return "Compra em andamento... conclua na janela do Google Play."
    if pending_msg != "":
        return pending_msg
    if is_ready() and not prices.is_empty():
        return ""
    if simulating():
        return "MODO DE TESTE: as compras são SIMULADAS (sem cobrança).\nNa versão da Play Store o pagamento é real."
    if connecting:
        return "Conectando à Google Play..."
    if not is_available():
        return "A loja funciona no app instalado pela Google Play."
    return "Google Play indisponível agora. Tente de novo mais tarde."

## Inicia a compra. true se o pagamento abriu (ou a simulação entregou).
func buy(id: String) -> bool:
    var reason := ShopLogic.block_reason(id, int(GameState.state.get("max_stage", 1)), ledger, legend_google)
    if reason != "":
        _fail(reason)
        return false
    if busy:
        return false
    if simulating():
        simulated += 1
        _queue.append({"id": id, "token": "debug-%d-%d" % [Time.get_ticks_usec(), simulated], "quantity": 1,
            "consumable": ShopLogic.is_consumable(id), "ack": true, "fake": true})
        _flush_queue()
        return true
    if not is_ready():
        _fail("Loja indisponível: abra o jogo pela Google Play com internet.")
        if is_available() and not connecting:
            _connect()
        return false
    var r: Variant = _client.call("purchase", id)
    if r is Dictionary and int(r.get("response_code", RESPONSE_OK)) != RESPONSE_OK:
        _fail(_error_text(int(r["response_code"])))
        return false
    busy = true
    shop_changed.emit()
    return true

## Smoke do CI: inerte sem o plugin; simulação entrega 1x por token; lendário trancado antes da fase 51.
func smoke_ok() -> bool:
    if plugin_ok or is_available():
        return false
    var l := ShopLogic.default_ledger()
    var st := {"gems": 0, "gold": 0}
    var once: bool = ShopLogic.deliver(st, l, "gems_5000", "smoke-1")["ok"] and not ShopLogic.deliver(st, l, "gems_5000", "smoke-1")["ok"]
    var g0: int = int(GameState.state["gems"])
    var bought: bool = buy("gems_5000")
    var got: bool = int(GameState.state["gems"]) == g0 + 5000
    return once and int(st["gems"]) == 5000 and bought == OS.is_debug_build() and got == OS.is_debug_build() \
        and ShopLogic.block_reason(ShopLogic.LEGEND_ID, 1, l) != ""

# ---------------------------------------------------------------- conexão
func _start() -> void:
    _client = _make(CLIENT_CLASS)
    if _client == null:
        last_error = "BillingClient não pôde ser criado"
        return
    if _client is Node:
        add_child(_client)
    for pair in [["connected", _on_connected], ["disconnected", _on_disconnected], ["connect_error", _on_connect_error],
            ["query_product_details_response", _on_details], ["query_purchases_response", _on_purchases_query],
            ["on_purchase_updated", _on_purchase_updated], ["consume_purchase_response", _on_finished],
            ["acknowledge_purchase_response", _on_finished]]:
        if _client.has_signal(pair[0]):
            _client.connect(pair[0], pair[1])
        else:
            push_warning("ShopManager: o plugin não tem o sinal " + str(pair[0]))
    _connect()

func _connect() -> void:
    connecting = true
    _client.call("start_connection")
    shop_changed.emit()

func _on_connected() -> void:
    connected = true
    connecting = false
    last_error = ""
    _client.call("query_product_details", ShopLogic.ids(), _inapp())
    _client.call("query_purchases", _inapp())
    shop_changed.emit()

func _on_disconnected() -> void:
    connected = false
    connecting = false
    busy = false
    shop_changed.emit()

func _on_connect_error(code: int, message: String) -> void:
    connected = false
    connecting = false
    last_error = "%d %s" % [code, message]
    shop_changed.emit()

func _on_details(resp: Dictionary) -> void:
    if int(resp.get("response_code", -99)) == RESPONSE_OK:
        prices = ShopLogic.parse_prices(resp.get("product_details", []))
    else:
        last_error = str(resp.get("debug_message", ""))
    shop_changed.emit()

func _on_purchases_query(resp: Dictionary) -> void:
    if int(resp.get("response_code", -99)) == RESPONSE_OK:
        _take_purchases(resp.get("purchases", []))

func _on_purchase_updated(resp: Dictionary) -> void:
    busy = false
    var code: int = int(resp.get("response_code", -99))
    if code == RESPONSE_OK:
        _take_purchases(resp.get("purchases", []))
    elif code == RESPONSE_ITEM_ALREADY_OWNED:
        _client.call("query_purchases", _inapp())   # compra antiga não finalizada: recupera e entrega
    else:
        _fail(_error_text(code))
    shop_changed.emit()

func _on_finished(_resp: Dictionary) -> void:
    pass   # consumo/confirmação concluídos: nada a fazer (o livro já impede entrega duplicada)

# ---------------------------------------------------------------- entrega
func _take_purchases(list: Variant) -> void:
    if not (list is Array):
        return
    var purchased: int = _purchase_state("PURCHASED", 1)
    var pending: int = _purchase_state("PENDING", 2)
    for p in list:
        if not (p is Dictionary):
            continue
        var state: int = int(p.get("purchase_state", -1))
        var ids_v: Variant = p.get("product_ids", [])
        if state == pending:
            pending_msg = "Pagamento pendente: o pacote chega assim que o Google confirmar."
            purchase_pending.emit(pending_msg)
            continue
        if state != purchased:
            continue
        for id in ids_v:
            if ShopLogic.product(str(id)).is_empty():
                continue
            if str(id) == ShopLogic.LEGEND_ID:
                legend_google = true
            _queue.append({"id": str(id), "token": str(p.get("purchase_token", "")), "quantity": int(p.get("quantity", 1)),
                "consumable": ShopLogic.is_consumable(str(id)), "ack": bool(p.get("is_acknowledged", false))})
        pending_msg = ""
    _flush_queue()
    shop_changed.emit()

## Entrega só com um jogo aberto (no menu inicial não há para quem dar): fica na fila até o jogador entrar num jogo salvo.
func _flush_queue() -> void:
    if GameState.slot <= 0 and not _smoke:
        return
    var left: Array = []
    for q in _queue:
        var token: String = q["token"]
        if not ShopLogic.was_delivered(ledger, token):
            var r := ShopLogic.deliver(GameState.state, ledger, q["id"], token, int(q["quantity"]))
            if r["ok"]:
                _save_ledger()           # grava o livro ANTES de consumir: se o app cair aqui, não entrega 2x
                GameState.recalc()
                GameState.save()
                AudioHub.play("ui_buy")
                _say("COMPRA CONCLUÍDA: " + ShopLogic.delivered_text(r))
                purchase_done.emit(ShopLogic.delivered_text(r))
        if not bool(q.get("fake", false)) and _client != null:
            if bool(q["consumable"]):
                _client.call("consume_purchase", token)
            elif not bool(q["ack"]):
                _client.call("acknowledge_purchase", token)
    _queue = left
    shop_changed.emit()

func _say(text: String) -> void:
    _flash = text
    _flash_until = Time.get_ticks_msec() + 5000
    shop_changed.emit()

func _fail(message: String) -> void:
    _say(message)
    purchase_failed.emit(message)

func _error_text(code: int) -> String:
    match code:
        RESPONSE_USER_CANCELED:
            return "Compra cancelada."
        RESPONSE_ITEM_ALREADY_OWNED:
            return "Você já tem este pacote."
        2, 3, 12, -1, -3:
            return "Sem conexão com a Google Play. Tente de novo."
        4:
            return "Pacote indisponível na loja no momento."
    return "Não foi possível concluir a compra (erro %d)." % code

# ---------------------------------------------------------------- livro de entregas (arquivo próprio)
func _load_ledger() -> Dictionary:
    if not FileAccess.file_exists(LEDGER_FILE):
        return ShopLogic.default_ledger()
    var f := FileAccess.open(LEDGER_FILE, FileAccess.READ)
    if f == null:
        return ShopLogic.default_ledger()
    return ShopLogic.sanitize_ledger(JSON.parse_string(f.get_as_text()))

func _save_ledger() -> void:
    if _smoke:
        return
    var tmp := LEDGER_FILE + ".tmp"
    var f := FileAccess.open(tmp, FileAccess.WRITE)
    if f == null:
        return
    f.store_string(JSON.stringify(ledger))
    f.close()
    DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(LEDGER_FILE))

# ---------------------------------------------------------------- plugin por nome (sem dependência de compilação)
func _inapp() -> int:
    var v: Variant = _enum_value("ProductType", "INAPP")
    return int(v) if v != null else 0

func _purchase_state(key: String, fallback: int) -> int:
    var v: Variant = _enum_value("PurchaseState", key)
    return int(v) if v != null else fallback

func _global_class_path(cname: String) -> String:
    for c in ProjectSettings.get_global_class_list():
        if str(c.get("class", "")) == cname:
            return str(c.get("path", ""))
    return ""

func _make(cname: String) -> Object:
    var path: String = _global_class_path(cname)
    if path == "":
        return null
    var sc = load(path)
    return sc.new() if sc != null else null

func _enum_value(enum_name: String, key: String) -> Variant:
    var path: String = _global_class_path(CLIENT_CLASS)
    if path == "":
        return null
    var sc: Script = load(path) as Script
    if sc == null:
        return null
    var consts: Dictionary = sc.get_script_constant_map()
    if consts.has(enum_name) and consts[enum_name] is Dictionary:
        return consts[enum_name].get(key)
    return null
