class_name VirtualJoystick
extends Control
## Joystick flutuante: aparece onde o dedo toca (metade esquerda da tela).
## Limitação conhecida: 1 toque por vez (multitoque para habilidades virá na etapa 9).

const RADIUS := 90.0
var output := Vector2.ZERO
var _active := false
var _center := Vector2.ZERO

func _ready() -> void:
    anchor_left = 0.0
    anchor_top = 0.3
    anchor_right = 0.45
    anchor_bottom = 1.0
    offset_left = 0.0
    offset_top = 0.0
    offset_right = 0.0
    offset_bottom = 0.0
    mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        _active = event.pressed
        _center = event.position
        output = Vector2.ZERO
        queue_redraw()
    elif event is InputEventMouseMotion and _active:
        output = ((event.position - _center) / RADIUS).limit_length(1.0)
        queue_redraw()

func _draw() -> void:
    if not _active:
        return
    draw_circle(_center, RADIUS, Color(1, 1, 1, 0.08))
    draw_arc(_center, RADIUS, 0.0, TAU, 32, Color(1, 1, 1, 0.35), 2.0)
    draw_circle(_center + output * RADIUS, 28.0, Color(1.0, 0.95, 0.7, 0.6))
