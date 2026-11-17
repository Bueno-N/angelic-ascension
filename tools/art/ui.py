"""Chamas da arena, ícones de interface (24x24), avatares (32x32) e FONTE PIXEL (5x7). Tudo ORIGINAL (CC0)."""
import math
from pixel import *

OUT = hexc('#0e1230')
GOLD, GOLD_L, GOLD_D = hexc('#eab93f'), hexc('#fde28f'), hexc('#a8751f')
WHITE, STEEL, STEEL_D = hexc('#f4f6fd'), hexc('#dfe6f5'), hexc('#8d99b8')
RED, RED_D = hexc('#e0373b'), hexc('#8f1d24')
BLUE, BLUE_L, BLUE_D = hexc('#4a68e0'), hexc('#8aa6ff'), hexc('#26358f')
CYAN, CYAN_L = hexc('#41d3f4'), hexc('#b8f3ff')
LAV, LAV_L = hexc('#9fadf0'), hexc('#d3daff')
BROWN, BROWN_D = hexc('#9a6535'), hexc('#5e3a1c')
SKIN = hexc('#f4cfa6')

# ------------------------------------------------------------------ chama (cantos da arena) 32x48 x6
def flame():
    fr = []
    for i in range(6):
        c = Canvas(32, 48)
        t = i / 6 * math.tau
        def tongue(cx, w, h, col, ph):
            L, R = [], []
            for k in range(0, 9):
                u = k / 8
                y = 47 - h * u
                wob = math.sin(t + ph + u * 3.2) * (1.0 + 4.0 * u)
                half = max(0.4, w * (1 - u) ** 0.85)
                L.append((cx + wob - half, y)); R.append((cx + wob + half, y))
            c.poly(L + R[::-1], col)
        tongue(10, 7, 28, hexc('#e8431a'), 1.7)
        tongue(22, 7, 32, hexc('#e8431a'), 3.1)
        tongue(16, 10, 44, hexc('#e8431a'), 0.0)
        tongue(16, 7.5, 36, hexc('#ff8a1f'), 0.4)
        tongue(16, 4.5, 26, hexc('#ffd23f'), 0.8)
        tongue(16, 2.2, 14, hexc('#fff4b0'), 1.2)
        for k in range(5):
            c.px(8 + (k * 5 + i * 3) % 18, 6 + (k * 9 + i * 7) % 26, hexc('#ffd23f'))
        fr.append(c)
    return fr

# ------------------------------------------------------------------ ícones 24x24
def sword():
    c = Canvas(24, 24)
    c.poly([(20, 1), (23, 4), (11, 17), (7, 13)], STEEL)
    c.line(9, 15, 20, 4, WHITE)
    c.line(4, 12, 12, 20, GOLD, 3)
    c.line(6, 18, 2, 22, BROWN, 3)
    return c.finish(OUT)
def heart():
    c = Canvas(24, 24)
    c.ell(8, 9, 5, 5, RED); c.ell(16, 9, 5, 5, RED)
    c.poly([(3, 11), (21, 11), (12, 22)], RED)
    c.px(6, 7, hexc('#ff9aa0')); c.px(7, 6, hexc('#ff9aa0'))
    return c.finish(OUT)
def shield():
    c = Canvas(24, 24)
    c.poly([(4, 3), (20, 3), (20, 12), (12, 22), (4, 12)], BLUE)
    c.line(12, 5, 12, 18, GOLD, 2); c.line(7, 9, 17, 9, GOLD, 2)
    return c.finish(OUT)
def boot():
    c = Canvas(24, 24)
    c.poly([(7, 3), (15, 3), (15, 13), (21, 16), (21, 21), (5, 21), (5, 3)], BROWN)
    c.rect(7, 3, 14, 6, GOLD)
    c.rect(5, 19, 21, 21, BROWN_D)
    return c.finish(OUT)
def bolt():
    c = Canvas(24, 24)
    c.poly([(14, 1), (5, 13), (11, 13), (8, 23), (19, 9), (13, 9), (17, 1)], hexc('#ffd23f'))
    c.line(13, 3, 8, 12, hexc('#fff4b0'))
    return c.finish(OUT)
