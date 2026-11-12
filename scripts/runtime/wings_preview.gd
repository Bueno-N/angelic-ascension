class_name WingsPreview
extends Control

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.02, 0.07, 0.9))
    AngelDraw.draw_angel(self, int(GameState.state["wings_level"]), int(GameState.state["glow_tier"]), 1.6)
