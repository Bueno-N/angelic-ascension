"""Anjo guerreiro encapuzado, estilo 'arcanjo de armadura branca/azul-marinho/dourada' (design ORIGINAL),
em CAMADAS alinhadas (72x64 por quadro). Equipamentos são camadas claras tingidas por tier; a armadura de tier
alto (dourada) completa o visual. Animações: idle, attack, cast (11 quadros)."""
import math
from pixel import *

W, H = 72, 64
OUT = hexc('#0e1230')
NAVY, NAVY_D, NAVY_L = hexc('#2a3b94'), hexc('#18235f'), hexc('#4660cf')
WHITE, WHITE_D = hexc('#f4f6fd'), hexc('#c3c9e8')
GOLD, GOLD_L, GOLD_D = hexc('#eab93f'), hexc('#fde28f'), hexc('#a8751f')
VOID, EYE = hexc('#060919'), hexc('#aef2ff')
LAV_D, LAV, LAV_L, WING_W = hexc('#6f80d9'), hexc('#9fadf0'), hexc('#d3daff'), hexc('#f6f8ff')
GEM, GEM_L = hexc('#2f58e0'), hexc('#9bb8ff')
LG, LG_D, LG_L, EQ_OUT = hexc('#e4e8f2'), hexc('#b5bcd2'), hexc('#ffffff'), hexc('#262b3d')

# quadros: idle0-3, attack0-3, cast0-2
POSES = []
for dy, flap, sash in zip([0, -1, -2, -1], [10, 0, -12, 0], [0, 1, 2, 1]):
    POSES.append(dict(dy=dy, lh=(22, 43), rh=(48, 43), sw=-35, flap=flap, sash=sash))
for dy, lh, rh, sw, flap, sash in [(-1, (21, 42), (47, 31), 105, 14, 2), (0, (21, 42), (51, 36), 20, 6, 3),
                                   (1, (22, 43), (51, 45), -45, -8, 1), (0, (22, 43), (48, 43), -35, 0, 0)]:
    POSES.append(dict(dy=dy, lh=lh, rh=rh, sw=sw, flap=flap, sash=sash))
for dy, lh, rh, flap, sash in [(-1, (23, 36), (49, 36), 12, 1), (-2, (20, 28), (52, 28), 18, 2), (-2, (21, 24), (51, 24), 22, 3)]:
    POSES.append(dict(dy=dy, lh=lh, rh=rh, sw=90, flap=flap, sash=sash))
N = len(POSES)
ANIMS = {"idle": dict(start=0, count=4, fps=6, loop=True),
         "attack": dict(start=4, count=4, fps=14, loop=False),
         "cast": dict(start=8, count=3, fps=10, loop=False)}
OY = 3   # margem superior (halo)

def ribbon(c, p0, p1, p2, r0, r1, col, col_l):
    pts = []
    for i in range(21):
        t = i / 20
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]
        r = r0 + (r1 - r0) * t
        c.ell(x, y, r, r, col)
        pts.append((x, y, r))
    for x, y, r in pts[::2]:
        c.px(x - 0.5, y - 0.5, col_l)

def arm(c, sh, hand, d, sgn):
    sx, sy = sh
    hx, hy = hand[0], hand[1] + d
    ex, ey = (sx + hx) / 2 + sgn * 2, (sy + hy) / 2 + 2
    c.line(sx, sy, ex, ey, WHITE_D, 5); c.line(ex, ey, hx, hy, WHITE_D, 5)
    c.line(sx, sy, ex, ey, WHITE, 4); c.line(ex, ey, hx, hy, WHITE, 4)
    c.line(ex + (hx - ex) * 0.45, ey + (hy - ey) * 0.45, ex + (hx - ex) * 0.85, ey + (hy - ey) * 0.85, GOLD, 4)
    c.ell(hx, hy, 2.8, 2.8, NAVY_D)

