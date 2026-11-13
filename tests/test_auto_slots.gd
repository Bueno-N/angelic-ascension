extends TestCase
## Automático por slot, migração do save antigo e trava de troca de habilidades em recarga.

func test_default_all_slots_auto() -> void:
    var st := SaveData.default_state()
    check(AutoCast.auto_count(st["settings"]) == 3, "padrão: 3 slots automáticos")
    for i in range(3):
        check(AutoCast.slot_auto(st["settings"], i), "slot %d automático" % i)

func test_toggle_individual_slots() -> void:
    var st := SaveData.default_state()
    check(Shop.toggle_slot_auto(st, 1), "alterna slot 2")
    check(not AutoCast.slot_auto(st["settings"], 1), "slot 2 manual")
    check(AutoCast.slot_auto(st["settings"], 0) and AutoCast.slot_auto(st["settings"], 2), "slots 1 e 3 intactos")
    check(AutoCast.auto_count(st["settings"]) == 2, "apenas 2 automáticos")
    Shop.toggle_slot_auto(st, 0)
    Shop.toggle_slot_auto(st, 2)
    check(AutoCast.auto_count(st["settings"]) == 0, "todos manuais")
    Shop.toggle_slot_auto(st, 1)
    check(AutoCast.auto_count(st["settings"]) == 1 and AutoCast.slot_auto(st["settings"], 1), "apenas o slot 2 automático")
    check(not Shop.toggle_slot_auto(st, 3), "índice inválido")
    check(not Shop.toggle_slot_auto(st, -1), "índice negativo")

func test_set_all_auto() -> void:
    var st := SaveData.default_state()
    Shop.set_all_auto(st, false)
    check(AutoCast.auto_count(st["settings"]) == 0, "todas manuais")
    Shop.set_all_auto(st, true)
    check(AutoCast.auto_count(st["settings"]) == 3, "todas automáticas")

func test_auto_slots_survive_save() -> void:
    var st := SaveData.default_state()
    Shop.toggle_slot_auto(st, 1)
    var back := SaveData.from_json(SaveData.to_json(st))
    check(AutoCast.slot_auto(back["settings"], 0), "slot 1 auto")
    check(not AutoCast.slot_auto(back["settings"], 1), "slot 2 manual")
    check(AutoCast.slot_auto(back["settings"], 2), "slot 3 auto")

func test_migration_from_old_global_flag() -> void:
    var off := SaveData.sanitize({"settings": {"auto_skills": false}})
    check(AutoCast.auto_count(off["settings"]) == 0, "auto_skills=false => todos manuais")
    var on := SaveData.sanitize({"settings": {"auto_skills": true}})
    check(AutoCast.auto_count(on["settings"]) == 3, "auto_skills=true => todos automáticos")

func test_sanitize_weird_auto_slots() -> void:
    var short := SaveData.sanitize({"settings": {"auto_slots": [false]}})
    check(short["settings"]["auto_slots"] == [false, true, true], "completa com automático")
    var long := SaveData.sanitize({"settings": {"auto_slots": [true, false, true, false, false]}})
    check(long["settings"]["auto_slots"].size() == 3, "trunca em 3")
    var junk := SaveData.sanitize({"settings": {"auto_slots": "abc"}})
    check(AutoCast.auto_count(junk["settings"]) == 3, "lixo => padrão")

func test_rule_text_for_every_skill() -> void:
    for id in SkillsDB.ids():
        check(AutoCast.rule_text(id).length() > 10, "regra descrita para " + str(id))

func test_unequip_lock_while_on_cooldown() -> void:
    var st := SaveData.default_state()
    st["gems"] = 1000
    for id in ["celestial_lance", "holy_shield"]:
        Shop.buy_skill(st, id)
        Shop.equip_skill(st, id)
    var slots := SkillSlots.new()
    slots.load_from_state(st)
    check(slots.can_unequip("celestial_lance"), "pronta: pode remover")
    slots.use("celestial_lance")
    check(not slots.can_unequip("celestial_lance"), "em recarga: NÃO pode remover")
    check(slots.can_unequip("holy_shield"), "a outra segue livre")
    slots.tick(7.9)
    check(not slots.can_unequip("celestial_lance"), "ainda travada aos 7,9 s")
    slots.tick(0.2)
    check(slots.can_unequip("celestial_lance"), "liberada após 8 s")

func test_no_cooldown_reset_exploit() -> void:
    # Cenário do bug original: usar, remover e recolocar para pagar só 2 s de recarga.
    var st := SaveData.default_state()
    st["gems"] = 1000
    Shop.buy_skill(st, "celestial_lance")
    Shop.equip_skill(st, "celestial_lance")
    var slots := SkillSlots.new()
    slots.load_from_state(st)
    slots.use("celestial_lance")
    slots.tick(1.0)
    check(not slots.can_unequip("celestial_lance"), "não dá para remover durante a recarga")
    check(slots.remaining("celestial_lance") > SkillsDB.EQUIP_DELAY, "recarga restante (7 s) maior que o atraso de equipar (2 s)")
