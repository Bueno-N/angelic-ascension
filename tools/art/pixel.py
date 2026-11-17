"""Mini biblioteca de pixel art (sem dependências). Toda a arte do jogo é gerada por código ORIGINAL,
sem assets de terceiros (sem direitos autorais). Licença da arte: CC0 / uso livre no projeto."""
import math, struct, zlib

def hexc(h, a=255):
    h = h.lstrip('#')
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)

def mix(c, t, amt):
    """mistura c com a cor t em amt (0..1)"""
    return tuple(int(c[i] * (1 - amt) + t[i] * amt) for i in range(3)) + (c[3],)

def light(c, a=0.2): return mix(c, (255, 255, 255, 255), a)
def dark(c, a=0.25): return mix(c, (0, 0, 0, 255), a)
def alpha(c, a): return (c[0], c[1], c[2], a)

class Canvas:
    def __init__(s, w, h):
        s.w, s.h = w, h
        s.p = [[None] * w for _ in range(h)]
    def px(s, x, y, c):
        x, y = int(x), int(y)
        if 0 <= x < s.w and 0 <= y < s.h:
            s.p[y][x] = c
    def get(s, x, y):
        if 0 <= x < s.w and 0 <= y < s.h:
            return s.p[y][x]
        return None
    def rect(s, x0, y0, x1, y1, c):
        for y in range(int(y0), int(y1) + 1):
            for x in range(int(x0), int(x1) + 1):
                s.px(x, y, c)
    def ell(s, cx, cy, rx, ry, c):
        for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
                if ((x + 0.5 - cx) / max(rx, 0.1)) ** 2 + ((y + 0.5 - cy) / max(ry, 0.1)) ** 2 <= 1.0:
                    s.px(x, y, c)
    def line(s, x0, y0, x1, y1, c, th=1):
        n = int(max(abs(x1 - x0), abs(y1 - y0))) * 2 + 1
        for i in range(n + 1):
            t = i / n
            x = x0 + (x1 - x0) * t
            y = y0 + (y1 - y0) * t
            if th <= 1:
                s.px(round(x), round(y), c)
            else:
                s.ell(x, y, th / 2.0, th / 2.0, c)
    def poly(s, pts, c):
        ys = [p[1] for p in pts]
        n = len(pts)
        for y in range(int(min(ys)), int(max(ys)) + 1):
            yy = y + 0.5
            xs = []
            for i in range(n):
                x0, y0 = pts[i]
                x1, y1 = pts[(i + 1) % n]
                if (y0 <= yy < y1) or (y1 <= yy < y0):
                    xs.append(x0 + (yy - y0) * (x1 - x0) / (y1 - y0))
            xs.sort()
            for k in range(0, len(xs) - 1, 2):
                for x in range(int(math.floor(xs[k] + 0.5)), int(math.floor(xs[k + 1] + 0.5))):
                    s.px(x, y, c)
    def blit(s, o, ox=0, oy=0):
        for y in range(o.h):
            for x in range(o.w):
                c = o.p[y][x]
                if c is not None:
                    s.px(x + ox, y + oy, c)
    def over(s, o, ox=0, oy=0):
        """composição com transparência (para prévias)"""
        for y in range(o.h):
            for x in range(o.w):
                c = o.p[y][x]
                if c is None:
                    continue
                d = s.get(x + ox, y + oy)
                if d is None or c[3] >= 255:
                    s.px(x + ox, y + oy, c)
                else:
                    a = c[3] / 255.0
                    s.px(x + ox, y + oy, tuple(int(c[j] * a + d[j] * (1 - a)) for j in range(3)) + (255,))
    def flip(s):
        r = Canvas(s.w, s.h)
        for y in range(s.h):
            for x in range(s.w):
                r.p[y][s.w - 1 - x] = s.p[y][x]
        return r
    def shade(s, rim=0.22, under=0.28, left=0.08):
        """luz vinda de cima/esquerda: realça bordas superiores e escurece as inferiores"""
        out = [row[:] for row in s.p]
        for y in range(s.h):
            for x in range(s.w):
                c = s.p[y][x]
                if c is None:
                    continue
                if s.get(x, y - 1) is None:
                    out[y][x] = light(c, rim)
                elif s.get(x, y + 1) is None:
                    out[y][x] = dark(c, under)
                elif s.get(x - 1, y) is None:
                    out[y][x] = light(c, left)
        s.p = out
    def outline(s, col):
        out = [row[:] for row in s.p]
        for y in range(s.h):
            for x in range(s.w):
                if s.p[y][x] is None:
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        if s.get(x + dx, y + dy) is not None:
                            out[y][x] = col
                            break
        s.p = out
    def finish(s, outline_col, rim=0.22, under=0.28):
        s.shade(rim, under)
        s.outline(outline_col)
        return s

def strip(frames):
    w, h = frames[0].w, frames[0].h
    c = Canvas(w * len(frames), h)
    for i, f in enumerate(frames):
        c.blit(f, i * w, 0)
    return c

def save_png(canvas, path):
    raw = bytearray()
    for y in range(canvas.h):
        raw.append(0)
        for x in range(canvas.w):
            c = canvas.p[y][x]
            raw.extend(c if c is not None else (0, 0, 0, 0))
    def chunk(t, d):
        b = struct.pack('>I', len(d)) + t + d
        return b + struct.pack('>I', zlib.crc32(t + d) & 0xffffffff)
    png = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', canvas.w, canvas.h, 8, 6, 0, 0, 0))
    png += chunk(b'IDAT', zlib.compress(bytes(raw), 9)) + chunk(b'IEND', b'')
    open(path, 'wb').write(png)

def scaled(canvas, k, bg=None):
    r = Canvas(canvas.w * k, canvas.h * k)
    for y in range(canvas.h):
        for x in range(canvas.w):
            c = canvas.p[y][x]
            if c is None:
                c = bg
            if c is None:
                continue
            for dy in range(k):
                for dx in range(k):
                    r.p[y * k + dy][x * k + dx] = c
    return r
