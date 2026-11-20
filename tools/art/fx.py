"""Efeitos (aura, golpe, impacto, explosões, raio de luz, escudo, projétil), aliados, espada orbital,
tocha e chão. ORIGINAIS. Efeitos são claros/brancos: o jogo os TINGE (modulate) e usa mistura aditiva."""
import math, random
from pixel import *

WHITE = hexc('#ffffff'); GOLDL = hexc('#ffe9a0'); GOLD = hexc('#f0c24a')

def A(c, a): return (c[0], c[1], c[2], max(0, min(255, int(a))))

# ---------------------------------------------------------------- AURA (anel rúnico giratório) 112x112 x8
def aura():
    fr = []
    for i in range(8):
        c = Canvas(112, 112)
        cx = cy = 55.5
        rot = math.radians(i * 15 / 8.0)
        for k in range(24):                                   # anel externo tracejado (período 15°)
            a0 = rot + k * math.radians(15)
            for s in range(0, 8):
                a = a0 + math.radians(s)
                for r in (51, 52):
                    c.px(cx + math.cos(a) * r, cy - math.sin(a) * r, A(GOLDL, 210))
        for s in range(360):                                  # anel interno fino
            a = math.radians(s)
            c.px(cx + math.cos(a) * 46, cy - math.sin(a) * 46, A(GOLD, 120))
        rot2 = -math.radians(i * 45 / 8.0)
        for k in range(8):                                    # runas em losango (período 45°)
            a = rot2 + k * math.radians(45)
            x, y = cx + math.cos(a) * 49, cy - math.sin(a) * 49
            c.poly([(x, y - 3), (x + 2.5, y), (x, y + 3), (x - 2.5, y)], A(WHITE, 235))
            c.px(x, y, A(GOLD, 255))
        for k in range(4):                                    # luzes pequenas ao redor
            a = rot * 3 + k * math.pi / 2
            c.px(cx + math.cos(a) * 40, cy - math.sin(a) * 40, A(WHITE, 160))
        fr.append(c)
    return fr

# ---------------------------------------------------------------- IMPACTO (faíscas) 24x24 x4
def hit():
    fr = []
    for f in range(4):
        c = Canvas(24, 24)
        L = 3 + f * 3
        fade = 1.0 - f * 0.22
        for d in range(8):
            a = math.radians(d * 45 + 22)
            r0 = 1 + f * 1.5
            c.line(11.5 + math.cos(a) * r0, 11.5 - math.sin(a) * r0, 11.5 + math.cos(a) * L, 11.5 - math.sin(a) * L, A(mix(GOLDL, WHITE, 0.5), 255 * fade), 2 if f < 2 else 1)
        if f < 2:
            c.ell(11.5, 11.5, 4 - f * 1.5, 4 - f * 1.5, A(WHITE, 255))
        fr.append(c)
    return fr

# ---------------------------------------------------------------- EXPLOSÃO EM ANEL 64x64 x6
def burst():
    fr = []
    R = [8, 16, 24, 29, 31, 32]; T = [7, 6, 5, 4, 3, 2]; AL = [255, 240, 210, 160, 100, 50]
    rng = random.Random(5)
    for f in range(6):
        c = Canvas(64, 64)
        r, t = R[f], T[f]
        c.ell(31.5, 31.5, r, r, A(WHITE, AL[f]))
        c.ell(31.5, 31.5, max(r - t, 0.1), max(r - t, 0.1), None)
        if f < 5:
            c.ell(31.5, 31.5, max(r - t - 2, 0.1) * 0.9, max(r - t - 2, 0.1) * 0.9, A(GOLDL, AL[f] * 0.18))
        for k in range(14):
            a = rng.random() * math.tau
            rr = r + 2 + rng.random() * 3
            c.px(31.5 + math.cos(a) * rr, 31.5 - math.sin(a) * rr, A(WHITE, AL[f]))
        fr.append(c)
    return fr