def body_frame(p):
    c = Canvas(W, H)
    d = p['dy'] + OY
    s = p['sash']
    # faixas esvoaçantes (atrás do corpo)
    for sgn, x0 in ((-1, 31), (1, 41)):
        ribbon(c, (x0, 44 + d), (x0 + sgn * (8 + s), 48 + d), (x0 + sgn * (11 + 2 * s), 56 + d), 2.8, 1.2, NAVY, NAVY_L)
    # saia/ponta flutuante
    c.poly([(30, 43 + d), (42, 43 + d), (40, 51 + d), (36, 58 + d), (32, 51 + d)], NAVY)
    c.line(30, 43 + d, 32, 51 + d, WHITE); c.line(32, 51 + d, 36, 58 + d, WHITE)
    c.line(42, 43 + d, 40, 51 + d, WHITE); c.line(40, 51 + d, 36, 58 + d, WHITE)
    c.poly([(36, 42 + d), (40, 49 + d), (36, 57 + d), (32, 49 + d)], GOLD_D)
    c.poly([(36, 44 + d), (39, 49 + d), (36, 55 + d), (33, 49 + d)], WHITE)
    c.poly([(34, 54 + d), (38, 54 + d), (36, 59 + d)], GOLD)
    # tronco
    c.poly([(27, 28 + d), (45, 28 + d), (42, 44 + d), (30, 44 + d)], NAVY)
    c.poly([(33, 28 + d), (39, 28 + d), (38, 44 + d), (34, 44 + d)], WHITE)
    c.poly([(36, 30 + d), (39, 34 + d), (36, 38 + d), (33, 34 + d)], GOLD)
    c.ell(36, 34 + d, 1.4, 1.4, GEM); c.px(35, 33 + d, GEM_L)
    c.rect(30, 42 + d, 42, 43 + d, GOLD); c.px(36, 42 + d, GOLD_L); c.px(36, 43 + d, GOLD_D)
    # braços (o esquerdo atrás)
    arm(c, (27, 30 + d), p['lh'], d, -1)
    arm(c, (45, 30 + d), p['rh'], d, 1)
    # manto dos ombros com friso dourado
    c.poly([(21, 34 + d), (27, 26 + d), (45, 26 + d), (51, 34 + d), (45, 36 + d), (27, 36 + d)], WHITE)
    c.line(23, 35 + d, 49, 35 + d, GOLD)
    # capuz com abertura escura e olhos
    c.ell(36, 18 + d, 8.4, 9.4, WHITE)
    c.poly([(31, 16 + d), (41, 16 + d), (36, 6 + d)], WHITE)
    c.ell(36, 20.5 + d, 6.4, 7.6, GOLD)
    c.ell(36, 21 + d, 5.1, 6.4, VOID)
    c.rect(33, 20 + d, 34, 20 + d, EYE); c.rect(38, 20 + d, 39, 20 + d, EYE)
    # halo com espinho
    c.ell(36, 4 + d, 8, 3, GOLD)
    c.ell(36, 4 + d, 5.4, 1.2, None)
    c.poly([(35, 2 + d), (37, 2 + d), (36, -2 + d)], GOLD_L)
    c.finish(OUT)
    return c

def armor_frame(p):
    c = Canvas(W, H)
    d = p['dy'] + OY
    c.poly([(30, 28 + d), (42, 28 + d), (41, 39 + d), (36, 44 + d), (31, 39 + d)], LG)
    c.line(36, 29 + d, 36, 42 + d, LG_D)
    c.poly([(31, 25 + d), (41, 25 + d), (39, 29 + d), (33, 29 + d)], LG)
    for sgn, cx in ((-1, 24), (1, 48)):
        y0 = 30 + d
        c.poly([(cx - 7, y0 + 3), (cx - 6, y0 - 4), (cx + 1, y0 - 7), (cx + 8, y0 - 3), (cx + 7, y0 + 4), (cx, y0 + 6)], LG)
        c.poly([(cx + sgn * -3, y0 - 5), (cx + sgn * 2, y0 - 13), (cx + sgn * 6, y0 - 5)], LG_D)      # espinho para cima
        c.poly([(cx + sgn * 2, y0 - 4), (cx + sgn * 10, y0 - 8), (cx + sgn * 9, y0)], LG)               # ponta para fora
        c.line(cx - 5, y0 + 1, cx + 6, y0 + 1, LG_D)
        c.ell(cx, y0 - 1, 1.8, 1.8, LG_L)
    c.finish(EQ_OUT, 0.3, 0.3)
    return c

