"""Efeitos sonoros sintetizados (22,05 kHz, mono). Cada função devolve um vetor float; o normalizador cuida do pico."""
import numpy as np
from synth import *

SR = 22050
def R(seed): return np.random.default_rng(seed)
def N(sec): return int(sec * SR)

def tinkle(f, dur=0.35, decay=14.0, seed=1):
    n = N(dur); t = tarr(n, SR)
    mod = np.sin(2 * np.pi * f * 2.01 * t) * np.exp(-t * 30) * 1.5
    return np.sin(2 * np.pi * f * t + mod) * exp_env(n, SR, decay)

def bell(f, dur=0.9, decay=4.0):
    n = N(dur); t = tarr(n, SR)
    return (np.sin(2 * np.pi * f * t) + 0.5 * np.sin(2 * np.pi * f * 2.76 * t) * np.exp(-t * 3)
            + 0.3 * np.sin(2 * np.pi * f * 5.4 * t) * np.exp(-t * 6)) * exp_env(n, SR, decay)

def thump(f0=160, f1=45, dur=0.3, decay=11.0):
    n = N(dur)
    return np.sin(2 * np.pi * np.cumsum(sweep(f0, f1, n, 3.0)) / SR) * exp_env(n, SR, decay)

def whoosh(dur, f1, f2, rng, peak_at=0.5, width=0.6):
    n = N(dur)
    x = noise(n, rng)
    u = np.linspace(0, 1, n)
    env = np.exp(-((u - peak_at) / width) ** 2 * 3.0)
    out = np.zeros(n)
    steps = 6
    for k in range(steps):
        a, b = k / steps, (k + 1) / steps
        fc1 = f1 + (f2 - f1) * a; fc2 = f1 + (f2 - f1) * b
        seg = bp(x, max(60, fc1 * 0.7), fc2 * 1.3 + 100, SR)
        m = (u >= a) & (u < b + (1.0 / steps) * 0.5)
        out += seg * m * np.minimum(1, (np.clip(u - a, 0, 1) * steps * 3 + 0.3))
    return out * env

def burst(dur, fc, rng, decay=20.0, kind='lp'):
    n = N(dur)
    x = noise(n, rng)
    x = lp(x, fc, SR) if kind == 'lp' else (hp(x, fc, SR) if kind == 'hp' else bp(x, fc * 0.6, fc * 1.6, SR))
    return x * exp_env(n, SR, decay, 0.001)

def voice(f0, f1, dur, formants, rng, noise_amt=0.05, vib=0.0, decay=6.0):
    n = N(dur)
    f = sweep(f0, f1, n, 1.5)
    v = formant_voice(f, n, SR, formants, rng, vib=vib, breath=noise_amt)
    return v * exp_env(n, SR, decay, 0.01)

def explosion(dur, rng, low=45, bright=5500):
    n = N(dur)
    x = noise(n, rng)
    u = np.linspace(0, 1, n)
    out = np.zeros(n)
    for k, fc in enumerate([bright, bright * 0.5, bright * 0.2, bright * 0.08]):
        a = k / 4
        out += lp(x, fc, SR) * np.exp(-((u - a * 0.6) / 0.35) ** 2 * 2) * (1.0 if k else 0.8)
    out *= exp_env(n, SR, 3.0, 0.001)
    return out + 1.4 * thump(low * 2.2, low, dur, 3.2)[:n] * 1.0

def chord(freqs, dur, kind='saw', lpf=1500, a=0.05, r=0.3, det=0.004, vib=0.004):
    n = N(dur)
    out = np.zeros(n)
    for f in freqs:
        for d in (-det, 0, det):
            out += osc(kind, f * (1 + d), n, SR, vib=vib)
    out = lp(out, lpf, SR)
    return out * adsr(n, SR, a, 0.1, 0.85, r) / (3 * len(freqs))

M = lambda n: 440.0 * 2 ** ((n - 69) / 12)

# ---------------------------------------------------------------- jogador
def atk():
    r = R(1)
    w = whoosh(0.16, 1500, 5200, r, 0.4, 0.5)
    t = tarr(N(0.16), SR)
    ting = np.sin(2 * np.pi * np.cumsum(sweep(2200, 1500, N(0.16))) / SR) * exp_env(N(0.16), SR, 28) * 0.35
    return mixsum(w, ting)

