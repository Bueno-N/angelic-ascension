class_name ShopLogic
extends RefCounted
## Loja PAGA (Google Play Billing): LÓGICA PURA, sem plugin nem autoloads. Testada em tests/test_shop.gd.
## - Catálogo: IDs iguais aos do Play Console (Monetizar > Produtos > Produtos no app). O PREÇO cobrado é o do Play Console;
##   "ref_price" só aparece quando a loja do Google não respondeu (PC, sem internet) e serve de referência.
## - Entrega: cada compra tem um token único do Google. O "livro" (ledger) guarda os tokens já entregues, para a mesma compra
##   nunca dar gemas/ouro duas vezes (ex.: o app fechou antes de consumir e o Google devolve a compra de novo ao abrir).
## - Pacote Lendário: compra única (não consumível) e só liberado DEPOIS de passar da fase 50 (fase máxima >= 51).

const LEGEND_ID := "pack_legend_50000"
const LEGEND_MIN_STAGE := 51          # "ao passar da fase 50"
const LEDGER_MAX := 200               # tokens guardados (os mais antigos saem; consumíveis já consumidos não voltam)

const CATALOG := [
    {"id": "gems_5000", "kind": "gems", "amount": 5000, "ref_price": "R$ 2,99", "consumable": true,
        "title": "5.000 gemas", "sub": "Pacote de gemas"},
    {"id": "gems_10000", "kind": "gems", "amount": 10000, "ref_price": "R$ 5,00", "consumable": true,
        "title": "10.000 gemas", "sub": "O dobro de gemas"},
    {"id": "gems_25000", "kind": "gems", "amount": 25000, "ref_price": "R$ 13,99", "consumable": true,
        "title": "25.000 gemas", "sub": "Baú de gemas"},
    {"id": LEGEND_ID, "kind": "gems", "amount": 50000, "ref_price": "R$ 10,00", "consumable": false,
        "title": "Pacote Lendário: 50.000 gemas", "sub": "OFERTA ÚNICA: só 1 vez por conta"},
    {"id": "gold_50000", "kind": "gold", "amount": 50000, "ref_price": "R$ 0,99", "consumable": true,
        "title": "50.000 de ouro", "sub": "Saco de ouro"},
    {"id": "gold_100000", "kind": "gold", "amount": 100000, "ref_price": "R$ 1,79", "consumable": true,
        "title": "100.000 de ouro", "sub": "Baú de ouro  |  10% mais barato"},
    {"id": "gold_250000", "kind": "gold", "amount": 250000, "ref_price": "R$ 3,99", "consumable": true,
        "title": "250.000 de ouro", "sub": "Tesouro de ouro  |  20% mais barato"},
]

static func product(id: String) -> Dictionary:
    for p in CATALOG:
        if p["id"] == id:
            return p
    return {}

static func ids() -> PackedStringArray:
    var out := PackedStringArray()
    for p in CATALOG:
        out.append(str(p["id"]))
    return out

static func is_consumable(id: String) -> bool:
    return bool(product(id).get("consumable", true))

# ---------------------------------------------------------------- livro de entregas (arquivo global, vale para todos os jogos)
## {"tokens": [token...], "legend": bool}
static func default_ledger() -> Dictionary:
    return {"tokens": [], "legend": false}

static func sanitize_ledger(raw: Variant) -> Dictionary:
    var l := default_ledger()
    if raw is Dictionary:
        var t: Variant = raw.get("tokens", [])
        if t is Array:
            for x in t:
                if x is String and x != "" and not l["tokens"].has(x):
                    l["tokens"].append(x)
        var lg: Variant = raw.get("legend", false)
        l["legend"] = lg is bool and lg
    while l["tokens"].size() > LEDGER_MAX:
        l["tokens"].pop_front()
    return l

static func was_delivered(ledger: Dictionary, token: String) -> bool:
    return ledger["tokens"].has(token)

# ---------------------------------------------------------------- regras de compra
## "" = pode comprar; senão o motivo (mostrado no botão/aviso).
static func block_reason(id: String, max_stage: int, ledger: Dictionary, legend_owned_on_google: bool = false) -> String:
    var p := product(id)
    if p.is_empty():
        return "Produto desconhecido"
    if id == LEGEND_ID:
        if bool(ledger.get("legend", false)) or legend_owned_on_google:
            return "Já comprado"
        if max_stage < LEGEND_MIN_STAGE:
            return "Passe da fase 50"
    return ""