def aura():
    c = Canvas(24, 24)
    c.ell(12, 12, 11, 11, GOLD); c.ell(12, 12, 9, 9, None)
    c.ell(12, 12, 7, 7, GOLD_L); c.ell(12, 12, 5, 5, None)
    c.ell(12, 12, 2.5, 2.5, WHITE)
    return c.finish(OUT, 0.05, 0.1)
def coin():
    c = Canvas(24, 24)
    c.ell(12, 12, 10.5, 10.5, GOLD_D); c.ell(12, 12, 8.5, 8.5, GOLD)
    c.rect(11, 6, 12, 17, GOLD_D); c.rect(8, 8, 15, 9, GOLD_L)
    return c.finish(OUT)
def gem():
    c = Canvas(24, 24)
    c.poly([(12, 2), (21, 9), (12, 22), (3, 9)], CYAN)
    c.poly([(12, 2), (17, 9), (7, 9)], CYAN_L)
    c.line(3, 9, 21, 9, hexc('#2a9bc0')); c.line(12, 9, 12, 21, hexc('#2a9bc0'))
    return c.finish(OUT)
def shard():
    c = Canvas(24, 24)
    c.poly([(12, 1), (19, 10), (12, 23), (5, 10)], LAV)
    c.poly([(12, 1), (15, 10), (12, 23), (9, 10)], LAV_L)
    return c.finish(OUT)
def skills():
    c = Canvas(24, 24)
    pts = []
    for k in range(16):
        a = k * math.tau / 16 - math.pi / 2
        r = 11 if k % 2 == 0 else 4.5
        pts.append((12 + math.cos(a) * r, 12 + math.sin(a) * r))
    c.poly(pts, GOLD)
    c.ell(12, 12, 3, 3, WHITE)
    return c.finish(OUT)
def wings():
    c = Canvas(24, 24)
    w = Canvas(24, 24)
    w.poly([(11, 19), (1, 4), (7, 9), (4, 13), (9, 14), (6, 17)], WHITE)
    w.line(11, 18, 3, 6, LAV)
    c.blit(w); c.blit(w.flip())
    return c.finish(OUT)
def armor():
    c = Canvas(24, 24)
    c.poly([(5, 3), (19, 3), (22, 8), (18, 21), (6, 21), (2, 8)], GOLD)
    c.line(12, 4, 12, 20, GOLD_D); c.ell(12, 11, 2.2, 2.2, CYAN)
    return c.finish(OUT)
def glove():
    c = Canvas(24, 24)
    c.rect(7, 11, 18, 22, STEEL_D)
    for x in (7, 10, 13, 16):
        c.rect(x, 3, x + 2, 11, STEEL)
    c.rect(2, 12, 6, 16, STEEL)
    return c.finish(OUT)
def menu():
    c = Canvas(24, 24)
    for y in (5, 10, 15):
        c.rect(3, y, 20, y + 3, WHITE)
    return c.finish(OUT, 0.05, 0.1)
def user():
    c = Canvas(24, 24)
    c.ell(12, 8, 5, 5, SKIN)
    c.ell(12, 22, 10, 8, BLUE)
    return c.finish(OUT)
def glow():
    c = Canvas(24, 24)
    for k in range(8):
        a = k * math.tau / 8
        c.line(12 + math.cos(a) * 6, 12 + math.sin(a) * 6, 12 + math.cos(a) * 11, 12 + math.sin(a) * 11, GOLD, 2)
    c.ell(12, 12, 5.5, 5.5, GOLD_L)
    return c.finish(OUT, 0.05, 0.1)
def close():
    c = Canvas(24, 24)
    c.line(5, 5, 18, 18, WHITE, 4); c.line(18, 5, 5, 18, WHITE, 4)
    return c.finish(OUT, 0.05, 0.1)
def back():
    c = Canvas(24, 24)
    c.poly([(3, 12), (12, 3), (12, 8), (21, 8), (21, 16), (12, 16), (12, 21)], WHITE)
    return c.finish(OUT, 0.05, 0.1)