def hurt():
    r = R(2)
    return mixsum(thump(200, 55, 0.25, 14) * 1.2, burst(0.18, 1100, r, 18) * 0.8,
                  voice(240, 130, 0.22, VOW_O, r, 0.1, 0.02, 11) * 0.5)

def die():
    r = R(3)
    n = N(1.5)
    f = sweep(520, 90, n, 1.6)
    x = osc('tri', f, n, SR, vib=0.02) * exp_env(n, SR, 1.6, 0.02)
    x += 0.5 * lp(osc('saw', f * 0.5, n, SR), 900, SR) * exp_env(n, SR, 2.2)
    y = mixsum(x, np.concatenate([thump(120, 35, 0.6, 5.0), np.zeros(n - N(0.6))]) * 0.9)
    return reverb(y, SR, 1.0, 0.3, r)

def stage_up():
    parts = []
    out = np.zeros(N(1.0))
    for i, nn in enumerate([72, 76, 79, 84]):
        place(out, bell(M(nn), 0.6, 5.0) * 0.7, i * 0.11, SR)
    place(out, chord([M(60), M(64), M(67)], 0.7, 'saw', 1200, 0.02, 0.4) * 0.5, 0.3, SR)
    return reverb(out, SR, 0.8, 0.2)

def ui_click():
    n = N(0.05)
    return np.sin(2 * np.pi * 1000 * tarr(n, SR)) * exp_env(n, SR, 70, 0.0005) + 0.4 * np.sin(2 * np.pi * 2000 * tarr(n, SR)) * exp_env(n, SR, 90, 0.0005)

def ui_buy():
    out = np.zeros(N(0.4))
    place(out, bell(M(88), 0.3, 12.0), 0.0, SR)
    place(out, bell(M(93), 0.35, 10.0), 0.07, SR)
    return out

def mob_hit():
    r = R(5)
    return mixsum(burst(0.05, 1800, r, 60, 'bp') * 0.8, thump(300, 120, 0.06, 50) * 0.5)

# ---------------------------------------------------------------- habilidades do anjo
def sk_celestial_lance():
    r = R(10)
    n = N(0.45)
    f = np.concatenate([sweep(2600, 450, N(0.2), 2.2), np.full(n - N(0.2), 450.0)])
    zap = lp(osc('saw', f, n, SR), 3500, SR) * exp_env(n, SR, 9, 0.002)
    shim = np.sin(2 * np.pi * 3300 * tarr(n, SR)) * (0.6 + 0.4 * np.sin(2 * np.pi * 38 * tarr(n, SR))) * exp_env(n, SR, 7)
    return mixsum(zap * 0.7, shim * 0.3, burst(0.1, 4500, r, 40, 'hp') * 0.5)

def sk_holy_shield():
    out = np.zeros(N(1.1))
    for i, nn in enumerate([72, 79, 84]):
        place(out, bell(M(nn), 0.9, 3.2) * 0.6, i * 0.05, SR)
    place(out, chord([M(48), M(55), M(60)], 1.0, 'saw', 900, 0.25, 0.5), 0.0, SR)
    return reverb(out, SR, 1.1, 0.25)

def sk_rain_of_light():
    r = R(12)
    out = np.zeros(N(1.1))
    for k in range(16):
        f = r.choice([M(n) for n in (84, 88, 91, 93, 96)])
        place(out, tinkle(f, 0.3, 16 + r.random() * 8) * (0.4 + 0.6 * r.random()), k * 0.05 + r.random() * 0.03, SR)
    place(out, whoosh(0.9, 1500, 3500, r, 0.5, 0.7) * 0.18, 0.0, SR)
    return reverb(out, SR, 0.7, 0.2)

def sk_rain_hit():
    r = R(13)
    return mixsum(tinkle(M(89 + int(r.integers(0, 3))), 0.18, 22), thump(200, 90, 0.1, 30) * 0.4)

def sk_swords_of_paradise():
    r = R(14)
    out = np.zeros(N(0.8))
    for k in range(3):
        place(out, whoosh(0.22, 1500, 6000, r, 0.45, 0.5) * 0.8, k * 0.17, SR)
        place(out, bell(M(88 + k * 2), 0.5, 7.0) * 0.25, k * 0.17 + 0.05, SR)
    return out