# ---------------------------------------------------------------- RAIO DE LUZ (pilar) 32x96 x6
def strike():
    fr = []
    Wd = [3, 9, 14, 12, 8, 4]; AL = [255, 255, 230, 190, 120, 60]
    rng = random.Random(9)
    for f in range(6):
        c = Canvas(32, 96)
        w = Wd[f]
        c.rect(16 - w, 0, 15 + w, 88, A(GOLD, AL[f] * 0.55))
        c.rect(16 - w // 2 - 1, 0, 15 + w // 2 + 1, 88, A(WHITE, AL[f]))
        c.ell(15.5, 90, 4 + f * 2.4, 2 + f * 0.9, A(WHITE, AL[f]))
        for k in range(10):
            c.px(rng.randint(16 - w - 3, 15 + w + 3), rng.randint(10, 85), A(GOLDL, AL[f]))
        fr.append(c)
    return fr

# ---------------------------------------------------------------- ESCUDO (bolha) 64x64 x4
def shield():
    fr = []
    for i in range(4):
        c = Canvas(64, 64)
        c.ell(31.5, 31.5, 30, 30, A(WHITE, 38))
        for s in range(360):
            a = math.radians(s)
            c.px(31.5 + math.cos(a) * 30, 31.5 - math.sin(a) * 30, A(WHITE, 190))
            c.px(31.5 + math.cos(a) * 29, 31.5 - math.sin(a) * 29, A(WHITE, 90))
        for base in (0, 180):
            a0 = math.radians(base + i * 45 + 25)
            for s in range(0, 40):
                a = a0 + math.radians(s)
                for r in (26, 27, 28):
                    c.px(31.5 + math.cos(a) * r, 31.5 - math.sin(a) * r, A(WHITE, 230))
        fr.append(c)
    return fr

# ---------------------------------------------------------------- MORTE DO INIMIGO 32x32 x6
def poof():
    fr = []
    rng = random.Random(21)
    specks = [(rng.random() * math.tau, 3 + rng.random() * 4) for _ in range(16)]
    for f in range(6):
        c = Canvas(32, 32)
        fade = 1.0 - f / 6.0
        r = 3 + f * 2.4
        c.ell(15.5, 15.5, r, r, A(WHITE, 200 * fade))
        c.ell(15.5, 15.5, max(r - 3.5, 0.1), max(r - 3.5, 0.1), None)
        for a, sp in specks:
            d = 2 + f * sp * 0.5
            c.px(15.5 + math.cos(a) * d, 15.5 - math.sin(a) * d, A(GOLDL, 255 * fade))
        fr.append(c)
    return fr

# ---------------------------------------------------------------- BOLA DE FOGO 16x16 x4
def fireball():
    OUT = hexc('#5a1405'); F1 = hexc('#ff8a1f'); F2 = hexc('#ffd23f'); F3 = hexc('#fff4b0')
    fr = []
    for i in range(4):
        c = Canvas(16, 16)
        t = [0, 1, 2, 1][i]
        c.poly([(1, 8), (8, 4 + t % 2), (8, 12 - t % 2)], hexc('#d6451a'))
        c.poly([(3 + t, 8), (8, 5), (8, 11)], F1)
        c.ell(10, 8, 4.5, 4.5, F1); c.ell(10.5, 8, 3, 3, F2); c.ell(11, 8, 1.4, 1.4, F3)
        c.finish(OUT, 0.05, 0.1)
        fr.append(c)
    return fr

# ---------------------------------------------------------------- ALIADO (guerreiro celestial) 24x24 x4
def ally():
    OUT = hexc('#3a2a05'); ARM = hexc('#f0c24a'); ARM_D = hexc('#b8862b'); WING = hexc('#fffaf0'); SKIN = hexc('#f4cfa6'); BL = hexc('#f3f6ff')
    fr = []
    for i in range(4):
        c = Canvas(24, 24)
        bob = [0, -1, 0, -1][i]; lo = [0, 1, 0, -1][i]; fl = [2, 0, -2, 0][i]
        for sgn, ox in ((-1, 9), (1, 15)):
            c.poly([(ox, 11 + bob), (ox + sgn * 7, 5 + bob - fl), (ox + sgn * 5, 11 + bob), (ox + sgn * 3, 14 + bob)], WING)
        c.rect(9, 18 + bob, 11, 21 + lo, ARM_D); c.rect(13, 18 + bob, 15, 21 - lo, ARM_D)
        c.ell(12, 14 + bob, 4.5, 5, ARM)
        c.ell(12, 7 + bob, 3.6, 3.6, ARM)
        c.rect(10, 7 + bob, 14, 8 + bob, SKIN)
        c.rect(11, 3 + bob, 13, 4 + bob, hexc('#fff3b0'))
        c.line(18, 13 + bob, 21, 3 + bob, BL, 2)
        c.rect(17, 13 + bob, 20, 14 + bob, ARM_D)
        fr.append(c.finish(OUT))
    return fr

# ---------------------------------------------------------------- ESPADA ORBITAL 16x40 x1
def sword_orbit():
    c = Canvas(16, 40)
    c.poly([(5, 28), (11, 28), (10, 6), (8, 1), (6, 6)], hexc('#eaf0ff'))
    c.line(8, 4, 8, 26, hexc('#ffffff'))
    c.rect(2, 28, 13, 30, hexc('#f0c24a')); c.rect(7, 31, 8, 37, hexc('#b8862b')); c.ell(7.5, 38, 2, 1.5, hexc('#f0c24a'))
    c.finish(hexc('#3a2a05'), 0.15, 0.2)
    return [c]

# ---------------------------------------------------------------- TOCHA 16x32 x4
def torch():
    OUT = hexc('#140a05'); ST = hexc('#4a4a55'); ST_L = hexc('#6e6e7c'); F1 = hexc('#ff7a18'); F2 = hexc('#ffc233'); F3 = hexc('#fff1a8')
    fr = []
    for i in range(4):
        c = Canvas(16, 32)
        c.rect(7, 16, 8, 30, ST); c.rect(4, 28, 11, 31, ST_L)
        c.poly([(3, 14), (12, 14), (10, 19), (5, 19)], ST_L)
        h = [11, 13, 12, 14][i]; sw = [0, 1, 0, -1][i]
        c.poly([(4, 14), (11, 14), (8 + sw, 14 - h)], F1)
        c.poly([(5, 14), (10, 14), (8 - sw, 14 - h + 4)], F2)
        c.poly([(6, 14), (9, 14), (8, 14 - h + 8)], F3)
        fr.append(c.finish(OUT, 0.05, 0.1))
    return fr

# ---------------------------------------------------------------- CHÃO (ladrilho de pedra sombria) 64x64
def ground():
    rng = random.Random(77)
    c = Canvas(64, 64)
    base = [hexc('#5b5668'), hexc('#625c70'), hexc('#544f61')]
    for y in range(64):
        for x in range(64):
            c.px(x, y, base[(x // 8 + y // 8 * 3 + rng.randint(0, 2)) % 3])
    for k in range(40):
        x, y = rng.randint(1, 62), rng.randint(1, 62)
        c.px(x, y, hexc('#464256'))
    for yy in (16, 33, 50):                                    # juntas das lajes
        c.rect(0, yy, 63, yy, hexc('#3d394c'))
    for xx in (21, 44):
        c.rect(xx, 0, xx, 63, hexc('#3d394c'))
    lava = hexc('#ff6a1a')
    for k in range(3):                                         # rachadura com lava (não toca as bordas)
        x, y = rng.randint(10, 50), rng.randint(10, 50)
        for s in range(9):
            c.px(x, y, hexc('#2a2536')); c.px(x + 1, y, lava if s % 3 == 0 else hexc('#2a2536'))
            x += rng.choice([-1, 0, 1]); y += rng.choice([0, 1, 1])
            x = max(4, min(59, x)); y = max(4, min(59, y))
    return [c]

SHEETS = {
    "fx_aura": (aura, dict(play=dict(start=0, count=8, fps=10, loop=True))),
    "fx_hit": (hit, dict(play=dict(start=0, count=4, fps=24, loop=False))),
    "fx_burst": (burst, dict(play=dict(start=0, count=6, fps=16, loop=False))),
    "fx_strike": (strike, dict(play=dict(start=0, count=6, fps=16, loop=False))),
    "fx_shield": (shield, dict(play=dict(start=0, count=4, fps=8, loop=True))),
    "fx_poof": (poof, dict(play=dict(start=0, count=6, fps=16, loop=False))),
    "fx_fireball": (fireball, dict(play=dict(start=0, count=4, fps=12, loop=True))),
    "ally": (ally, dict(walk=dict(start=0, count=4, fps=8, loop=True))),
    "sword_orbit": (sword_orbit, dict(idle=dict(start=0, count=1, fps=1, loop=True))),
    "torch": (torch, dict(idle=dict(start=0, count=4, fps=8, loop=True))),
    "ground": (ground, dict(idle=dict(start=0, count=1, fps=1, loop=True))),
}