def speed():
    c = Canvas(24, 24)
    c.poly([(3, 4), (11, 12), (3, 20), (3, 15), (6, 12), (3, 9)], GOLD)
    c.poly([(12, 4), (20, 12), (12, 20), (12, 15), (15, 12), (12, 9)], GOLD)
    return c.finish(OUT, 0.05, 0.1)
def fx():
    c = Canvas(24, 24)
    c.poly([(12, 1), (14, 10), (23, 12), (14, 14), (12, 23), (10, 14), (1, 12), (10, 10)], WHITE)
    c.poly([(19, 3), (20, 6), (23, 7), (20, 8), (19, 11), (18, 8), (15, 7), (18, 6)], GOLD_L)
    return c.finish(OUT, 0.05, 0.1)
def nxt():
    c = Canvas(24, 24)
    c.poly([(3, 6), (14, 12), (3, 18)], WHITE)
    c.poly([(10, 6), (21, 12), (10, 18)], WHITE)
    return c.finish(OUT, 0.05, 0.1)

def gear():
    c = Canvas(24, 24)
    for k in range(8):
        a = k * math.tau / 8
        c.line(12 + math.cos(a) * 6, 12 + math.sin(a) * 6, 12 + math.cos(a) * 10.5, 12 + math.sin(a) * 10.5, STEEL, 4)
    c.ell(12, 12, 8, 8, STEEL)
    c.ell(12, 12, 3.6, 3.6, OUT)
    return c.finish(OUT, 0.05, 0.1)
def stages():
    c = Canvas(24, 24)
    c.rect(2, 17, 22, 21, GOLD_D)
    c.rect(6, 12, 22, 17, GOLD)
    c.rect(10, 7, 22, 12, GOLD_L)
    c.rect(14, 2, 22, 7, WHITE)
    return c.finish(OUT, 0.05, 0.1)
def speaker():
    c = Canvas(24, 24)
    c.poly([(3, 9), (8, 9), (14, 4), (14, 20), (8, 15), (3, 15)], WHITE)
    c.line(17, 8, 17, 16, GOLD, 2); c.line(20, 5, 20, 19, GOLD, 2)
    return c.finish(OUT, 0.05, 0.1)

ICONS = [("sword", sword), ("heart", heart), ("shield", shield), ("boot", boot), ("bolt", bolt), ("aura", aura),
         ("coin", coin), ("gem", gem), ("shard", shard), ("skills", skills), ("wings", wings), ("armor", armor),
         ("glove", glove), ("menu", menu), ("user", user), ("glow", glow), ("close", close), ("back", back),
         ("speed", speed), ("fx", fx), ("next", nxt), ("gear", gear), ("speaker", speaker), ("stages", stages)]

# ------------------------------------------------------------------ avatares 32x32
def av_hood(hood, trim, eye, halo):
    c = Canvas(32, 32)
    c.ell(16, 18, 11.5, 12.5, hood)
    c.poly([(9, 12), (23, 12), (16, 3)], hood)
    c.ell(16, 20, 8, 9, trim); c.ell(16, 20.5, 6.8, 8, hexc('#060919'))
    c.rect(12, 20, 13, 21, eye); c.rect(19, 20, 20, 21, eye)
    c.ell(16, 5, 8, 2.6, halo); c.ell(16, 5, 5.4, 1.1, None)
    return c.finish(OUT)
def av_golden():
    c = Canvas(32, 32)
    c.ell(16, 28, 13, 8, WHITE)
    c.ell(16, 15, 10.5, 10.5, hexc('#f2d46a'))
    c.ell(16, 18, 7.2, 8, SKIN)
    c.rect(12, 18, 13, 19, hexc('#3a6ea5')); c.rect(19, 18, 20, 19, hexc('#3a6ea5'))
    c.ell(16, 4, 8, 2.6, GOLD); c.ell(16, 4, 5.4, 1.1, None)
    return c.finish(OUT)