def sk_divine_judgment():
    r = R(15)
    n = N(1.2)
    crack = burst(0.04, 6000, r, 120, 'hp') * 1.4
    thunder = lp(noise(n, r), 1500, SR) * exp_env(n, SR, 3.2, 0.005)
    sub = thump(110, 38, 1.0, 3.5)
    choir = chord([M(50), M(57), M(62), M(66)], 1.1, 'saw', 1100, 0.15, 0.6) * 0.8
    return reverb(mixsum(crack, thunder * 0.9, sub * 1.1, choir * 0.5), SR, 1.0, 0.25, r)

def sk_wings_of_redemption():
    r = R(16)
    out = np.zeros(N(1.3))
    place(out, whoosh(0.8, 900, 3200, r, 0.55, 0.6) * 0.9, 0.0, SR)
    for i, nn in enumerate([67, 71, 74, 79]):
        place(out, chord([M(nn), M(nn + 12)], 0.8, 'tri', 2200, 0.15, 0.4, 0.002) * 1.2, 0.1 + i * 0.12, SR)
    for i in range(6):
        place(out, tinkle(M(91 + i % 3 * 2), 0.3, 16) * 0.5, 0.45 + i * 0.07, SR)
    return reverb(out, SR, 1.2, 0.3, r)

def sk_army_of_archangels():
    out = np.zeros(N(1.4))
    for i, (nn, d) in enumerate([(55, 0.22), (62, 0.22), (67, 0.7)]):
        place(out, chord([M(nn), M(nn + 12)], d + 0.15, 'saw', 1400, 0.03, 0.1, 0.006, 0.01), i * 0.23, SR)
    place(out, burst(0.9, 7000, R(17), 3.5, 'hp') * 0.15, 0.46, SR)
    return reverb(out, SR, 1.0, 0.25)

def sk_celestial_fury():
    r = R(18)
    n = N(1.0)
    f = sweep(70, 200, n, 0.7)
    growl = soft(lp(osc('saw', f, n, SR, vib=0.03, vib_hz=17), 1300, SR), 2.5) * adsr(n, SR, 0.02, 0.1, 0.8, 0.3)
    rise = whoosh(0.8, 500, 4500, r, 0.8, 0.5) * 0.4
    pw = chord([M(45), M(52), M(57)], 0.9, 'saw', 1800, 0.01, 0.4)
    return reverb(mixsum(growl * 0.7, rise, pw * 0.6, thump(150, 50, 0.4, 7)), SR, 0.8, 0.2, r)

def sk_holy_apocalypse():
    r = R(19)
    n = N(1.9)
    ex = explosion(1.9, r, 42, 6500)
    out = ex[:n]
    for i, nn in enumerate([72, 76, 79, 84, 88]):
        place(out, bell(M(nn), 1.2, 2.5) * 0.35, 0.05 + i * 0.05, SR)
    return reverb(out, SR, 1.4, 0.25, r)

def sk_death_of_hell():
    r = R(20)
    n = N(2.4)
    ex = explosion(2.0, r, 36, 5000)
    choir = np.zeros(n)
    for i, f in enumerate([M(43), M(50), M(55), M(59), M(62)]):
        place(choir, formant_voice(np.full(N(2.0), f), N(2.0), SR, VOW_A, r, 0.01, 0.02) * adsr(N(2.0), SR, 0.5, 0.1, 0.9, 0.8) * 0.4, 0.1, SR)
    rumble = lp(noise(n, r), 220, SR) * exp_env(n, SR, 1.4, 0.01)
    shock = whoosh(0.6, 300, 3000, r, 0.2, 0.4) * 0.8
    out = mixsum(ex * 1.0, choir * 0.9, rumble * 1.6, shock)
    for i, nn in enumerate([79, 83, 86, 91]):
        place(out, bell(M(nn), 1.4, 2.0) * 0.3, 0.3 + i * 0.1, SR)
    return reverb(out, SR, 1.6, 0.3, r)

