class_name MenuPanel
extends Control
## Menu em duas etapas: 1) grade de ícones (Loja, Atributos, Habilidades, Asas, Equipamentos, Opções [+ Teste]);
## 2) ao tocar num ícone, abre a lista daquela aba para comprar/evoluir. Com o menu aberto o JOGO PAUSA (o HUD cuida disso).

const HEAD := 92.0
const PREVIEW_W := 300.0     # prévia do anjo (asas/equipamentos) numa coluna à esquerda; a lista usa o resto da largura
var _mode := "grid"
var _tabs: Array = []
var _tiles: Array = []
var _back: UiButton
var _close: UiButton
var _list: UiList
var _angel: AngelSprite
var _dirty := true
var _timer := 0.0
var _reset_armed := false
var _last_rows: Array = []

func _ready() -> void:
    # Ocupa a tela toda, por cima da fase (o jogo segue rodando), só deixando livre a coluna de botões à direita
    # (MENU / FASES / BOSS SEMANAL): o jogador fecha esta aba para usar as outras.
    anchor_left = 0.0
    anchor_right = 1.0
    anchor_top = 0.0
    anchor_bottom = 1.0
    offset_left = 16.0
    offset_right = -212.0
    offset_top = 16.0
    offset_bottom = -16.0
    visible = false
    mouse_filter = Control.MOUSE_FILTER_STOP
    _tabs = MenuModel.tabs(DebugTools.enabled())
    for t in _tabs:
        var b := UiButton.new()
        b.tile = true
        b.configure(str(t["name"]), str(t["icon"]))
        b.pressed.connect(_open_tab.bind(str(t["id"])))
        add_child(b)
        _tiles.append(b)
    _back = UiButton.new()
    _back.configure("VOLTAR", "back")
    _back.pressed.connect(_show_grid)
    add_child(_back)
    _close = UiButton.new()
    _close.configure("", "close", UiTheme.RED)
    _close.pressed.connect(close)
    add_child(_close)
    _list = UiList.new()
    _list.action.connect(_on_action)
    add_child(_list)
    _angel = AngelSprite.new()
    add_child(_angel)
    resized.connect(_apply_layout)
    Events.state_changed.connect(func(): _dirty = true)
    ShopManager.shop_changed.connect(func(): _dirty = true)
    _apply_layout()

## Só para o smoke do CI: abre uma aba / volta à grade.
func debug_open(id: String) -> void:
    visible = true
    _open_tab(id)

func toggle() -> void:
    visible = not visible
    if visible:
        _mode = "grid"
        _apply_layout()
        _dirty = true

func close() -> void:
    visible = false

func _tab_name(id: String) -> String:
    for t in _tabs:
        if t["id"] == id:
            return str(t["name"])
    return ""

func _show_grid() -> void:
    _mode = "grid"
    _apply_layout()

func _open_tab(id: String) -> void:
    _mode = id
    _reset_armed = false
    _last_rows = []
    _list.scroll_to_top()
    _rebuild()
    _apply_layout()

func _apply_layout() -> void:
    if _list == null:
        return
    var w: float = size.x
    var h: float = size.y
    var grid: bool = _mode == "grid"
    _close.position = Vector2(w - 62.0, 12.0)
    _close.size = Vector2(50.0, 50.0)
    _back.visible = not grid
    _back.position = Vector2(12.0, 12.0)
    _back.size = Vector2(170.0, 50.0)
    var cols := 3
    var rows: int = ceili(float(_tiles.size()) / float(cols))
    var gap := 14.0
    var tw: float = (w - 28.0 - gap * float(cols - 1)) / float(cols)
    var th: float = minf(150.0, (h - HEAD - 20.0 - gap * float(rows - 1)) / float(rows))
    for i in range(_tiles.size()):
        _tiles[i].visible = grid
        _tiles[i].position = Vector2(14.0 + float(i % cols) * (tw + gap), HEAD + 10.0 + float(floori(float(i) / float(cols))) * (th + gap))
        _tiles[i].size = Vector2(tw, th)
    var preview: bool = (not grid) and MenuModel.tab_has_preview(_mode)
    var lx: float = 8.0 + (PREVIEW_W + 8.0 if preview else 0.0)
    _list.visible = not grid
    _list.position = Vector2(lx, HEAD)
    _list.size = Vector2(maxf(40.0, w - lx - 8.0), maxf(40.0, h - HEAD - 8.0))
    _angel.visible = preview
    _angel.position = Vector2(8.0 + PREVIEW_W / 2.0, HEAD + (h - HEAD) / 2.0)
    queue_redraw()

func _cooldowns() -> Dictionary:
    var d := {}
    for id in GameState.state["skills_equipped"]:
        d[id] = GameState.skill_remaining(id)
    return d

func _rebuild() -> void:
    var rows := MenuModel.rows(_mode, GameState.state, GameState.stats, {"cooldowns": _cooldowns(), "reset_armed": _reset_armed,
        "shop": ShopManager.menu_ctx() if _mode == "shop" else {}})
    if rows != _last_rows:
        _last_rows = rows
        _list.set_rows(rows)
    if MenuModel.tab_has_preview(_mode):
        _angel.set_look(int(GameState.state["wings_level"]), int(GameState.state["glow_tier"]), GameState.state["equipped"])

func _on_action(id: String) -> void:
    if id.begins_with("iap|"):          # loja paga: quem cobra é o Google (ShopManager), não o MenuModel
        AudioHub.play("ui_click")
        ShopManager.buy(id.substr(4))
        _last_rows = []
        _rebuild()
        return
    if id == "debug|reset|0" and not _reset_armed:
        _reset_armed = true          # reset exige dois toques
        _rebuild()
        return
    _reset_armed = false
    GameState.menu_action(id)
    _last_rows = []
    _rebuild()
    queue_redraw()

func _process(delta: float) -> void:
    if not visible:
        return
    _timer -= delta
    if _timer > 0.0:
        return
    _timer = 0.25
    if _dirty or _mode == "skills":   # recargas das habilidades mudam a cada segundo
        _dirty = false
        queue_redraw()
        if _mode != "grid":
            _rebuild()

func _draw() -> void:
    UiTheme.panel(self, Rect2(Vector2.ZERO, size), UiTheme.BG, UiTheme.GOLD)
    var title: String = "MENU" if _mode == "grid" else _tab_name(_mode)
    var tx: float = 22.0 if _mode == "grid" else 198.0
    PixelFont.draw(self, Vector2(tx, 24.0), title, 3, UiTheme.GOLD)
    var s: Dictionary = GameState.state
    var x := 22.0
    for it in [["coin", int(s["gold"])], ["gem", int(s["gems"])], ["shard", int(s["shards"])]]:
        var txt: String = UiLogic.fmt_int(int(it[1]))
        UiIcons.draw(self, str(it[0]), Rect2(x, 62.0, 24.0, 24.0))
        PixelFont.draw(self, Vector2(x + 30.0, 67.0), txt, 2, UiTheme.TEXT)
        x += 30.0 + float(PixelFont.width(txt, 2)) + 26.0
    if _mode != "grid" and MenuModel.tab_has_preview(_mode):
        UiTheme.panel(self, Rect2(8.0, HEAD, PREVIEW_W, size.y - HEAD - 8.0), Color(0.04, 0.03, 0.09, 1.0), UiTheme.GOLD_D)
