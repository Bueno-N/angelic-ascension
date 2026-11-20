class_name AngelDraw
extends RefCounted
## Cores por tier de equipamento (usadas no menu). O desenho antigo do anjo com espada foi removido.

const TIER_COLORS := [
    Color(0.75, 0.78, 0.85), Color(0.6, 0.85, 0.6), Color(0.45, 0.7, 1.0),
    Color(0.75, 0.5, 1.0), Color(1.0, 0.7, 0.3), Color(1.0, 0.95, 0.6),
]
const SKIN := Color(0.95, 0.85, 0.5)

static func tier_color(tier: int) -> Color:
    return TIER_COLORS[clampi(tier, 1, TIER_COLORS.size()) - 1]