def av_knight():
    c = Canvas(32, 32)
    c.poly([(16, 0), (22, 3), (19, 9), (13, 9), (10, 3)], RED)
    c.ell(16, 17, 11, 12, STEEL_D); c.ell(16, 16, 9.5, 10.5, STEEL)
    c.rect(8, 15, 24, 18, hexc('#1a1f36'))
    c.rect(15, 18, 16, 27, STEEL_D)
    c.rect(7, 22, 10, 27, STEEL_D); c.rect(22, 22, 25, 27, STEEL_D)
    return c.finish(OUT)
def av_crown():
    c = Canvas(32, 32)
    c.ell(16, 28, 12, 8, hexc('#5a1a7a'))
    c.ell(16, 18, 9, 10, hexc('#c98f5a'))
    c.rect(12, 17, 13, 18, hexc('#2a1a0a')); c.rect(19, 17, 20, 18, hexc('#2a1a0a'))
    c.poly([(6, 10), (8, 3), (12, 8), (16, 1), (20, 8), (24, 3), (26, 10)], GOLD)
    c.ell(16, 7, 1.6, 1.6, RED); c.ell(9, 8, 1.2, 1.2, CYAN); c.ell(23, 8, 1.2, 1.2, CYAN)
    return c.finish(OUT)
def av_flame():
    c = Canvas(32, 32)
    c.poly([(8, 12), (6, 4), (11, 9), (13, 1), (16, 8), (19, 0), (21, 9), (26, 3), (24, 12)], hexc('#ff8a1f'))
    c.poly([(12, 12), (13, 6), (16, 10), (19, 5), (20, 12)], hexc('#ffd23f'))
    c.ell(16, 19, 9, 10, SKIN)
    c.rect(12, 18, 13, 19, WHITE); c.rect(19, 18, 20, 19, WHITE)
    c.ell(16, 29, 11, 6, hexc('#8f1d24'))
    return c.finish(OUT)
def av_emblem():
    c = Canvas(32, 32)
    w = Canvas(32, 32)
    w.poly([(15, 22), (1, 5), (9, 11), (4, 17), (12, 17), (8, 21)], WHITE)
    c.blit(w); c.blit(w.flip())
    c.poly([(9, 6), (23, 6), (23, 17), (16, 28), (9, 17)], BLUE)
    c.poly([(11, 8), (21, 8), (21, 16), (16, 25), (11, 16)], BLUE_L)
    c.ell(16, 14, 3, 3, GOLD_L)
    return c.finish(OUT)

AVATARS = [lambda: av_hood(WHITE, GOLD, hexc('#aef2ff'), GOLD), av_golden,
           lambda: av_hood(hexc('#b3261e'), GOLD, hexc('#ffd23f'), hexc('#ff6a5a')), av_knight,
           lambda: av_hood(hexc('#2b1a4a'), STEEL_D, hexc('#ff6bd6'), STEEL), av_crown, av_flame, av_emblem]

