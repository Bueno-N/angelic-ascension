class_name WingsDB
extends RefCounted
## Asas (fragmentos de chefe -> % em TODOS os atributos) e Brilho (gemas -> % nas habilidades).

const MAX_LEVEL := 10
const BONUS_PER_LEVEL := 0.05      # nível 1 = +5%, nível 2 = +10%...

static func bonus_for_level(level: int) -> float:
    return BONUS_PER_LEVEL * float(clampi(level, 0, MAX_LEVEL))

## Fragmentos para ir de `level` para `level+1` (0 se já no máximo).
static func shards_for_next(level: int) -> int:
    if level >= MAX_LEVEL:
        return 0
    return int(ceil(2.0 * pow(1.5, float(level))))

# Preços de brilho = PLACEHOLDERS (o design não os definiu).
const GLOW := [
    {"name": "Brilho Celestial", "bonus": 0.05, "price": 50},
    {"name": "Luz Sagrada", "bonus": 0.10, "price": 200},
    {"name": "Luz Divina", "bonus": 0.20, "price": 800},
    {"name": "Aura do Arcanjo", "bonus": 0.35, "price": 3000},
    {"name": "Luz do Paraíso", "bonus": 0.50, "price": 12000},
    {"name": "Esplendor do Criador", "bonus": 0.75, "price": 50000},
]

static func glow_bonus(tier: int) -> float:
    if tier < 1 or tier > GLOW.size():
        return 0.0
    return float(GLOW[tier - 1]["bonus"])