# ---------------------------------------------------------------- mobs (por sprite)
def mob_imp_atk():
    r = R(30); return mixsum(voice(720, 520, 0.14, VOW_A, r, 0.08, 0.02, 14), burst(0.05, 3000, r, 60, 'hp') * 0.2)
def mob_imp_die():
    r = R(31); return voice(900, 230, 0.28, VOW_A, r, 0.1, 0.03, 8)
def mob_warrior_atk():
    r = R(32); return mixsum(voice(150, 105, 0.2, VOW_O, r, 0.12, 0.02, 9), bell(430, 0.18, 20) * 0.4, burst(0.06, 2500, r, 50, 'bp') * 0.4)
def mob_warrior_die():
    r = R(33); return mixsum(voice(160, 55, 0.4, VOW_O, r, 0.12, 0.03, 5), thump(130, 40, 0.3, 9) * 0.9)
def mob_shadow_atk():
    r = R(34); return mixsum(burst(0.22, 3500, r, 9, 'hp') * 0.7, whoosh(0.22, 2000, 5000, r, 0.3, 0.5) * 0.4)
def mob_shadow_die():
    r = R(35); return reverb(mixsum(whoosh(0.4, 4000, 600, r, 0.25, 0.5), voice(420, 130, 0.35, VOW_U, r, 0.2, 0.05, 6) * 0.5), SR, 0.5, 0.25, r)
def mob_hound_atk():
    r = R(36); return mixsum(voice(210, 150, 0.24, VOW_A, r, 0.25, 0.04, 8), burst(0.1, 1600, r, 22, 'bp') * 0.3)
def mob_hound_die():
    r = R(37); return voice(620, 200, 0.32, VOW_A, r, 0.1, 0.06, 6)
def mob_caster_atk():
    n = N(0.18); t = tarr(n, SR)
    return np.sin(2 * np.pi * np.cumsum(sweep(500, 900, n, 1.0)) / SR) * (0.6 + 0.4 * np.sin(2 * np.pi * 30 * t)) * exp_env(n, SR, 9)
def mob_caster_die():
    r = R(38); n = N(0.4)
    return mixsum(burst(0.4, 4500, r, 8, 'hp') * 0.5, np.sin(2 * np.pi * np.cumsum(sweep(1100, 200, n, 2.0)) / SR) * exp_env(n, SR, 7))
def mob_leech_atk():
    r = R(39); n = N(0.25)
    f = 140 + 60 * np.sin(2 * np.pi * 22 * tarr(n, SR))
    return lp(noise(n, r), 700, SR) * 0.8 * exp_env(n, SR, 8) + osc('sine', f, n, SR) * exp_env(n, SR, 9) * 0.6
def mob_leech_die():
    r = R(40); return mixsum(burst(0.12, 700, r, 25) * 1.0, thump(150, 50, 0.3, 11), lp(noise(N(0.3), r), 400, SR) * exp_env(N(0.3), SR, 10) * 0.6)
def mob_shoot():
    r = R(41); return mixsum(whoosh(0.3, 600, 2000, r, 0.35, 0.5) * 0.9, burst(0.06, 1200, r, 40) * 0.6)
def mob_drain():
    r = R(42); n = N(0.5)
    f = sweep(120, 330, n, 1.0) + 40 * np.sin(2 * np.pi * 14 * tarr(n, SR))
    return mixsum(lp(osc('saw', f, n, SR), 900, SR) * adsr(n, SR, 0.05, 0.1, 0.8, 0.2) * 0.6, lp(noise(n, r), 600, SR) * exp_env(n, SR, 5) * 0.4)

# ---------------------------------------------------------------- chefes e mini-chefes
def warn():
    out = np.zeros(N(0.42))
    for i in range(2):
        n = N(0.14)
        place(out, osc('square', 196, n, SR) * adsr(n, SR, 0.005, 0.02, 0.8, 0.04) * 0.5, i * 0.2, SR)
    return lp(out, 1200, SR)

def ab_area_slam():
    r = R(50)
    out = mixsum(thump(90, 28, 0.9, 5.0) * 1.5, burst(0.5, 700, r, 7) * 0.9, burst(0.25, 3500, r, 20, 'hp') * 0.3)
    for i in range(5):
        place(out, burst(0.05, 2500, r, 60, 'bp') * 0.3, 0.12 + i * 0.07 + r.random() * 0.04, SR)
    return out

