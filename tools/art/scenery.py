"""Cenário do mapa das fases: textura de CRATERAS (tile sem emendas, 320x160, desenhada a 2x no jogo).
Só tons de preto/branco com transparência: o jogo tinge pela dificuldade (o fundo fica mais vermelho). ORIGINAL (CC0)."""
import math, random
from pixel import *

W, H = 320, 160
LIGHT = (-0.7071, -0.7071)       # luz vinda de cima/esquerda

def _q(a, steps=5):
    """quantiza a transparência (aspecto pixel art em faixas)"""
    a = max(0.0, min(1.0, a))
    return round(a * steps) / steps

def crater(c, cx, cy, rx, ry, rnd):
    ex = 1.45
    for y in range(int(cy - ry * ex) - 1, int(cy + ry * ex) + 2):
        for x in range(int(cx - rx * ex) - 1, int(cx + rx * ex) + 2):
            dx, dy = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
            d = math.hypot(dx, dy)
            if d > ex:
                continue
            nx, ny = (dx / d, dy / d) if d > 1e-6 else (0.0, 0.0)
            lit = nx * LIGHT[0] + ny * LIGHT[1]            # +1 = lado voltado para a luz
            col, a = None, 0.0
            if d < 0.70:                                    # fundo: escuro e liso
                col, a = (0, 0, 0), 0.24 + 0.04 * rnd.random()
            elif d < 0.90:                                  # parede interna: o lado de baixo/direita recebe luz
                t = (d - 0.70) / 0.20
                if lit < 0:
                    col, a = (255, 255, 255), (0.30 * -lit) * (0.5 + 0.5 * t)
                else:
                    col, a = (0, 0, 0), 0.38 * lit * (1.0 - 0.4 * t) + 0.30
            elif d < 1.06:                                  # borda levantada
                if lit > 0:
                    col, a = (255, 255, 255), 0.42 * lit + 0.08
                else:
                    col, a = (0, 0, 0), 0.20 * -lit + 0.05
            else:                                           # sombra do material ejetado
                t = (d - 1.06) / (ex - 1.06)
                if lit < -0.2:
                    col, a = (0, 0, 0), 0.20 * (1.0 - t) * -lit
            if col is None or a <= 0.04:
                continue
            a = _q(a)
            if a <= 0.0:
                continue
            for ox in (-W, 0, W):                           # emenda: repete nas bordas do tile
                for oy in (-H, 0, H):
                    px, py = x + ox, y + oy
                    if 0 <= px < W and 0 <= py < H:
                        old = c.p[py][px]
                        if old is None or a >= old[3] / 255.0:
                            c.px(px, py, col + (int(a * 255),))

def craters():
    rnd = random.Random(20240611)
    c = Canvas(W, H)
    spots = []
    def free(x, y, r):
        for (sx, sy, sr) in spots:
            for ox in (-W, 0, W):
                for oy in (-H, 0, H):
                    if math.hypot(x - (sx + ox), (y - (sy + oy)) * 1.6) < (r + sr) * 0.95:
                        return False
        return True
    plan = [(46, 2), (30, 4), (20, 6), (12, 8), (7, 10)]       # (raio em px, quantidade)
    for r, n in plan:
        placed = 0
        tries = 0
        while placed < n and tries < 400:
            tries += 1
            x, y = rnd.uniform(0, W), rnd.uniform(0, H)
            if free(x, y, r):
                spots.append((x, y, r))
                crater(c, x, y, r, r * 0.55, rnd)
                placed += 1
    # pedrinhas e poeira
    for _ in range(70):
        x, y = rnd.randrange(W), rnd.randrange(H)
        if c.get(x, y) is None:
            c.px(x, y, (255, 255, 255, 46))
            if rnd.random() < 0.5 and c.get(x + 1, y + 1) is None:
                c.px(x + 1, y + 1, (0, 0, 0, 60))
    return c