# ------------------------------------------------------------------ FONTE PIXEL (5x7), cédula 7x11
P = {}
def g(ch, rows): P[ch] = rows.split('/')
for ch, r in {
 'A': '.###./#...#/#...#/#####/#...#/#...#/#...#', 'B': '####./#...#/#...#/####./#...#/#...#/####.',
 'C': '.####/#..../#..../#..../#..../#..../.####', 'D': '####./#...#/#...#/#...#/#...#/#...#/####.',
 'E': '#####/#..../#..../####./#..../#..../#####', 'F': '#####/#..../#..../####./#..../#..../#....',
 'G': '.####/#..../#..../#.###/#...#/#...#/.###.', 'H': '#...#/#...#/#...#/#####/#...#/#...#/#...#',
 'I': '.###./..#../..#../..#../..#../..#../.###.', 'J': '..###/...#./...#./...#./...#./#..#./.##..',
 'K': '#...#/#..#./#.#../##.../#.#../#..#./#...#', 'L': '#..../#..../#..../#..../#..../#..../#####',
 'M': '#...#/##.##/#.#.#/#.#.#/#...#/#...#/#...#', 'N': '#...#/##..#/#.#.#/#..##/#...#/#...#/#...#',
 'O': '.###./#...#/#...#/#...#/#...#/#...#/.###.', 'P': '####./#...#/#...#/####./#..../#..../#....',
 'Q': '.###./#...#/#...#/#...#/#.#.#/#..#./.##.#', 'R': '####./#...#/#...#/####./#.#../#..#./#...#',
 'S': '.####/#..../#..../.###./....#/....#/####.', 'T': '#####/..#../..#../..#../..#../..#../..#..',
 'U': '#...#/#...#/#...#/#...#/#...#/#...#/.###.', 'V': '#...#/#...#/#...#/#...#/#...#/.#.#./..#..',
 'W': '#...#/#...#/#...#/#.#.#/#.#.#/##.##/#...#', 'X': '#...#/#...#/.#.#./..#../.#.#./#...#/#...#',
 'Y': '#...#/#...#/.#.#./..#../..#../..#../..#..', 'Z': '#####/....#/...#./..#../.#.../#..../#####',
 '0': '.###./#...#/#..##/#.#.#/##..#/#...#/.###.', '1': '..#../.##../..#../..#../..#../..#../.###.',
 '2': '.###./#...#/....#/...#./..#../.#.../#####', '3': '.###./#...#/....#/..##./....#/#...#/.###.',
 '4': '...#./..##./.#.#./#..#./#####/...#./...#.', '5': '#####/#..../####./....#/....#/#...#/.###.',
 '6': '..##./.#.../#..../####./#...#/#...#/.###.', '7': '#####/....#/...#./..#../.#.../.#.../.#...',
 '8': '.###./#...#/#...#/.###./#...#/#...#/.###.', '9': '.###./#...#/#...#/.####/....#/...#./.##..',
 '.': '...../...../...../...../...../.##../.##..', ',': '...../...../...../...../.##../.##../..#..',
 ':': '...../.##../.##../...../.##../.##../.....', ';': '...../.##../.##../...../.##../.##../.#...',
 '!': '..#../..#../..#../..#../..#../...../..#..', '?': '.###./#...#/....#/...#./..#../...../..#..',
 '-': '...../...../...../#####/...../...../.....', '+': '...../..#../..#../#####/..#../..#../.....',
 '*': '...../#.#.#/.###./#####/.###./#.#.#/.....', '/': '....#/....#/...#./..#../.#.../#..../#....',
 '%': '##..#/##..#/...#./..#../.#.../#..##/#..##', '(': '...#./..#../.#.../.#.../.#.../..#../...#.',
 ')': '.#.../..#../...#./...#./...#./..#../.#...', '[': '.###./.#.../.#.../.#.../.#.../.#.../.###.',
 ']': '.###./...#./...#./...#./...#./...#./.###.', "'": '..#../..#../...../...../...../...../.....',
 '"': '.#.#./.#.#./...../...../...../...../.....', '=': '...../...../#####/...../#####/...../.....',
 '>': '#..../.#.../..#../...#./..#../.#.../#....', '<': '....#/...#./..#../.#.../..#../...#./....#',
 '_': '...../...../...../...../...../...../#####', '#': '.#.#./#####/.#.#./.#.#./.#.#./#####/.#.#.',
 '|': '..#../..#../..#../..#../..#../..#../..#..', '&': '.##../#..#./#.#../.#.../#.#.#/#..#./.##.#',
 ' ': '...../...../...../...../...../...../.....',
 'a': '...../...../.###./....#/.####/#...#/.####', 'b': '#..../#..../####./#...#/#...#/#...#/####.',
 'c': '...../...../.###./#..../#..../#...#/.###.', 'd': '....#/....#/.####/#...#/#...#/#...#/.####',
 'e': '...../...../.###./#...#/#####/#..../.###.', 'f': '..##./.#..#/.#.../###../.#.../.#.../.#...',
 'h': '#..../#..../#.##./##..#/#...#/#...#/#...#', 'i': '..#../...../.##../..#../..#../..#../.###.',
 'k': '#..../#..../#..#./#.#../##.../#.#../#..#.', 'l': '.##../..#../..#../..#../..#../..#../.###.',
 'm': '...../...../##.#./#.#.#/#.#.#/#...#/#...#', 'n': '...../...../#.##./##..#/#...#/#...#/#...#',
 'o': '...../...../.###./#...#/#...#/#...#/.###.', 'r': '...../...../#.##./##..#/#..../#..../#....',
 's': '...../...../.####/#..../.###./....#/####.', 't': '.#.../.#.../###../.#.../.#.../.#..#/..##.',
 'u': '...../...../#...#/#...#/#...#/#..##/.##.#', 'v': '...../...../#...#/#...#/#...#/.#.#./..#..',
 'w': '...../...../#...#/#...#/#.#.#/#.#.#/.#.#.', 'x': '...../...../#...#/.#.#./..#../.#.#./#...#',
 'z': '...../...../#####/...#./..#../.#.../#####',
}.items():
    g(ch, r)
