"""Gera TODA a arte do jogo em assets/sprites/*.png + manifest.json + prévia em docs/art_preview.png.
Uso: python3 tools/art/generate.py   (arte original; CC0)"""
import json, os, sys
sys.path.insert(0, os.path.dirname(__file__))
from pixel import *
import angel, enemies, fx, ui, scenery

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
OUT = os.path.join(ROOT, 'assets', 'sprites')
os.makedirs(OUT, exist_ok=True)
manifest = {}

def emit(name, frames, anims):
    sheet = strip(frames)
    save_png(sheet, os.path.join(OUT, name + '.png'))
    manifest[name] = {"fw": frames[0].w, "fh": frames[0].h, "frames": len(frames), "anims": anims}

for name, frames in angel.build().items():
    emit(name, frames, angel.ANIMS)

for name, (fn, w, h) in enemies.SHEETS.items():
    d = fn()
    frames = list(d['walk']) + list(d.get('cast', []))
    anims = {"walk": dict(start=0, count=len(d['walk']), fps=8, loop=True)}
    if 'cast' in d:
        anims["cast"] = dict(start=len(d['walk']), count=len(d['cast']), fps=8, loop=True)
    emit(name, frames, anims)

for name, (fn, anims) in fx.SHEETS.items():
    emit(name, fn(), anims)

# ---- interface: chamas da arena, ícones, avatares e fonte pixel ----
emit("fx_flame", ui.flame(), dict(play=dict(start=0, count=6, fps=10, loop=True)))
icon_frames = [f() for n, f in ui.ICONS]
emit("ui_icons", icon_frames, dict(idle=dict(start=0, count=len(icon_frames), fps=1, loop=True)))
avatar_frames = [f() for f in ui.AVATARS]
emit("avatars", avatar_frames, dict(idle=dict(start=0, count=len(avatar_frames), fps=1, loop=True)))
font_c, font_adv = ui.font_canvas()
save_png(font_c, os.path.join(OUT, 'font.png'))
save_png(scenery.craters(), os.path.join(OUT, 'map_craters.png'))   # cenário do mapa (tile 320x160)
json.dump(manifest, open(os.path.join(OUT, 'manifest.json'), 'w'), indent=1)
# O jogo lê o manifesto de um .gd (arquivos .json NÃO entram no APK exportado; scripts entram).
gd = ("class_name SpriteManifest\nextends RefCounted\n## GERADO por tools/art/generate.py. Não edite à mão.\n\nconst DATA := " + json.dumps(manifest, indent=1) + "\n"
      + "\nconst ICON_NAMES := " + json.dumps([n for n, f in ui.ICONS]) + "\nconst AVATAR_COUNT := " + str(len(avatar_frames)) + "\n"
      + "const FONT_CHARS := " + json.dumps(ui.CHARS) + "\nconst FONT_ADV := " + json.dumps(font_adv)
      + "\nconst FONT_CW := " + str(ui.CW) + "\nconst FONT_CH := " + str(ui.CH) + "\nconst FONT_COLS := " + str(ui.COLS) + "\n")
open(os.path.join(ROOT, 'data', 'sprite_manifest.gd'), 'w').write(gd)
print("sheets:", len(manifest))

# ---- prévia (para o humano conferir a arte) ----
def tint(f, t):
    g = Canvas(f.w, f.h)
    for y in range(f.h):
        for x in range(f.w):
            p = f.p[y][x]
            if p:
                g.p[y][x] = tuple(int(p[j] * t[j] / 255) for j in range(3)) + (p[3],)
    return g
rows = []
body, w3 = angel.build()['angel_body'], angel.build()['angel_wings_3']
comp = []
sh = angel.build()
for i in (0, 1, 5, 6, 9, 10):
    c = Canvas(angel.W, angel.H); c.blit(sh['angel_wings_3'][i]); c.blit(sh['angel_body'][i])
    for k, t in (('angel_boots', (255, 224, 130)), ('angel_armor', (255, 224, 130)), ('angel_gloves', (255, 224, 130))):
        c.blit(tint(sh[k][i], t))
    comp.append(c)
rows.append(strip(comp))
for name in ('imp', 'warrior', 'shadow', 'hound', 'caster', 'leech'):
    d = enemies.SHEETS[name][0]()
    rows.append(strip(d['walk'][:2] + d.get('cast', [])[:1] + d['walk'][2:3]))
for name in ('boss_baal', 'boss_mordath', 'boss_ignarr', 'boss_azazel'):
    d = enemies.SHEETS[name][0]()
    rows.append(strip([d['walk'][0], d['walk'][2], d['cast'][0]]))
fxrow = []
for name in ('fx_aura', 'fx_hit', 'fx_burst', 'fx_shield', 'fx_poof', 'fx_fireball', 'ally', 'torch'):
    fr = dict(fx.SHEETS)[name][0]() if name in dict(fx.SHEETS) else None
    fxrow.append(fr[len(fr) // 2])
fxs = []
for f in fxrow:
    pad = Canvas(max(f.w, 64) if f.w < 64 else 64, 64)
    pad.over(f, 0, 0) if f.w <= 64 and f.h <= 64 else None
    fxs.append(pad)
rows.append(strip(fxs))
rows.append(strip(icon_frames))
rows.append(strip(avatar_frames))
rows.append(strip(ui.flame()))
def stack_h(canvases, k, gap):
    W = max(c.w for c in canvases) * k
    Hh = sum(c.h * k + gap for c in canvases)
    out = Canvas(W, Hh)
    for y in range(Hh):
        out.p[y] = [hexc('#1b1030')] * W
    y = 0
    for c in canvases:
        out.over(scaled(c, k), 0, y); y += c.h * k + gap
    return out
os.makedirs(os.path.join(ROOT, 'docs'), exist_ok=True)
prev = stack_h(rows, 3, 6)
save_png(prev, os.path.join(ROOT, 'docs', 'art_preview.png'))
print("preview:", prev.w, prev.h)
