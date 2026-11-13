class_name WingsPreview
extends Control
## Prévia do anjo (asas, brilho e equipamentos), usada nas abas Equip. e Asas.

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.02, 0.07, 0.9))
    var origin := Vector2(size.x * 0.5, size.y * 0.55)
    draw_set_transform(origin, 0.0, Vector2.ONE)
    AngelDraw.draw_angel(self, int(GameState.state["wings_level"]), int(GameState.state["glow_tier"]), 1.6, GameState.state["equipped"])
