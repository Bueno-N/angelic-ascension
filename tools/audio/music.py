"""Compositor procedural das 4 trilhas (3 de fase + 1 de chefe). Cada uma é um LOOP de 16 compassos, sem emendas
(caudas de reverb dão a volta no início). 32 kHz, mono. Tudo ORIGINAL (CC0)."""
import numpy as np
from synth import *

SR = 32000
M = lambda n: 440.0 * 2 ** ((n - 69) / 12)
QUAL = {'maj': [0, 4, 7], 'min': [0, 3, 7], 'maj7': [0, 4, 7, 11], 'min7': [0, 3, 7, 10], 'sus2': [0, 2, 7], 'dim': [0, 3, 6], 'maj9': [0, 4, 7, 14]}

def add(buf, sig, start):
    n = len(buf); L = len(sig); start %= n
    e = min(L, n - start)
    buf[start:start + e] += sig[:e]
    pos, r = e, L - e
    while r > 0:
        m = min(r, n)
        buf[:m] += sig[pos:pos + m]
        pos += m; r -= m

# ---------------------------------------------------------------- vozes
def v_pad(freqs, n, lpf, a, r):
    out = np.zeros(n)
    for f in freqs:
        for d in (-0.006, 0.0, 0.006):
            out += osc('saw', f * (1 + d), n, SR, vib=0.002, vib_hz=0.4)
    return lp(out, lpf, SR) * adsr(n, SR, a, 0.1, 0.9, r) / (3 * len(freqs))

def v_pluck(f, n, bright=1.0, decay=7.0):
    t = tarr(n, SR)
    x = np.sin(2 * np.pi * f * t) + 0.5 * np.sin(2 * np.pi * f * 2 * t) * bright * np.exp(-t * decay * 0.8) + 0.25 * np.sin(2 * np.pi * f * 3 * t) * bright * np.exp(-t * decay * 1.3)
    return x * exp_env(n, SR, decay, 0.002)

def v_bell(f, n, decay=3.0):
    t = tarr(n, SR)
    mod = np.sin(2 * np.pi * f * 3.5 * t) * 1.8 * np.exp(-t * 6)
    return np.sin(2 * np.pi * f * t + mod) * exp_env(n, SR, decay, 0.002)

def v_bass(f, n, kind='tri', lpf=500, decay=4.0, drive=1.0):
    x = osc(kind, f, n, SR)
    x = lp(x, lpf, SR)
    if drive > 1.0: x = soft(x, drive)
    return x * adsr(n, SR, 0.004, 0.05, 0.8, min(0.05, n / SR * 0.4)) * np.exp(-tarr(n, SR) * decay * 0.3)

def v_lead(f, n, kind='saw', lpf=2600, vib=0.008, a=0.02, r=0.08):
    x = osc(kind, f, n, SR, vib=vib, vib_hz=5.2) + 0.6 * osc(kind, f * 1.004, n, SR, vib=vib, vib_hz=5.0)
    return lp(x, lpf, SR) * adsr(n, SR, a, 0.08, 0.8, r) * 0.5

def v_choir(f, n, rng, vowel):
    x = formant_voice(np.full(n, f), n, SR, vowel, rng, 0.006, 0.02) + formant_voice(np.full(n, f * 1.005), n, SR, vowel, rng, 0.007, 0.0)
    return x * adsr(n, SR, 0.3, 0.1, 0.9, 0.5) * 0.5

def kick(punch=1.0):
    n = int(0.32 * SR)
    f = sweep(150, 42, n, 3.5)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * exp_env(n, SR, 11, 0.001) * punch

def snare(rng, snap=1.0):
    n = int(0.25 * SR)
    t = tarr(n, SR)
    return (bp(noise(n, rng), 1200, 7000, SR) * exp_env(n, SR, 16, 0.001) * 0.7 + np.sin(2 * np.pi * 190 * t) * exp_env(n, SR, 22) * 0.5) * snap

