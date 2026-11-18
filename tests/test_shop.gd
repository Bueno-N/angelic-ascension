extends TestCase
## Loja paga (Google Play Billing): catálogo, entrega sem duplicar, Pacote Lendário (uma vez, depois da fase 50) e a aba Loja.

func test_catalog_matches_the_requested_packs() -> void:
    var want := {"gems_5000": 5000, "gems_10000": 10000, "gems_25000": 25000, "pack_legend_50000": 50000,
        "gold_50000": 50000, "gold_100000": 100000, "gold_250000": 250000}
    check(ShopLogic.CATALOG.size() == want.size(), "7 produtos")
    for id in want:
        check(int(ShopLogic.product(id).get("amount", 0)) == int(want[id]), "quantidade de " + id)
        check(ShopLogic.ids().has(id), "id na lista consultada no Google: " + id)
    check(ShopLogic.product("gems_5000")["ref_price"] == "R$ 2,99", "5.000 gemas: R$ 2,99")
    check(ShopLogic.product("gems_10000")["ref_price"] == "R$ 5,00", "10.000 gemas: R$ 5,00")
    check(ShopLogic.product("gems_25000")["ref_price"] == "R$ 13,99", "25.000 gemas: R$ 13,99")
    check(ShopLogic.product(ShopLogic.LEGEND_ID)["ref_price"] == "R$ 10,00", "lendário: R$ 10,00")
    check(not ShopLogic.is_consumable(ShopLogic.LEGEND_ID), "lendário NÃO é consumível (compra única)")
    check(ShopLogic.is_consumable("gold_250000") and ShopLogic.is_consumable("gems_5000"), "pacotes comuns são consumíveis")
    for p in ShopLogic.CATALOG:
        var id: String = p["id"]
        check(id == id.to_lower() and id.length() <= 40, "id válido no Play Console: " + id)

func test_deliver_adds_gems_or_gold_once_per_token() -> void:
    var s := SaveData.default_state()
    var l := ShopLogic.default_ledger()
    var g0: int = int(s["gems"])
    var r := ShopLogic.deliver(s, l, "gems_10000", "tok-1")
    check(r["ok"] and int(s["gems"]) == g0 + 10000, "+10.000 gemas")
    check(not ShopLogic.deliver(s, l, "gems_10000", "tok-1")["ok"] and int(s["gems"]) == g0 + 10000, "mesmo token: não entrega de novo")
    var gold0: int = int(s["gold"])
    check(ShopLogic.deliver(s, l, "gold_250000", "tok-2")["ok"] and int(s["gold"]) == gold0 + 250000, "+250.000 de ouro")
    check(not ShopLogic.deliver(s, l, "nao_existe", "tok-3")["ok"], "produto desconhecido: nada")
    check(not ShopLogic.deliver(s, l, "gems_5000", "")["ok"], "sem token: nada")
    check(ShopLogic.deliver(s, l, "gems_5000", "tok-4", 3)["amount"] == 15000, "quantidade 3: 15.000")
    check(ShopLogic.delivered_text({"kind": "gold", "amount": 50000}) == "+50.000 DE OURO", "texto do aviso")

func test_legend_pack_only_after_stage_50_and_only_once() -> void:
    var l := ShopLogic.default_ledger()
    var id := ShopLogic.LEGEND_ID
    check(ShopLogic.block_reason(id, 1, l) == "Passe da fase 50", "fase 1: bloqueado")
    check(ShopLogic.block_reason(id, 50, l) == "Passe da fase 50", "na fase 50 ainda não passou dela")
    check(ShopLogic.block_reason(id, 51, l) == "", "passou da 50: liberado")
    check(ShopLogic.block_reason(id, 51, l, true) == "Já comprado", "o Google diz que já é dono: bloqueado")
    var s := SaveData.default_state()
    check(ShopLogic.deliver(s, l, id, "leg-1")["amount"] == 50000, "entrega 50.000 gemas")
    check(l["legend"] and ShopLogic.block_reason(id, 300, l) == "Já comprado", "comprado: nunca mais")
    check(ShopLogic.block_reason("gems_5000", 1, l) == "", "pacotes comuns: sempre liberados")