def ab_charge():
    r = R(51)
    out = np.zeros(N(0.9))
    place(out, whoosh(0.6, 400, 3000, r, 0.8, 0.5) * 0.8, 0.0, SR)
    for i in range(4):
        place(out, thump(120, 40, 0.2, 14) * 0.8, 0.05 + i * 0.13, SR)
    place(out, thump(140, 35, 0.3, 9) * 1.1, 0.58, SR)
    return out

def ab_summon_demons():
    r = R(52)
    out = np.zeros(N(1.4))
    place(out, chord([M(33), M(36), M(40), M(45)], 1.3, 'saw', 650, 0.5, 0.5, 0.01, 0.02), 0.0, SR)
    place(out, bp(noise(N(1.2), r), 800, 2500, SR) * exp_env(N(1.2), SR, 2.0, 0.3) * 0.45, 0.1, SR)
    place(out, thump(80, 30, 0.5, 6) * 0.9, 0.0, SR)
    for i in range(3):
        place(out, voice(180 + i * 40, 90, 0.5, VOW_O, r, 0.2, 0.05, 3.5) * 0.6, 0.3 + i * 0.2, SR)
    return reverb(out, SR, 1.2, 0.3, r)

def ab_hellfire_projectiles():
    r = R(53)
    out = np.zeros(N(0.9))
    for i in range(5):
        place(out, mixsum(whoosh(0.3, 700, 2500, r, 0.35, 0.5), burst(0.05, 1500, r, 40) * 0.6), i * 0.07, SR)
    return out * 0.7

def ab_meteor_rain():
    r = R(54)
    out = np.zeros(N(1.7))
    for i in range(5):
        t0 = 0.05 + i * 0.2
        n = N(0.5)
        w = np.sin(2 * np.pi * np.cumsum(sweep(2200 - i * 150, 300, n, 1.6)) / SR) * exp_env(n, SR, 2.0, 0.05) * 0.25
        place(out, w, t0, SR)
        place(out, explosion(0.7, r, 50, 4000) * 0.55, t0 + 0.45, SR)
    return out

def ab_flame_breath():
    r = R(55)
    n = N(1.1)
    u = np.linspace(0, 1, n)
    base = bp(noise(n, r), 300, 3000, SR) * (np.minimum(1, u * 6) * (1 - u ** 3))
    crackle = (noise(n, r) > 0.985) * noise(n, r)
    crackle = hp(crackle, 1500, SR) * 3.0 * (1 - u)
    return mixsum(base * 1.0, crackle * 0.5, thump(80, 50, 0.6, 3) * 0.4)

def ab_shadow_step():
    r = R(56)
    out = np.zeros(N(1.0))
    place(out, whoosh(0.35, 3000, 400, r, 0.3, 0.5) * 0.6, 0.0, SR)
    place(out, voice(300, 120, 0.4, VOW_U, r, 0.3, 0.04, 4) * 0.5, 0.05, SR)
    place(out, whoosh(0.35, 400, 3500, r, 0.7, 0.5) * 0.6, 0.35, SR)
    place(out, thump(110, 35, 0.35, 8) * 1.0, 0.62, SR)
    return reverb(out, SR, 0.7, 0.25, r)

def ab_soul_orbs():
    r = R(57)
    out = np.zeros(N(1.4))
    for i in range(4):
        n = N(0.7)
        f = sweep(380 + i * 70, 760 + i * 90, n, 0.8) * (1 + 0.02 * np.sin(2 * np.pi * 6 * tarr(n, SR)))
        x = np.sin(2 * np.pi * np.cumsum(f) / SR) * adsr(n, SR, 0.1, 0.1, 0.7, 0.4) * (0.7 + 0.3 * np.sin(2 * np.pi * 9 * tarr(n, SR)))
        place(out, x * 0.5, i * 0.12, SR)
    place(out, bp(noise(N(1.0), r), 1200, 4000, SR) * exp_env(N(1.0), SR, 2.5, 0.1) * 0.2, 0.05, SR)
    return reverb(out, SR, 1.2, 0.35, r)