# letras com descendentes (9 linhas)
for ch, r in {'g': '...../...../.####/#...#/#...#/.####/....#/#...#/.###.',
              'j': '...#./...../..##./...#./...#./...#./...#./#..#./.##..',
              'p': '...../...../####./#...#/#...#/####./#..../#..../#....',
              'q': '...../...../.####/#...#/#...#/.####/....#/....#/....#',
              'y': '...../...../#...#/#...#/#...#/.####/....#/#...#/.###.'}.items():
    g(ch, r)

ACC = {'acute': [(3, 0), (2, 1)], 'grave': [(1, 0), (2, 1)], 'circ': [(2, 0), (1, 1), (3, 1)],
       'tilde': [(1, 1), (2, 0), (3, 0), (4, 1)], 'diaer': [(1, 0), (3, 0)]}
ACCENTED = {}
for base, marks in {'a': 'á à â ã ä', 'e': 'é è ê - ë', 'i': 'í ì î - ï', 'o': 'ó ò ô õ ö', 'u': 'ú ù û - ü',
                    'A': 'Á À Â Ã Ä', 'E': 'É È Ê - Ë', 'I': 'Í Ì Î - Ï', 'O': 'Ó Ò Ô Õ Ö', 'U': 'Ú Ù Û - Ü'}.items():
    for ch, kind in zip(marks.split(), ['acute', 'grave', 'circ', 'tilde', 'diaer']):
        if ch != '-':
            ACCENTED[ch] = (base, kind)
ACCENTED['ç'] = ('c', 'cedilla'); ACCENTED['Ç'] = ('C', 'cedilla'); ACCENTED['ñ'] = ('n', 'tilde'); ACCENTED['Ñ'] = ('N', 'tilde')

CHARS = ''.join(sorted(P.keys(), key=lambda c: (c.isalpha(), ord(c)))) + ''.join(ACCENTED.keys())
CW, CH, COLS = 7, 11, 32

def glyph_pixels(ch):
    """devolve (lista de (x,y) em coordenadas da célula 7x11, largura útil)"""
    pix = []
    if ch in P:
        rows, extra = P[ch], []
    else:
        base, kind = ACCENTED[ch]
        rows = [r for r in P[base]]
        if base == 'i':
            rows[0] = '.....'
        upper = base.isupper()
        for (x, y) in (ACC[kind] if kind in ACC else []):
            pix.append((x, y if upper else y + 2))
        if kind == 'cedilla':
            pix += [(2, 9), (1, 10)] if False else [(2, 9)]
    for ry, row in enumerate(rows):
        for rx, v in enumerate(row):
            if v == '#':
                pix.append((rx, ry + 2))
    right = max([x for x, y in pix], default=2)
    return pix, right

def font_canvas():
    n = len(CHARS)
    rows = (n + COLS - 1) // COLS
    c = Canvas(COLS * CW, rows * CH)
    adv = []
    for i, ch in enumerate(CHARS):
        pix, right = glyph_pixels(ch)
        ox, oy = (i % COLS) * CW, (i // COLS) * CH
        for x, y in pix:
            c.px(ox + x, oy + y, (255, 255, 255, 255))
        adv.append(4 if ch == ' ' else right + 2)
    return c, adv
