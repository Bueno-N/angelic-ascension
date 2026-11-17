class_name HudTop
extends Control
## Parte desenhada do HUD: perfil, VIDA VERDE, fase, contador de mobs, marcos (mini-chefe/chefe), recursos,
## barra do chefe e o banner de AVISO DE CHEFE. Não recebe toques (os botões são UiButton).

var hp := 100.0
var max_hp := 100.0
var boss_hp := 0.0
var boss_max := 0.0
var boss_name := ""
var boss_is_mini := false
var killed := 0
var total := 0
var label := "MOBS"
var repeat := false
var last_stage_secs := 0.0
var banner_t := 0.0
var banner_title := ""
var banner_sub := ""
var _pace_t := 0.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func show_banner(title: String, sub: String) -> void:
    banner_title = title
    banner_sub = sub
    banner_t = 3.0
    queue_redraw()

func _process(delta: float) -> void:
    _pace_t -= delta
    if banner_t > 0.0:
        banner_t -= delta
        queue_redraw()
    elif _pace_t <= 0.0:
        _pace_t = 1.0
        queue_redraw()

func _draw() -> void:
    var s: Dictionary = GameState.state
    var w: float = size.x
    # ---- cartão do jogador: nome, VIDA VERDE, fase e mobs ----
    UiTheme.panel(self, Rect2(12.0, 8.0, 384.0, 96.0), UiTheme.BG, UiTheme.GOLD)
    PixelFont.draw(self, Vector2(112.0, 18.0), str(s["profile"]["name"]), 2, UiTheme.GOLD)
    var bx := 112.0
    var by := 42.0
    var bw := 272.0
    var bh := 28.0
    draw_rect(Rect2(bx - 2.0, by - 2.0, bw + 4.0, bh + 4.0), Color(0, 0, 0, 0.85))
    var ratio: float = clampf(hp / maxf(max_hp, 1.0), 0.0, 1.0)
    draw_rect(Rect2(bx, by, bw, bh), Color(0.05, 0.12, 0.06, 1.0))
    draw_rect(Rect2(bx, by, bw * ratio, bh), UiTheme.GREEN_D)
    draw_rect(Rect2(bx, by, bw * ratio, bh * 0.55), UiTheme.GREEN)
    draw_rect(Rect2(bx, by + 3.0, bw * ratio, 3.0), Color(1, 1, 1, 0.28))
    var ht: String = "%d / %d" % [int(ceil(maxf(hp, 0.0))), int(max_hp)]
    PixelFont.draw(self, Vector2(bx + (bw - float(PixelFont.width(ht, 2))) / 2.0, by + 7.0), ht, 2, Color.WHITE)
    var stg: int = int(s["stage"])
    PixelFont.draw(self, Vector2(112.0, 78.0), "FASE %d%s" % [stg, " (repetindo)" if repeat else ""], 2, UiTheme.TEXT)
    # ---- barra de PROGRESSO da fase (mobs), no meio do topo da tela, com o contador dentro ----
    var mob_w := 440.0
    var mob_x: float = (w - mob_w) / 2.0
    var mob_y := 10.0
    var mob_h := 34.0
    var pr: float = clampf(float(killed) / maxf(float(total), 1.0), 0.0, 1.0)
    var special: bool = label != "MOBS"
    draw_rect(Rect2(mob_x - 3.0, mob_y - 3.0, mob_w + 6.0, mob_h + 6.0), UiTheme.GOLD_D)
    draw_rect(Rect2(mob_x - 1.0, mob_y - 1.0, mob_w + 2.0, mob_h + 2.0), Color(0, 0, 0, 0.9))
    draw_rect(Rect2(mob_x, mob_y, mob_w, mob_h), Color(0.07, 0.07, 0.16, 1.0))
    var fill_col: Color = Color(0.95, 0.5, 0.15) if special else Color(0.28, 0.5, 0.95)
    draw_rect(Rect2(mob_x, mob_y, mob_w * pr, mob_h), fill_col)
    draw_rect(Rect2(mob_x, mob_y, mob_w * pr, mob_h * 0.45), fill_col.lightened(0.25))
    var mt: String = "%s %d/%d" % [label, killed, total]
    PixelFont.draw(self, Vector2(mob_x + (mob_w - float(PixelFont.width(mt, 2))) / 2.0, mob_y + 10.0), mt, 2, Color.WHITE)
    # ---- recursos: ouro / gemas / fragmentos, logo EMBAIXO do cartão do anjo ----
    var items: Array = [["coin", int(s["gold"])], ["gem", int(s["gems"])], ["shard", int(s["shards"])]]
    var need := 16.0
    for it in items:
        need += 30.0 + float(PixelFont.width(UiLogic.fmt_int(int(it[1])), 2)) + 18.0
    UiTheme.panel(self, Rect2(12.0, 112.0, maxf(384.0, need), 44.0), UiTheme.BG, UiTheme.GOLD_D)
    var x := 24.0
    for it in items:
        var txt: String = UiLogic.fmt_int(int(it[1]))
        UiIcons.draw(self, str(it[0]), Rect2(x, 122.0, 24.0, 24.0))
        PixelFont.draw(self, Vector2(x + 30.0, 127.0), txt, 2, UiTheme.TEXT)
        x += 30.0 + float(PixelFont.width(txt, 2)) + 18.0 + maxf(0.0, 384.0 - need) / 3.0
    # ---- próximo marco e ritmo ----
    var ms := StageLogic.next_milestone(stg)
    if not ms.is_empty():
        var kind: String = "Mini-chefe" if ms["kind"] == "mini" else "Chefe"
        var when: String = "AGORA" if int(ms["in"]) == 0 else "na fase %d (em %d)" % [int(ms["stage"]), int(ms["in"])]
        PixelFont.draw(self, Vector2(16.0, 168.0), "Próx.: %s %s" % [kind, when], 2, UiTheme.TEXT_DIM)
    var pace := "Última fase: %s | Gemas/h: %s" % ["-" if last_stage_secs <= 0.0 else "%d s" % int(last_stage_secs),
        "-" if GameState.session_gems_per_hour() <= 0.0 else "%d" % int(GameState.session_gems_per_hour())]
    PixelFont.draw(self, Vector2(16.0, 188.0), ("[TESTE] " if DebugTools.enabled() else "") + pace, 2, Color(UiTheme.TEXT_DIM, 0.8))
    # ---- barra do chefe / mini-chefe (à direita dos botões de velocidade/fase, à esquerda do MENU) ----
    if boss_max > 0.0 and boss_hp > 0.0:
        var bx0 := 804.0
        var bx1: float = w - 212.0
        var bw2: float = maxf(160.0, bx1 - bx0)
        var cx: float = bx0 + bw2 / 2.0
        var nm: String = boss_name
        PixelFont.draw(self, Vector2(cx - float(PixelFont.width(nm, 2)) / 2.0, 56.0), nm, 2, Color(1.0, 0.7, 0.3) if boss_is_mini else Color(1.0, 0.35, 0.3))
        draw_rect(Rect2(bx0 - 2.0, 78.0, bw2 + 4.0, 26.0), Color(0, 0, 0, 0.85))
        var br: float = clampf(boss_hp / boss_max, 0.0, 1.0)
        draw_rect(Rect2(bx0, 80.0, bw2 * br, 22.0), Color(0.55, 0.08, 0.1))
        draw_rect(Rect2(bx0, 80.0, bw2 * br, 11.0), Color(0.9, 0.2, 0.18))
    # ---- banner de AVISO DE CHEFE ----
    if banner_t > 0.0:
        var a: float = clampf(banner_t / 0.6, 0.0, 1.0)
        var pulse: float = 0.5 + 0.5 * sin(banner_t * 14.0)
        var y: float = size.y * 0.22
        draw_rect(Rect2(0.0, y - 24.0, w, 132.0), Color(0, 0, 0, 0.5 * a))
        draw_rect(Rect2(0.0, y - 24.0, w, 4.0), Color(1.0, 0.25, 0.15, a))
        draw_rect(Rect2(0.0, y + 104.0, w, 4.0), Color(1.0, 0.25, 0.15, a))
        var col := Color(1.0, 0.22 + 0.3 * pulse, 0.15, a)
        PixelFont.draw(self, Vector2((w - float(PixelFont.width(banner_title, 5))) / 2.0, y), banner_title, 5, col)
        PixelFont.draw(self, Vector2((w - float(PixelFont.width(banner_sub, 3))) / 2.0, y + 58.0), banner_sub, 3, Color(1.0, 0.9, 0.7, a))