def boss_roar():
    r = R(60)
    n = N(1.5)
    f = sweep(95, 48, n, 1.2) * (1 + 0.04 * np.sin(2 * np.pi * 14 * tarr(n, SR)))
    g = soft(formant_voice(f, n, SR, [(300, 120, 1.0), (850, 200, 0.7), (1900, 300, 0.2)], r, 0.0, 0.2), 2.0) * adsr(n, SR, 0.1, 0.2, 0.8, 0.6)
    return reverb(mixsum(g * 1.0, thump(70, 28, 0.8, 4) * 0.8, lp(noise(n, r), 500, SR) * exp_env(n, SR, 2.5) * 0.5), SR, 1.0, 0.25, r)

def mini_roar():
    r = R(61)
    n = N(0.8)
    f = sweep(140, 80, n, 1.2) * (1 + 0.03 * np.sin(2 * np.pi * 16 * tarr(n, SR)))
    g = soft(formant_voice(f, n, SR, [(350, 120, 1.0), (900, 200, 0.6), (2000, 300, 0.2)], r, 0.0, 0.15), 2.0) * adsr(n, SR, 0.05, 0.1, 0.8, 0.3)
    return reverb(mixsum(g, thump(90, 35, 0.4, 6) * 0.6), SR, 0.6, 0.2, r)

def boss_die():
    r = R(62)
    n = N(2.2)
    f = sweep(110, 30, n, 1.0)
    g = soft(formant_voice(f, n, SR, VOW_O, r, 0.02, 0.2), 2.5) * exp_env(n, SR, 1.4, 0.05)
    return reverb(mixsum(explosion(2.0, r, 40, 4500), g * 0.9), SR, 1.4, 0.3, r)

def mini_die():
    r = R(63)
    return reverb(mixsum(explosion(1.0, r, 55, 4500) * 0.9, voice(160, 60, 0.6, VOW_O, r, 0.1, 0.03, 4) * 0.7), SR, 0.7, 0.2, r)

def ally_strike():
    r = R(64)
    return mixsum(burst(0.1, 3500, r, 30, 'bp') * 0.7, bell(M(84), 0.25, 12) * 0.3)

SFX = {
    "atk": atk, "hurt": hurt, "die": die, "stage_up": stage_up, "ui_click": ui_click, "ui_buy": ui_buy, "mob_hit": mob_hit,
    "sk_celestial_lance": sk_celestial_lance, "sk_holy_shield": sk_holy_shield, "sk_rain_of_light": sk_rain_of_light,
    "sk_rain_hit": sk_rain_hit, "sk_swords_of_paradise": sk_swords_of_paradise, "sk_divine_judgment": sk_divine_judgment,
    "sk_wings_of_redemption": sk_wings_of_redemption, "sk_army_of_archangels": sk_army_of_archangels,
    "sk_celestial_fury": sk_celestial_fury, "sk_holy_apocalypse": sk_holy_apocalypse, "sk_death_of_hell": sk_death_of_hell,
    "mob_imp_atk": mob_imp_atk, "mob_imp_die": mob_imp_die, "mob_warrior_atk": mob_warrior_atk, "mob_warrior_die": mob_warrior_die,
    "mob_shadow_atk": mob_shadow_atk, "mob_shadow_die": mob_shadow_die, "mob_hound_atk": mob_hound_atk, "mob_hound_die": mob_hound_die,
    "mob_caster_atk": mob_caster_atk, "mob_caster_die": mob_caster_die, "mob_leech_atk": mob_leech_atk, "mob_leech_die": mob_leech_die,
    "mob_shoot": mob_shoot, "mob_drain": mob_drain, "warn": warn,
    "ab_area_slam": ab_area_slam, "ab_charge": ab_charge, "ab_summon_demons": ab_summon_demons,
    "ab_hellfire_projectiles": ab_hellfire_projectiles, "ab_meteor_rain": ab_meteor_rain, "ab_flame_breath": ab_flame_breath,
    "ab_shadow_step": ab_shadow_step, "ab_soul_orbs": ab_soul_orbs, "boss_roar": boss_roar, "mini_roar": mini_roar,
    "boss_die": boss_die, "mini_die": mini_die, "ally_strike": ally_strike,
}