## Entrega a compra no estado do jogo. Devolve {"ok": bool, "kind": "gems"/"gold", "amount": int}.
## ok=false se o token já foi entregue ou o produto não existe (nada muda). quantity: compras múltiplas (normalmente 1).
## O Pacote Lendário é entregue mesmo antes da fase 51 (se o Google cobrou, o jogador recebe).
static func deliver(state: Dictionary, ledger: Dictionary, id: String, token: String, quantity: int = 1) -> Dictionary:
    var p := product(id)
    if p.is_empty() or token == "" or was_delivered(ledger, token):
        return {"ok": false, "kind": "", "amount": 0}
    var amount: int = int(p["amount"]) * maxi(1, quantity)
    var key: String = "gems" if p["kind"] == "gems" else "gold"
    state[key] = int(state.get(key, 0)) + amount
    ledger["tokens"].append(token)
    while ledger["tokens"].size() > LEDGER_MAX:
        ledger["tokens"].pop_front()
    if id == LEGEND_ID:
        ledger["legend"] = true
    return {"ok": true, "kind": str(p["kind"]), "amount": amount}

static func delivered_text(result: Dictionary) -> String:
    var what: String = "GEMAS" if result.get("kind", "") == "gems" else "DE OURO"
    return "+%s %s" % [UiLogic.fmt_int(int(result.get("amount", 0))), what]

# ---------------------------------------------------------------- dados que vêm do plugin
## O formato de cada "product_details" do plugin não está documentado: procura as chaves em qualquer nível.
static func find_key(d: Variant, keys: Array) -> String:
    if d is Dictionary:
        for k in keys:
            if d.has(k) and (d[k] is String) and str(d[k]) != "":
                return str(d[k])
        for v in d.values():
            var r := find_key(v, keys)
            if r != "":
                return r
    elif d is Array:
        for v in d:
            var r := find_key(v, keys)
            if r != "":
                return r
    return ""

## Lista de product_details -> {id: "R$ 2,99"} (preço formatado na moeda do jogador).
static func parse_prices(details: Variant) -> Dictionary:
    var out := {}
    if details is Array:
        for d in details:
            var id := find_key(d, ["product_id", "productId", "id"])
            var price := find_key(d, ["formatted_price", "formattedPrice", "price"])
            if id != "" and price != "":
                out[id] = clean_text(price)
    return out

## A fonte pixel não tem todos os símbolos (ex.: o espaço especial que o Android põe em "R$ 2,99"): troca o que não sabe desenhar.
static func clean_text(s: String) -> String:
    var out := ""
    for i in range(s.length()):
        var c: String = s[i]
        if c == " " or c == " ":
            out += " "
        elif SpriteManifest.FONT_CHARS.contains(c):
            out += c
    return out.strip_edges()

static func price_text(id: String, prices: Dictionary) -> String:
    return str(prices.get(id, product(id).get("ref_price", "")))

# ---------------------------------------------------------------- linhas da aba "Loja" (MenuModel desenha)
## ctx: {"prices": {id: preço}, "status": texto de situação, "max_stage": int, "ledger": {}, "legend_google": bool, "busy": bool}
static func rows(ctx: Dictionary) -> Array:
    var prices: Dictionary = ctx.get("prices", {})
    var max_stage: int = int(ctx.get("max_stage", 1))
    var ledger: Dictionary = ctx.get("ledger", default_ledger())
    var legend_google: bool = bool(ctx.get("legend_google", false))
    var busy: bool = bool(ctx.get("busy", false))
    var out: Array = []
    var status: String = str(ctx.get("status", ""))
    if status != "":
        out.append({"kind": "info", "sub": status})
    out.append({"kind": "header", "title": "Oferta lendária"})
    out.append(_row(LEGEND_ID, "crown", prices, max_stage, ledger, legend_google, busy))
    out.append({"kind": "header", "title": "Gemas"})
    for id in ["gems_5000", "gems_10000", "gems_25000"]:
        out.append(_row(id, "gem", prices, max_stage, ledger, legend_google, busy))
    out.append({"kind": "header", "title": "Ouro"})
    for id in ["gold_50000", "gold_100000", "gold_250000"]:
        out.append(_row(id, "coins", prices, max_stage, ledger, legend_google, busy))
    out.append({"kind": "info", "sub": "Pagamento seguro pelo Google Play.\nAs gemas e o ouro vão para o jogo aberto agora."})
    return out

static func _row(id: String, icon: String, prices: Dictionary, max_stage: int, ledger: Dictionary, legend_google: bool, busy: bool) -> Dictionary:
    var p := product(id)
    var reason := block_reason(id, max_stage, ledger, legend_google)
    var sub: String = str(p["sub"])
    if id == LEGEND_ID and reason == "Passe da fase 50":
        sub += "\nLibera depois de passar da fase 50 (você está na %d)" % max_stage
    var row := {"kind": "item", "icon": icon, "title": str(p["title"]), "sub": sub, "cost": 0, "cost_icon": "",
        "action": "iap|" + id, "tone": "buy", "enabled": reason == "" and not busy, "poor": false}
    if reason == "":
        row["button"] = "COMPRAR"
        row["price"] = price_text(id, prices)
    elif reason == "Já comprado":
        row["button"] = "COMPRADO"
        row["tone"] = "active"
        row["action"] = ""
    else:
        row["button"] = "FASE 51"
        row["tone"] = "locked"
        row["action"] = ""
    return row