def hat(rng, open_=False):
    n = int((0.22 if open_ else 0.05) * SR)
    return hp(noise(n, rng), 7000, SR) * exp_env(n, SR, 9 if open_ else 55, 0.0005) * 0.35

def taiko(rng, pitch=1.0):
    n = int(0.55 * SR)
    f = sweep(130 * pitch, 62 * pitch, n, 3.0)
    return (np.sin(2 * np.pi * np.cumsum(f) / SR) * exp_env(n, SR, 6.0, 0.001) + 0.25 * lp(noise(n, rng), 600, SR) * exp_env(n, SR, 30)) * 1.0

def crash(rng):
    n = int(2.2 * SR)
    return hp(noise(n, rng), 4000, SR) * exp_env(n, SR, 2.2, 0.002) * 0.4

def riser(n, rng):
    x = bp(noise(n, rng), 600, 9000, SR)
    return x * np.linspace(0, 1, n) ** 2.2 * 0.35

# ---------------------------------------------------------------- melodia
def make_melody(rng, scale, root, chords, bars, lo, hi, patterns):
    """devolve [(compasso, tempo_em_batidas, duração_em_batidas, nota_midi)]"""
    cands = [n for n in range(lo, hi + 1) if (n - root) % 12 in scale]
    notes = []
    last = cands[len(cands) // 2]
    motif_rhythm = {}
    for b in range(bars):
        cr, q = chords[b % len(chords)]
        tones = [n for n in cands if (n - cr) % 12 in QUAL[q]]
        key = (b // 2) % 2          # compassos em pares compartilham o ritmo (soa como frase)
        if b % 4 in (0, 2) or key not in motif_rhythm:
            motif_rhythm[key] = patterns[int(rng.integers(0, len(patterns)))]
        pat = motif_rhythm[key] if b % 8 != 7 else [(0.0, 3.0)]
        for (st, ln) in pat:
            if st in (0.0, 2.0) or ln >= 2.0:
                pool = sorted(tones, key=lambda n: abs(n - last))[:3]
                nn = int(rng.choice(pool))
            else:
                i = cands.index(min(cands, key=lambda n: abs(n - last)))
                i = int(np.clip(i + int(rng.choice([-2, -1, 1, 2])), 0, len(cands) - 1))
                nn = cands[i]
            notes.append((b, st, ln, nn))
            last = nn
    return notes

def build(spec):
    rng = np.random.default_rng(spec['seed'])
    bpm = spec['bpm']
    beat = 60.0 / bpm
    bar_n = int(round(4 * beat * SR))
    bars = len(spec['chords']) * 2 if False else spec['bars']
    N = bar_n * bars
    ch = spec['chords']                      # lista de (raiz_midi_grave, qualidade) por compasso (repete)
    root = spec['root']
    def chord_at(b): return ch[b % len(ch)]
    def notes_of(b, octave_shift=0):
        r_, q = chord_at(b)
        return [r_ + i + 12 * octave_shift for i in QUAL[q]]
    L = spec['layers']                      # layer -> (compasso_inicial, compasso_final) onde toca

    def active(name, b):
        a = L.get(name)
        return a is not None and a[0] <= b < a[1]

    pad_bus = np.zeros(N); arp_bus = np.zeros(N); bass_bus = np.zeros(N); lead_bus = np.zeros(N)
    choir_bus = np.zeros(N); drum_bus = np.zeros(N); fx_bus = np.zeros(N)

    for b in range(bars):
        s0 = b * bar_n
        if active('pad', b):
            add(pad_bus, v_pad([M(n + 12) for n in notes_of(b)], bar_n + int(0.6 * SR), spec['pad_lpf'], 0.5, 0.6), s0)
        if active('choir', b):
            r_, q = chord_at(b)
            for i, n in enumerate([r_ + 24, r_ + 24 + QUAL[q][1], r_ + 24 + QUAL[q][2]]):
                add(choir_bus, v_choir(M(n), bar_n + int(0.5 * SR), rng, spec['vowel']), s0)
        if active('bass', b):
            r_, q = chord_at(b)
            pat = spec['bass_pat']           # lista de (posição_em_batidas, duração, oitava_extra)
            for (st, ln, oc) in pat:
                f = M(r_ - 12 + 12 * oc)
                add(bass_bus, v_bass(f, int(ln * beat * SR), spec['bass_kind'], spec['bass_lpf'], 4.0, spec.get('bass_drive', 1.0)), s0 + int(st * beat * SR))
        if active('arp', b):
            tones = notes_of(b, 1) + [n + 12 for n in notes_of(b, 1)]
            step = spec['arp_step']          # em batidas
            k = 0
            pos = 0.0
            while pos < 4.0 - 1e-6:
                n = tones[spec['arp_pat'][k % len(spec['arp_pat'])] % len(tones)]
                ln = int(step * beat * SR * spec.get('arp_len', 1.6))
                if spec['arp_voice'] == 'bell':
                    sig = v_bell(M(n + 12), ln, 4.0)
                elif spec['arp_voice'] == 'saw':
                    sig = lp(osc('saw', M(n), ln, SR), 1800, SR) * exp_env(ln, SR, 9, 0.002) * 0.5
                else:
                    sig = v_pluck(M(n), ln, 1.0, spec.get('arp_decay', 7.0))
                add(arp_bus, sig * (1.0 if (k % 4 == 0) else 0.72), s0 + int(pos * beat * SR))
                pos += step; k += 1
        if active('drums', b):
            for (st, kind, vel) in spec['drum_pat']:
                if kind == 'kick': sig = kick() * vel
                elif kind == 'snare': sig = snare(rng) * vel
                elif kind == 'hat': sig = hat(rng) * vel
                elif kind == 'ohat': sig = hat(rng, True) * vel
                elif kind == 'taiko': sig = taiko(rng) * vel
                elif kind == 'taiko2': sig = taiko(rng, 1.35) * vel
                else: continue
                add(drum_bus, sig, s0 + int(st * beat * SR))
        if b in spec.get('crash_bars', []):
            add(fx_bus, crash(rng) * 0.8, s0)
        if b == bars - 1 and spec.get('riser', False):
            add(fx_bus, riser(bar_n, rng), s0)

    if 'lead' in L:
        a, z = L['lead']
        mel = make_melody(rng, spec['scale'], root, ch, bars, spec['lead_lo'], spec['lead_hi'], spec['lead_patterns'])
        for (b, st, ln, nn) in mel:
            if not (a <= b < z): continue
            n_s = int(ln * beat * SR * 0.95) + int(0.12 * SR)
            if spec['lead_voice'] == 'bell':
                sig = v_bell(M(nn), n_s, 2.5) * 0.9
            else:
                sig = v_lead(M(nn), n_s, spec['lead_voice'], spec['lead_lpf'], 0.008, 0.015, 0.1)
            add(lead_bus, sig, b * bar_n + int(st * beat * SR))

    wet = spec['reverb']
    pad_bus = reverb(pad_bus, SR, 1.8, wet, rng, True)
    choir_bus = reverb(choir_bus, SR, 2.2, wet + 0.1, rng, True)
    lead_bus = reverb(lead_bus, SR, 1.4, wet, rng, True)
    arp_bus = reverb(arp_bus, SR, 1.0, wet * 0.7, rng, True)
    g = spec['mix']
    mix = (pad_bus * g['pad'] + choir_bus * g['choir'] + lead_bus * g['lead'] + arp_bus * g['arp']
           + bass_bus * g['bass'] + drum_bus * g['drums'] + fx_bus * g.get('fx', 0.5))
    ref = np.percentile(np.abs(mix), 99.5) + 1e-9
    mix = soft(mix / ref * 0.9, 1.0)          # limitador suave: o pico fica perto de 0,7 sem estourar
    rms = np.sqrt(np.mean(mix ** 2)) + 1e-9
    mix = mix * min(1.0, 0.16 / rms)           # volume médio ~ -16 dBFS; o jogo ainda aplica o volume do jogador
    mix = np.clip(mix, -0.97, 0.97)
    return mix

def pat_even(*rows):
    return list(rows)

# ---------------------------------------------------------------- as 4 trilhas
D_LYD = [0, 2, 4, 6, 7, 9, 11]
A_AEO = [0, 2, 3, 5, 7, 8, 10]
E_PHR = [0, 1, 3, 5, 7, 8, 10]
D_HARM = [0, 2, 3, 5, 7, 8, 11]

def eighth(skip=()):
    return [(i * 0.5, 0.5, 0) for i in range(8) if i not in skip]

TRACKS = {
    # fases 1-100 (Fácil e Normal): esperançosa, sinos e coro suave
    "music_1": dict(seed=101, bpm=92, bars=16, root=62, scale=D_LYD,
        chords=[(50, 'maj7'), (45, 'maj'), (47, 'min7'), (43, 'maj7'), (50, 'maj7'), (45, 'maj'), (43, 'maj7'), (45, 'sus2')],
        layers={'pad': (0, 16), 'arp': (0, 16), 'bass': (2, 16), 'choir': (4, 16), 'lead': (8, 16), 'drums': (8, 16)},
        pad_lpf=1900, arp_step=0.5, arp_pat=[0, 2, 4, 3, 5, 2, 4, 1], arp_voice='bell', arp_len=2.2, reverb=0.3,
        bass_pat=[(0.0, 1.9, 0), (2.0, 1.9, 0)], bass_kind='tri', bass_lpf=420,
        drum_pat=[(0.0, 'kick', 0.8), (2.0, 'kick', 0.7), (1.0, 'hat', 0.5), (3.0, 'hat', 0.5), (1.5, 'hat', 0.3), (3.5, 'hat', 0.3)],
        vowel=VOW_O, lead_voice='bell', lead_lo=69, lead_hi=88, lead_lpf=3000,
        lead_patterns=[[(0.0, 1.5), (1.5, 0.5), (2.0, 1.0), (3.0, 1.0)], [(0.0, 1.0), (1.0, 1.0), (2.0, 1.5), (3.5, 0.5)], [(0.0, 2.0), (2.0, 1.0), (3.0, 1.0)]],
        mix=dict(pad=0.9, choir=0.55, lead=0.7, arp=0.55, bass=0.9, drums=0.6), crash_bars=[8]),
    # fases 101-200 (Difícil e Pesadelo): marcha tensa em lá menor
    "music_2": dict(seed=202, bpm=108, bars=16, root=57, scale=A_AEO,
        chords=[(45, 'min'), (41, 'maj'), (48, 'maj'), (43, 'maj'), (45, 'min'), (41, 'maj'), (38, 'min'), (40, 'maj')],
        layers={'pad': (0, 16), 'arp': (0, 16), 'bass': (0, 16), 'lead': (4, 16), 'drums': (0, 16)},
        pad_lpf=1300, arp_step=0.5, arp_pat=[0, 1, 2, 1, 3, 2, 1, 2], arp_voice='pluck', arp_len=1.4, reverb=0.22,
        bass_pat=eighth(), bass_kind='saw', bass_lpf=380, bass_drive=1.5,
        drum_pat=[(0.0, 'kick', 1.0), (1.0, 'snare', 0.8), (2.0, 'kick', 0.9), (2.5, 'kick', 0.6), (3.0, 'snare', 0.8),
                  (0.0, 'taiko', 0.5), (2.0, 'taiko', 0.4)] + [(i * 0.5, 'hat', 0.45) for i in range(8)],
        vowel=VOW_A, lead_voice='saw', lead_lo=64, lead_hi=84, lead_lpf=2300,
        lead_patterns=[[(0.0, 1.0), (1.0, 0.5), (1.5, 0.5), (2.0, 1.5), (3.5, 0.5)], [(0.0, 0.5), (0.5, 0.5), (1.0, 1.0), (2.0, 2.0)], [(0.0, 1.5), (1.5, 1.5), (3.0, 1.0)]],
        mix=dict(pad=0.8, choir=0.0, lead=0.75, arp=0.6, bass=0.95, drums=0.85), crash_bars=[0, 8]),
    # fases 201-300 (Infernal e Abismal): sombria, frígia, baixo pesado
    "music_3": dict(seed=303, bpm=118, bars=16, root=64, scale=E_PHR,
        chords=[(40, 'min'), (41, 'maj'), (40, 'min'), (43, 'maj'), (40, 'min'), (41, 'maj'), (43, 'maj'), (42, 'dim')],
        layers={'pad': (0, 16), 'arp': (2, 16), 'bass': (0, 16), 'lead': (8, 16), 'drums': (0, 16), 'choir': (8, 16)},
        pad_lpf=900, arp_step=0.25, arp_pat=[0, 0, 2, 0, 3, 0, 2, 0], arp_voice='saw', arp_len=1.1, reverb=0.18,
        bass_pat=[(i * 0.25, 0.25, 1 if i % 8 == 7 else 0) for i in range(16)], bass_kind='saw', bass_lpf=300, bass_drive=2.2,
        drum_pat=[(0.0, 'kick', 1.0), (0.75, 'kick', 0.6), (1.0, 'snare', 0.9), (2.0, 'kick', 1.0), (2.5, 'kick', 0.7), (3.0, 'snare', 0.9),
                  (1.0, 'taiko', 0.5), (3.0, 'taiko', 0.5)] + [(i * 0.25, 'hat', 0.3 if i % 2 else 0.5) for i in range(16)],
        vowel=VOW_U, lead_voice='saw', lead_lo=64, lead_hi=81, lead_lpf=1800,
        lead_patterns=[[(0.0, 0.75), (0.75, 0.25), (1.0, 1.0), (2.0, 0.5), (2.5, 0.5), (3.0, 1.0)], [(0.0, 1.0), (1.0, 1.0), (2.0, 0.5), (2.5, 1.5)]],
        mix=dict(pad=0.8, choir=0.7, lead=0.7, arp=0.5, bass=1.0, drums=0.95), crash_bars=[0, 8]),
    # chefes: rápida e épica em ré menor harmônica
    "music_boss": dict(seed=404, bpm=150, bars=16, root=62, scale=D_HARM,
        chords=[(50, 'min'), (46, 'maj'), (43, 'min'), (45, 'maj'), (50, 'min'), (46, 'maj'), (48, 'maj'), (45, 'maj')],
        layers={'pad': (0, 16), 'arp': (0, 16), 'bass': (0, 16), 'lead': (4, 16), 'drums': (0, 16), 'choir': (0, 16)},
        pad_lpf=1500, arp_step=0.25, arp_pat=[0, 2, 1, 3, 0, 2, 4, 3], arp_voice='saw', arp_len=1.0, reverb=0.2,
        bass_pat=[(i * 0.25, 0.25, 1 if i % 8 == 6 else 0) for i in range(16)], bass_kind='saw', bass_lpf=330, bass_drive=2.5,
        drum_pat=[(0.0, 'kick', 1.0), (0.5, 'taiko', 0.7), (1.0, 'snare', 1.0), (1.5, 'kick', 0.7), (2.0, 'kick', 1.0), (2.5, 'taiko2', 0.7),
                  (3.0, 'snare', 1.0), (3.5, 'kick', 0.8)] + [(i * 0.25, 'hat', 0.28 if i % 2 else 0.42) for i in range(16)],
        vowel=VOW_A, lead_voice='saw', lead_lo=62, lead_hi=86, lead_lpf=3200,
        lead_patterns=[[(0.0, 0.5), (0.5, 0.5), (1.0, 0.5), (1.5, 0.5), (2.0, 1.0), (3.0, 1.0)], [(0.0, 0.75), (0.75, 0.75), (1.5, 0.5), (2.0, 1.0), (3.0, 0.5), (3.5, 0.5)]],
        mix=dict(pad=0.7, choir=0.8, lead=0.8, arp=0.55, bass=1.0, drums=1.0, fx=0.6), crash_bars=[0, 4, 8, 12], riser=True),
}