def boots_frame(p):
    c = Canvas(W, H)
    d = p['dy'] + OY
    c.poly([(32, 49 + d), (40, 49 + d), (38, 55 + d), (36, 60 + d), (34, 55 + d)], LG)
    c.line(36, 50 + d, 36, 58 + d, LG_D)
    c.finish(EQ_OUT, 0.3, 0.3)
    return c

def gloves_frame(p):
    c = Canvas(W, H)
    d = p['dy'] + OY
    for h in (p['lh'], p['rh']):
        c.ell(h[0], h[1] + d, 3.8, 3.8, LG)
        c.ell(h[0], h[1] + d, 1.4, 1.4, LG_L)
    c.finish(EQ_OUT, 0.3, 0.3)
    return c

def wings_frame(p, stage):
    L = [22, 26, 29, 31][stage]
    nf = [7, 8, 9, 10][stage]
    c = Canvas(W, H)
    d = p['dy'] + OY
    root = (31.5, 30 + d)
    wing = Canvas(W, H)
    feathers = []
    for k in range(nf):
        t = k / (nf - 1)
        phi = math.radians(116 + 80 * t - p['flap'] * 0.9)
        ln = L * (0.97 - 0.42 * t * t - 0.1 * t)
        w = 2.1 * (1 - 0.2 * t) + 0.18 * stage
        feathers.append((phi, ln, w, k))
    for phi, ln, w, k in feathers:                                 # as de baixo desenham por cima das de cima
        S = int(ln * 1.8)
        for s_ in range(S + 1):
            u = s_ / S
            x = root[0] + math.cos(phi) * ln * u
            y = root[1] - math.sin(phi) * ln * u
            r = w * (1 - 0.62 * u) + 0.6
            col = mix(LAV, WING_W, u ** 1.5)
            col = mix(LAV_D, col, min(1.0, u * 2.0))
            if k % 2 == 1:
                col = light(col, 0.1)
            wing.ell(x, y, r, r, col)
        # sombra sob cada pena (separa as penas)
        for s_ in range(int(S * 0.25), S + 1, 2):
            u = s_ / S
            wing.px(root[0] + math.cos(phi) * ln * u - math.sin(phi) * 0.0, root[1] - math.sin(phi) * ln * u + w * 0.9, LAV_D)
    if stage >= 1:                                                 # placa dourada na asa
        ph = math.radians(126 - p['flap'] * 0.6)
        dxp, dyp = math.cos(ph), -math.sin(ph)
        nxp, nyp = -dyp, dxp
        pts = [(root[0] + dxp * 1 + nxp * 3, root[1] + dyp * 1 + nyp * 3), (root[0] + dxp * 9 + nxp * 4.5, root[1] + dyp * 9 + nyp * 4.5),
               (root[0] + dxp * 16, root[1] + dyp * 16), (root[0] + dxp * 9 - nxp * 4.5, root[1] + dyp * 9 - nyp * 4.5),
               (root[0] + dxp * 1 - nxp * 3, root[1] + dyp * 1 - nyp * 3)]
        wing.poly(pts, GOLD)
        wing.line(root[0] + dxp * 2, root[1] + dyp * 2, root[0] + dxp * 15, root[1] + dyp * 15, GOLD_L)
        if stage >= 2:
            gx, gy = root[0] + dxp * 8, root[1] + dyp * 8
            wing.ell(gx, gy, 2.6, 2.6, GEM); wing.px(gx - 1, gy - 1, GEM_L)
    if stage >= 3:                                                 # friso dourado na pena superior
        phi, ln, w, k = feathers[0]
        for s_ in range(int(ln * 0.5), int(ln) + 1):
            wing.px(root[0] + math.cos(phi) * s_, root[1] - math.sin(phi) * s_ - w * 0.7, GOLD_L)
    c.blit(wing)
    c.blit(wing.flip())
    c.finish(hexc('#232b6e'), 0.1, 0.18)
    return c

def build():
    sheets = {}
    sheets['angel_body'] = [body_frame(p) for p in POSES]
    sheets['angel_armor'] = [armor_frame(p) for p in POSES]
    sheets['angel_boots'] = [boots_frame(p) for p in POSES]
    sheets['angel_gloves'] = [gloves_frame(p) for p in POSES]
    for s in range(4):
        sheets['angel_wings_%d' % s] = [wings_frame(p, s) for p in POSES]
    return sheets
