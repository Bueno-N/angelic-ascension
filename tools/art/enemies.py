"""Demônios comuns, especiais e 4 chefes. Todos ORIGINAIS, desenhados por código.
Cada função devolve {animação: [quadros]}; 'walk' (4 quadros) e, quando faz sentido, 'cast' (2)."""
import math
from pixel import *

def ani(frames_walk, frames_cast=None):
    d = {"walk": frames_walk}
    if frames_cast:
        d["cast"] = frames_cast
    return d

# --------------------------------------------------------------- IMP (demônio comum) 24x24
def imp():
    OUT = hexc('#2b0d12'); R = hexc('#c0392b'); RD = hexc('#7a1f1a'); BELLY = hexc('#e07a5f'); BONE = hexc('#efe3c2'); EYE = hexc('#ffd23f')
    fr = []
    for i in range(4):
        c = Canvas(24, 24)
        bob = [0, -1, 0, -1][i]
        flap = [3, 0, -2, 0][i]
        # asas de morcego
        for sgn, ox in ((-1, 8), (1, 16)):
            c.poly([(ox, 12 + bob), (ox + sgn * 7, 6 + bob - flap), (ox + sgn * 5, 10 + bob), (ox + sgn * 7, 14 + bob - flap // 2), (ox + sgn * 3, 14 + bob)], RD)
        # cauda
        c.line(8, 18 + bob, 4, 16 + bob, R, 2); c.line(4, 16 + bob, 3, 12 + bob, R, 1); c.poly([(2, 12 + bob), (5, 12 + bob), (3, 9 + bob)], RD)
        # pernas alternadas
        lo = [0, 1, 0, -1][i]
        c.rect(9, 19 + bob, 11, 21 + lo, RD); c.rect(13, 19 + bob, 15, 21 - lo, RD)
        # corpo + barriga
        c.ell(12, 15 + bob, 5.5, 5.5, R); c.ell(12, 16 + bob, 3.3, 3.5, BELLY)
        # cabeça + chifres
        c.ell(12, 8 + bob, 4.8, 4.2, R)
        c.poly([(8, 6 + bob), (7, 1 + bob), (10, 5 + bob)], BONE); c.poly([(16, 6 + bob), (17, 1 + bob), (14, 5 + bob)], BONE)
        c.rect(9, 8 + bob, 10, 9 + bob, EYE); c.rect(14, 8 + bob, 15, 9 + bob, EYE)
        c.px(10, 9 + bob, OUT); c.px(14, 9 + bob, OUT)
        c.px(11, 11 + bob, BONE); c.px(13, 11 + bob, BONE)
        fr.append(c.finish(OUT))
    return ani(fr)

# --------------------------------------------------------------- WARRIOR (demônio guerreiro) 28x28
def warrior():
    OUT = hexc('#220a0e'); R = hexc('#9b2226'); RD = hexc('#5e1316'); IRON = hexc('#7c828f'); IRON_L = hexc('#aab0be'); BONE = hexc('#e8dcb8'); EYE = hexc('#ffcf33'); WOOD = hexc('#6b4226')
    fr = []
    for i in range(4):
        c = Canvas(28, 28)
        bob = [0, -1, 0, -1][i]; lo = [0, 1, 0, -1][i]
        c.rect(10, 22 + bob, 13, 26 + lo, RD); c.rect(15, 22 + bob, 18, 26 - lo, RD)
        c.rect(9, 26 + lo, 13, 27 + lo, IRON); c.rect(15, 26 - lo, 19, 27 - lo, IRON)
        c.ell(14, 17 + bob, 7.5, 7, R)
        c.poly([(9, 12 + bob), (19, 12 + bob), (18, 21 + bob), (10, 21 + bob)], IRON)
        c.line(14, 13 + bob, 14, 20 + bob, IRON_L)
        c.rect(9, 19 + bob, 19, 20 + bob, hexc('#5a3a1e'))
        # escudo (esquerda) e machado (direita)
        c.ell(5, 17 + bob + lo, 3.3, 5.5, IRON); c.ell(5, 17 + bob + lo, 1.3, 1.3, IRON_L)
        c.line(23, 9 + bob - lo, 22, 24 + bob - lo, WOOD, 2)
        c.poly([(22, 6 + bob - lo), (27, 8 + bob - lo), (27, 14 + bob - lo), (22, 13 + bob - lo)], IRON_L)
        # cabeça com elmo e chifres
        c.ell(14, 8 + bob, 5.2, 4.8, IRON)
        c.rect(11, 8 + bob, 17, 9 + bob, hexc('#1a0a0a')); c.rect(12, 8 + bob, 13, 8 + bob, EYE); c.rect(15, 8 + bob, 16, 8 + bob, EYE)
        c.poly([(9, 7 + bob), (5, 5 + bob), (3, 0 + bob), (8, 3 + bob), (10, 5 + bob)], BONE)
        c.poly([(19, 7 + bob), (23, 5 + bob), (25, 0 + bob), (20, 3 + bob), (18, 5 + bob)], BONE)
        fr.append(c.finish(OUT))
    return ani(fr)

# --------------------------------------------------------------- SHADOW (criatura sombria) 24x24
def shadow():
    OUT = hexc('#0e0818'); BODY = hexc('#4a3478', 225); BODY_D = hexc('#2c1d4f', 225); EYE = hexc('#7ff3ff')
    fr = []
    for i in range(4):
        c = Canvas(24, 24)
        bob = [0, -1, -1, 0][i]
        sw = [0, 1, 0, -1][i]
        pts = [(12, 2 + bob), (19, 9 + bob), (21, 19 + bob), (18 + sw, 23 + bob), (15, 19 + bob), (12 - sw, 23 + bob), (9, 19 + bob), (6 + sw, 23 + bob), (3, 19 + bob), (5, 9 + bob)]
        c.poly(pts, BODY)
        c.ell(12, 10 + bob, 5, 6, BODY_D)
        c.ell(12, 10 + bob, 3.6, 4.4, hexc('#07030f'))
        c.rect(9, 10 + bob, 10, 11 + bob, EYE); c.rect(14, 10 + bob, 15, 11 + bob, EYE)
        c.line(4, 12 + bob, 1, 16 + bob + sw, BODY_D, 2); c.line(20, 12 + bob, 23, 16 + bob - sw, BODY_D, 2)
        for k in range(3):
            c.px(2 + k * 9 + sw, 3 + (i * 3 + k * 5) % 9, hexc('#a78bfa', 160))
        c.shade(0.12, 0.1); c.outline(alpha(OUT, 200))
        fr.append(c)
    return ani(fr)

# --------------------------------------------------------------- HOUND (fera infernal) 32x24
def hound():
    OUT = hexc('#2a0e05'); BODY = hexc('#7a2e12'); BODY_D = hexc('#4d1b0a'); FIRE = hexc('#f4a259'); FIRE2 = hexc('#ffe08a'); EYE = hexc('#ffe14d'); BONE = hexc('#eadfc0')
    fr = []
    for i in range(4):
        c = Canvas(32, 24)
        bob = [0, -1, 0, -1][i]
        g = [(-3, 3), (0, 0), (3, -3), (0, 0)][i]
        # pernas (fundo e frente)
        for hx, off in ((8, g[0]), (11, g[1]), (21, g[1]), (24, g[0])):
            c.line(hx, 15 + bob, hx + off, 21, BODY_D, 2); c.rect(hx + off - 1, 21, hx + off + 1, 22, BODY_D)
        # cauda com chama
        c.line(6, 12 + bob, 2, 8 + bob, BODY, 2); c.poly([(0, 8 + bob), (4, 7 + bob), (2, 3 + bob - i % 2)], FIRE)
        # corpo + espinhos/crina de fogo
        c.ell(15, 13 + bob, 10, 5.5, BODY)
        for k in range(6):
            x = 8 + k * 3
            h = 4 + (k + i) % 3
            c.poly([(x - 1, 9 + bob), (x + 1, 9 + bob), (x, 9 + bob - h)], FIRE if k % 2 == 0 else FIRE2)
        # cabeça: focinho, mandíbula, orelhas
        c.ell(25, 11 + bob, 4.5, 4, BODY); c.rect(26, 11 + bob, 31, 14 + bob, BODY)
        c.rect(27, 14 + bob, 31, 15 + bob, BODY_D)
        c.poly([(23, 8 + bob), (22, 3 + bob), (26, 7 + bob)], BODY_D)
        c.rect(25, 9 + bob, 26, 10 + bob, EYE)
        c.px(28, 13 + bob, BONE); c.px(30, 13 + bob, BONE)
        fr.append(c.finish(OUT))
    return ani(fr)

# --------------------------------------------------------------- CASTER (conjurador profano) 24x28
def caster():
    OUT = hexc('#190826'); ROBE = hexc('#4a1d6b'); ROBE_L = hexc('#6b2c94'); FACE = hexc('#8e5fa8'); EYE = hexc('#ff6bd6'); BONE = hexc('#e7dcc0'); ORB = hexc('#ff4fd8'); ORB_L = hexc('#ffd1f4'); WOOD = hexc('#3a2414')
    def make(i, casting):
        c = Canvas(24, 28)
        bob = [0, -1, 0, 1][i % 4]
        sway = [0, 1, 0, -1][i % 4]
        c.poly([(7, 12 + bob), (17, 12 + bob), (20 + sway, 26 + bob), (4 + sway, 26 + bob)], ROBE)
        c.line(12, 14 + bob, 12, 26 + bob, ROBE_L)
        c.poly([(9, 12 + bob), (15, 12 + bob), (13, 18 + bob), (11, 18 + bob)], hexc('#2a1040'))
        # braços e cajado
        if casting:
            c.line(7, 14 + bob, 4, 7 + bob, ROBE_L, 2); c.line(17, 14 + bob, 20, 6 + bob, ROBE_L, 2)
            c.line(20, 5 + bob, 20, 24 + bob, WOOD, 1)
            r = 3.4 + (i % 2) * 0.8
            c.ell(20, 4 + bob, r, r, ORB); c.ell(20, 4 + bob, r - 1.6, r - 1.6, ORB_L)
            for k in range(3):
                c.px(16 + k * 3, 1 + (k * 2 + i) % 4, ORB_L)
        else:
            c.line(7, 14 + bob, 5, 20 + bob, ROBE_L, 2); c.line(17, 14 + bob, 20, 16 + bob, ROBE_L, 2)
            c.line(20, 7 + bob, 19, 26 + bob, WOOD, 1)
            c.ell(20, 6 + bob, 2.6, 2.6, ORB); c.px(20, 5 + bob, ORB_L)
        # cabeça com chifres
        c.ell(12, 8 + bob, 4.6, 4.6, FACE)
        c.poly([(8, 5 + bob), (5, 1 + bob), (4, 6 + bob), (7, 8 + bob)], BONE); c.poly([(16, 5 + bob), (19, 1 + bob), (20, 6 + bob), (17, 8 + bob)], BONE)
        c.rect(9, 8 + bob, 10, 8 + bob, EYE); c.rect(14, 8 + bob, 15, 8 + bob, EYE)
        c.px(12, 11 + bob, hexc('#2a1040'))
        return c.finish(OUT)
    return ani([make(i, False) for i in range(4)], [make(i, True) for i in range(2)])

# --------------------------------------------------------------- LEECH (sanguessuga de almas) 24x24
def leech():
    OUT = hexc('#06201a'); BODY = hexc('#1f8a70', 235); BODY_D = hexc('#0f5a49', 235); EYEW = hexc('#f4fff9'); PUPIL = hexc('#ffb703'); SPIKE = hexc('#7ef0c8')
    fr = []
    for i in range(4):
        c = Canvas(24, 24)
        bob = [0, -1, 0, 1][i]
        for k, x in enumerate((7, 10, 14, 17)):
            ph = (i + k) % 4
            off = [0, 1, 0, -1][ph]
            c.line(x, 15 + bob, x + off, 20 + bob, BODY_D, 2); c.line(x + off, 20 + bob, x - off, 23, BODY_D, 1)
        c.ell(12, 10 + bob, 7, 7, BODY)
        for k in range(5):
            ang = math.radians(200 + k * 35)
            c.poly([(12 + math.cos(ang) * 6, 10 + bob - math.sin(ang) * 6), (12 + math.cos(ang + 0.2) * 6, 10 + bob - math.sin(ang + 0.2) * 6), (12 + math.cos(ang + 0.1) * 10, 10 + bob - math.sin(ang + 0.1) * 10)], SPIKE)
        c.ell(12, 10 + bob, 4, 4, EYEW)
        c.ell(12 + [0, 1, 0, -1][i], 10 + bob, 1.6, 2, PUPIL)
        c.px(12 + [0, 1, 0, -1][i], 10 + bob, OUT)
        c.shade(0.12, 0.18); c.outline(OUT)
        fr.append(c)
    return ani(fr)

# =============================================================== CHEFES 64x64
def boss_baal():
    OUT = hexc('#1c0505'); R = hexc('#7a0f0f'); RL = hexc('#a32222'); BONE = hexc('#efe0b8'); EYE = hexc('#ffd23f'); IRON = hexc('#8a8f9c'); IRON_L = hexc('#b9bfcc')
    def make(i, cast):
        c = Canvas(64, 64)
        bob = [0, -1, 0, -1][i % 4]; lo = [0, 2, 0, -2][i % 4]
        # pernas
        c.rect(20, 46 + bob, 28, 59 + lo, R); c.rect(36, 46 + bob, 44, 59 - lo, R)
        c.rect(18, 59 + lo, 29, 62 + lo, hexc('#4a0808')); c.rect(35, 59 - lo, 46, 62 - lo, hexc('#4a0808'))
        # tronco
        c.ell(32, 36 + bob, 17, 14, R); c.ell(32, 39 + bob, 10, 9, RL)
        for k in range(3):
            c.line(26, 33 + bob + k * 4, 38, 33 + bob + k * 4, R)
        c.rect(18, 46 + bob, 46, 49 + bob, hexc('#3b2a1a'))
        for x in range(20, 46, 6):
            c.poly([(x, 46 + bob), (x + 2, 46 + bob), (x + 1, 43 + bob)], IRON_L)
        # ombros com espinhos
        c.ell(14, 27 + bob, 9, 7, R); c.ell(50, 27 + bob, 9, 7, R)
        for sx in (10, 14, 18):
            c.poly([(sx, 22 + bob), (sx + 3, 22 + bob), (sx + 1, 15 + bob)], IRON_L)
        for sx in (45, 49, 53):
            c.poly([(sx, 22 + bob), (sx + 3, 22 + bob), (sx + 2, 15 + bob)], IRON_L)
        # braços
        if cast:
            hl, hr = (8, 12 + (i % 2) * 3), (56, 12 + (i % 2) * 3)
        else:
            sw = [0, 3, 0, -3][i % 4]
            hl, hr = (9, 46 + sw + bob), (55, 46 - sw + bob)
        c.line(14, 28 + bob, hl[0], hl[1], R, 7); c.line(50, 28 + bob, hr[0], hr[1], R, 7)
        c.ell(hl[0], hl[1], 5.5, 5.5, RL); c.ell(hr[0], hr[1], 5.5, 5.5, RL)
        # maça na mão direita
        c.line(hr[0], hr[1], hr[0] + 2, hr[1] - 14, hexc('#5a3a1e'), 2)
        c.ell(hr[0] + 2, hr[1] - 17, 5, 5, IRON)
        for a in range(0, 360, 60):
            c.px(hr[0] + 2 + math.cos(math.radians(a)) * 6, hr[1] - 17 - math.sin(math.radians(a)) * 6, IRON_L)
        # cabeça, mandíbula, chifres, olhos
        c.ell(32, 17 + bob, 10, 9, R)
        c.rect(25, 22 + bob, 39, 25 + bob, RL)
        c.px(27, 24 + bob, BONE); c.px(30, 24 + bob, BONE); c.px(34, 24 + bob, BONE); c.px(37, 24 + bob, BONE)
        c.poly([(23, 13 + bob), (14, 12 + bob), (6, 3 + bob), (9, 13 + bob), (18, 18 + bob), (24, 17 + bob)], BONE)
        c.poly([(41, 13 + bob), (50, 12 + bob), (58, 3 + bob), (55, 13 + bob), (46, 18 + bob), (40, 17 + bob)], BONE)
        c.rect(26, 15 + bob, 29, 17 + bob, EYE); c.rect(35, 15 + bob, 38, 17 + bob, EYE)
        return c.finish(OUT)
    return ani([make(i, False) for i in range(4)], [make(i, True) for i in range(2)])

def boss_mordath():
    OUT = hexc('#0c0618'); ROBE = hexc('#2a1a4a'); ROBE_L = hexc('#4b2f7a'); RUNE = hexc('#c36bff'); BONE = hexc('#e9e1cf'); GOLD = hexc('#e8b23a'); FLAME = hexc('#b05cff'); FLAME_L = hexc('#e6c2ff')
    def make(i, cast):
        c = Canvas(64, 64)
        bob = [0, -2, -3, -2][i % 4]; sw = [0, 2, 0, -2][i % 4]
        hem = [(8 + sw, 61 + bob), (14, 57 + bob), (20 - sw, 62 + bob), (26, 58 + bob), (32 + sw, 63 + bob), (38, 58 + bob), (44 - sw, 62 + bob), (50, 57 + bob), (56 + sw, 61 + bob)]
        c.poly([(22, 22 + bob), (42, 22 + bob)] + [(56 - 4, 40 + bob)] + hem[::-1] + [(12, 40 + bob)], ROBE)
        c.poly([(28, 24 + bob), (36, 24 + bob), (40, 58 + bob), (24, 58 + bob)], ROBE_L)
        for k in range(4):
            y = 32 + k * 7 + bob
            c.line(27, y, 37, y, RUNE); c.px(32, y - 1, RUNE); c.px(32, y + 1, RUNE)
        # capuz + caveira + coroa
        c.ell(32, 16 + bob, 11, 11, ROBE)
        c.ell(32, 19 + bob, 6.5, 7.5, BONE)
        c.rect(28, 18 + bob, 30, 21 + bob, hexc('#1a0a2e')); c.rect(34, 18 + bob, 36, 21 + bob, hexc('#1a0a2e'))
        c.px(29, 19 + bob, RUNE); c.px(35, 19 + bob, RUNE); c.rect(30, 25 + bob, 34, 26 + bob, hexc('#1a0a2e'))
        for k, x in enumerate((22, 27, 32, 37, 42)):
            h = 8 if k == 2 else 5
            c.poly([(x - 2, 8 + bob), (x + 2, 8 + bob), (x, 8 + bob - h)], GOLD)
        # braços e chamas
        if cast:
            hl, hr = (8, 12 + (i % 2) * 2), (56, 12 + (i % 2) * 2)
            c.line(22, 26 + bob, hl[0], hl[1], ROBE_L, 5); c.line(42, 26 + bob, hr[0], hr[1], ROBE_L, 5)
        else:
            hl, hr = (10, 38 + bob), (54, 38 + bob)
            c.line(22, 26 + bob, hl[0], hl[1], ROBE_L, 5); c.line(42, 26 + bob, hr[0], hr[1], ROBE_L, 5)
        for (hx, hy) in (hl, hr):
            c.ell(hx, hy, 3, 3, BONE)
            f = 6 + (i % 2) * 2
            c.poly([(hx - 4, hy - 2), (hx + 4, hy - 2), (hx + (i % 2) - 1, hy - 2 - f - (4 if cast else 0))], FLAME)
            c.poly([(hx - 2, hy - 2), (hx + 2, hy - 2), (hx, hy - 2 - f // 2 - 1)], FLAME_L)
        return c.finish(OUT)
    return ani([make(i, False) for i in range(4)], [make(i, True) for i in range(2)])

def boss_ignarr():
    OUT = hexc('#2a0d04'); BODY = hexc('#a8410f'); BODY_D = hexc('#5c1f08'); BODY_L = hexc('#d2651f'); F1 = hexc('#ffb347'); F2 = hexc('#ffe066'); F3 = hexc('#e8591a'); EYE = hexc('#fff27a'); BONE = hexc('#efe3c2')
    def make(i, cast):
        c = Canvas(64, 64)
        bob = [0, -1, 0, -1][i % 4]
        g = [(-4, 4), (0, 0), (4, -4), (0, 0)][i % 4]
        # pernas
        for hx, off in ((16, g[0]), (22, g[1]), (40, g[1]), (46, g[0])):
            c.line(hx, 38 + bob, hx + off, 56, BODY_D, 6); c.rect(hx + off - 4, 56, hx + off + 4, 60, BODY_D)
        # cauda em chamas
        c.line(10, 32 + bob, 3, 22 + bob, BODY, 5)
        c.poly([(-1, 22 + bob), (8, 20 + bob), (4, 6 + bob - i % 2 * 2)], F1)
        # corpo
        c.ell(30, 35 + bob, 21, 11, BODY); c.ell(30, 39 + bob, 15, 6, BODY_L)
        # crina de fogo
        for k in range(8):
            x = 14 + k * 4
            h = 10 + (k * 3 + i * 2) % 7
            c.poly([(x - 3, 28 + bob), (x + 3, 28 + bob), (x, 28 + bob - h)], F3 if k % 2 else F1)
            c.poly([(x - 1, 28 + bob), (x + 2, 28 + bob), (x + 1, 28 + bob - h // 2)], F2)
        # cabeça
        c.ell(51, 28 + bob, 9, 8, BODY)
        c.poly([(46, 21 + bob), (44, 12 + bob), (52, 20 + bob)], BODY_D); c.poly([(52, 21 + bob), (56, 11 + bob), (58, 22 + bob)], BODY_D)
        jaw = 6 if cast else 0
        c.poly([(54, 28 + bob), (63, 29 + bob), (63, 34 + bob + jaw), (53, 34 + bob + jaw)], BODY)
        c.rect(55, 33 + bob, 62, 33 + bob + jaw, hexc('#2a0606') if cast else BODY_D)
        for x in (56, 59, 62):
            c.px(x, 32 + bob, BONE); c.px(x, 34 + bob + jaw, BONE)
        c.rect(50, 25 + bob, 53, 27 + bob, EYE)
        if cast:
            c.poly([(63, 31 + bob), (63, 38 + bob), (60, 36 + bob), (58, 34 + bob)], F2)
        return c.finish(OUT)
    return ani([make(i, False) for i in range(4)], [make(i, True) for i in range(2)])

def boss_azazel():
    OUT = hexc('#1a0615'); BODY = hexc('#4a0f3a'); BODY_L = hexc('#7a1d5e'); WING = hexc('#5c1348'); BONE = hexc('#e8dcc4'); GOLD = hexc('#f0c24a'); EYE = hexc('#ff4f6d'); ORB = hexc('#ff5fa8'); ORB_L = hexc('#ffd6ea')
    def make(i, cast):
        c = Canvas(64, 64)
        bob = [0, -2, -3, -2][i % 4]
        flap = [8, 0, -8, 0][i % 4]
        # asas de membrana
        for sgn, ox in ((-1, 26), (1, 38)):
            tips = [(ox + sgn * 26, 4 + bob - flap), (ox + sgn * 29, 22 + bob - flap // 2), (ox + sgn * 23, 38 + bob), (ox + sgn * 12, 40 + bob)]
            c.poly([(ox, 24 + bob)] + tips, WING)
            for t in tips[:3]:
                c.line(ox, 24 + bob, t[0], t[1], BONE)
        # cauda
        c.line(32, 46 + bob, 40, 56 + bob, BODY, 3); c.poly([(40, 56 + bob), (46, 56 + bob), (42, 62 + bob)], GOLD)
        # pernas
        c.line(28, 44 + bob, 26, 54 + bob, BODY, 5); c.line(36, 44 + bob, 38, 54 + bob, BODY, 5)
        # tronco
        c.ell(32, 33 + bob, 9, 13, BODY); c.ell(32, 34 + bob, 5, 8, BODY_L)
        c.rect(26, 40 + bob, 38, 42 + bob, GOLD)
        # braços e orbe
        if cast:
            hl, hr = (18, 18 + bob), (46, 18 + bob)
            r = 5 + (i % 2) * 2
            c.line(26, 26 + bob, hl[0], hl[1], BODY, 4); c.line(38, 26 + bob, hr[0], hr[1], BODY, 4)
            c.ell(32, 10 + bob, r, r, ORB); c.ell(32, 10 + bob, r - 2.5, r - 2.5, ORB_L)
        else:
            hl, hr = (20, 38 + bob), (44, 38 + bob)
            c.line(26, 26 + bob, hl[0], hl[1], BODY, 4); c.line(38, 26 + bob, hr[0], hr[1], BODY, 4)
            c.ell(44, 34 + bob, 4, 4, ORB); c.ell(44, 34 + bob, 2, 2, ORB_L)
        c.ell(hl[0], hl[1], 3, 3, BODY_L); c.ell(hr[0], hr[1], 3, 3, BODY_L)
        # cabeça com coroa
        c.ell(32, 17 + bob, 7, 7, BODY_L)
        c.poly([(27, 12 + bob), (22, 5 + bob), (30, 9 + bob)], BONE); c.poly([(37, 12 + bob), (42, 5 + bob), (34, 9 + bob)], BONE)
        for k, x in enumerate((26, 29, 32, 35, 38)):
            h = 7 if k == 2 else 4
            c.poly([(x - 1, 11 + bob), (x + 1, 11 + bob), (x, 11 + bob - h)], GOLD)
        c.rect(28, 17 + bob, 30, 18 + bob, EYE); c.rect(34, 17 + bob, 36, 18 + bob, EYE)
        return c.finish(OUT)
    return ani([make(i, False) for i in range(4)], [make(i, True) for i in range(2)])

SHEETS = {
    "imp": (imp, 24, 24), "warrior": (warrior, 28, 28), "shadow": (shadow, 24, 24), "hound": (hound, 32, 24),
    "caster": (caster, 24, 28), "leech": (leech, 24, 24),
    "boss_baal": (boss_baal, 64, 64), "boss_mordath": (boss_mordath, 64, 64),
    "boss_ignarr": (boss_ignarr, 64, 64), "boss_azazel": (boss_azazel, 64, 64),
}