func test_ledger_sanitize_and_limit() -> void:
    check(ShopLogic.sanitize_ledger(null) == ShopLogic.default_ledger(), "sem arquivo: padrão")
    check(ShopLogic.sanitize_ledger({"tokens": "x", "legend": "sim"}) == ShopLogic.default_ledger(), "lixo: padrão")
    var many: Array = []
    for i in range(ShopLogic.LEDGER_MAX + 30):
        many.append("t%d" % i)
    var l := ShopLogic.sanitize_ledger({"tokens": many + ["t1", 5], "legend": true})
    check(l["tokens"].size() == ShopLogic.LEDGER_MAX and l["legend"], "limite de tokens e lendário preservado")
    check(l["tokens"].has("t%d" % (ShopLogic.LEDGER_MAX + 29)), "os mais novos ficam")

func test_prices_come_from_google_details() -> void:
    var details := [
        {"product_id": "gems_5000", "title": "5.000 gemas (Angelic Ascension)", "one_time_purchase_offer_details_list":
            [{"price_amount_micros": 2990000, "price_currency_code": "BRL", "formatted_price": "R$ 2,99", "offer_id": null}],
            "subscription_offer_details": null},
        {"productId": "gold_50000", "oneTimePurchaseOfferDetailsList": [{"formattedPrice": "R$ 0,99"}]},
        {"title": "sem id"},
    ]
    var prices := ShopLogic.parse_prices(details)
    check(prices.get("gems_5000", "") == "R$ 2,99", "preço formatado (espaço especial trocado)")
    check(prices.get("gold_50000", "") == "R$ 0,99", "formato alternativo")
    check(prices.size() == 2, "item sem id é ignorado")
    check(ShopLogic.price_text("gems_25000", prices) == "R$ 13,99", "sem resposta do Google: preço de referência")
    check(ShopLogic.clean_text("€ 1,99") == "1,99", "símbolo que a fonte não desenha é removido")

func test_shop_tab_rows() -> void:
    check(MenuModel.tabs(false)[0]["id"] == "shop" and MenuModel.tabs(false)[0]["icon"] == "shop", "Loja é a primeira aba do MENU")
    var rows: Array = ShopLogic.rows({"prices": {}, "max_stage": 10, "ledger": ShopLogic.default_ledger()})
    var buy := 0
    var legend: Dictionary = {}
    for r in rows:
        if r["kind"] == "item" and r["enabled"]:
            buy += 1
            check(str(r["action"]).begins_with("iap|") and str(r.get("price", "")) != "", "botão com preço: " + str(r["title"]))
        if r["kind"] == "item" and str(r["title"]).contains("Lendário"):
            legend = r
        for k in ["title", "sub", "button", "price"]:
            for ch in str(r.get(k, "")):
                check(SpriteManifest.FONT_CHARS.contains(ch) or ch == "\n", "a fonte desenha '%s' em %s" % [ch, str(r.get("title", ""))])
    check(buy == 6, "6 pacotes compráveis antes da fase 51")
    check(not legend.is_empty() and not legend["enabled"] and legend["button"] == "FASE 51", "lendário bloqueado na fase 10")
    var busy: Array = ShopLogic.rows({"max_stage": 60, "busy": true})
    for r in busy:
        if r["kind"] == "item":
            check(not r["enabled"], "compra em andamento: botões travados")
    var ctx_rows: Array = MenuModel.rows("shop", SaveData.default_state(), {}, {"shop": {"max_stage": 60}})
    var on := 0
    for r in ctx_rows:
        if r["kind"] == "item" and r["enabled"]:
            on += 1
    check(on == 7, "fase 60: os 7 pacotes liberados")
    for n in ["shop", "crown", "coins"]:
        check(SpriteManifest.ICON_NAMES.has(n), "ícone " + n)
    check(SpriteManifest.FONT_CHARS.contains("$"), "a fonte desenha o cifrão")
